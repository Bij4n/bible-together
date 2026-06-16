#!/usr/bin/env python3
"""Render public/icon.png from the open-book brand mark."""

from __future__ import annotations

from PIL import Image, ImageDraw

SIZE = 512
SCALE = SIZE / 48
BRAND = (26, 137, 23, 255)  # #1A8917
SHINE = (255, 255, 255, 38)
DOT = (255, 255, 255, 255)


def scale(x: float, y: float) -> tuple[float, float]:
    return x * SCALE, y * SCALE


def polygon(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], fill) -> None:
    draw.polygon([scale(x, y) for x, y in points], fill=fill)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    left_book = [(24, 41), (24, 14.5), (9, 18), (7, 28.5), (10, 39.5), (24, 41)]
    right_book = [(24, 41), (24, 14.5), (39, 18), (41, 28.5), (38, 39.5), (24, 41)]
    left_shine = [(24, 16.5), (24, 39), (12.5, 35), (11, 27), (24, 16.5)]
    right_shine = [(24, 16.5), (24, 39), (35.5, 35), (37, 27), (24, 16.5)]

    polygon(draw, left_book, BRAND)
    polygon(draw, right_book, BRAND)
    polygon(draw, left_shine, SHINE)
    polygon(draw, right_shine, SHINE)

    for cx, cy, r in [(14.5, 10, 3.25), (33.5, 10, 3.25)]:
        sx, sy = scale(cx, cy)
        sr = r * SCALE
        draw.ellipse((sx - sr, sy - sr, sx + sr, sy + sr), fill=DOT)

    out = "public/icon.png"
    img.save(out, format="PNG", optimize=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
