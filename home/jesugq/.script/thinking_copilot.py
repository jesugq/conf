#!/usr/bin/env python3

# Copilot CLI TextSpinner animation (1.0.x)
import math
import os
import signal
import sys
import time

sys.path.insert(0, os.path.expanduser("~/.script"))
from thinking_common import centered, enable_quit, quit_requested, restore_terminal

TEXT = sys.argv[1] if len(sys.argv) > 1 else "Working"
PAD = "  "
PULSE_FRAMES = "●◉◎○◎◉"
INTERVAL = 0.09
TICK_STEP = 3
PAUSE = 0.3
# Copilot's "default" theme delegates these colors to the terminal palette.
BRAND = "\033[35m"
BRAND_BRIGHT = "\033[95m"
GRADIENT = (
    BRAND_BRIGHT,
    BRAND_BRIGHT,
    BRAND,
    BRAND,
    BRAND,
    BRAND,
    BRAND_BRIGHT,
    BRAND_BRIGHT,
)
RESET = "\033[0m"


def render(elapsed):
    ticks = int(elapsed / INTERVAL) * TICK_STEP
    gradient_length = len(GRADIENT)
    shimmer_length = len(TEXT) + gradient_length
    pause_ticks = round(PAUSE / INTERVAL) * TICK_STEP
    cycle = math.ceil((shimmer_length + pause_ticks) / TICK_STEP) * TICK_STEP
    position = min(ticks % cycle, shimmer_length)
    frame_index = (ticks // TICK_STEP) % len(PULSE_FRAMES)
    sweep_width = max((gradient_length - 1) * 2, 1)
    sweep = (ticks // TICK_STEP) % sweep_width
    color_index = sweep if sweep < gradient_length else sweep_width - sweep

    text = []
    for index, character in enumerate(TEXT):
        gradient_index = position - index
        color = GRADIENT[gradient_index] if 0 <= gradient_index < gradient_length else BRAND
        text.append(f"{color}{character}")
    return f"{GRADIENT[color_index]}{PULSE_FRAMES[frame_index]}{RESET} " + "".join(text) + RESET


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
    sys.stdout.write(centered(render(elapsed)))
    sys.stdout.flush()
    time.sleep(INTERVAL)
