"""Animate an indexed GIF's brightest used color toward magenta and back."""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    parser.add_argument("--frames", type=int, default=32)
    parser.add_argument("--duration", type=int, default=60, help="Milliseconds per frame")
    args = parser.parse_args()

    if args.frames < 2:
        raise SystemExit("--frames must be at least 2")

    with Image.open(args.input) as source:
        if source.mode != "P":
            raise SystemExit(f"Expected an indexed P-mode GIF, got {source.mode!r}")
        source.seek(0)
        source.load()
        base = source.copy()
        palette = source.getpalette()
        transparency = source.info.get("transparency")

    if palette is None:
        raise SystemExit("The image has no palette")

    used_indices = {index for _, index in (base.getcolors(maxcolors=256) or [])}
    if transparency is not None:
        used_indices.discard(transparency)
    if not used_indices:
        raise SystemExit("The image has no visible palette entries")

    def luminance(index: int) -> float:
        red, green, blue = palette[index * 3 : index * 3 + 3]
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue

    brightest = max(used_indices, key=luminance)
    original = tuple(palette[brightest * 3 : brightest * 3 + 3])
    target = (255, 0, 255)
    frames: list[Image.Image] = []

    for frame_number in range(args.frames):
        phase = 2.0 * math.pi * frame_number / args.frames
        amount = (1.0 - math.cos(phase)) / 2.0
        animated_color = tuple(
            round(start + (end - start) * amount)
            for start, end in zip(original, target)
        )
        frame_palette = palette.copy()
        offset = brightest * 3
        frame_palette[offset : offset + 3] = animated_color
        frame = base.copy()
        frame.putpalette(frame_palette)
        frames.append(frame)

    output = args.output or args.input.with_name(f"{args.input.stem}__white-to-magenta.gif")
    save_options = {
        "save_all": True,
        "append_images": frames[1:],
        "duration": args.duration,
        "loop": 0,
        "optimize": False,
        "disposal": 1,
    }
    if transparency is not None:
        save_options["transparency"] = transparency
    frames[0].save(output, **save_options)

    print(f"Wrote: {output}")
    print(f"Animated palette index: {brightest}")
    print(f"Color: #{original[0]:02X}{original[1]:02X}{original[2]:02X} <-> #FF00FF")
    print(f"Frames: {args.frames}; duration: {args.duration} ms each")


if __name__ == "__main__":
    main()
