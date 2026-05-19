#!/usr/bin/env python3
"""Build the SaneSales launch-week marketing video from approved screenshots."""

from __future__ import annotations

import argparse
import hashlib
import math
import re
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DOC_IMAGES = ROOT / "docs" / "images"
DOC_VIDEOS = ROOT / "docs" / "videos"
VIDEO_DIR = ROOT / "Videos"
SLIDE_DIR = VIDEO_DIR / "launch-week-pro-slides"
FINAL_MP4 = VIDEO_DIR / "launch-week-pro-all-devices.mp4"
DOC_MP4 = DOC_VIDEOS / "sanesales-launch-week-pro-all-devices.mp4"
POSTER = DOC_IMAGES / "sanesales-launch-video-poster.png"
SOURCE_CONTACT_SHEET = VIDEO_DIR / "launch-week-pro-contact-sheet.png"
VIDEO_CONTACT_SHEET = VIDEO_DIR / "launch-week-pro-video-contact-sheet.jpg"
AUDIO_BED = VIDEO_DIR / "launch-week-pro-bed.wav"
MUSIC_SOURCE = VIDEO_DIR / "pulse-ledger.mp3"
APP_ICON_SOURCE = ROOT / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "icon_1024x1024.png"
TMP_MP4 = VIDEO_DIR / "launch-week-pro-all-devices.tmp.mp4"
TMP_POSTER = VIDEO_DIR / "launch-week-pro-poster.tmp.png"
TMP_VIDEO_CONTACT_SHEET = VIDEO_DIR / "launch-week-pro-video-contact-sheet.tmp.jpg"
WEBSITE_INDEX = ROOT / "docs" / "index.html"

W, H = 1920, 1080
LEFT_X = 126
LOGO_Y = 108
TITLE_Y = 232
BODY_Y = 430
BADGE_Y = 735
PROOF_X = 860
PROOF_TOP = 128
BG = (8, 8, 12)
PANEL = (18, 20, 30)
PANEL_2 = (24, 27, 40)
TEXT = (246, 248, 255)
MUTED = (216, 222, 238)
ACCENT = (95, 168, 211)
ACCENT_BRIGHT = (82, 224, 240)


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Avenir Next.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size, index=1 if weight == "bold" else 0)
        except Exception:
            continue
    return ImageFont.load_default()


FONTS = {
    "hero": font(74, "bold"),
    "h1": font(58, "bold"),
    "h2": font(42, "bold"),
    "body": font(30),
    "small": font(23),
    "tiny": font(18),
    "badge": font(28, "bold"),
}


ASSET_FILES = {
    "mac_dashboard": "screenshot-mac-dashboard.png",
    "mac_products": "screenshot-mac-products.png",
    "mac_orders": "screenshot-mac-orders.png",
    "mac_settings": "screenshot-mac-settings.png",
    "iphone_dash": "screenshot-iphone-dashboard.png",
    "iphone_orders": "screenshot-iphone-orders.png",
    "iphone_products": "screenshot-iphone-products.png",
    "iphone_settings": "screenshot-iphone-settings.png",
    "ipad_dash": "screenshot-ipad-dashboard.png",
    "ipad_products": "screenshot-ipad-products.png",
    "watch_dash": "screenshot-watch-dashboard.png",
    "watch_recent": "screenshot-watch-recent.png",
}
ASSETS: dict[str, Image.Image] = {}
CHART_ASSET_CHECKS = {
    "mac_dashboard": ((300, 480, 1000, 635), 10, 35),
    "ipad_dash": ((40, 1250, 2030, 1740), 10, 80),
    "iphone_dash": ((40, 2050, 1160, 2500), 4, 25),
}
APPSTORE_IMPORTS = {
    "appstore-01-onboarding-dark-6.7.png": "screenshot-iphone-onboarding.png",
    "appstore-02-dashboard-dark-6.7.png": "screenshot-iphone-dashboard.png",
    "appstore-03-orders-dark-6.7.png": "screenshot-iphone-orders.png",
    "appstore-04-products-dark-6.7.png": "screenshot-iphone-products.png",
    "appstore-05-settings-dark-6.7.png": "screenshot-iphone-settings.png",
    "appstore-01-onboarding-dark-ipad.png": "screenshot-ipad-onboarding.png",
    "appstore-02-dashboard-dark-ipad.png": "screenshot-ipad-dashboard.png",
    "appstore-03-orders-dark-ipad.png": "screenshot-ipad-orders.png",
    "appstore-04-products-dark-ipad.png": "screenshot-ipad-products.png",
    "appstore-05-settings-dark-ipad.png": "screenshot-ipad-settings.png",
    # Keep curated macOS screenshots unless capture is explicitly reviewed.
    # Mac captures can expose system permission prompts or Basic/upgrade banners,
    # which poison website/video marketing assets.
    "appstore-01-dashboard-dark-watch.png": "screenshot-watch-dashboard.png",
    # Keep curated watch recent-sales screenshots unless capture is explicitly
    # reviewed; old demo data can contain other SaneApps product names.
}


def import_appstore_screenshots() -> None:
    screenshot_dir = ROOT / "Screenshots"
    if not screenshot_dir.exists():
        return
    manifest = screenshot_dir / ".capture_manifest"
    allowed_platforms: set[str] | None = None
    if manifest.exists():
        for line in manifest.read_text(encoding="utf-8").splitlines():
            if line.startswith("platforms="):
                allowed_platforms = {value for value in line.removeprefix("platforms=").split(",") if value}
                break
    DOC_IMAGES.mkdir(parents=True, exist_ok=True)
    imported = []
    for source_name, target_name in APPSTORE_IMPORTS.items():
        platform = target_name.split("-")[1]
        if allowed_platforms is not None and platform not in allowed_platforms:
            continue
        source = screenshot_dir / source_name
        if not source.exists():
            continue
        if source.stat().st_size <= 0:
            raise SystemExit(f"Screenshot source is empty: {source}")
        target = DOC_IMAGES / target_name
        shutil.copy2(source, target)
        imported.append(target_name)
    if imported:
        print(f"Imported {len(imported)} Screenshots/appstore images into docs/images.")


def load_asset(name: str) -> Image.Image:
    path = DOC_IMAGES / name
    if not path.exists():
        raise SystemExit(f"Missing required video source screenshot: {path}")
    return Image.open(path).convert("RGBA")


def crop_content(img: Image.Image, bottom: int) -> Image.Image:
    return img.crop((0, 0, img.width, min(bottom, img.height)))


def load_assets() -> None:
    ASSETS.clear()
    if not APP_ICON_SOURCE.exists():
        raise SystemExit(f"Missing official app icon source: {APP_ICON_SOURCE}")
    ASSETS["brand_logo"] = Image.open(APP_ICON_SOURCE).convert("RGBA")
    for key, filename in ASSET_FILES.items():
        ASSETS[key] = load_asset(filename)
    validate_chart_assets()


def green_bar_heights(image: Image.Image, roi: tuple[int, int, int, int]) -> list[int]:
    left, top, right, bottom = roi
    rgb = image.convert("RGB")
    columns: list[tuple[int, int, int]] = []
    for x in range(left, right):
        ys: list[int] = []
        for y in range(top, bottom):
            r, g, b = rgb.getpixel((x, y))
            if g > 110 and g > r * 1.25 and g > b * 1.10 and r < 100:
                ys.append(y)
        if len(ys) > 5:
            columns.append((x, min(ys), max(ys)))

    groups: list[list[tuple[int, int, int]]] = []
    for column in columns:
        if groups and column[0] <= groups[-1][-1][0] + 1:
            groups[-1].append(column)
        else:
            groups.append([column])

    heights: list[int] = []
    for group in groups:
        if len(group) < 10:
            continue
        heights.append(max(column[2] for column in group) - min(column[1] for column in group) + 1)
    return heights


def validate_chart_assets() -> None:
    for key, (roi, min_bars, min_range) in CHART_ASSET_CHECKS.items():
        heights = green_bar_heights(ASSETS[key], roi)
        if len(heights) < min_bars:
            raise SystemExit(f"{ASSET_FILES[key]} chart QA failed: found {len(heights)} bars, expected at least {min_bars}.")
        height_range = max(heights) - min(heights)
        if height_range < min_range:
            raise SystemExit(
                f"{ASSET_FILES[key]} chart QA failed: bars are too flat "
                f"(range {height_range}px, expected at least {min_range}px)."
            )


def rounded(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def fit(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    ratio = min(max_w / img.width, max_h / img.height)
    size = (max(1, int(img.width * ratio)), max(1, int(img.height * ratio)))
    return img.resize(size, Image.LANCZOS)


def cover(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    ratio = max(target_w / img.width, target_h / img.height)
    resized = img.resize((int(img.width * ratio), int(img.height * ratio)), Image.LANCZOS)
    left = max(0, (resized.width - target_w) // 2)
    top = max(0, (resized.height - target_h) // 2)
    return resized.crop((left, top, left + target_w, top + target_h))


def shadow(base: Image.Image, box: tuple[int, int, int, int], radius: int = 48) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i, alpha in enumerate((70, 40, 20)):
        inset = i * 12
        d.rounded_rectangle(
            (box[0] + inset, box[1] + inset, box[2] + inset, box[3] + inset),
            radius=radius,
            fill=(0, 0, 0, alpha),
        )
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(20)))


def background() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    px = img.load()
    top_left = (8, 17, 34)
    top_right = (13, 28, 56)
    bottom_left = (5, 12, 22)
    bottom_right = (9, 18, 36)
    for y in range(H):
        for x in range(W):
            nx = x / W
            ny = y / H
            top = tuple(int(top_left[i] * (1 - nx) + top_right[i] * nx) for i in range(3))
            bottom = tuple(int(bottom_left[i] * (1 - nx) + bottom_right[i] * nx) for i in range(3))
            base = [top[i] * (1 - ny) + bottom[i] * ny for i in range(3)]
            soft_blue = max(0.0, 1.0 - math.sqrt((nx - 0.66) ** 2 + (ny - 0.30) ** 2) * 1.55)
            blue_lift = soft_blue * 10
            px[x, y] = (
                int(base[0] + soft_blue * 2),
                int(base[1] + soft_blue * 4),
                int(base[2] + blue_lift),
                255,
            )
    return img


def draw_text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, font_obj, fill=TEXT, max_width: int | None = None, line_gap: int = 10) -> int:
    x, y = xy
    try:
        ascent, descent = font_obj.getmetrics()
        line_height = ascent + descent + line_gap
    except Exception:
        line_height = draw.textbbox((0, 0), "Ag", font=font_obj)[3] + line_gap
    if not max_width:
        for line in text.split("\n"):
            draw.text((x, y), line, font=font_obj, fill=fill)
            y += line_height
        return y
    lines: list[str] = []
    for paragraph in text.split("\n"):
        words = paragraph.split()
        current = ""
        for word in words:
            candidate = f"{current} {word}".strip()
            if draw.textbbox((0, 0), candidate, font=font_obj)[2] <= max_width or not current:
                current = candidate
            else:
                lines.append(current)
                current = word
        if current:
            lines.append(current)
    for line in lines:
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += line_height
    return y


def callout(draw: ImageDraw.ImageDraw, x: int, y: int, label: str, fill=ACCENT_BRIGHT) -> None:
    draw.line((x, y + 4, x, y + 42), fill=fill, width=5)
    draw.text((x + 22, y), label, font=FONTS["badge"], fill=fill)


def after_title(title_bottom: int, minimum: int = BODY_Y, gap: int = 30) -> int:
    return max(minimum, title_bottom + gap)


def mac_frame(base: Image.Image, shot: Image.Image, x: int, y: int, w: int, h: int, title: str = "") -> None:
    d = ImageDraw.Draw(base)
    outer = (x, y, x + w, y + h)
    rounded(d, outer, 26, (38, 42, 56), (88, 99, 130), 2)
    rounded(d, (x + 10, y + 10, x + w - 10, y + 50), 18, (29, 33, 45), None)
    for i, c in enumerate(((255, 95, 87), (255, 189, 46), (40, 200, 64))):
        d.ellipse((x + 28 + i * 28, y + 26, x + 42 + i * 28, y + 40), fill=c)
    if title:
        d.text((x + 118, y + 20), title, font=FONTS["tiny"], fill=MUTED)
    content = fit(shot, w - 34, h - 72)
    cx = x + (w - content.width) // 2
    cy = y + 58 + (h - 72 - content.height) // 2
    rounded(d, (cx - 3, cy - 3, cx + content.width + 3, cy + content.height + 3), 16, (9, 10, 15))
    base.alpha_composite(content, (cx, cy))


def phone_frame(base: Image.Image, shot: Image.Image, x: int, y: int, w: int, h: int) -> None:
    d = ImageDraw.Draw(base)
    rounded(d, (x, y, x + w, y + h), 54, (10, 12, 18), (98, 110, 140), 3)
    rounded(d, (x + 13, y + 13, x + w - 13, y + h - 13), 44, (4, 6, 10), None)
    content = cover(shot, w - 30, h - 30)
    mask = Image.new("L", content.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, content.width, content.height), radius=38, fill=255)
    base.paste(content, (x + 15, y + 15), mask)
    rounded(d, (x + w // 2 - 48, y + 20, x + w // 2 + 48, y + 36), 8, (8, 10, 14), None)


def tablet_frame(base: Image.Image, shot: Image.Image, x: int, y: int, w: int, h: int) -> None:
    d = ImageDraw.Draw(base)
    rounded(d, (x, y, x + w, y + h), 42, (12, 14, 20), (95, 106, 136), 3)
    rounded(d, (x + 18, y + 18, x + w - 18, y + h - 18), 28, (5, 7, 11), None)
    content = fit(shot, w - 42, h - 42)
    cx = x + 21 + ((w - 42) - content.width) // 2
    cy = y + 21 + ((h - 42) - content.height) // 2
    mask = Image.new("L", content.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, content.width, content.height), radius=24, fill=255)
    base.paste(content, (cx, cy), mask)


def watch_frame(base: Image.Image, shot: Image.Image, x: int, y: int, w: int, h: int) -> None:
    d = ImageDraw.Draw(base)
    rounded(d, (x + 28, y - 56, x + w - 28, y + 28), 38, (31, 34, 45), None)
    rounded(d, (x + 28, y + h - 28, x + w - 28, y + h + 56), 38, (31, 34, 45), None)
    rounded(d, (x, y, x + w, y + h), 58, (10, 12, 18), (98, 110, 140), 3)
    content = cover(shot, w - 28, h - 28)
    mask = Image.new("L", content.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, content.width, content.height), radius=46, fill=255)
    base.paste(content, (x + 14, y + 14), mask)


def logo_icon(size: int) -> Image.Image:
    icon = cover(ASSETS["brand_logo"], size, size)
    alpha = Image.new("L", (size, size), 0)
    src = icon.convert("RGBA")
    src_px = src.load()
    alpha_px = alpha.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = src_px[x, y]
            cyan = max(g, b)
            saturation = cyan - r
            if cyan < 78 or saturation < 30:
                keyed = 0
            else:
                keyed = max((cyan - 72) * 4, (saturation - 28) * 5, 0)
            alpha_px[x, y] = min(255, int(keyed) * a // 255)
    icon.putalpha(alpha)
    return icon


def logo(base: Image.Image, draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    icon_size = 96
    icon = logo_icon(icon_size)
    base.alpha_composite(icon, (x, y))
    draw.text((x + icon_size + 24, y + 22), "SaneSales", font=FONTS["h2"], fill=TEXT)


def slide_hero() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "Tired of sales apps that spy and charge forever?", FONTS["hero"], TEXT, 760, 18)
    body_y = after_title(title_bottom)
    body_bottom = draw_text(
        d,
        (LEFT_X + 4, body_y),
        "Most dashboards mean another monthly bill and another cloud holding your customer data.",
        FONTS["body"],
        MUTED,
        700,
        14,
    )
    callout_y = max(650, body_bottom + 64)
    callout(d, LEFT_X, callout_y, "There is a cleaner way.")
    mac_frame(img, ASSETS["mac_products"], PROOF_X, PROOF_TOP, 780, 545, "Products")
    phone_frame(img, ASSETS["iphone_dash"], 1350, 270, 320, 695)
    watch_frame(img, ASSETS["watch_dash"], 760, 625, 270, 322)
    return img


def slide_ipad_chart() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "See what sold today.", FONTS["hero"], TEXT, 700, 18)
    draw_text(
        d,
        (LEFT_X + 4, after_title(title_bottom)),
        "See revenue, orders, refunds, and product performance without opening three dashboards.",
        FONTS["body"],
        MUTED,
        610,
        14,
    )
    callout(d, LEFT_X, 625, "See what changed today")
    tablet_frame(img, ASSETS["ipad_dash"], PROOF_X, 92, 760, 870)
    phone_frame(img, ASSETS["iphone_dash"], 1430, 295, 280, 610)
    return img


def slide_mac() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "Everything in one native Mac app.", FONTS["hero"], TEXT, 700, 22)
    draw_text(
        d,
        (LEFT_X + 4, after_title(title_bottom)),
        "Track Lemon Squeezy, Gumroad, and Stripe with products, orders, exports, and menu bar revenue.",
        FONTS["body"],
        MUTED,
        640,
        14,
    )
    callout(d, LEFT_X, BADGE_Y, "Revenue, orders, and products")
    mac_frame(img, ASSETS["mac_products"], PROOF_X, 140, 720, 500, "Product breakdown")
    mac_frame(img, ASSETS["mac_orders"], 1035, 490, 650, 455, "Orders")
    return img


def slide_iphone() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "Check sales anywhere.", FONTS["hero"], TEXT, 700, 22)
    draw_text(
        d,
        (LEFT_X + 4, after_title(title_bottom)),
        "Open SaneSales on iPhone for revenue, orders, and product mix away from your Mac.",
        FONTS["body"],
        MUTED,
        640,
        14,
    )
    callout(d, LEFT_X, BADGE_Y, "Everything important in one place")
    phone_frame(img, ASSETS["iphone_dash"], 870, 115, 345, 750)
    phone_frame(img, ASSETS["iphone_orders"], 1230, 200, 305, 665)
    phone_frame(img, ASSETS["iphone_products"], 1540, 260, 270, 590)
    return img


def slide_ipad() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "See the bigger picture.", FONTS["hero"], TEXT, 700, 22)
    draw_text(
        d,
        (LEFT_X + 4, after_title(title_bottom)),
        "Use iPad for readable charts, order lists, and product breakdowns without spreadsheet work.",
        FONTS["body"],
        MUTED,
        600,
        14,
    )
    callout(d, LEFT_X, BADGE_Y, "See trends and top products faster")
    tablet_frame(img, crop_content(ASSETS["ipad_dash"], 2180), 850, 115, 650, 855)
    tablet_frame(img, crop_content(ASSETS["ipad_products"], 1540), 1305, 340, 475, 590)
    return img


def slide_watch() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "A quick glance when you need it.", FONTS["hero"], TEXT, 700, 18)
    draw_text(
        d,
        (LEFT_X + 4, after_title(title_bottom)),
        "Check totals and recent sales from Apple Watch without reaching for your Mac or phone.",
        FONTS["body"],
        MUTED,
        610,
        14,
    )
    callout(d, LEFT_X, BADGE_Y, "Apple Watch included")
    watch_frame(img, ASSETS["watch_dash"], 1080, 175, 430, 514)
    callout(d, 1015, 760, "Today, month, and all-time totals")
    return img


def slide_privacy() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "Track sales privately.\nNo subscription.", FONTS["hero"], TEXT, 780, 22)
    points = [
        "No private sales data collected",
        "Your sales data stays on your devices",
        "No customer lists sent to SaneApps",
        "No analytics cloud collecting your history",
        "Pay once.",
        "No monthly analytics bill.",
    ]
    y = after_title(title_bottom, gap=34)
    for point in points:
        d.ellipse((LEFT_X, y + 12, LEFT_X + 26, y + 38), fill=ACCENT_BRIGHT)
        draw_text(d, (LEFT_X + 48, y), point, FONTS["body"], TEXT, 640, 8)
        y += 64
    mac_frame(img, ASSETS["mac_settings"], PROOF_X, 165, 720, 495, "Settings")
    phone_frame(img, ASSETS["iphone_settings"], 1380, 450, 260, 565)
    return img


def slide_cta() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    logo(img, d, LEFT_X, LOGO_Y)
    title_bottom = draw_text(d, (LEFT_X, TITLE_Y), "Launch week special.", FONTS["hero"], TEXT, 720, 18)
    price_y = after_title(title_bottom, minimum=380, gap=22)
    price_bottom = draw_text(d, (LEFT_X + 4, price_y), "$9.99", FONTS["hero"], TEXT, 520, 10)
    offer_bottom = draw_text(d, (LEFT_X + 4, price_bottom + 36), "Save 60% through May 21.", FONTS["h2"], ACCENT_BRIGHT, 650, 10)
    proof_y = offer_bottom + 36
    device_bottom = draw_text(
        d,
        (LEFT_X + 4, proof_y),
        "SaneSales Pro for every device.",
        FONTS["body"],
        MUTED,
        560,
        14,
    )
    proof_bottom = draw_text(d, (LEFT_X + 4, device_bottom + 16), "Pay once. Own your data.", FONTS["body"], MUTED, 520, 14)
    callout(d, LEFT_X, max(780, proof_bottom + 56), "sanesales.com")
    mac_frame(img, ASSETS["mac_products"], 880, 170, 610, 420, "SaneSales Pro")
    tablet_frame(img, ASSETS["ipad_dash"], 1210, 420, 420, 520)
    phone_frame(img, ASSETS["iphone_dash"], 1505, 290, 250, 545)
    watch_frame(img, ASSETS["watch_dash"], 760, 660, 230, 276)
    return img


SLIDES = [
    ("slide-01-hero.png", slide_hero),
    ("slide-02-privacy.png", slide_privacy),
    ("slide-03-chart.png", slide_ipad_chart),
    ("slide-04-mac.png", slide_mac),
    ("slide-05-iphone.png", slide_iphone),
    ("slide-06-ipad.png", slide_ipad),
    ("slide-07-watch.png", slide_watch),
    ("slide-08-cta.png", slide_cta),
]


def write_audio(path: Path, duration: float, sample_rate: int = 48000) -> None:
    if not MUSIC_SOURCE.exists():
        raise SystemExit(f"Missing required music source: {MUSIC_SOURCE}")

    fade_out_start = max(0.0, duration - 2.0)
    audio_filter = (
        f"loudnorm=I=-18:TP=-1.5:LRA=11,"
        f"afade=t=in:st=0:d=0.6,"
        f"afade=t=out:st={fade_out_start:.3f}:d=2.0"
    )
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-stream_loop",
            "-1",
            "-i",
            str(MUSIC_SOURCE),
            "-t",
            f"{duration:.3f}",
            "-vn",
            "-ac",
            "2",
            "-ar",
            str(sample_rate),
            "-af",
            audio_filter,
            str(path),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def make_contact_sheet(paths: list[Path], out: Path, cols: int = 4) -> None:
    thumbs = []
    for path in paths:
        img = Image.open(path).convert("RGB")
        img.thumbnail((430, 242), Image.LANCZOS)
        canvas = Image.new("RGB", (450, 282), (14, 16, 24))
        canvas.paste(img, ((450 - img.width) // 2, 12))
        d = ImageDraw.Draw(canvas)
        d.text((16, 254), path.name, font=FONTS["tiny"], fill=(230, 235, 250))
        thumbs.append(canvas)
    rows = math.ceil(len(thumbs) / cols)
    sheet = Image.new("RGB", (cols * 450, rows * 282), (8, 8, 12))
    for i, thumb in enumerate(thumbs):
        sheet.paste(thumb, ((i % cols) * 450, (i // cols) * 282))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=94)


def require_tools() -> None:
    missing = [tool for tool in ("ffmpeg",) if shutil.which(tool) is None]
    if missing:
        raise SystemExit(f"Missing required video tool: {', '.join(missing)}")


def run_ffmpeg(slides: list[Path], duration: float, transition: float, output: Path) -> None:
    total = len(slides) * duration
    write_audio(AUDIO_BED, total)
    args = ["ffmpeg", "-y"]
    for slide in slides:
        args += ["-loop", "1", "-t", str(duration), "-i", str(slide)]
    args += ["-i", str(AUDIO_BED)]

    filters = []
    fade_duration = min(0.28, max(0.0, transition / 3))
    for idx in range(len(slides)):
        out_start = max(0.0, duration - fade_duration)
        filters.append(
            f"[{idx}:v]fps=30,format=yuv420p,setpts=PTS-STARTPTS,"
            f"fade=t=in:st=0:d={fade_duration:.3f},"
            f"fade=t=out:st={out_start:.3f}:d={fade_duration:.3f}[v{idx}]"
        )
    concat_inputs = "".join(f"[v{idx}]" for idx in range(len(slides)))
    filters.append(f"{concat_inputs}concat=n={len(slides)}:v=1:a=0[vout]")

    args += [
        "-filter_complex",
        ";".join(filters),
        "-map",
        "[vout]",
        "-map",
        f"{len(slides)}:a",
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-preset",
        "medium",
        "-crf",
        "20",
        "-c:a",
        "aac",
        "-b:a",
        "160k",
        "-movflags",
        "+faststart",
        "-shortest",
        str(output),
    ]
    subprocess.run(args, check=True)


def sample_final_video(video_path: Path, output: Path) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(video_path),
            "-vf",
            "fps=1/7,scale=480:-1,tile=4x2",
            "-frames:v",
            "1",
            str(output),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def media_version(path: Path) -> str:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return digest[:12]


def update_website_cache_tag(version: str) -> None:
    html = WEBSITE_INDEX.read_text(encoding="utf-8")
    replacements = {
        r"sanesales-launch-video-poster\.png(?:\?v=[A-Za-z0-9_-]+)?": f"sanesales-launch-video-poster.png?v={version}",
        r"sanesales-launch-week-pro-all-devices\.mp4(?:\?v=[A-Za-z0-9_-]+)?": f"sanesales-launch-week-pro-all-devices.mp4?v={version}",
    }
    for pattern, replacement in replacements.items():
        html = re.sub(pattern, replacement, html)
    WEBSITE_INDEX.write_text(html, encoding="utf-8")


def publish_outputs(slide_paths: list[Path], duration: float, transition: float) -> str:
    shutil.copyfile(slide_paths[0], TMP_POSTER)
    run_ffmpeg(slide_paths, duration, transition, TMP_MP4)
    sample_final_video(TMP_MP4, TMP_VIDEO_CONTACT_SHEET)

    TMP_MP4.replace(FINAL_MP4)
    TMP_VIDEO_CONTACT_SHEET.replace(VIDEO_CONTACT_SHEET)
    shutil.copyfile(FINAL_MP4, DOC_MP4.with_suffix(".tmp.mp4"))
    DOC_MP4.with_suffix(".tmp.mp4").replace(DOC_MP4)
    TMP_POSTER.replace(POSTER)
    version = media_version(FINAL_MP4)
    update_website_cache_tag(version)
    return version


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--duration", type=float, default=7.0)
    parser.add_argument("--transition", type=float, default=0.9)
    parser.add_argument("--no-import-screenshots", action="store_true")
    args = parser.parse_args()

    require_tools()
    if not args.no_import_screenshots:
        import_appstore_screenshots()
    load_assets()
    SLIDE_DIR.mkdir(parents=True, exist_ok=True)
    VIDEO_DIR.mkdir(parents=True, exist_ok=True)
    DOC_VIDEOS.mkdir(parents=True, exist_ok=True)
    for stale in SLIDE_DIR.glob("*.png"):
        stale.unlink()

    slide_paths: list[Path] = []
    for name, build in SLIDES:
        path = SLIDE_DIR / name
        build().convert("RGB").save(path, quality=96)
        slide_paths.append(path)

    make_contact_sheet(slide_paths, SOURCE_CONTACT_SHEET)
    version = publish_outputs(slide_paths, args.duration, args.transition)
    print(f"Wrote {FINAL_MP4}")
    print(f"Wrote {DOC_MP4}")
    print(f"Wrote {POSTER}")
    print(f"Wrote {SOURCE_CONTACT_SHEET}")
    print(f"Wrote {VIDEO_CONTACT_SHEET}")
    print(f"Updated website media cache tag: {version}")


if __name__ == "__main__":
    main()
