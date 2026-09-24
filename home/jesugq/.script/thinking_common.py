import os
import re
import select
import shutil
import sys
import termios
import tty

_input_fd = None
_input_settings = None
_ansi = re.compile(r"\033\[[0-?]*[ -/]*[@-~]")


def centered(text):
    visible = _ansi.sub("", text)
    size = shutil.get_terminal_size((80, 24))
    width = size.columns
    padding = max((width - len(visible)) // 2, 0)
    vertical_padding = max((size.lines - 1) // 2, 0)
    return "\033[2J\033[H" + "\n" * vertical_padding + " " * padding + text


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
            select.select([_input_fd], [], [], 0.01)
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
