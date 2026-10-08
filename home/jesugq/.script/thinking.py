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
LOREM = (
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
    "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, "
    "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo "
    "consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse "
    "cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat "
    "non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
)


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


def load_lines(path):
    lines = [line.strip() for line in load_text(path).splitlines() if line.strip()]
    if not lines:
        sys.stderr.write(f"thinking: {path}: no messages\n")
        raise SystemExit(1)
    return lines


def parse_invocation(default_label):
    """Optional positional args, same shape as the afk pane commands.

    script.py
    script.py MESSAGES
    script.py MESSAGES REASONING

    MESSAGES is a text file with one status line per row. REASONING is the
    dimmed text file. Both start on a random line and loop back to the top.
    """
    args = sys.argv[1:]
    messages = [default_label]
    text = LOREM
    if args:
        messages = load_lines(args[0])
    if len(args) > 1:
        text = load_text(args[1])
    return messages, text


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
        self.lines = lines or ["Thinking"]
        self.start = random.randrange(len(self.lines))

    def current(self, elapsed):
        index = (self.start + int(elapsed / LABEL_INTERVAL)) % len(self.lines)
        return self.lines[index]


def reasoning_limit(height):
    return max(height - STATUS_ROWS, 0)


class Reasoning:
    def __init__(self, source):
        self.tokens = tokenize(rotate_to_random_line(source)) or tokenize(LOREM)
        self.max_lines = 1
        self.index = 0
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

    def _emit(self):
        token = self.tokens[self.index % len(self.tokens)]
        cycling = self.index > 0 and self.index % len(self.tokens) == 0
        self.index += 1
        if cycling and (not self.emitted or self.emitted[-1] is not None):
            self.emitted.append(None)
        if token is None:
            self.emitted.append(None)
            self.next_at += BREAK_INTERVAL
            return
        self.emitted.append(token)
        self.next_at += WORD_INTERVAL

    def _wrap(self, tokens):
        rows = []
        current = ""
        for token in tokens:
            if token is None:
                if current:
                    rows.append(current)
                    current = ""
                rows.append("")
                continue
            if current and len(current) + 1 + len(token) > self.limit:
                rows.append(current)
                current = token
            elif current:
                current = f"{current} {token}"
            else:
                current = token
        if current:
            rows.append(current)
        return rows

    def _trim(self):
        # Keep already-printed lines so a wider wrap can bring them back.
        slack = max(self.max_lines * 8, self.max_lines)
        rows = self._wrap(self.emitted)
        if len(rows) <= slack:
            return
        kept = []
        for row in rows[-slack:]:
            if row == "":
                kept.append(None)
            else:
                kept.extend(row.split())
        self.emitted = kept

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


def run(render, interval, default_label="Thinking..."):
    messages, source = parse_invocation(default_label)
    status = Messages(messages)
    reasoning = Reasoning(source)

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
