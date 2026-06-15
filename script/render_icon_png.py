#!/usr/bin/env python3
"""Render public/icon.png from the v3 brand spec (Medium green concentric mark)."""

from __future__ import annotations

from PIL import Image, ImageDraw

SIZE = 512
CX, CY = SIZE // 2, SIZE // 2
BRAND = (26, 137, 23, 255)  # #1A8917
PAIR = (255, 255, 255, 255)


def ring(draw: ImageDraw.ImageDraw, radius: int, width: int, alpha: int) -> None:
    color = (*BRAND[:3], alpha)
    draw.ellipse(
        (CX - radius, CY - radius, CX + radius, CY + radius),
        outline=color,
        width=width,
    )


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    ring(draw, 200, 3, 64)
    ring(draw, 160, 3, 115)
    draw.ellipse((CX - 112, CY - 112, CX + 112, CY + 112), fill=BRAND)
    draw.ellipse((CX - 72, CY - 18, CX - 36, CY + 18), fill=PAIR)
    draw.ellipse((CX + 36, CY - 18, CX + 72, CY + 18), fill=PAIR)

    out = "public/icon.png"
    img.save(out, format="PNG", optimize=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
