#!/usr/bin/env python3
"""
tools/extract_all_character_assets.py
Extracts and creates crystal-clear RGBA sprites with transparent backgrounds
for all character gameplay poses, portraits, and props from the Bloomhaven sheets.
"""

import os
from collections import deque
from PIL import Image, ImageFilter

def remove_parchment_background(img: Image.Image) -> Image.Image:
    """
    Removes the warm tan/sepia parchment background from the outer perimeter
    inward using flood-fill with gradient boundary protection.
    """
    rgba = img.convert("RGBA")
    w, h = rgba.size
    pixels = rgba.load()

    def is_parchment(r, g, b):
        # Parchment is warm, bright, low saturation beige/tan
        if r > 165 and g > 145 and b > 120 and r >= g >= b and (r - b) < 80:
            return True
        # Also clean near white or light grey borders
        if r > 210 and g > 200 and b > 185:
            return True
        return False

    visited = set()
    queue = deque()

    # Seed from all four borders
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        if x < 0 or x >= w or y < 0 or y >= h:
            continue
        visited.add((x, y))

        r, g, b, a = pixels[x, y]
        if is_parchment(r, g, b):
            pixels[x, y] = (0, 0, 0, 0)
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    queue.append((nx, ny))

    # Feather edge alpha slightly for crisp smooth blending
    alpha = rgba.split()[3]
    bbox = alpha.getbbox()
    if bbox:
        return rgba.crop(bbox)
    return rgba


def remove_black_background(img: Image.Image, threshold: int = 25) -> Image.Image:
    """
    Removes black background from cut-out parts sheets.
    """
    rgba = img.convert("RGBA")
    datas = rgba.getdata()
    new_data = []
    for p in datas:
        r, g, b, a = p
        if r < threshold and g < threshold and b < threshold:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(p)
    rgba.putdata(new_data)
    bbox = rgba.getbbox()
    if bbox:
        return rgba.crop(bbox)
    return rgba


def main():
    os.makedirs("assets/character/poses", exist_ok=True)
    os.makedirs("assets/character/portraits", exist_ok=True)
    os.makedirs("assets/character/props", exist_ok=True)

    key_sheet_path = "assets/character/sheets/key_poses_sheet.jpg"
    expr_sheet_path = "assets/character/sheets/expressions_props_sheet.jpg"

    if not os.path.exists(key_sheet_path):
        print(f"Error: {key_sheet_path} not found!")
        return

    key_sheet = Image.open(key_sheet_path).convert("RGB")
    print(f"Loaded Key Poses Sheet: {key_sheet.size}")

    # 1. Extract Gameplay Key Poses
    poses = {
        "idle_a": (25, 110, 175, 410),
        "idle_b": (180, 110, 335, 410),
        "walk_1": (335, 110, 505, 410), # Walk Contact Left
        "walk_2": (505, 110, 665, 410), # Walk Passing Left
        "walk_3": (665, 110, 830, 410), # Walk Contact Right
        "walk_4": (830, 110, 985, 410), # Walk Passing Right
        "action_inspect_bulb": (40, 460, 220, 760),
        "action_write_notebook": (220, 460, 365, 760),
        "action_water_flowers": (370, 460, 570, 760),
        "action_harvest_flowers": (575, 460, 780, 760),
        "action_celebrate": (785, 460, 975, 760),
    }

    for name, box in poses.items():
        cropped = key_sheet.crop(box)
        clean = remove_parchment_background(cropped)
        out_path = f"assets/character/poses/{name}.png"
        clean.save(out_path)
        print(f"✓ Saved pose: {out_path} ({clean.size})")

    # 2. Extract Portraits & Expressions
    if os.path.exists(expr_sheet_path):
        expr_sheet = Image.open(expr_sheet_path).convert("RGB")
        print(f"Loaded Expressions Sheet: {expr_sheet.size}")

        portraits = {
            "portrait_neutral": (0, 10, 175, 230),
            "portrait_gentle_smile": (170, 10, 340, 230),
            "portrait_happy": (335, 10, 505, 230),
            "portrait_surprised": (500, 10, 670, 230),
            "portrait_focused": (665, 10, 835, 230),
            "portrait_worried": (830, 10, 1000, 230),
        }

        for name, box in portraits.items():
            cropped = expr_sheet.crop(box)
            clean = remove_black_background(cropped)
            out_path = f"assets/character/portraits/{name}.png"
            clean.save(out_path)
            print(f"✓ Saved portrait: {out_path} ({clean.size})")

        # Extract props
        props = {
            "prop_watering_can": (760, 550, 995, 770),
            "prop_trowel": (620, 570, 775, 760),
            "prop_notebook": (15, 600, 185, 770),
            "prop_tulip_bulb": (490, 545, 605, 765),
        }

        for name, box in props.items():
            cropped = expr_sheet.crop(box)
            clean = remove_black_background(cropped)
            out_path = f"assets/character/props/{name}.png"
            clean.save(out_path)
            print(f"✓ Saved prop: {out_path} ({clean.size})")

    print("\n🎉 ALL ASSETS EXTRACTED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
