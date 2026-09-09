#!/usr/bin/env python3
"""
tools/extract_environment_assets.py
Automated pipeline tool for extracting, cleaning, organizing, and verifying
the 10 new 2.5D isometric environmental assets into finest-garden-prototype.
"""

import os
import sys
from PIL import Image, ImageDraw

SRC_DIR = "/home/el3laimy/Downloads/Assets"
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_BASE = os.path.join(BASE_DIR, "assets", "environment")
ARTIFACT_DIR = "/home/el3laimy/.gemini/antigravity/brain/c18f39df-35cc-4bc9-9225-9e72dac391af"

def ensure_dirs():
    dirs = [
        os.path.join(OUT_BASE, "terrain"),
        os.path.join(OUT_BASE, "cottage"),
        os.path.join(OUT_BASE, "trees"),
        os.path.join(OUT_BASE, "foliage"),
        os.path.join(OUT_BASE, "fences"),
        os.path.join(OUT_BASE, "plots"),
    ]
    for d in dirs:
        os.makedirs(d, exist_ok=True)
    print("✓ Output directories ensured.")

def tight_crop(im):
    bbox = im.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

def process_all():
    ensure_dirs()
    extracted_manifest = []

    # -------------------------------------------------------------
    # 1. Terrain Island (Image #1)
    # -------------------------------------------------------------
    p1 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (1).png")
    im1 = Image.open(p1).convert("RGBA")
    terrain_out = os.path.join(OUT_BASE, "terrain", "terrain_island_meadow.png")
    im1.save(terrain_out)
    extracted_manifest.append(("terrain/terrain_island_meadow.png", im1.size, terrain_out))
    print(f"✓ Extracted Terrain Island: {im1.size}")

    # -------------------------------------------------------------
    # 2. Cottage Suite (Images #2, #3, #4)
    # -------------------------------------------------------------
    p2 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (2).png")
    p3 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (3).png")
    p4 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (4).png")

    base = Image.open(p2).convert("RGBA")
    roof = Image.open(p3).convert("RGBA")
    awning = Image.open(p4).convert("RGBA")

    base_out = os.path.join(OUT_BASE, "cottage", "cottage_base.png")
    roof_out = os.path.join(OUT_BASE, "cottage", "cottage_roof.png")
    awning_out = os.path.join(OUT_BASE, "cottage", "cottage_awning.png")
    combined_out = os.path.join(OUT_BASE, "cottage", "cottage_combined.png")

    base.save(base_out)
    roof.save(roof_out)
    tight_crop(awning).save(awning_out)

    combined_cottage = Image.new("RGBA", (1254, 1254), (0, 0, 0, 0))
    combined_cottage.alpha_composite(base)
    combined_cottage.alpha_composite(roof)
    combined_cottage.save(combined_out)

    extracted_manifest.append(("cottage/cottage_base.png", base.size, base_out))
    extracted_manifest.append(("cottage/cottage_roof.png", roof.size, roof_out))
    extracted_manifest.append(("cottage/cottage_combined.png", combined_cottage.size, combined_out))
    extracted_manifest.append(("cottage/cottage_awning.png", tight_crop(awning).size, awning_out))
    print("✓ Extracted Cottage layers and combined beauty asset.")

    # -------------------------------------------------------------
    # 3. Ancient Oak Tree (Images #5, #6, #10)
    # -------------------------------------------------------------
    p5 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (5).png")
    p6 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (6).png")
    p10 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (10).png")

    trunk = Image.open(p5).convert("RGBA")
    canopy = Image.open(p6).convert("RGBA")
    vignette = Image.open(p10).convert("RGBA")

    trunk_out = os.path.join(OUT_BASE, "trees", "oak_trunk.png")
    canopy_out = os.path.join(OUT_BASE, "trees", "oak_canopy.png")
    tree_combined_out = os.path.join(OUT_BASE, "trees", "oak_combined.png")
    vignette_out = os.path.join(OUT_BASE, "trees", "foreground_canopy_vignette.png")

    trunk.save(trunk_out)
    canopy.save(canopy_out)
    vignette.save(vignette_out)

    tree_combined = Image.new("RGBA", (1254, 1254), (0, 0, 0, 0))
    tree_combined.alpha_composite(trunk)
    tree_combined.alpha_composite(canopy)
    tree_combined.save(tree_combined_out)

    extracted_manifest.append(("trees/oak_trunk.png", trunk.size, trunk_out))
    extracted_manifest.append(("trees/oak_canopy.png", canopy.size, canopy_out))
    extracted_manifest.append(("trees/oak_combined.png", tree_combined.size, tree_combined_out))
    extracted_manifest.append(("trees/foreground_canopy_vignette.png", vignette.size, vignette_out))
    print("✓ Extracted Oak Tree layers and foreground vignette.")

    # -------------------------------------------------------------
    # 4. Bushes & Foliage (Image #7)
    # -------------------------------------------------------------
    p7 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (7).png")
    im7 = Image.open(p7).convert("RGBA")

    bush_crops = {
        "bush_round_dense.png": (504, 128, 948, 528),
        "bush_flowering.png": (976, 160, 1432, 536),
        "bush_low_shrub.png": (28, 284, 476, 528),
        "bush_boxwood_sphere.png": (224, 580, 680, 984),
        "bush_ivy_patch.png": (732, 616, 1372, 1004)
    }

    for name, box in bush_crops.items():
        crop = tight_crop(im7.crop(box))
        target_p = os.path.join(OUT_BASE, "foliage", name)
        crop.save(target_p)
        extracted_manifest.append((f"foliage/{name}", crop.size, target_p))
    print(f"✓ Extracted {len(bush_crops)} foliage shrubs & bushes.")

    # -------------------------------------------------------------
    # 5. Modular Fences & Gates (Image #8)
    # -------------------------------------------------------------
    p8 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (8).png")
    im8 = Image.open(p8).convert("RGBA")

    fence_crops = {
        "fence_post.png": (1272, 228, 1380, 516),
        "fence_straight.png": (436, 232, 1200, 564),
        "fence_corner_left.png": (48, 236, 388, 496),
        "gate_closed.png": (416, 592, 736, 876),
        "gate_open.png": (748, 592, 920, 880),
        "fence_short_angled_1.png": (32, 624, 388, 828),
        "fence_corner_right.png": (1092, 624, 1412, 836),
        "fence_post_short.png": (968, 632, 1072, 860)
    }

    for name, box in fence_crops.items():
        crop = tight_crop(im8.crop(box))
        target_p = os.path.join(OUT_BASE, "fences", name)
        crop.save(target_p)
        extracted_manifest.append((f"fences/{name}", crop.size, target_p))
    print(f"✓ Extracted {len(fence_crops)} rustic modular fence pieces.")

    # -------------------------------------------------------------
    # 6. Soil Plots & Beehive (Image #9)
    # -------------------------------------------------------------
    p9 = os.path.join(SRC_DIR, "ChatGPT Image Sep 9, 2026, 11_23_11 AM (9).png")
    im9 = Image.open(p9).convert("RGBA")

    plot_crops = {
        "decor_beehive.png": (1048, 96, 1416, 512),
        "soil_wet.png": (552, 220, 964, 496),
        "soil_dry.png": (88, 224, 480, 492),
        "soil_seeded.png": (40, 552, 724, 996),
        "soil_mature.png": (768, 556, 1424, 1012)
    }

    for name, box in plot_crops.items():
        crop = tight_crop(im9.crop(box))
        target_p = os.path.join(OUT_BASE, "plots", name)
        crop.save(target_p)
        extracted_manifest.append((f"plots/{name}", crop.size, target_p))
    print(f"✓ Extracted {len(plot_crops)} soil beds and beehive decor.")

    # -------------------------------------------------------------
    # 7. Generate Master Verification Contact Sheet
    # -------------------------------------------------------------
    grid_cols = 4
    item_w = 360
    item_h = 300
    grid_rows = (len(extracted_manifest) + grid_cols - 1) // grid_cols
    sheet_w = grid_cols * item_w
    sheet_h = grid_rows * item_h

    master_sheet = Image.new("RGBA", (sheet_w, sheet_h), (245, 243, 238, 255))
    draw = ImageDraw.Draw(master_sheet)

    for i, (rel_name, size, full_path) in enumerate(extracted_manifest):
        c = i % grid_cols
        r = i // grid_cols
        x = c * item_w
        y = r * item_h

        draw.rectangle([x + 10, y + 10, x + item_w - 10, y + item_h - 10], outline=(200, 195, 185, 255), width=1)

        elem_im = Image.open(full_path)
        thumb = elem_im.copy()
        thumb.thumbnail((item_w - 40, item_h - 70), Image.Resampling.LANCZOS)

        tx = x + (item_w - thumb.width) // 2
        ty = y + 15 + (item_h - 70 - thumb.height) // 2
        master_sheet.paste(thumb, (tx, ty), thumb)

        draw.text((x + 15, y + item_h - 45), rel_name, fill=(40, 45, 40, 255))
        draw.text((x + 15, y + item_h - 28), f"{size[0]}x{size[1]} px", fill=(120, 125, 115, 255))

    master_sheet_path = os.path.join(ARTIFACT_DIR, "environment_assets_master_sheet.png")
    master_sheet.save(master_sheet_path)
    print(f"\n🎉 Master verification sheet saved to: {master_sheet_path}")
    print(f"Total extracted environment assets: {len(extracted_manifest)}")

if __name__ == "__main__":
    process_all()
