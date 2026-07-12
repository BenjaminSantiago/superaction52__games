"""Combine still images into a looping forward-and-back GIF."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("inputs", type=Path, nargs="+")
    parser.add_argument("--duration", type=int, default=160)
    args = parser.parse_args()

    if len(args.inputs) < 2:
        raise SystemExit("Provide at least two input images")

    frames: list[Image.Image] = []
    for path in args.inputs:
        with Image.open(path) as image:
            image.seek(0)
            frames.append(image.copy())

    ping_pong = frames + frames[-2:0:-1]
    ping_pong[0].save(
        args.output,
        save_all=True,
        append_images=ping_pong[1:],
        duration=args.duration,
        loop=0,
        optimize=False,
        disposal=1,
    )
    print(f"Wrote: {args.output} ({len(ping_pong)} frames)")


if __name__ == "__main__":
    main()
