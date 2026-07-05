from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


OUT_DIR = Path(__file__).resolve().parent

W, H = 1120, 720
SIDEBAR_W = 252
TITLEBAR_H = 54

BLUE = (0, 122, 255)
GREEN = (40, 176, 76)
AMBER = (196, 132, 0)
RED = (218, 61, 51)
TEXT = (29, 29, 31)
SECONDARY = (104, 104, 112)
TERTIARY = (143, 143, 148)
BORDER = (211, 211, 218)
WINDOW_BG = (246, 246, 248)
SIDEBAR_BG = (238, 238, 242)
GROUP_BG = (255, 255, 255)
CONTROL_BG = (250, 250, 252)
FIELD_BG = (232, 232, 236)

FONT_PATH = "/System/Library/Fonts/SFNS.ttf"
MONO_PATH = "/System/Library/Fonts/SFNSMono.ttf"


def sf(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size=size)


def mono(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(MONO_PATH, size=size)


def text_size(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=font)
    return box[2] - box[0], box[3] - box[1]


def fit_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, max_w: int) -> str:
    if text_size(draw, text, font)[0] <= max_w:
        return text
    ellipsis = "..."
    base = text
    while base and text_size(draw, base + ellipsis, font)[0] > max_w:
        base = base[:-1]
    return base + ellipsis if base else ellipsis


def round_rect(draw: ImageDraw.ImageDraw, box, radius=10, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_text(draw, xy, text, size=14, fill=TEXT, max_w=None, font=None):
    f = font or sf(size)
    if max_w is not None:
        text = fit_text(draw, text, f, max_w)
    draw.text(xy, text, font=f, fill=fill)


def draw_wrapped_text(draw, xy, text, size=14, fill=TEXT, max_w=300, line_h=19, max_lines=3):
    f = sf(size)
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if text_size(draw, candidate, f)[0] <= max_w:
            current = candidate
            continue
        if current:
            lines.append(current)
        current = word
        if len(lines) == max_lines:
            break
    if current and len(lines) < max_lines:
        lines.append(current)
    if len(lines) > max_lines:
        lines = lines[:max_lines]
    if len(lines) == max_lines and " ".join(lines) != text:
        lines[-1] = fit_text(draw, lines[-1], f, max_w)
    x, y = xy
    for idx, line in enumerate(lines):
        draw.text((x, y + idx * line_h), line, font=f, fill=fill)


def draw_symbol(draw, cx, cy, symbol, color=SECONDARY, size=14):
    # SF Symbols are not available to PIL, so mock them as native-sized monochrome glyph slots.
    glyphs = {
        "overview": "○",
        "items": "▤",
        "behavior": "≡",
        "layout": "▥",
        "search": "⌕",
        "second": "▭",
        "groups": "◎",
        "hotkeys": "⌘",
        "profiles": "▦",
        "automation": "↗",
        "import": "⇅",
        "privacy": "◇",
        "diagnostics": "⌁",
        "advanced": "⌥",
        "about": "i",
    }
    draw_text(draw, (cx - 7, cy - 9), glyphs.get(symbol, "•"), size=size, fill=color)


SIDEBAR_GROUPS = [
    ("General", [
        ("Overview", "overview"),
        ("Menu Bar Items", "items"),
        ("Behavior", "behavior"),
        ("Layout", "layout"),
    ]),
    ("Pro Features", [
        ("Search", "search"),
        ("Second Bar", "second"),
        ("Groups", "groups"),
        ("Hotkeys", "hotkeys"),
        ("Profiles", "profiles"),
        ("Automation", "automation"),
    ]),
    ("System", [
        ("Import / Export", "import"),
        ("Privacy", "privacy"),
        ("Diagnostics", "diagnostics"),
        ("Advanced", "advanced"),
        ("About", "about"),
    ]),
]


def draw_shell(selected: str, title: str, toolbar: Iterable[str] = (), search=True) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (W, H), WINDOW_BG)
    draw = ImageDraw.Draw(img)

    # Outer window and titlebar.
    round_rect(draw, (16, 16, W - 16, H - 16), 14, fill=WINDOW_BG, outline=(190, 190, 198))
    draw.rectangle((17, 16 + TITLEBAR_H, W - 17, H - 17), fill=WINDOW_BG)
    draw.line((17, 16 + TITLEBAR_H, W - 17, 16 + TITLEBAR_H), fill=BORDER)
    draw.rectangle((17, 17, 17 + SIDEBAR_W, H - 17), fill=SIDEBAR_BG)
    draw.line((17 + SIDEBAR_W, 16, 17 + SIDEBAR_W, H - 17), fill=BORDER)

    # Traffic lights.
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        draw.ellipse((36 + i * 20, 35, 48 + i * 20, 47), fill=c, outline=(160, 160, 165))

    draw_text(draw, (17 + SIDEBAR_W + 28, 33), title, 18, TEXT)

    # Toolbar items.
    x = W - 420
    for label in toolbar:
        bw = max(74, text_size(draw, label, sf(13))[0] + 26)
        round_rect(draw, (x, 28, x + bw, 50), 6, fill=CONTROL_BG, outline=BORDER)
        draw_text(draw, (x + 13, 32), label, 13, TEXT)
        x += bw + 8

    if search:
        round_rect(draw, (W - 244, 28, W - 44, 50), 7, fill=FIELD_BG, outline=(218, 218, 224))
        draw_text(draw, (W - 225, 32), "Search", 13, TERTIARY)

    # Sidebar.
    y = 86
    for group, items in SIDEBAR_GROUPS:
        draw_text(draw, (38, y), group.upper(), 11, SECONDARY)
        y += 23
        for name, icon in items:
            is_sel = name == selected
            if is_sel:
                round_rect(draw, (30, y - 4, 250, y + 26), 7, fill=BLUE)
            draw_symbol(draw, 48, y + 11, icon, color=(255, 255, 255) if is_sel else SECONDARY)
            draw_text(draw, (68, y + 1), name, 14, (255, 255, 255) if is_sel else TEXT, max_w=160)
            y += 34
        y += 14

    return img, draw


def draw_dot(draw, x, y, color):
    draw.ellipse((x, y, x + 8, y + 8), fill=color)


def draw_toggle(draw, x, y, on=True):
    fill = BLUE if on else (205, 205, 211)
    round_rect(draw, (x, y, x + 42, y + 24), 12, fill=fill)
    knob_x = x + 20 if on else x + 2
    draw.ellipse((knob_x, y + 2, knob_x + 20, y + 22), fill=(255, 255, 255), outline=(190, 190, 196))


def draw_button(draw, x, y, label, primary=False, destructive=False):
    f = sf(13)
    bw = text_size(draw, label, f)[0] + 26
    fill = BLUE if primary else CONTROL_BG
    outline = BLUE if primary else BORDER
    text_color = (255, 255, 255) if primary else (RED if destructive else TEXT)
    round_rect(draw, (x, y, x + bw, y + 24), 6, fill=fill, outline=outline)
    draw_text(draw, (x + 13, y + 4), label, 13, text_color)
    return bw


def draw_popup(draw, x, y, label, w=150):
    round_rect(draw, (x, y, x + w, y + 24), 6, fill=CONTROL_BG, outline=BORDER)
    draw_text(draw, (x + 10, y + 4), label, 13, TEXT, max_w=w - 28)
    draw_text(draw, (x + w - 19, y + 4), "⌄", 13, SECONDARY)


def draw_status(draw, x, y, label, color):
    draw_dot(draw, x, y + 6, color)
    draw_text(draw, (x + 14, y), label, 13, SECONDARY)


@dataclass
class Row:
    title: str
    detail: str = ""
    control: str = "value"
    value: str = ""
    on: bool = False
    tone: str = "neutral"


@dataclass
class Section:
    title: str
    rows: list[Row]


TONE_COLOR = {
    "neutral": SECONDARY,
    "green": GREEN,
    "amber": AMBER,
    "red": RED,
    "blue": BLUE,
}


def draw_grouped_form(selected: str, title: str, sections: list[Section], toolbar: Iterable[str] = ()) -> Image.Image:
    img, draw = draw_shell(selected, title, toolbar)
    x0 = 17 + SIDEBAR_W + 34
    y = 92
    max_w = W - x0 - 52

    for section in sections:
        draw_text(draw, (x0, y), section.title, 13, SECONDARY)
        y += 24
        row_h = 50
        height = row_h * len(section.rows)
        round_rect(draw, (x0, y, x0 + max_w, y + height), 10, fill=GROUP_BG, outline=BORDER)
        for idx, row in enumerate(section.rows):
            ry = y + idx * row_h
            if idx:
                draw.line((x0 + 16, ry, x0 + max_w - 16, ry), fill=(229, 229, 234))
            draw_text(draw, (x0 + 18, ry + 9), row.title, 14, TEXT, max_w=max_w - 330)
            if row.detail:
                draw_text(draw, (x0 + 18, ry + 28), row.detail, 12, SECONDARY, max_w=max_w - 330)
            cx = x0 + max_w - 190
            if row.control == "toggle":
                draw_toggle(draw, x0 + max_w - 64, ry + 13, row.on)
            elif row.control == "button":
                draw_button(draw, x0 + max_w - 134, ry + 13, row.value, primary=row.tone == "blue", destructive=row.tone == "red")
            elif row.control == "popup":
                draw_popup(draw, x0 + max_w - 174, ry + 13, row.value, 142)
            elif row.control == "status":
                draw_status(draw, cx, ry + 17, row.value, TONE_COLOR.get(row.tone, SECONDARY))
            elif row.control == "slider":
                draw.line((x0 + max_w - 174, ry + 25, x0 + max_w - 52, ry + 25), fill=(190, 190, 198), width=3)
                draw.line((x0 + max_w - 174, ry + 25, x0 + max_w - 98, ry + 25), fill=BLUE, width=3)
                draw.ellipse((x0 + max_w - 104, ry + 18, x0 + max_w - 90, ry + 32), fill=(255, 255, 255), outline=BORDER)
            else:
                draw_text(draw, (cx, ry + 17), row.value, 13, SECONDARY, max_w=160)
        y += height + 26

    return img


def draw_segmented(draw, x, y, labels, selected=0, w=320):
    h = 28
    round_rect(draw, (x, y, x + w, y + h), 7, fill=(224, 224, 230), outline=BORDER)
    seg_w = w // len(labels)
    for i, lab in enumerate(labels):
        sx = x + i * seg_w
        if i == selected:
            round_rect(draw, (sx + 2, y + 2, sx + seg_w - 2, y + h - 2), 6, fill=GROUP_BG)
        if i:
            draw.line((sx, y + 5, sx, y + h - 5), fill=(205, 205, 212))
        draw_text(draw, (sx + 12, y + 6), lab, 13, TEXT, max_w=seg_w - 24)


def draw_table_page(selected: str, title: str, columns: list[str], rows: list[list[str]], inspector: list[Row], toolbar=(), segment=None) -> Image.Image:
    img, draw = draw_shell(selected, title, toolbar)
    x0 = 17 + SIDEBAR_W + 30
    y0 = 86
    content_w = W - x0 - 42
    inspector_w = 260
    table_w = content_w - inspector_w - 16

    if segment:
        draw_segmented(draw, x0, y0, segment, 0, 360)
        y0 += 44

    round_rect(draw, (x0, y0, x0 + table_w, H - 44), 10, fill=GROUP_BG, outline=BORDER)
    header_h = 34
    draw.rectangle((x0 + 1, y0 + 1, x0 + table_w - 1, y0 + header_h), fill=(246, 246, 248))
    if len(columns) == 6:
        ratios = [0.08, 0.28, 0.20, 0.16, 0.14, 0.14]
    else:
        ratios = [1 / max(len(columns), 1)] * len(columns)
    col_widths = [max(36, int(table_w * ratio)) for ratio in ratios]
    if col_widths:
        col_widths[-1] += table_w - sum(col_widths)
    xx = x0
    for i, col in enumerate(columns):
        cw = col_widths[i] if i < len(col_widths) else 120
        if i:
            draw.line((xx, y0 + 7, xx, H - 52), fill=(232, 232, 238))
        draw_text(draw, (xx + 10, y0 + 10), col, 12, SECONDARY, max_w=cw - 18)
        xx += cw

    row_h = 38
    for r, row in enumerate(rows):
        ry = y0 + header_h + r * row_h
        if r == 1:
            draw.rectangle((x0 + 1, ry, x0 + table_w - 1, ry + row_h), fill=(219, 237, 255))
        elif r % 2:
            draw.rectangle((x0 + 1, ry, x0 + table_w - 1, ry + row_h), fill=(251, 251, 253))
        draw.line((x0 + 1, ry, x0 + table_w - 1, ry), fill=(235, 235, 240))
        xx = x0
        for i, val in enumerate(row):
            cw = col_widths[i] if i < len(col_widths) else 120
            color = TEXT
            if val in ("Visible", "On", "Ready", "Healthy"):
                color = GREEN
            if val in ("Requires Permission", "Warning", "Preview"):
                color = AMBER
            if val in ("Error", "Failed"):
                color = RED
            if i == 0:
                draw_text(draw, (xx + 16, ry + 10), val, 13, SECONDARY)
            else:
                draw_text(draw, (xx + 10, ry + 10), val, 13, color, max_w=cw - 18)
            xx += cw

    ix = x0 + table_w + 16
    round_rect(draw, (ix, y0, ix + inspector_w, H - 44), 10, fill=GROUP_BG, outline=BORDER)
    draw_text(draw, (ix + 18, y0 + 18), "Inspector", 17, TEXT)
    yy = y0 + 58
    for row in inspector:
        draw_text(draw, (ix + 18, yy), row.title, 12, SECONDARY)
        if row.control == "button":
            draw_button(draw, ix + 18, yy + 20, row.value, primary=row.tone == "blue", destructive=row.tone == "red")
            yy += 60
        elif row.control == "status":
            draw_status(draw, ix + 18, yy + 20, row.value, TONE_COLOR.get(row.tone, SECONDARY))
            yy += 54
        else:
            draw_text(draw, (ix + 18, yy + 20), row.value, 14, TEXT, max_w=inspector_w - 34)
            yy += 54

    return img


def draw_preview_bar(draw, x, y, w, title):
    round_rect(draw, (x, y, x + w, y + 88), 10, fill=GROUP_BG, outline=BORDER)
    draw_text(draw, (x + 18, y + 14), title, 13, SECONDARY)
    bar_y = y + 44
    round_rect(draw, (x + 18, bar_y, x + w - 18, bar_y + 25), 8, fill=(236, 236, 240), outline=BORDER)
    names = ["Control", "Wi-Fi", "Battery", "VPN", "Cloud", "Backup", "Hidden", "Always Hidden"]
    xx = x + 30
    for i, name in enumerate(names):
        color = BLUE if i == 0 else (GREEN if i < 6 else AMBER)
        draw_dot(draw, xx, bar_y + 9, color)
        draw_text(draw, (xx + 12, bar_y + 5), name, 11, SECONDARY)
        xx += 88 if i < 4 else 104


def draw_layout_page() -> Image.Image:
    sections = [
        Section("Menu Bar Geometry", [
            Row("Primary separator length", "Controls how far icons are pushed when collapsed.", "slider"),
            Row("Always-hidden zone", "Optional second boundary for items that should stay hidden.", "toggle", on=True),
            Row("Separator markers", "Show markers while adjusting layout.", "popup", "While Editing"),
        ]),
        Section("Reveal Behavior", [
            Row("Full Menu Bar Mode", "Temporarily reveal everything for setup tasks.", "button", "Enter", tone="blue"),
            Row("Crowded reveal rescue", "Use a safer fallback when inline reveal is too crowded.", "toggle", on=True),
            Row("Spacing Labs", "Experimental spacing presets, reversible by design.", "status", "Off", tone="amber"),
        ]),
    ]
    img = draw_grouped_form("Layout", "Layout", sections, toolbar=("Suggestions", "Reset"))
    draw = ImageDraw.Draw(img)
    x0 = 17 + SIDEBAR_W + 34
    draw_preview_bar(draw, x0, 88, W - x0 - 52, "Menu Bar Preview")
    # Shift the generated sections visually down by overlaying a fresh lower form-like area was not worth the complexity;
    # the preview intentionally occupies the first page band in this mockup.
    return img


def draw_assistant() -> Image.Image:
    img = Image.new("RGB", (980, 620), (246, 246, 248))
    draw = ImageDraw.Draw(img)
    round_rect(draw, (18, 18, 962, 602), 14, fill=WINDOW_BG, outline=(190, 190, 198))
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        draw.ellipse((38 + i * 20, 37, 50 + i * 20, 49), fill=c, outline=(160, 160, 165))
    draw_text(draw, (428, 37), "MenuBarDeclutter Setup", 15, TEXT)
    draw.rectangle((19, 72, 230, 601), fill=SIDEBAR_BG)
    steps = ["Welcome", "Basic Mode", "Position Control", "Privacy", "Finish"]
    y = 104
    for idx, step in enumerate(steps):
        if idx == 2:
            round_rect(draw, (38, y - 7, 210, y + 27), 7, fill=BLUE)
        draw_text(draw, (56, y), step, 14, (255, 255, 255) if idx == 2 else TEXT)
        y += 42
    draw_text(draw, (280, 118), "Position the control item", 26, TEXT)
    draw_text(draw, (280, 158), "Use the standard macOS menu bar behavior. No permissions are needed.", 15, SECONDARY)
    draw_preview_bar(draw, 280, 214, 620, "Command-drag the control where hidden items should begin")
    round_rect(draw, (280, 336, 900, 438), 10, fill=GROUP_BG, outline=BORDER)
    draw_text(draw, (304, 360), "Basic Mode uses only app-owned menu bar items.", 15, TEXT)
    draw_text(draw, (304, 388), "Accessibility, Screen Recording, Apple Events, Input Monitoring, and network access stay off.", 14, SECONDARY)
    draw_button(draw, 732, 548, "Continue", primary=True)
    draw_button(draw, 624, 548, "Back")
    return img


def draw_panels() -> Image.Image:
    img = Image.new("RGB", (1120, 720), (230, 232, 236))
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, 1120, 28), fill=(248, 248, 250))
    draw_text(draw, (22, 6), "Finder", 13, TEXT)
    draw_text(draw, (892, 6), "Wi-Fi   Battery   MenuBarDeclutter", 13, SECONDARY)

    def panel(x, y, w, h, title, search=False, rows=None):
        round_rect(draw, (x, y, x + w, y + h), 13, fill=(250, 250, 252), outline=(170, 170, 178))
        draw_text(draw, (x + 18, y + 16), title, 17, TEXT)
        yy = y + 48
        if search:
            round_rect(draw, (x + 16, yy, x + w - 16, yy + 30), 8, fill=FIELD_BG, outline=BORDER)
            draw_text(draw, (x + 32, yy + 7), "Search", 13, TERTIARY)
            yy += 42
        for i, row in enumerate(rows or []):
            if i == 1:
                draw.rectangle((x + 8, yy - 3, x + w - 8, yy + 34), fill=(219, 237, 255))
            draw_text(draw, (x + 22, yy + 6), row[0], 14, TEXT)
            draw_text(draw, (x + w - 114, yy + 7), row[1], 12, SECONDARY)
            yy += 38
        draw.line((x, y + h - 46, x + w, y + h - 46), fill=BORDER)
        draw_button(draw, x + w - 94, y + h - 34, "Open", primary=True)

    panel(90, 90, 390, 500, "Find Icon", True, [
        ("Wi-Fi", "Visible"),
        ("VPN", "Hidden"),
        ("Backup", "Always Hidden"),
        ("Cloud Sync", "Hidden"),
        ("Drive Helper", "Second Bar"),
    ])
    panel(520, 120, 420, 430, "Second Bar", True, [
        ("VPN", "Always Hidden"),
        ("Backup", "Hidden"),
        ("Drive Helper", "Hidden"),
        ("Cloud Sync", "Hidden"),
    ])
    round_rect(draw, (810, 58, 860, 78), 8, fill=(250, 250, 252), outline=(170, 170, 178))
    draw.polygon([(836, 58), (846, 44), (856, 58)], fill=(250, 250, 252), outline=(170, 170, 178))
    draw_text(draw, (90, 628), "Reusable compact utility template: transient NSPanel/popover, search first, list second, actions in footer.", 15, SECONDARY)
    return img


def draw_status_menu() -> Image.Image:
    img = Image.new("RGB", (900, 620), (230, 232, 236))
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, 900, 28), fill=(248, 248, 250))
    draw_text(draw, (640, 6), "MenuBarDeclutter", 13, TEXT)
    x, y, w, h = 520, 38, 300, 448
    round_rect(draw, (x, y, x + w, y + h), 10, fill=(250, 250, 252), outline=(170, 170, 178))
    items = [
        ("Expand Hidden Items", ""),
        ("Collapse Hidden Items", ""),
        ("Reveal All", ""),
        ("", ""),
        ("Find Icon...", "⌘F"),
        ("Show Second Bar", ""),
        ("Refresh Menu Bar Items", "⌘R"),
        ("", ""),
        ("Basic Mode: On", ""),
        ("Pro Mode: Off", ""),
        ("Pause Automation", ""),
        ("", ""),
        ("Layout Suggestions...", ""),
        ("Open Settings...", "⌘,"),
        ("Diagnostics...", ""),
        ("", ""),
        ("Quit MenuBarDeclutter", "⌘Q"),
    ]
    yy = y + 12
    for label, key in items:
        if not label:
            draw.line((x + 12, yy + 5, x + w - 12, yy + 5), fill=BORDER)
            yy += 15
            continue
        if label == "Find Icon...":
            draw.rectangle((x + 6, yy - 2, x + w - 6, yy + 25), fill=(219, 237, 255))
        draw_text(draw, (x + 18, yy + 4), label, 14, TEXT)
        if key:
            draw_text(draw, (x + w - 50, yy + 4), key, 13, SECONDARY)
        yy += 27
    draw_text(draw, (76, 96), "Native status menu template", 28, TEXT)
    draw_text(draw, (76, 138), "Pure NSMenu. Commands are grouped by task, with Settings and Diagnostics near the bottom.", 15, SECONDARY, max_w=360)
    return img


def draw_template_map() -> Image.Image:
    img = Image.new("RGB", (1400, 1040), (246, 246, 248))
    draw = ImageDraw.Draw(img)
    draw_text(draw, (48, 42), "MenuBarDeclutter Native macOS Redesign", 34, TEXT)
    draw_text(draw, (48, 86), "HIG inventory pass: 171 Apple routes accounted for, then reduced into reusable native macOS templates.", 17, SECONDARY)

    templates = [
        ("Settings Shell", "Split view, sidebar, titlebar toolbar, search, optional inspector"),
        ("Grouped Settings Form", "Overview, Behavior, Layout, Search, Second Bar, Privacy, Automation, Advanced, About"),
        ("Table + Inspector", "Menu Bar Items, Diagnostics, Hotkeys"),
        ("Outline/List + Detail Editor", "Groups, Profiles, Import / Export"),
        ("Assistant / Sheet", "Onboarding, import dry run, destructive confirmations"),
        ("Compact Utility Panel", "Find Icon, Second Bar, group panels, layout suggestions"),
        ("Native Status Menu", "Control item menu and separator contextual menu"),
        ("Status / Progress State", "Discovery, import/export, diagnostics, repair, permission checks"),
    ]
    y = 136
    for title, detail in templates:
        round_rect(draw, (48, y, 652, y + 82), 12, fill=GROUP_BG, outline=BORDER)
        draw_text(draw, (74, y + 17), title, 19, TEXT)
        draw_text(draw, (74, y + 48), detail, 14, SECONDARY, max_w=540)
        y += 96

    pages = [
        ("Overview", "Grouped Form"), ("Menu Bar Items", "Table + Inspector"), ("Behavior", "Grouped Form"),
        ("Layout", "Grouped Form + Preview"), ("Search", "Grouped Form"), ("Second Bar", "Grouped Form"),
        ("Groups", "Outline + Detail"), ("Hotkeys", "Table + Inspector"), ("Profiles", "Outline + Detail"),
        ("Automation", "Grouped Form"), ("Import / Export", "Outline + Assistant"), ("Privacy", "Grouped Form"),
        ("Diagnostics", "Table + Inspector"), ("Advanced", "Grouped Form"), ("About", "Grouped Form"),
        ("Onboarding", "Assistant"), ("Find Icon / Second Bar", "Compact Panel"), ("Status Menu", "NSMenu"),
    ]
    x0, y0 = 720, 150
    for i, (page, tmpl) in enumerate(pages):
        x = x0 + (i % 2) * 310
        y = y0 + (i // 2) * 74
        round_rect(draw, (x, y, x + 278, y + 54), 9, fill=GROUP_BG, outline=BORDER)
        draw_text(draw, (x + 16, y + 10), page, 15, TEXT)
        draw_text(draw, (x + 16, y + 31), tmpl, 12, SECONDARY)

    refs = [
        "Apple HIG inventory: Getting Started, Foundations, Patterns, Components, Inputs, Technologies",
        "Core HIG pages: Designing for macOS, Settings, Menus, Windows, Materials, Privacy, Accessibility",
        "Implementation target: SwiftUI NavigationSplitView/Form/Table/Inspector + AppKit NSMenu/NSPanel",
    ]
    y = 920
    for ref in refs:
        draw_text(draw, (48, y), ref, 14, SECONDARY)
        y += 24
    return img


def draw_hig_coverage_matrix() -> Image.Image:
    img = Image.new("RGB", (1400, 1080), WINDOW_BG)
    draw = ImageDraw.Draw(img)
    draw_text(draw, (48, 42), "Apple HIG Coverage Matrix", 34, TEXT)
    draw_text(draw, (48, 86), "Every visible route from Apple's HIG index is accounted for, then translated into native macOS surfaces.", 17, SECONDARY)

    columns = [
        ("HIG Area", 50, 300),
        ("Primary Decision", 350, 515),
        ("Native Template Impact", 900, 440),
    ]
    y0 = 136
    draw.rectangle((48, y0, 1352, y0 + 38), fill=(232, 232, 238))
    for label, x, w in columns:
        draw_text(draw, (x + 12, y0 + 11), label, 13, SECONDARY)

    rows = [
        ("Getting Started", "Use macOS as the product law. Other platforms are only contrast.", "Native accessory app, menu bar control, keyboard and pointer-first behavior."),
        ("Foundations", "Privacy, accessibility, layout, materials, color, typography, and writing define the visual system.", "System colors, SF text, SF Symbols, real window/sidebar/titlebar materials, no decorative glass."),
        ("Patterns", "Settings, onboarding, searching, feedback, file flows, modality, undo, launch behavior, and loading are core.", "Settings window, setup assistant, import/export sheet, diagnostics progress, reversible layout edits."),
        ("Components", "Use standard controls and containers instead of custom dashboard widgets.", "Split views, sidebars, tables, outlines, toolbars, search fields, popovers, panels, sheets, alerts."),
        ("Inputs", "Keyboard, focus, pointer, and drag/drop are first-class macOS interactions.", "Shortcut recorder, table focus, row selection, menu commands, contextual actions, drag grouping."),
        ("Technologies", "Only App Shortcuts, Siri, VoiceOver, and possible future iCloud sync are relevant now.", "Automation remains opt-in; VoiceOver labels are mandatory; no account, payment, widget, AR, or media surfaces."),
        ("macOS 27 Resources", "Treat the new design kit as reference for states, Dark Mode, resizing, and Liquid Glass naming.", "Adopt via native SDK materials and controls. Do not fake Liquid Glass with hand-painted translucency."),
    ]

    y = y0 + 38
    row_h = 104
    for idx, row in enumerate(rows):
        fill = GROUP_BG if idx % 2 == 0 else (251, 251, 253)
        draw.rectangle((48, y, 1352, y + row_h), fill=fill)
        draw.line((48, y, 1352, y), fill=BORDER)
        draw_text(draw, (62, y + 18), row[0], 18, TEXT, max_w=260)
        draw_wrapped_text(draw, (362, y + 18), row[1], 14, TEXT, max_w=500, line_h=20, max_lines=3)
        draw_wrapped_text(draw, (912, y + 18), row[2], 14, SECONDARY, max_w=400, line_h=20, max_lines=3)
        y += row_h
    draw.line((48, y, 1352, y), fill=BORDER)

    x = 48
    y += 38
    decisions = [
        ("Core", "Mac UI surfaces: Settings, menu bar, panels, forms, tables, privacy, accessibility."),
        ("Supporting", "Future or secondary cases: charts, notifications, app icon, RTL, iCloud, Siri."),
        ("Defer / NA", "Platform-specific or unrelated: tvOS, watchOS, visionOS-only, payments, media, AR, games."),
    ]
    for label, detail in decisions:
        round_rect(draw, (x, y, x + 400, y + 96), 12, fill=GROUP_BG, outline=BORDER)
        tone = GREEN if label == "Core" else (AMBER if label == "Supporting" else SECONDARY)
        draw_status(draw, x + 24, y + 22, label, tone)
        draw_wrapped_text(draw, (x + 24, y + 52), detail, 13, SECONDARY, max_w=344, line_h=18, max_lines=2)
        x += 438

    return img


GROUPED_PAGES = {
    "01-overview.png": ("Overview", "Overview", [
        Section("Status", [
            Row("Mode", "Basic Mode works without sensitive permissions.", "status", "Basic Mode On", tone="green"),
            Row("Pro Mode", "Optional features remain disabled until enabled.", "status", "Off", tone="neutral"),
            Row("Accessibility", "Needed only for Pro discovery features.", "status", "Not Granted", tone="amber"),
            Row("Health", "Last check completed successfully.", "status", "Ready", tone="green"),
        ]),
        Section("Common Settings", [
            Row("Launch at Login", "Start MenuBarDeclutter automatically.", "toggle", on=False),
            Row("Start Collapsed", "Hide selected menu bar items at launch.", "toggle", on=True),
            Row("Show Drag Hint", "Display positioning help near the menu bar control.", "button", "Show"),
        ]),
    ]),
    "03-behavior.png": ("Behavior", "Behavior", [
        Section("Collapse and Reveal", [
            Row("Auto-rehide", "Collapse again after a short delay.", "toggle", on=True),
            Row("Rehide Delay", "Seconds before hidden items collapse again.", "slider"),
            Row("Hover Reveal", "Temporarily reveal when pointer reaches the menu bar edge.", "toggle", on=False),
            Row("Option-click Reveal All", "Reveal both hidden zones from the control item.", "toggle", on=True),
        ]),
        Section("Control Item", [
            Row("Primary click", "Choose what the menu bar control does.", "popup", "Toggle Hidden Items"),
            Row("Separator appearance", "Use the most native low-contrast marker.", "popup", "Subtle"),
        ]),
    ]),
    "05-search.png": ("Search", "Search", [
        Section("Find Icon", [
            Row("Enable Find Icon", "Search discovered menu bar items.", "toggle", on=False),
            Row("Search Hotkey", "Keyboard shortcut for the transient search panel.", "value", "⌥⌘F"),
            Row("Selection Action", "What Return does in the search panel.", "popup", "Reveal and Highlight"),
            Row("Highlight Duration", "How long the approximate item frame remains visible.", "slider"),
        ]),
        Section("Requirements", [
            Row("Pro Mode", "Find Icon depends on explicit Pro opt-in.", "status", "Off", tone="amber"),
            Row("Accessibility Discovery", "Reads public menu bar metadata only.", "status", "Requires Permission", tone="amber"),
        ]),
    ]),
    "06-second-bar.png": ("Second Bar", "Second Bar", [
        Section("Second Bar", [
            Row("Enable Second Bar", "Show hidden items in a floating utility panel.", "toggle", on=False),
            Row("Placement", "Where the panel opens.", "popup", "Below Menu Bar"),
            Row("Show Labels", "Display item names beside icons.", "toggle", on=True),
            Row("Close When Clicking Outside", "Dismiss the panel when focus leaves it.", "toggle", on=True),
        ]),
        Section("Behavior", [
            Row("Search in Panel", "Filter hidden items inside the Second Bar.", "toggle", on=True),
            Row("Activate Owning App", "Optional action from item details.", "toggle", on=False),
        ]),
    ]),
    "10-automation.png": ("Automation", "Automation", [
        Section("Automation", [
            Row("Pause All Automation", "Stops triggers and URL commands without affecting manual controls.", "toggle", on=True),
            Row("App Intents", "Expose safe commands to Shortcuts.", "toggle", on=False),
            Row("URL Commands", "Allow local menubardeclutter:// commands.", "toggle", on=False),
        ]),
        Section("Allowed Actions", [
            Row("Visibility Commands", "Expand, collapse, toggle, reveal all.", "status", "Available", tone="green"),
            Row("Profile Apply", "Requires explicit profile selection.", "status", "Optional", tone="neutral"),
            Row("Spacing Labs", "Experimental commands stay disabled by default.", "status", "Off", tone="amber"),
        ]),
    ]),
    "12-privacy.png": ("Privacy", "Privacy & Permissions", [
        Section("Basic Mode", [
            Row("Accessibility", "Not requested by Basic Mode.", "status", "Off", tone="green"),
            Row("Screen Recording", "No screenshots or pixel capture.", "status", "Off", tone="green"),
            Row("Network Access", "No telemetry, sync, or analytics.", "status", "Off", tone="green"),
            Row("Local Storage", "Settings stay on this Mac.", "status", "On", tone="green"),
        ]),
        Section("Pro Mode", [
            Row("Enable Pro Mode", "Unlock permission-gated features only after opt-in.", "toggle", on=False),
            Row("Accessibility Discovery", "Reads public menu bar metadata after permission.", "status", "Requires Permission", tone="amber"),
            Row("Open Privacy Settings", "Open macOS System Settings to grant access.", "button", "Open"),
        ]),
    ]),
    "14-advanced.png": ("Advanced", "Advanced", [
        Section("Recovery", [
            Row("Reset App Layout", "Recreate app-owned menu bar items.", "button", "Reset"),
            Row("Safe Mode Next Launch", "Disable optional services on next start.", "toggle", on=False),
            Row("Application Support", "Open local support folder.", "button", "Open"),
        ]),
        Section("Labs", [
            Row("Icon Moving", "Experimental explicit drag operation.", "status", "Off", tone="amber"),
            Row("Menu Bar Spacing Labs", "Reversible spacing presets.", "status", "Off", tone="amber"),
            Row("Show Experimental Features", "Display Labs controls in Settings.", "toggle", on=False),
        ]),
    ]),
    "15-about.png": ("About", "About", [
        Section("MenuBarDeclutter", [
            Row("Version", "", "value", "0.1.1 (2)"),
            Row("Mode", "", "status", "Accessory Menu Bar App", tone="neutral"),
            Row("Privacy", "Basic Mode uses no sensitive permissions.", "status", "Privacy Safe", tone="green"),
        ]),
        Section("Support", [
            Row("Open Help", "View local help and troubleshooting.", "button", "Open"),
            Row("Export Diagnostics", "Create a privacy-safe local diagnostics file.", "button", "Export"),
        ]),
    ]),
}


def main() -> None:
    outputs: list[tuple[str, Image.Image]] = []
    outputs.append(("00-page-template-map.png", draw_template_map()))
    outputs.append(("19-hig-coverage-matrix.png", draw_hig_coverage_matrix()))
    for filename, (selected, title, sections) in GROUPED_PAGES.items():
        outputs.append((filename, draw_grouped_form(selected, title, sections, toolbar=("Reset",) if selected in {"Advanced", "Behavior"} else ())))

    outputs.append(("02-menu-bar-items.png", draw_table_page(
        "Menu Bar Items",
        "Menu Bar Items",
        ["", "Item", "App", "Zone", "Visibility", "Last Seen"],
        [
            ["◌", "Wi-Fi", "System", "Visible", "Visible", "Now"],
            ["◌", "VPN", "Network Utility", "Hidden", "Hidden", "Now"],
            ["◌", "Battery", "System", "Visible", "Visible", "Now"],
            ["◌", "Cloud Sync", "Cloud Sync", "Hidden", "Hidden", "2 min"],
            ["◌", "Backup", "Backup Assist", "Always Hidden", "Hidden", "5 min"],
            ["◌", "Drive Helper", "Drive", "Second Bar", "Preview", "8 min"],
        ],
        [
            Row("Selected Item", value="VPN"),
            Row("Zone", control="status", value="Hidden", tone="amber"),
            Row("Default Visibility", value="Hidden"),
            Row("Action", control="button", value="Reveal", tone="blue"),
            Row("Move", control="button", value="Move to Visible"),
        ],
        toolbar=("Reveal", "Hide", "Refresh"),
        segment=["All", "Visible", "Hidden", "Always Hidden"],
    )))
    outputs.append(("04-layout.png", draw_layout_page()))
    outputs.append(("07-groups.png", draw_table_page(
        "Groups",
        "Groups",
        ["", "Group", "Items", "Status", "Hotkey", "Updated"],
        [
            ["◌", "Work Essentials", "6 items", "Ready", "⌥⌘1", "Today"],
            ["◌", "Network Tools", "4 items", "Ready", "⌥⌘2", "Today"],
            ["◌", "Quiet Mode", "8 items", "Preview", "None", "Yesterday"],
            ["◌", "Always Hidden", "5 items", "Ready", "⌥⌘H", "Mon"],
        ],
        [
            Row("Selected Group", value="Network Tools"),
            Row("Protected", control="status", value="Off", tone="neutral"),
            Row("Status Item", control="status", value="Hidden", tone="neutral"),
            Row("Action", control="button", value="Open Panel", tone="blue"),
            Row("Edit", control="button", value="Edit Group"),
        ],
        toolbar=("Add", "Duplicate", "Delete"),
    )))
    outputs.append(("08-hotkeys.png", draw_table_page(
        "Hotkeys",
        "Hotkeys",
        ["", "Shortcut", "Command", "Scope", "Status", "Conflict"],
        [
            ["⌘", "⌥⌘B", "Toggle Hidden Items", "Global", "Ready", "None"],
            ["⌘", "⌥⌘F", "Find Icon", "Pro", "Requires Permission", "None"],
            ["⌘", "⌥⌘2", "Open Network Tools", "Group", "Ready", "None"],
            ["⌘", "⌥⌘S", "Second Bar", "Pro", "Preview", "None"],
        ],
        [
            Row("Selected Shortcut", value="⌥⌘F"),
            Row("Command", value="Find Icon"),
            Row("Availability", control="status", value="Requires Permission", tone="amber"),
            Row("Action", control="button", value="Record Shortcut", tone="blue"),
        ],
        toolbar=("Add", "Record", "Remove"),
    )))
    outputs.append(("09-profiles.png", draw_table_page(
        "Profiles",
        "Profiles",
        ["", "Profile", "Trigger", "Visibility", "Status", "Updated"],
        [
            ["◌", "Default", "Manual", "Basic", "Ready", "Today"],
            ["◌", "Presentation", "Display Count", "Expanded", "Ready", "Today"],
            ["◌", "Travel", "Battery Low", "Collapsed", "Preview", "Yesterday"],
            ["◌", "Focus Work", "Time of Day", "Collapsed", "Ready", "Mon"],
        ],
        [
            Row("Selected Profile", value="Presentation"),
            Row("Dry Run", control="status", value="No changes yet", tone="neutral"),
            Row("Action", control="button", value="Apply", tone="blue"),
            Row("Export", control="button", value="Export"),
        ],
        toolbar=("Add", "Duplicate", "Apply"),
    )))
    outputs.append(("11-import-export.png", draw_table_page(
        "Import / Export",
        "Import / Export",
        ["", "Package", "Kind", "Source", "Status", "Date"],
        [
            ["⇅", "Settings Export", "Export", "Local", "Ready", "Today"],
            ["⇅", "Profile Pack", "Import", "Selected File", "Preview", "Today"],
            ["⇅", "Backup Before Import", "Backup", "Local", "Ready", "Today"],
        ],
        [
            Row("Workflow", value="Dry-run before apply"),
            Row("Backup", control="status", value="Created", tone="green"),
            Row("Action", control="button", value="Export", tone="blue"),
            Row("Import", control="button", value="Choose File"),
        ],
        toolbar=("Export", "Import", "Backup"),
    )))
    outputs.append(("13-diagnostics.png", draw_table_page(
        "Diagnostics",
        "Diagnostics",
        ["", "Time", "Area", "Severity", "Message", "Privacy"],
        [
            ["✓", "10:14", "Health", "Healthy", "Status items installed", "Local"],
            ["!", "10:15", "Privacy", "Warning", "Accessibility not granted", "Local"],
            ["✓", "10:16", "Layout", "Healthy", "Separator geometry valid", "Local"],
            ["!", "10:17", "Search", "Warning", "Find Icon unavailable", "Local"],
            ["✓", "10:18", "Export", "Healthy", "Diagnostics export ready", "Local"],
        ],
        [
            Row("Selected Event", value="Accessibility not granted"),
            Row("Severity", control="status", value="Warning", tone="amber"),
            Row("Data", value="No screenshots or query text"),
            Row("Action", control="button", value="Copy"),
            Row("Export", control="button", value="Export", tone="blue"),
        ],
        toolbar=("Run Check", "Repair", "Export"),
        segment=["All", "Warnings", "Errors"],
    )))
    outputs.append(("16-onboarding-assistant.png", draw_assistant()))
    outputs.append(("17-utility-panels.png", draw_panels()))
    outputs.append(("18-status-menu.png", draw_status_menu()))

    for filename, image in outputs:
        image.save(OUT_DIR / filename)
        print(filename)


if __name__ == "__main__":
    main()
