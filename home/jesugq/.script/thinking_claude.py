#!/usr/bin/env python3

# Claude Code: sparkle palindrome (Spinner.tsx) + dark theme claude / claudeShimmer
import os
import signal
import sys
import time

sys.path.insert(0, os.path.expanduser("~/.script"))
from thinking_common import centered, enable_quit, quit_requested, restore_terminal

# getDefaultCharacters() (darwin) + reverse — Spinner.tsx SPINNER_FRAMES
BASE = ["·", "✢", "✱", "✶", "✻", "✽"]
FRAMES = BASE + BASE[::-1]
TEXT = sys.argv[1] if len(sys.argv) > 1 else "Thinking…"
SPIN_MS = 0.12
INTERVAL = 0.05
CYCLE = 2.0
PAD = "  "
# darkTheme: claude rgb(215,119,87) / claudeShimmer rgb(235,159,127)
CLAUDE = (215, 119, 87)
SHIMMER = (235, 159, 127)
reset = "\033[0m"


def lerp(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(x + (y - x) * t) for x, y in zip(a, b))


def gradient_at(elapsed):
    x = (elapsed % CYCLE) / CYCLE
    t = x * 2 if x < 0.5 else 2 - x * 2
    return lerp(CLAUDE, SHIMMER, t)


def rgb(color):
    return f"\033[38;2;{color[0]};{color[1]};{color[2]}m"


def restore(*_):
    restore_terminal(reset)


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
    color = gradient_at(elapsed)
    frame = FRAMES[int(elapsed / SPIN_MS) % len(FRAMES)]
    sys.stdout.write(centered(f"{rgb(color)}{frame} {TEXT}{reset}"))
    sys.stdout.flush()
    time.sleep(INTERVAL)
