#!/usr/bin/env python3
"""Render frames logged by the "Dump Frame" button as LED matrix PNGs.

    esphome logs your-device.yaml | tee frames.log
    (pick a preset in Home Assistant, press "Dump Frame", repeat)
    python3 tools/render_frames.py frames.log docs/img/

Writes one PNG per preset, named after it ("Hot Tub" -> hot-tub.png). Of several
dumps of one preset the one with the most lit LEDs is kept, so blinking colons
show. Pixels are drawn square, as the case's pixel grid shows them; --style round
draws bare LEDs. Needs Pillow.
"""

import argparse
from pathlib import Path
import re
import sys

from PIL import Image, ImageDraw

ANSI = re.compile(r"\x1b\[[0-9;]*m")
FRAME_LINE = re.compile(r"\[frame(?::\d+)?\]:\s*(.*)$")
BEGIN = re.compile(r"^begin (\d+)x(\d+) (.*)$")
ROW = re.compile(r"^(\d+)\s+([0-9a-f]+)$")

PITCH = 16  # image pixels per LED
CELL = 14  # square style: grid cell, about the case grid's 3.5 mm opening at 4 mm pitch
DOT = 12  # round style: LED diameter
STYLES = ("square", "round")
BACKGROUND = (12, 12, 12)
LED_OFF = (45, 12, 10)
LED_ON = (255, 48, 32)


def parse(lines):
    """Return [(preset, [hex row, ...])] in log order, skipping incomplete dumps."""
    frames = []  # (preset, width, height, rows)
    for raw in lines:
        m = FRAME_LINE.search(ANSI.sub("", raw).rstrip())
        if not m:
            continue
        text = m.group(1)
        if begin := BEGIN.match(text):
            width, height, preset = begin.groups()
            frames.append((preset.strip(), int(width), int(height), []))
        elif frames and (row := ROW.match(text)):
            rows = frames[-1][3]
            if int(row.group(1)) == len(rows):
                rows.append(row.group(2))
            else:
                rows.append(None)  # lost or out-of-order log line
    complete = []
    for preset, width, height, rows in frames:
        if len(rows) == height and all(r is not None and len(r) * 4 == width for r in rows):
            complete.append((preset, rows))
        else:
            print(f"skipping incomplete dump of {preset!r}", file=sys.stderr)
    return complete


def pick(frames):
    """Return {preset: rows}, keeping the dump with the most lit LEDs per preset."""
    best = {}
    for preset, rows in frames:
        lit = sum(bin(int(r, 16)).count("1") for r in rows)
        if preset not in best or lit > best[preset][0]:
            best[preset] = (lit, rows)
    return {preset: rows for preset, (_, rows) in best.items()}


def render(rows, path, style="square"):
    width = len(rows[0]) * 4
    img = Image.new("RGB", (width * PITCH, len(rows) * PITCH), BACKGROUND)
    draw = ImageDraw.Draw(img)
    size = CELL if style == "square" else DOT
    inset = (PITCH - size) // 2
    shape = draw.rectangle if style == "square" else draw.ellipse
    for y, row in enumerate(rows):
        bits = f"{int(row, 16):0{width}b}"
        for x, bit in enumerate(bits):
            x0, y0 = x * PITCH + inset, y * PITCH + inset
            shape(
                [x0, y0, x0 + size - 1, y0 + size - 1],
                fill=LED_ON if bit == "1" else LED_OFF,
            )
    img.save(path)


def slug(preset):
    return re.sub(r"[^a-z0-9]+", "-", preset.lower()).strip("-") or "frame"


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("log", type=Path, help="log captured with esphome logs")
    parser.add_argument("outdir", type=Path, help="folder for the PNGs")
    parser.add_argument("--style", choices=STYLES, default="square", help="pixel shape")
    args = parser.parse_args()

    frames = parse(args.log.read_text(errors="replace").splitlines())
    if not frames:
        sys.exit("no complete frame dumps found; is the Dump Frame button enabled?")
    args.outdir.mkdir(parents=True, exist_ok=True)
    for preset, rows in pick(frames).items():
        path = args.outdir / f"{slug(preset)}.png"
        render(rows, path, args.style)
        print(f"{preset} -> {path}")


if __name__ == "__main__":
    main()
