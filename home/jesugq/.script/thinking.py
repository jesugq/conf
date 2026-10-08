import os
import random
import re
import select
import shutil
import signal
import sys
import termios
import time
import tty

_input_fd = None
_input_settings = None
_ansi = re.compile(r"\033\[[0-?]*[ -/]*[@-~]")
_teammate = re.compile(r"\{\{TEAMMATE\}\}")

# Halfway between the old faint gray (120, 120, 128) and Ryuuko foreground.
DIM = "\033[38;2;178;178;182m"
RESET = "\033[0m"
# Halfway between the original 0.18s/word pace and the fast 0.016s stream.
WORD_INTERVAL = 0.098
BREAK_INTERVAL = 0.12
# Status verbs ("Thinking", "Writing", ...) hold for about ten seconds.
LABEL_INTERVAL = 10
# The status band is a blank row, the centered line, and a blank row.
STATUS_ROWS = 3


def tokenize(text):
    """Words, with None marking a blank line so paragraphs stay separated."""
    tokens = []
    for line in text.splitlines():
        words = line.split()
        if words:
            tokens.extend(words)
        else:
            tokens.append(None)
    while tokens and tokens[0] is None:
        tokens.pop(0)
    while tokens and tokens[-1] is None:
        tokens.pop()
    return tokens


def load_text(path):
    try:
        with open(os.path.expanduser(path), encoding="utf-8") as handle:
            return handle.read()
    except OSError as exc:
        name = exc.filename or path
        sys.stderr.write(f"thinking: {name}: {exc.strerror}\n")
        raise SystemExit(1) from exc


def load_lines(path, kind):
    lines = [line.strip() for line in load_text(path).splitlines() if line.strip()]
    if not lines:
        sys.stderr.write(f"thinking: {path}: no {kind}\n")
        raise SystemExit(1)
    return lines


def parse_invocation():
    """Positional args, same shape as the afk pane commands.

    script.py MESSAGES NAMES REASONING

    MESSAGES is a text file with one status line per row. NAMES is the same
    shape, one person per row. REASONING is the dimmed text file. Each
    Each {{TEAMMATE}} is replaced, as it is printed, with the next name.
    Messages, names, and reasoning each start on a random line and loop.
    """
    args = sys.argv[1:]
    if len(args) < 3:
        sys.stderr.write("thinking: messages, names, and reasoning files are expected\n")
        raise SystemExit(1)
    messages = load_lines(args[0], "messages")
    names = load_lines(args[1], "names")
    text = load_text(args[2])
    if not tokenize(text):
        sys.stderr.write(f"thinking: {args[2]}: no reasoning\n")
        raise SystemExit(1)
    return messages, names, text


def rotate_to_random_line(text):
    """Begin at a random non-empty line, then continue through the file."""
    lines = text.splitlines()
    filled = [index for index, line in enumerate(lines) if line.strip()]
    if len(filled) <= 1:
        return text
    start = random.choice(filled)
    return "\n".join(lines[start:] + lines[:start])


class Messages:
    def __init__(self, lines):
        self.lines = lines
        self.start = random.randrange(len(self.lines))

    def current(self, elapsed):
        index = (self.start + int(elapsed / LABEL_INTERVAL)) % len(self.lines)
        return self.lines[index]


def reasoning_limit(height):
    return max(height - STATUS_ROWS, 0)


class Reasoning:
    def __init__(self, source, names):
        self.tokens = tokenize(rotate_to_random_line(source))
        self.names = names
        self.name_at = random.randrange(len(names))
        self.max_lines = 1
        self.index = 0
        self.pending = []
        self.emitted = []
        self.next_at = 0.0
        self.limit = 8

    def advance(self, elapsed, width, max_lines):
        self.limit = max(width - 2, 8)
        self.max_lines = max(0, max_lines)
        emitted = 0
        while self.max_lines > 0 and elapsed >= self.next_at and emitted < 4:
            self._emit()
            emitted += 1
        self._trim()
        return self.visible()

    def _next_name(self):
        """Next person, walking forward from a random line and wrapping."""
        name = self.names[self.name_at % len(self.names)]
        self.name_at += 1
        return name

    def _fill_teammate(self, token):
        """Swap each {{TEAMMATE}} for the next name. A suffix stays on the last word."""
        if "{{TEAMMATE}}" not in token:
            return [token]
        filled = _teammate.sub(lambda _match: self._next_name(), token)
        return filled.split() or [token]

    def _emit(self):
        if self.pending:
            self.emitted.append(self.pending.pop(0))
            self.next_at += WORD_INTERVAL
            return
        token = self.tokens[self.index % len(self.tokens)]
        cycling = self.index > 0 and self.index % len(self.tokens) == 0
        self.index += 1
        if cycling and (not self.emitted or self.emitted[-1] is not None):
            self.emitted.append(None)
        if token is None:
            self.emitted.append(None)
            self.next_at += BREAK_INTERVAL
            return
        pieces = self._fill_teammate(token)
        self.emitted.append(pieces[0])
        self.pending.extend(pieces[1:])
        self.next_at += WORD_INTERVAL

    def _hyphenate(self, token):
        """Break a token that cannot fit on one line, marking each cut with '-'."""
        limit = max(self.limit, 2)
        if len(token) <= limit:
            return [token]
        pieces = []
        while len(token) > limit:
            pieces.append(token[: limit - 1] + "-")
            token = token[limit - 1 :]
        if token:
            pieces.append(token)
        return pieces

    def _layout(self, tokens):
        """Wrap tokens. Each row records the emitted token that starts it."""
        rows = []
        starts = []
        current = ""
        current_start = None

        def flush():
            nonlocal current, current_start
            if current_start is None:
                return
            rows.append(current)
            starts.append(current_start)
            current = ""
            current_start = None

        for index, token in enumerate(tokens):
            if token is None:
                flush()
                rows.append("")
                starts.append(index)
                continue
            for piece in self._hyphenate(token):
                if current and len(current) + 1 + len(piece) > self.limit:
                    flush()
                if current:
                    current = f"{current} {piece}"
                else:
                    current = piece
                    current_start = index
        flush()
        return rows, starts

    def _wrap(self, tokens):
        rows, _starts = self._layout(tokens)
        return rows

    def _trim(self):
        # Keep already-printed lines so a wider wrap can bring them back.
        # Drop whole tokens so a later resize can rehyphenate the originals.
        slack = max(self.max_lines * 8, self.max_lines)
        rows, starts = self._layout(self.emitted)
        if len(rows) <= slack:
            return
        self.emitted = self.emitted[starts[len(rows) - slack] :]

    def visible(self):
        if self.max_lines <= 0:
            return []
        return self._wrap(self.emitted)[-self.max_lines :]


def centered(text, above=(), column=0):
    visible = _ansi.sub("", text)
    size = shutil.get_terminal_size((80, 24))
    width = size.columns
    height = size.lines
    padding = max((width - len(visible)) // 2, 0)
    room = reasoning_limit(height)
    rows = list(above)
    if len(rows) > room:
        rows = rows[-room:]
    if column <= 0:
        column = max((len(_ansi.sub("", line)) for line in rows), default=0)
    left = max((width - min(column, width)) // 2, 0)
    # Middle row of the bottom 3-line band. Reasoning sits above that band.
    status_row = max(height - (STATUS_ROWS // 2) - 1, 0)
    start = status_row - 1 - len(rows)
    parts = ["\033[2J\033[H"]
    for offset, line in enumerate(rows):
        if not line:
            continue
        parts.append(f"\033[{start + offset + 1};1H{' ' * left}{DIM}{line}{RESET}")
    parts.append(f"\033[{status_row + 1};1H{' ' * padding}{text}")
    return "".join(parts)


def enable_quit():
    global _input_fd, _input_settings
    try:
        _input_fd = os.open("/dev/tty", os.O_RDONLY)
        _input_settings = termios.tcgetattr(_input_fd)
        tty.setcbreak(_input_fd)
    except (OSError, termios.error):
        if _input_fd is not None:
            os.close(_input_fd)
        _input_fd = None
        _input_settings = None


def _discard_terminal_reply(kind):
    """Eat an OSC or CSI sequence so a color query is not a keypress."""
    end = time.time() + 0.05
    if kind == b"]":
        buf = b""
        while time.time() < end:
            ready, _, _ = select.select([_input_fd], [], [], max(0.0, end - time.time()))
            if not ready:
                return
            buf += os.read(_input_fd, 1)
            if buf.endswith(b"\a") or buf.endswith(b"\033\\"):
                return
        return
    while time.time() < end:
        ready, _, _ = select.select([_input_fd], [], [], max(0.0, end - time.time()))
        if not ready:
            return
        ch = os.read(_input_fd, 1)
        if ch and 0x40 <= ch[0] <= 0x7E:
            return


def quit_requested():
    if _input_fd is None:
        return False
    try:
        ready, _, _ = select.select([_input_fd], [], [], 0)
        if not ready:
            return False
        key = os.read(_input_fd, 1)
        if key.lower() == b"q":
            return True
        if key == b"\033":
            ready, _, _ = select.select([_input_fd], [], [], 0.01)
            if not ready:
                return True
            nxt = os.read(_input_fd, 1)
            # OSC/CSI replies (Codex color queries) are not a quit key.
            if nxt in (b"]", b"["):
                _discard_terminal_reply(nxt)
                return False
            return True
        return False
    except (OSError, termios.error):
        return False


def restore_terminal(reset):
    if _input_fd is not None and _input_settings is not None:
        try:
            termios.tcsetattr(_input_fd, termios.TCSADRAIN, _input_settings)
        except (OSError, termios.error):
            pass
        os.close(_input_fd)
    sys.stdout.write("\033[?25h" + reset + "\n")
    sys.stdout.flush()
    os._exit(0)


def run(render, interval):
    messages, names, source = parse_invocation()
    status = Messages(messages)
    reasoning = Reasoning(source, names)

    def restore(*_):
        restore_terminal(RESET)

    enable_quit()
    signal.signal(signal.SIGINT, restore)
    signal.signal(signal.SIGTERM, restore)
    sys.stdout.write("\033[?25l\n")
    sys.stdout.flush()
    start = time.monotonic()
    while True:
        if quit_requested():
            restore()
        elapsed = time.monotonic() - start
        size = shutil.get_terminal_size((80, 24))
        above = reasoning.advance(elapsed, size.columns, reasoning_limit(size.lines))
        sys.stdout.write(centered(render(elapsed, status.current(elapsed)), above, reasoning.limit))
        sys.stdout.flush()
        time.sleep(interval)
