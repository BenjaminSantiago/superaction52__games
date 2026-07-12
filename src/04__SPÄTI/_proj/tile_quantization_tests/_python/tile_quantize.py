"""Lossy, flip-aware 8x8 tile quantizer for indexed-color images."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


FLIPS = (
    ("none", lambda tile: tile),
    ("x", lambda tile: np.fliplr(tile)),
    ("y", lambda tile: np.flipud(tile)),
    ("xy", lambda tile: np.flipud(np.fliplr(tile))),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Replace similar 8x8 tiles with shared representative tiles. "
            "Comparison uses RGB color distance and tests X/Y flips."
        )
    )
    parser.add_argument("input", type=Path, help="Single-frame indexed image")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Output GIF; only valid when processing one threshold",
    )
    parser.add_argument(
        "-t",
        "--thresholds",
        type=float,
        nargs="+",
        default=0.95,
        help=(
            "One or more minimum similarities, as decimals or percentages "
            "(examples: 0.9 0.8, or 90 80; default: 0.95)"
        ),
    )
    parser.add_argument(
        "-s",
        "--tile-size",
        type=int,
        default=8,
        choices=(8, 16, 32),
        help="Square tile size in pixels: 8, 16, or 32 (default: 8)",
    )
    parser.add_argument(
        "--animation",
        type=Path,
        help="Also combine the generated levels into a looping ping-pong GIF",
    )
    parser.add_argument(
        "--frame-duration",
        type=int,
        default=160,
        help="Animation frame duration in milliseconds (default: 160)",
    )
    return parser.parse_args()


def normalize_threshold(value: float) -> float:
    if 1.0 < value <= 100.0:
        value /= 100.0
    if not 0.0 <= value <= 1.0:
        raise SystemExit("Thresholds must be between 0 and 1, or 0 and 100")
    return value


def threshold_label(threshold: float) -> str:
    percentage = threshold * 100
    return (
        str(int(percentage))
        if percentage.is_integer()
        else f"{percentage:g}".replace(".", "_")
    )


def similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Return 1 for identical RGB tiles and 0 for maximum RGB error."""
    difference = a.astype(np.float32) - b.astype(np.float32)
    rmse = float(np.sqrt(np.mean(difference * difference)))
    return 1.0 - (rmse / 255.0)


def quantize_tiles(
    indices: np.ndarray,
    rgb: np.ndarray,
    threshold: float,
    tile_size: int,
) -> tuple[np.ndarray, int, float]:
    output = np.empty_like(indices)
    representatives: list[tuple[np.ndarray, np.ndarray]] = []
    similarities: list[float] = []

    height, width = indices.shape
    for top in range(0, height, tile_size):
        for left in range(0, width, tile_size):
            index_tile = indices[top : top + tile_size, left : left + tile_size]
            rgb_tile = rgb[top : top + tile_size, left : left + tile_size]

            best_score = -1.0
            best_indices = None

            for representative_indices, representative_rgb in representatives:
                for _, flip in FLIPS:
                    candidate_rgb = flip(representative_rgb)
                    score = similarity(rgb_tile, candidate_rgb)
                    if score > best_score:
                        best_score = score
                        best_indices = flip(representative_indices)

            if best_indices is not None and best_score >= threshold:
                output[top : top + tile_size, left : left + tile_size] = best_indices
                similarities.append(best_score)
            else:
                stored_indices = index_tile.copy()
                stored_rgb = rgb_tile.copy()
                representatives.append((stored_indices, stored_rgb))
                output[top : top + tile_size, left : left + tile_size] = stored_indices
                similarities.append(1.0)

    return output, len(representatives), float(np.mean(similarities))


def main() -> None:
    args = parse_args()
    raw_thresholds = (
        args.thresholds if isinstance(args.thresholds, list) else [args.thresholds]
    )
    thresholds = [normalize_threshold(value) for value in raw_thresholds]
    if args.output is not None and len(thresholds) != 1:
        raise SystemExit("--output can only be used with one threshold")

    with Image.open(args.input) as source:
        if getattr(source, "n_frames", 1) != 1:
            raise SystemExit("This script accepts single-frame images only")
        if source.mode != "P":
            raise SystemExit(f"Expected an indexed P-mode image, got {source.mode!r}")
        if source.width % args.tile_size or source.height % args.tile_size:
            raise SystemExit(
                f"Image width and height must both be divisible by {args.tile_size}"
            )

        source.load()
        indices = np.asarray(source, dtype=np.uint8)
        rgb = np.asarray(source.convert("RGB"), dtype=np.uint8)
        palette = source.getpalette()
        transparency = source.info.get("transparency")

    total_tiles = (indices.shape[1] // args.tile_size) * (
        indices.shape[0] // args.tile_size
    )
    animation_frames: list[Image.Image] = []
    for threshold in thresholds:
        output_indices, representative_count, average_similarity = quantize_tiles(
            indices, rgb, threshold, args.tile_size
        )
        output_path = args.output or args.input.with_name(
            f"{args.input.stem}__tile-quantized-{args.tile_size}x{args.tile_size}"
            f"-{threshold_label(threshold)}pct.gif"
        )
        result = Image.frombytes(
            "P",
            (output_indices.shape[1], output_indices.shape[0]),
            output_indices.tobytes(),
        )
        if palette is not None:
            result.putpalette(palette)

        save_options = {}
        if transparency is not None:
            save_options["transparency"] = transparency
        result.save(output_path, **save_options)
        animation_frames.append(result.copy())

        print(f"Wrote: {output_path}")
        print(
            f"  Threshold: {threshold:.2%}; tiles: {total_tiles} total -> "
            f"{representative_count} representatives"
        )
        print(f"  Average selected-tile similarity: {average_similarity:.4f}")

    if args.animation is not None:
        if len(animation_frames) < 2:
            raise SystemExit("--animation requires at least two thresholds")
        ping_pong = animation_frames + animation_frames[-2:0:-1]
        animation_options = {
            "save_all": True,
            "append_images": ping_pong[1:],
            "duration": args.frame_duration,
            "loop": 0,
            "optimize": False,
            "disposal": 1,
        }
        if transparency is not None:
            animation_options["transparency"] = transparency
        ping_pong[0].save(args.animation, **animation_options)
        print(f"Wrote animation: {args.animation} ({len(ping_pong)} frames)")


if __name__ == "__main__":
    main()
