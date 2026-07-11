"""Render images through fixed 64/128/256-tile ordered-dither codebooks."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


TILE_SIZE = 8
PALETTE_HEX = (
    "000000",
    "0000D8",
    "0000FF",
    "DB0000",
    "FF0000",
    "D800D8",
    "FF00FF",
    "00D800",
    "00FF00",
    "00D8D8",
    "00FFFF",
    "D8D800",
    "FFFF00",
    "D8D8D8",
    "FFFFFF",
    "999999",
)
BAYER_8X8 = np.array(
    [
        [0, 48, 12, 60, 3, 51, 15, 63],
        [32, 16, 44, 28, 35, 19, 47, 31],
        [8, 56, 4, 52, 11, 59, 7, 55],
        [40, 24, 36, 20, 43, 27, 39, 23],
        [2, 50, 14, 62, 1, 49, 13, 61],
        [34, 18, 46, 30, 33, 17, 45, 29],
        [10, 58, 6, 54, 9, 57, 5, 53],
        [42, 26, 38, 22, 41, 25, 37, 21],
    ],
    dtype=np.uint8,
)


def palette_rgb() -> np.ndarray:
    return np.array(
        [
            tuple(int(color[offset : offset + 2], 16) for offset in (0, 2, 4))
            for color in PALETTE_HEX
        ],
        dtype=np.uint8,
    )


def gif_palette() -> list[int]:
    values = palette_rgb().reshape(-1).tolist()
    return values + [0] * (768 - len(values))


def candidate_patterns() -> list[np.ndarray]:
    candidates: list[np.ndarray] = []
    seen: set[bytes] = set()

    def add(tile: np.ndarray) -> None:
        key = tile.tobytes()
        if key not in seen:
            seen.add(key)
            candidates.append(tile.copy())

    for color in range(16):
        add(np.full((TILE_SIZE, TILE_SIZE), color, dtype=np.uint8))

    # Every unordered color pair at seven fill ratios (1/8 through 7/8).
    for color_a in range(16):
        for color_b in range(color_a + 1, 16):
            for eighths_b in range(1, 8):
                mask = BAYER_8X8 < eighths_b * 8
                add(np.where(mask, color_b, color_a).astype(np.uint8))

    return candidates


def select_nested_codebook(candidates: list[np.ndarray], count: int) -> np.ndarray:
    colors = palette_rgb()
    candidate_indices = np.stack(candidates)
    candidate_rgb = colors[candidate_indices].astype(np.float32)
    apparent_colors = candidate_rgb.mean(axis=(1, 2))

    # The first 16 entries are solids. Farthest-point sampling adds diverse
    # patterns while guaranteeing that smaller codebooks are prefixes.
    selected = list(range(16))
    minimum_error = np.full(len(candidates), np.inf, dtype=np.float32)
    for selected_index in selected:
        error = np.mean(
            (apparent_colors - apparent_colors[selected_index]) ** 2, axis=1
        )
        minimum_error = np.minimum(minimum_error, error)
    minimum_error[selected] = -1

    while len(selected) < count:
        next_index = int(np.argmax(minimum_error))
        selected.append(next_index)
        error = np.mean((apparent_colors - apparent_colors[next_index]) ** 2, axis=1)
        minimum_error = np.minimum(minimum_error, error)
        minimum_error[selected] = -1

    return candidate_indices[selected]


def render_with_codebook(source: Image.Image, codebook: np.ndarray) -> tuple[Image.Image, int]:
    source_rgb = np.asarray(source.convert("RGB"), dtype=np.float32)
    colors = palette_rgb()
    codebook_rgb = colors[codebook].astype(np.float32)
    codebook_apparent_colors = codebook_rgb.mean(axis=(1, 2))
    output = np.empty((source.height, source.width), dtype=np.uint8)
    used_tiles: set[int] = set()

    for top in range(0, source.height, TILE_SIZE):
        for left in range(0, source.width, TILE_SIZE):
            source_tile = source_rgb[top : top + 8, left : left + 8]
            source_apparent_color = source_tile.mean(axis=(0, 1))
            errors = np.mean(
                (codebook_apparent_colors - source_apparent_color) ** 2, axis=1
            )
            tile_id = int(np.argmin(errors))
            used_tiles.add(tile_id)
            output[top : top + 8, left : left + 8] = codebook[tile_id]

    result = Image.frombytes("P", source.size, output.tobytes())
    result.putpalette(gif_palette())
    return result, len(used_tiles)


def save_codebook(codebook: np.ndarray, output_directory: Path) -> None:
    columns = 16
    rows = (len(codebook) + columns - 1) // columns
    sheet = np.zeros((rows * 8, columns * 8), dtype=np.uint8)
    for tile_id, tile in enumerate(codebook):
        x = (tile_id % columns) * 8
        y = (tile_id // columns) * 8
        sheet[y : y + 8, x : x + 8] = tile

    image = Image.frombytes("P", (columns * 8, rows * 8), sheet.tobytes())
    image.putpalette(gif_palette())
    image.save(output_directory / f"dither-codebook-{len(codebook)}.gif")
    image.resize((image.width * 4, image.height * 4), Image.Resampling.NEAREST).save(
        output_directory / f"dither-codebook-{len(codebook)}-preview.png"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("inputs", type=Path, nargs="+")
    parser.add_argument(
        "-o",
        "--output-directory",
        type=Path,
        default=Path.cwd(),
    )
    args = parser.parse_args()
    args.output_directory.mkdir(parents=True, exist_ok=True)

    candidates = candidate_patterns()
    master = select_nested_codebook(candidates, 256)

    for size in (64, 128, 256):
        codebook = master[:size]
        save_codebook(codebook, args.output_directory)
        for input_path in args.inputs:
            with Image.open(input_path) as source:
                source.seek(0)
                if source.width % 8 or source.height % 8:
                    raise SystemExit(f"{input_path}: dimensions must be divisible by 8")
                result, used_count = render_with_codebook(source, codebook)

            output_path = args.output_directory / (
                f"{input_path.stem}__fixed-dither-{size}-tiles.gif"
            )
            result.save(output_path)
            print(f"Wrote: {output_path} ({used_count}/{size} codebook tiles used)")


if __name__ == "__main__":
    main()
