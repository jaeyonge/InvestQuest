from __future__ import annotations

from math import cos, pi, sin
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
APP_ICON_DIR = ROOT / "Sources/InvestQuest/Resources/Assets.xcassets/AppIcon.appiconset"
PREVIEW_PATH = ROOT / "docs/generated/AppIcon-preview.png"
MASTER_SIZE = 1024

ICON_SIZES = {
    "AppIcon-20@1x.png": 20,
    "AppIcon-20@2x.png": 40,
    "AppIcon-20@2x-ipad.png": 40,
    "AppIcon-20@3x.png": 60,
    "AppIcon-29@1x.png": 29,
    "AppIcon-29@2x.png": 58,
    "AppIcon-29@2x-ipad.png": 58,
    "AppIcon-29@3x.png": 87,
    "AppIcon-40@1x.png": 40,
    "AppIcon-40@2x.png": 80,
    "AppIcon-40@2x-ipad.png": 80,
    "AppIcon-40@3x.png": 120,
    "AppIcon-60@2x.png": 120,
    "AppIcon-60@3x.png": 180,
    "AppIcon-76@2x.png": 152,
    "AppIcon-83.5@2x.png": 167,
}


def lerp_color(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[index] + (b[index] - a[index]) * t) for index in range(3))


def apply_glow(
    image: Image.Image,
    *,
    shape: str,
    bbox: tuple[int, int, int, int],
    color: tuple[int, int, int],
    blur_radius: int,
    alpha: int,
) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    fill = (*color, alpha)
    if shape == "ellipse":
        draw.ellipse(bbox, fill=fill)
    else:
        draw.rounded_rectangle(bbox, radius=120, fill=fill)
    overlay = overlay.filter(ImageFilter.GaussianBlur(blur_radius))
    return Image.alpha_composite(image, overlay)


def line_glow(
    image: Image.Image,
    *,
    points: list[tuple[int, int]],
    color: tuple[int, int, int],
    width: int,
    blur_radius: int,
    alpha: int,
) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.line(points, fill=(*color, alpha), width=width, joint="curve")
    overlay = overlay.filter(ImageFilter.GaussianBlur(blur_radius))
    return Image.alpha_composite(image, overlay)


def star_points(
    center: tuple[float, float],
    outer_radius: float,
    inner_radius: float,
    count: int = 5,
) -> list[tuple[float, float]]:
    cx, cy = center
    points: list[tuple[float, float]] = []
    for index in range(count * 2):
        radius = outer_radius if index % 2 == 0 else inner_radius
        angle = -pi / 2 + index * pi / count
        points.append((cx + cos(angle) * radius, cy + sin(angle) * radius))
    return points


def build_background() -> Image.Image:
    top_left = (111, 235, 255)
    mid = (80, 169, 255)
    bottom_right = (37, 78, 255)

    image = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)

    for y in range(MASTER_SIZE):
        vertical_t = y / (MASTER_SIZE - 1)
        vertical_color = lerp_color(top_left, bottom_right, vertical_t)
        for x in range(MASTER_SIZE):
            horizontal_t = x / (MASTER_SIZE - 1)
            color = lerp_color(vertical_color, mid, 0.35 * (1 - horizontal_t))
            draw.point((x, y), fill=(*color, 255))

    image = apply_glow(
        image,
        shape="ellipse",
        bbox=(-140, -80, 520, 520),
        color=(255, 255, 255),
        blur_radius=70,
        alpha=90,
    )
    image = apply_glow(
        image,
        shape="ellipse",
        bbox=(540, 560, 1080, 1100),
        color=(106, 82, 255),
        blur_radius=100,
        alpha=65,
    )
    image = apply_glow(
        image,
        shape="ellipse",
        bbox=(40, 680, 300, 940),
        color=(255, 149, 77),
        blur_radius=80,
        alpha=70,
    )

    return image


def build_coin() -> Image.Image:
    layer = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    mask = Image.new("L", (MASTER_SIZE, MASTER_SIZE), 0)
    mask_draw = ImageDraw.Draw(mask)
    coin_bounds = (156, 204, 740, 788)
    mask_draw.ellipse(coin_bounds, fill=255)

    gradient = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    gradient_draw = ImageDraw.Draw(gradient)
    top = (255, 228, 122)
    middle = (255, 194, 72)
    bottom = (255, 150, 35)
    for y in range(MASTER_SIZE):
        t = (y - coin_bounds[1]) / (coin_bounds[3] - coin_bounds[1])
        t = min(max(t, 0), 1)
        if t < 0.55:
            color = lerp_color(top, middle, t / 0.55)
        else:
            color = lerp_color(middle, bottom, (t - 0.55) / 0.45)
        gradient_draw.line((coin_bounds[0], y, coin_bounds[2], y), fill=(*color, 255))
    gradient.putalpha(mask)
    layer = Image.alpha_composite(layer, gradient)

    draw = ImageDraw.Draw(layer)
    draw.ellipse(coin_bounds, outline=(255, 245, 210, 190), width=12)
    draw.ellipse((196, 244, 700, 748), outline=(255, 255, 255, 72), width=8)
    draw.ellipse((250, 250, 598, 452), fill=(255, 255, 255, 92))
    draw.ellipse((214, 604, 394, 734), fill=(255, 255, 255, 32))

    return layer.filter(ImageFilter.GaussianBlur(0.4))


def build_chart_path() -> Image.Image:
    shadow_color = (11, 40, 122)
    white = (255, 255, 255)
    cyan = (100, 236, 255)
    indigo = (40, 76, 208)

    points = [(248, 694), (370, 560), (492, 612), (648, 420), (822, 286)]

    image = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    image = line_glow(
        image,
        points=points,
        color=(255, 255, 255),
        width=142,
        blur_radius=24,
        alpha=150,
    )
    image = line_glow(
        image,
        points=points,
        color=cyan,
        width=114,
        blur_radius=14,
        alpha=190,
    )

    draw = ImageDraw.Draw(image)
    draw.line([(266, 710), (388, 576), (510, 628), (666, 436), (840, 302)], fill=(*shadow_color, 88), width=54, joint="curve")
    draw.line(points, fill=(*white, 255), width=62, joint="curve")
    draw.line(points, fill=(*cyan, 214), width=28, joint="curve")

    arrow = [(792, 284), (868, 250), (830, 328)]
    draw.polygon(arrow, fill=(*indigo, 90))
    draw.polygon([(778, 266), (864, 238), (834, 324)], fill=(*white, 255))
    draw.polygon([(792, 266), (850, 246), (832, 304)], fill=(*cyan, 255))

    for point in points[:-1]:
        x, y = point
        draw.ellipse((x - 26, y - 26, x + 26, y + 26), fill=(*white, 245))
        draw.ellipse((x - 14, y - 14, x + 14, y + 14), fill=(*indigo, 255))
        draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=(255, 255, 255, 180))

    return image


def build_badge() -> Image.Image:
    image = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    image = apply_glow(
        image,
        shape="ellipse",
        bbox=(724, 166, 962, 404),
        color=(255, 124, 121),
        blur_radius=30,
        alpha=155,
    )

    draw = ImageDraw.Draw(image)
    badge_bounds = (748, 188, 936, 376)
    draw.ellipse(badge_bounds, fill=(255, 117, 117, 255))
    draw.ellipse((762, 202, 922, 362), fill=(255, 174, 99, 240))
    draw.ellipse((782, 212, 910, 296), fill=(255, 255, 255, 72))

    star = star_points((842, 282), outer_radius=54, inner_radius=24)
    draw.polygon(star, fill=(255, 249, 194, 255))
    draw.polygon(star_points((836, 276), outer_radius=32, inner_radius=13), fill=(255, 229, 95, 255))

    return image


def build_sparkles() -> Image.Image:
    image = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    for center, size, color in (
        ((180, 286), 20, (255, 255, 255)),
        ((286, 176), 14, (255, 230, 152)),
        ((704, 170), 12, (255, 255, 255)),
    ):
        x, y = center
        draw.line((x - size, y, x + size, y), fill=(*color, 200), width=6)
        draw.line((x, y - size, x, y + size), fill=(*color, 200), width=6)
        draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(*color, 255))

    return image.filter(ImageFilter.GaussianBlur(0.3))


def build_icon() -> Image.Image:
    background = build_background()
    coin_shadow = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(coin_shadow).ellipse((184, 234, 768, 818), fill=(0, 47, 134, 86))
    coin_shadow = coin_shadow.filter(ImageFilter.GaussianBlur(28))
    image = Image.alpha_composite(background, coin_shadow)

    image = Image.alpha_composite(image, build_coin())
    image = Image.alpha_composite(image, build_chart_path())
    image = Image.alpha_composite(image, build_badge())
    image = Image.alpha_composite(image, build_sparkles())

    border = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border)
    border_draw.rounded_rectangle(
        (24, 24, MASTER_SIZE - 24, MASTER_SIZE - 24),
        radius=220,
        outline=(255, 255, 255, 34),
        width=4,
    )
    return Image.alpha_composite(image, border)


def main() -> None:
    APP_ICON_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)

    master = build_icon()
    master.save(APP_ICON_DIR / "AppIcon-1024.png")
    master.save(PREVIEW_PATH)

    for filename, size in ICON_SIZES.items():
        resized = master.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(APP_ICON_DIR / filename)

    print(f"Generated playful icon set in {APP_ICON_DIR}")


if __name__ == "__main__":
    main()
