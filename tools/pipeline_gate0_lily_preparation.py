#!/usr/bin/env python3
"""
tools/pipeline_gate0_lily_preparation.py
Gate 0 — Asset Preparation Pipeline for Lily (Bloomhaven Gardener)
v2: Re-extracts from lily_game_ready_sheet.jpg (labeled black-bg) and
    expressions_props_sheet.jpg, produces all spec-required outputs.

Source sheets:
  - lily_game_ready_sheet.jpg (1024x960) — separated body parts on black
  - expressions_props_sheet.jpg (1024x768) — faces, eyes, mouths, tools
"""

import os, json, math
from collections import deque
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "character", "sheets")
OUT = os.path.join(ROOT, "assets", "character", "Lily_Source")

SEPARATED = os.path.join(OUT, "separated_layers")
REPAIRED  = os.path.join(OUT, "repaired_hidden_parts")
CLEAN     = os.path.join(OUT, "clean_rgba_assets")
TOOLS     = os.path.join(OUT, "tool_variants")
FACE      = os.path.join(OUT, "face_variants")
RIG       = os.path.join(OUT, "rig_reference")

# ─── Helpers ─────────────────────────────────────────────────────────────────

def ensure_dirs():
    for d in [SEPARATED, REPAIRED, CLEAN, TOOLS, FACE, RIG]:
        os.makedirs(d, exist_ok=True)
    print("✓ Directories ready")


def flood_fill_bg(img, threshold=30):
    """BFS flood-fill dark background removal from edges → RGBA."""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    visited = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.extend([(x, 0), (x, h - 1)])
    for y in range(h):
        q.extend([(0, y), (w - 1, y)])
    while q:
        cx, cy = q.popleft()
        idx = cy * w + cx
        if visited[idx]:
            continue
        r, g, b, a = px[cx, cy]
        if max(r, g, b) >= threshold:
            continue
        visited[idx] = 1
        px[cx, cy] = (0, 0, 0, 0)
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny * w + nx]:
                q.append((nx, ny))
    bbox = rgba.getbbox()
    if bbox:
        return rgba.crop(bbox)
    return rgba


def extend_edges(img, top=0, bottom=0, left=0, right=0):
    """Extend canvas by duplicating edge pixels with fade-out alpha."""
    w, h = img.size
    new_w, new_h = w + left + right, h + top + bottom
    canvas = Image.new("RGBA", (new_w, new_h), (0, 0, 0, 0))
    canvas.paste(img, (left, top), img)
    px = canvas.load()
    ox, oy = left, top
    for dy in range(top):
        for x in range(left, left + w):
            src_r, src_g, src_b, src_a = px[x, top + dy] if (top + dy) < h else (0, 0, 0, 0)
            for sy in range(min(12, h)):
                r, g, b, a = px[x, oy + sy]
                if a > 50:
                    fade = float(dy + 1) / float(top) if top else 1.0
                    px[x, dy] = (r, g, b, int(a * fade))
                    break
    for dy in range(bottom):
        for x in range(left, left + w):
            for sy in range(min(12, h) - 1, -1, -1):
                py = oy + h - 1 - sy
                if 0 <= py < new_h:
                    r, g, b, a = px[x, py]
                    if a > 50:
                        fade = float(dy + 1) / float(bottom) if bottom else 1.0
                        px[x, oy + h + dy] = (r, g, b, int(a * fade))
                        break
    bbox = canvas.getbbox()
    return canvas.crop(bbox) if bbox else canvas


def alpha_threshold(img, threshold=8):
    """Remove near-black edge fringing: pixels with brightness < threshold → transparent."""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            br = max(r, g, b)
            if a > 0 and br < threshold:
                px[x, y] = (r, g, b, 0)
            elif a > 0 and br < threshold + 20:
                alpha = int(255 * (br - threshold) / 20.0)
                px[x, y] = (r, g, b, min(a, alpha))
    bbox = rgba.getbbox()
    return rgba.crop(bbox) if bbox else rgba


def mirror_horizontal(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def save_rgba(img, path):
    img.save(path)


def get_alpha_coverage(img):
    """Percentage of non-transparent pixels in the image."""
    rgba = img.convert("RGBA")
    px = rgba.getdata()
    total = len(px)
    opaque = sum(1 for p in px if p[3] > 10)
    return round(100.0 * opaque / max(1, total), 1)


# ─── GAME-READY SHEET: Body Parts ────────────────────────────────────────────
# Boxes derived from connected-component analysis of lily_game_ready_sheet.jpg
# Format: (x1, y1, x2, y2) — source pixels

BODY_BOXES = {
    # Row 1: Heads & Hats
    "head_base":       (12, 5, 121, 146),
    "head_3q":         (140, 5, 262, 146),      # extra (not spec-required)
    "head_side":       (289, 6, 414, 146),      # extra
    "straw_hat":       (437, 13, 593, 119),
    "hat_side":        (613, 16, 735, 116),     # extra
    "hat_back":        (753, 12, 884, 126),     # extra
    "hat_3q":          (894, 21, 1018, 123),    # extra

    # Row 2: Hair, Braids, Torso, Apron
    "front_hair":      (16, 192, 130, 358),
    "hair_back":       (170, 193, 287, 375),    # extra
    "braid_upper":     (341, 195, 406, 362),
    "braid_middle":    (499, 209, 531, 364),    # extra (spec has only upper+tip)
    "braid_tip":       (620, 209, 661, 355),
    "torso":           (701, 193, 870, 368),
    "apron_front":     (886, 204, 1018, 373),

    # Row 3: Apron back, Arms, Hands
    "apron_back":      (12, 419, 156, 615),
    "arm_L_upper":     (206, 412, 291, 612),
    "arm_L_lower":     (352, 422, 423, 609),
    "hand_L":          (467, 456, 533, 560),
    "arm_R_upper":     (607, 420, 685, 603),
    "arm_R_lower":     (740, 421, 895, 614),
    "hand_R_open":     (886, 434, 978, 548),

    # Row 4: Legs, Boots, Skirts, Accessories
    "leg_L_upper":     (24, 651, 86, 824),
    "boot_L":          (126, 699, 218, 821),
    "leg_R_upper":     (254, 652, 307, 823),
    "boot_R":          (357, 702, 444, 828),
    "skirt_under":     (478, 654, 636, 827),    # white petticoat → used as skirt_back layer
    "skirt_outer":     (655, 653, 815, 831),    # green overskirt → used as skirt_front layer
    "accessory_belt":  (855, 671, 1006, 778),   # extra — tool belt
    "flower_pouch":    (949, 747, 1006, 834),   # extra — flower pouch
}


# ─── EXPRESSIONS SHEET: Face Parts, Eyes, Mouths, Tools ──────────────────────

# Face portraits — 6 faces merged into one component at row top
# Each face is ~171px wide, starting at x=3, incrementing ~171
FACE_PORTRAIT_BOXES = {
    "face_neutral":    (3, 8, 168, 248),
    "face_smile":      (168, 8, 335, 248),
    "face_happy":      (335, 8, 502, 248),
    "face_surprised":  (502, 8, 669, 248),
    "face_focused":    (669, 8, 836, 248),
    "face_worried":    (836, 8, 1021, 248),
}

# Eye pairs — 3 types (OPEN, HALF-CLOSED, CLOSED), each type is left+right pair
# Crop region includes both eyes + avoids label text below
EYE_BOXES = {
    "eyes_open":    (14, 282, 120, 335),     # OPEN pair
    "eyes_half":    (134, 282, 240, 335),     # HALF-CLOSED pair
    "eyes_blink":   (252, 290, 355, 335),     # CLOSED pair (blink)
}

# Mouths — 4 types in a row
MOUTH_BOXES = {
    "mouth_neutral":   (393, 292, 457, 340),
    "mouth_smile":     (479, 292, 545, 340),
    "mouth_open":      (566, 286, 634, 340),
    "mouth_small_o":   (653, 286, 716, 340),
}

# Eyebrows — 6 types
# Each type has a label + 3 brow variants in a row. We crop one variant per type.
EYEBROW_BOXES = {
    "brow_neutral":    (754, 286, 810, 310),
    "brow_raised":     (816, 286, 870, 310),
    "brow_furrowed":   (754, 335, 810, 355),
    "brow_worried":    (818, 335, 870, 355),
    "brow_focused":    (780, 383, 841, 400),
    "brow_angry":      (894, 384, 944, 403),
}

# Tools from HANDS & PROPS row
TOOL_BOXES_EXPR = {
    "notebook_closed":  (7, 467, 196, 650),
    "notebook_open":    (178, 472, 496, 654),
    "tulip_bulb":       (511, 422, 619, 648),
    "trowel_expr":      (636, 441, 789, 642),
    "watering_can":     (795, 433, 1018, 647),
}


# ─── Spec Name Mapping ────────────────────────────────────────────────────────
# Spec name → source key (from BODY_BOXES)
SPEC_BODY_MAP = {
    "head_base":     "head_base",
    "front_hair":    "front_hair",
    "braid_upper":   "braid_upper",
    "braid_tip":     "braid_tip",
    "straw_hat":     "straw_hat",
    "torso_shirt":   "torso",         # renamed from torso → torso_shirt per spec
    "overalls_bib":  "apron_front",   # renamed from apron_front → overalls_bib per spec
    "skirt_front":   "skirt_outer",   # green overskirt → front
    "skirt_back":    "skirt_under",   # white petticoat → back
    "arm_L_upper":   "arm_L_upper",
    "arm_L_lower":   "arm_L_lower",
    "hand_L":        "hand_L",
    "arm_R_upper":   "arm_R_upper",
    "arm_R_lower":   "arm_R_lower",
    "hand_R_open":   "hand_R_open",
    "leg_L_upper":   "leg_L_upper",
    "boot_L":        "boot_L",
    "leg_R_upper":   "leg_R_upper",
    "boot_R":        "boot_R",
}

# Spec name → source key from TOOL_BOXES_EXPR
SPEC_TOOL_MAP = {
    "watering_can":  "watering_can",
    "trowel":        "trowel_expr",
    "notebook":      "notebook_closed",
    "flower_basket_empty":  None,   # keep from old extraction
    "flower_basket_filled": None,   # keep from old extraction
    "shears":        None,          # placeholder — no source on sheets
}

SPEC_FACE_MAP = {
    "eyes_open":     "eyes_open",
    "eyes_blink":    "eyes_blink",
    "eyes_smile":    "face_smile",  # extract eye region from smile face
    "mouth_smile":   "mouth_smile",
}


# ─── Main Pipeline ────────────────────────────────────────────────────────────

def step_extract_body():
    print("\n>>> Step 1: Extract Body Parts from lily_game_ready_sheet.jpg")
    sheet = Image.open(os.path.join(SRC, "lily_game_ready_sheet.jpg")).convert("RGB")
    manifest = {}

    for spec_name, src_key in SPEC_BODY_MAP.items():
        box = BODY_BOXES[src_key]
        crop = sheet.crop(box)
        clean = flood_fill_bg(crop)
        clean = alpha_threshold(clean, 8)

        # Save separated + clean
        out = f"{spec_name}.png"
        save_rgba(clean, os.path.join(SEPARATED, out))
        save_rgba(clean, os.path.join(CLEAN, out))
        manifest[spec_name] = {
            "file": out,
            "dimensions": list(clean.size),
            "category": "body" if any(k in spec_name for k in ["arm", "leg", "head", "torso", "pelvis", "hand"]) else "clothes",
            "source": "lily_game_ready_sheet.jpg",
            "alpha_coverage_pct": get_alpha_coverage(clean),
        }
        print(f"  ✓ {spec_name}: {clean.size}")

    # Also extract extras (non-spec) for reference
    extras = ["head_3q", "head_side", "hat_side", "hat_back", "hat_3q",
              "hair_back", "braid_middle", "apron_back", "apron_front",
              "accessory_belt", "flower_pouch", "skirt_outer", "skirt_under"]
    for name in extras:
        if name in BODY_BOXES:
            box = BODY_BOXES[name]
            crop = sheet.crop(box)
            clean = flood_fill_bg(crop)
            clean = alpha_threshold(clean, 8)
            out = f"{name}.png"
            save_rgba(clean, os.path.join(SEPARATED, out))
            save_rgba(clean, os.path.join(CLEAN, out))
            print(f"  ✓ extra: {name}: {clean.size}")

    # Generate pelvis from torso lower third
    torso_img = Image.open(os.path.join(SEPARATED, "torso_shirt.png"))
    tw, th = torso_img.size
    pelvis_crop = torso_img.crop((0, int(th * 0.65), tw, th))
    save_rgba(pelvis_crop, os.path.join(SEPARATED, "pelvis.png"))
    save_rgba(pelvis_crop, os.path.join(CLEAN, "pelvis.png"))
    manifest["pelvis"] = {
        "file": "pelvis.png",
        "dimensions": list(pelvis_crop.size),
        "category": "body",
        "source": "synthesized from torso_shirt lower third",
        "alpha_coverage_pct": get_alpha_coverage(pelvis_crop),
    }
    print(f"  ✓ pelvis (synthesized): {pelvis_crop.size}")

    # Generate hand_R_grip as mirror of hand_L
    hand_l = Image.open(os.path.join(SEPARATED, "hand_L.png"))
    hand_r_grip = mirror_horizontal(hand_l)
    save_rgba(hand_r_grip, os.path.join(SEPARATED, "hand_R_grip.png"))
    save_rgba(hand_r_grip, os.path.join(CLEAN, "hand_R_grip.png"))
    manifest["hand_R_grip"] = {
        "file": "hand_R_grip.png",
        "dimensions": list(hand_r_grip.size),
        "category": "body",
        "source": "mirrored from hand_L",
        "alpha_coverage_pct": get_alpha_coverage(hand_r_grip),
    }
    print(f"  ✓ hand_R_grip (mirrored hand_L): {hand_r_grip.size}")

    return manifest


def step_extract_tools():
    print("\n>>> Step 2: Extract Tool Variants from expressions_props_sheet.jpg")
    sheet = Image.open(os.path.join(SRC, "expressions_props_sheet.jpg")).convert("RGB")
    manifest = {}

    # Tools from expressions sheet
    for spec_name, src_key in SPEC_TOOL_MAP.items():
        if src_key is None:
            # Keep existing extraction (basket, shears placeholder)
            existing = os.path.join(TOOLS, f"{spec_name}.png")
            if os.path.exists(existing):
                img = Image.open(existing)
                print(f"  ✓ {spec_name}: kept existing ({img.size})")
                manifest[spec_name] = {"kept_existing": True}
            else:
                print(f"  ⚠ {spec_name}: no source available")
            continue

        box = TOOL_BOXES_EXPR[src_key]
        crop = sheet.crop(box)
        clean = flood_fill_bg(crop)
        clean = alpha_threshold(clean, 8)
        save_rgba(clean, os.path.join(TOOLS, f"{spec_name}.png"))
        save_rgba(clean, os.path.join(CLEAN, f"{spec_name}.png"))
        manifest[spec_name] = {
            "file": f"{spec_name}.png",
            "dimensions": list(clean.size),
            "alpha_coverage_pct": get_alpha_coverage(clean),
        }
        print(f"  ✓ {spec_name}: {clean.size}")

    # Extract extra expression props for reference
    for name, box in TOOL_BOXES_EXPR.items():
        if name in ("watering_can", "trowel_expr"):
            continue  # already extracted above
        crop = sheet.crop(box)
        clean = flood_fill_bg(crop)
        clean = alpha_threshold(clean, 8)
        out = f"{name}.png"
        save_rgba(clean, os.path.join(TOOLS, out))
        print(f"  ✓ extra tool: {name}: {clean.size}")

    return manifest


def step_extract_faces():
    print("\n>>> Step 3: Extract Face Variants from expressions_props_sheet.jpg")
    sheet = Image.open(os.path.join(SRC, "expressions_props_sheet.jpg")).convert("RGB")
    manifest = {}

    # Eyes
    for spec_name, src_key in SPEC_FACE_MAP.items():
        if spec_name.startswith("eyes_smile"):
            # Extract eye region from the smile face
            box = FACE_PORTRAIT_BOXES[src_key]
            face_crop = sheet.crop(box)
            fw, fh = face_crop.size
            # Eyes are roughly in the top 40% of the face, centered
            eye_box = (int(fw * 0.15), int(fh * 0.30), int(fw * 0.85), int(fh * 0.50))
            eyes = face_crop.crop(eye_box)
            eyes = flood_fill_bg(eyes)
            eyes = alpha_threshold(eyes, 8)
            save_rgba(eyes, os.path.join(FACE, f"{spec_name}.png"))
            save_rgba(eyes, os.path.join(CLEAN, f"{spec_name}.png"))
            manifest[spec_name] = {
                "file": f"{spec_name}.png",
                "dimensions": list(eyes.size),
                "source": f"eye region of {src_key}",
                "alpha_coverage_pct": get_alpha_coverage(eyes),
            }
            print(f"  ✓ {spec_name}: {eyes.size} (from {src_key} eye region)")
        elif spec_name.startswith("eyes_"):
            box = EYE_BOXES[src_key]
            crop = sheet.crop(box)
            clean = flood_fill_bg(crop)
            clean = alpha_threshold(clean, 8)
            save_rgba(clean, os.path.join(FACE, f"{spec_name}.png"))
            save_rgba(clean, os.path.join(CLEAN, f"{spec_name}.png"))
            manifest[spec_name] = {
                "file": f"{spec_name}.png",
                "dimensions": list(clean.size),
                "alpha_coverage_pct": get_alpha_coverage(clean),
            }
            print(f"  ✓ {spec_name}: {clean.size}")
        elif spec_name.startswith("mouth_"):
            box = MOUTH_BOXES[src_key]
            crop = sheet.crop(box)
            clean = flood_fill_bg(crop)
            clean = alpha_threshold(clean, 8)
            save_rgba(clean, os.path.join(FACE, f"{spec_name}.png"))
            save_rgba(clean, os.path.join(CLEAN, f"{spec_name}.png"))
            manifest[spec_name] = {
                "file": f"{spec_name}.png",
                "dimensions": list(clean.size),
                "alpha_coverage_pct": get_alpha_coverage(clean),
            }
            print(f"  ✓ {spec_name}: {clean.size}")

    # Extract all 6 face portraits for reference
    for name, box in FACE_PORTRAIT_BOXES.items():
        crop = sheet.crop(box)
        clean = flood_fill_bg(crop)
        clean = alpha_threshold(clean, 8)
        save_rgba(clean, os.path.join(FACE, f"{name}.png"))
        print(f"  ✓ extra face: {name}: {clean.size}")

    # Extract all mouth variants
    for name, box in MOUTH_BOXES.items():
        if name in ("mouth_smile",):
            continue
        crop = sheet.crop(box)
        clean = flood_fill_bg(crop)
        clean = alpha_threshold(clean, 8)
        save_rgba(clean, os.path.join(FACE, f"{name}.png"))
        print(f"  ✓ extra mouth: {name}: {clean.size}")

    # Extract eyebrow variants
    for name, box in EYEBROW_BOXES.items():
        crop = sheet.crop(box)
        clean = flood_fill_bg(crop)
        clean = alpha_threshold(clean, 8)
        save_rgba(clean, os.path.join(FACE, f"{name}.png"))
        print(f"  ✓ extra brow: {name}: {clean.size}")

    # Extract eye half-closed
    crop = sheet.crop(EYE_BOXES["eyes_half"])
    clean = flood_fill_bg(crop)
    clean = alpha_threshold(clean, 8)
    save_rgba(clean, os.path.join(FACE, "eyes_half_closed.png"))
    print(f"  ✓ extra eyes_half_closed: {clean.size}")

    return manifest


def step_repair_hidden_parts():
    print("\n>>> Step 4: Repair & Extend Hidden Joint Sockets")

    # arm_upper_occluded_fill — extend shoulder socket upward (use R arm as primary)
    for side in ("L", "R"):
        src = Image.open(os.path.join(SEPARATED, f"arm_{side}_upper.png"))
        rep = extend_edges(src, top=20, bottom=0)
        save_rgba(rep, os.path.join(REPAIRED, f"arm_{side}_upper_repaired.png"))
        save_rgba(rep, os.path.join(CLEAN, f"arm_{side}_upper_repaired.png"))
        print(f"  ✓ arm_{side}_upper_repaired: {rep.size}")

    # Use R arm as the canonical arm_upper_occluded_fill
    arm_r_rep = Image.open(os.path.join(REPAIRED, "arm_R_upper_repaired.png"))
    save_rgba(arm_r_rep, os.path.join(REPAIRED, "arm_upper_occluded_fill.png"))
    save_rgba(arm_r_rep, os.path.join(CLEAN, "arm_upper_occluded_fill.png"))
    print(f"  ✓ arm_upper_occluded_fill: {arm_r_rep.size}")

    # torso_behind_arms_fill — extend torso sides horizontally + top
    torso = Image.open(os.path.join(SEPARATED, "torso_shirt.png"))
    torso_wide = extend_edges(torso, top=10, bottom=5, left=15, right=15)
    save_rgba(torso_wide, os.path.join(REPAIRED, "torso_behind_arms_fill.png"))
    save_rgba(torso_wide, os.path.join(CLEAN, "torso_behind_arms_fill.png"))
    print(f"  ✓ torso_behind_arms_fill: {torso_wide.size}")

    # hair_under_hat_fill — extend hair upward to fill under hat brim
    hair = Image.open(os.path.join(SEPARATED, "front_hair.png"))
    hair_ext = extend_edges(hair, top=22, bottom=0, left=5, right=5)
    save_rgba(hair_ext, os.path.join(REPAIRED, "hair_under_hat_fill.png"))
    save_rgba(hair_ext, os.path.join(CLEAN, "hair_under_hat_fill.png"))
    print(f"  ✓ hair_under_hat_fill: {hair_ext.size}")

    # legs_under_skirt_fill — extend legs upward into hip area
    for side in ("L", "R"):
        leg = Image.open(os.path.join(SEPARATED, f"leg_{side}_upper.png"))
        leg_ext = extend_edges(leg, top=24, bottom=0)
        save_rgba(leg_ext, os.path.join(REPAIRED, f"leg_{side}_upper_repaired.png"))
        save_rgba(leg_ext, os.path.join(CLEAN, f"leg_{side}_upper_repaired.png"))
        print(f"  ✓ leg_{side}_upper_repaired: {leg_ext.size}")

    # Use L leg as canonical legs_under_skirt_fill
    leg_l_ext = Image.open(os.path.join(REPAIRED, "leg_L_upper_repaired.png"))
    save_rgba(leg_l_ext, os.path.join(REPAIRED, "legs_under_skirt_fill.png"))
    save_rgba(leg_l_ext, os.path.join(CLEAN, "legs_under_skirt_fill.png"))
    print(f"  ✓ legs_under_skirt_fill: {leg_l_ext.size}")

    return {}


def step_build_manifest(body_manifest, tool_manifest, face_manifest):
    print("\n>>> Step 5: Build manifest.json + joint_coordinates.json + rig_layer_diagram.png")

    joint_metadata = {
        "character_name": "Lily",
        "source_sheets": {
            "body": "lily_game_ready_sheet.jpg",
            "faces_tools": "expressions_props_sheet.jpg",
        },
        "reference_canvas": {"width": 320, "height": 320, "ground_baseline_y": 310},
        "display_scale": 0.28,
        "bones_hierarchy": [
            {"name": "root", "parent": None, "pivot_offset": [0, 0],
             "description": "Ground contact position between feet"},
            {"name": "pelvis", "parent": "root", "pivot_offset": [0, -28],
             "layer": "pelvis.png", "z_index": 0},
            {"name": "spine", "parent": "pelvis", "pivot_offset": [0, -8],
             "z_index": 1},
            {"name": "torso", "parent": "spine", "pivot_offset": [0, -6],
             "layer": "torso_shirt.png", "z_index": 2},
            {"name": "neck", "parent": "torso", "pivot_offset": [0, -18],
             "z_index": 3},
            {"name": "head", "parent": "neck", "pivot_offset": [0, -10],
             "layer": "head_base.png", "front_hair": "front_hair.png",
             "hat": "straw_hat.png", "z_index": 4},
            {"name": "braid_base", "parent": "head", "pivot_offset": [-8, 6],
             "layer": "braid_upper.png", "z_index": -1},
            {"name": "braid_tip", "parent": "braid_base", "pivot_offset": [4, 18],
             "layer": "braid_tip.png", "z_index": -1},
            {"name": "leg_L", "parent": "pelvis", "pivot_offset": [-7, 0],
             "layer": "leg_L_upper.png", "z_index": -2},
            {"name": "foot_L", "parent": "leg_L", "pivot_offset": [0, 16],
             "layer": "boot_L.png", "z_index": -2},
            {"name": "leg_R", "parent": "pelvis", "pivot_offset": [7, 0],
             "layer": "leg_R_upper.png", "z_index": 0},
            {"name": "foot_R", "parent": "leg_R", "pivot_offset": [0, 16],
             "layer": "boot_R.png", "z_index": 0},
            {"name": "skirt", "parent": "pelvis", "pivot_offset": [0, -4],
             "layer": "skirt_front.png", "z_index": 1},
            {"name": "arm_L_upper", "parent": "torso", "pivot_offset": [-14, -14],
             "layer": "arm_L_upper.png", "z_index": -3},
            {"name": "arm_L_lower", "parent": "arm_L_upper", "pivot_offset": [0, 14],
             "layer": "arm_L_lower.png", "hand": "hand_L.png", "z_index": -3},
            {"name": "arm_R_upper", "parent": "torso", "pivot_offset": [14, -14],
             "layer": "arm_R_upper.png", "z_index": 5},
            {"name": "arm_R_lower", "parent": "arm_R_upper", "pivot_offset": [0, 14],
             "layer": "arm_R_lower.png", "hand": "hand_R_open.png", "z_index": 5},
            {"name": "HandSocket", "parent": "arm_R_lower", "pivot_offset": [14, 18],
             "description": "Dynamic tool attachment socket",
             "z_index": 6},
        ],
        "repaired_fills": [
            "arm_upper_occluded_fill.png",
            "torso_behind_arms_fill.png",
            "hair_under_hat_fill.png",
            "legs_under_skirt_fill.png",
        ],
        "layers_merged_from_spec": {
            "torso_shirt": "torso on game-ready sheet",
            "overalls_bib": "apron_front on game-ready sheet",
            "skirt_front": "skirt_outer on game-ready sheet",
            "skirt_back": "skirt_under (white petticoat) on game-ready sheet",
            "pelvis": "synthesized from torso_shirt lower 35%",
            "hand_R_grip": "mirrored from hand_L (provisional)",
        },
        "provisional_assets": [
            "shears.png (placeholder — no source on sheets, needs artist-provided asset)",
        ],
    }

    manifest_path = os.path.join(CLEAN, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(joint_metadata, f, indent=2, ensure_ascii=False)

    ref_path = os.path.join(RIG, "joint_coordinates.json")
    with open(ref_path, "w", encoding="utf-8") as f:
        json.dump(joint_metadata, f, indent=2, ensure_ascii=False)

    print(f"  ✓ manifest.json ({os.path.getsize(manifest_path)} bytes)")
    print(f"  ✓ joint_coordinates.json")


def step_rig_diagram():
    """Generate rig_layer_diagram.png — bone hierarchy with layer thumbnails."""
    W, H = 900, 700
    canvas = Image.new("RGBA", (W, H), (240, 235, 225, 255))
    d = ImageDraw.Draw(canvas)

    # Title
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
        font_bone = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
    except OSError:
        font_title = ImageFont.load_default()
        font_small = ImageFont.load_default()
        font_bone = ImageFont.load_default()

    d.text((20, 10), "Lily — Skeleton2D Rig Layer Diagram", fill=(80, 60, 40), font=font_title)
    d.text((20, 35), "Bloomhaven · Godot 4.7.1 · 2D Cutout", fill=(140, 120, 100), font=font_small)

    # Bone positions (approximate, from joint_coordinates.json)
    bones = [
        ("root",         450, 620),
        ("pelvis",       450, 564),
        ("spine",        450, 536),
        ("torso",        450, 500),
        ("neck",         450, 464),
        ("head",         450, 410),
        ("braid_base",   420, 400),
        ("braid_tip",    430, 370),
        ("leg_L",        430, 564),
        ("foot_L",       430, 532),
        ("leg_R",        470, 564),
        ("foot_R",       470, 532),
        ("skirt",        450, 555),
        ("arm_L_upper",  400, 500),
        ("arm_L_lower",  380, 470),
        ("arm_R_upper",  500, 500),
        ("arm_R_lower",  520, 470),
        ("HandSocket",   535, 452),
    ]

    # Draw connections
    connections = [
        ("root", "pelvis"), ("pelvis", "spine"), ("spine", "torso"),
        ("torso", "neck"), ("neck", "head"), ("head", "braid_base"),
        ("braid_base", "braid_tip"),
        ("pelvis", "leg_L"), ("leg_L", "foot_L"),
        ("pelvis", "leg_R"), ("leg_R", "foot_R"),
        ("pelvis", "skirt"),
        ("torso", "arm_L_upper"), ("arm_L_upper", "arm_L_lower"),
        ("torso", "arm_R_upper"), ("arm_R_upper", "arm_R_lower"),
        ("arm_R_lower", "HandSocket"),
    ]

    bone_pos = {name: (x, y) for name, x, y in bones}
    for a, b in connections:
        if a in bone_pos and b in bone_pos:
            x1, y1 = bone_pos[a]
            x2, y2 = bone_pos[b]
            d.line([(x1, y1), (x2, y2)], fill=(120, 100, 80, 180), width=2)

    # Draw bone nodes + labels
    for name, x, y in bones:
        r = 5
        d.ellipse([x - r, y - r, x + r, y + r], fill=(180, 140, 90), outline=(100, 70, 40))
        if x > 450:
            d.text((x + 10, y - 6), name, fill=(80, 60, 40), font=font_small)
        else:
            tw = d.textlength(name, font=font_small)
            d.text((x - 10 - tw, y - 6), name, fill=(80, 60, 40), font=font_small)

    # Legend: layer thumbnails along bottom
    d.text((20, H - 90), "Layers (Z-index →):", fill=(100, 80, 60), font=font_small)
    layers_for_legend = [
        "leg_L_upper", "leg_R_upper", "boot_L", "boot_R",
        "arm_L_upper", "arm_L_lower", "hand_L",
        "pelvis", "torso_shirt", "skirt_front",
        "arm_R_upper", "arm_R_lower", "hand_R_open",
        "head_base", "front_hair", "braid_upper", "braid_tip", "straw_hat",
    ]
    x_off = 20
    for name in layers_for_legend:
        layer_path = os.path.join(SEPARATED, f"{name}.png")
        if not os.path.exists(layer_path):
            layer_path = os.path.join(CLEAN, f"{name}.png")
        if os.path.exists(layer_path):
            thumb = Image.open(layer_path).convert("RGBA")
            thumb.thumbnail((40, 40))
            canvas.paste(thumb, (x_off, H - 75), thumb)
        d.text((x_off, H - 30), name[:10], fill=(120, 100, 80), font=font_small)
        x_off += 48

    save_rgba(canvas, os.path.join(RIG, "rig_layer_diagram.png"))
    print(f"  ✓ rig_layer_diagram.png ({W}x{H})")


def step_verify():
    print("\n>>> Step 6: Verification Report")
    print("=" * 60)

    # Check all spec-required files
    spec_separated = [
        "head_base", "front_hair", "braid_upper", "braid_tip", "straw_hat",
        "torso_shirt", "overalls_bib", "skirt_front", "skirt_back", "pelvis",
        "arm_L_upper", "arm_L_lower", "hand_L", "arm_R_upper", "arm_R_lower",
        "hand_R_open", "hand_R_grip", "leg_L_upper", "boot_L",
        "leg_R_upper", "boot_R",
    ]
    spec_repaired = [
        "arm_upper_occluded_fill",
        "torso_behind_arms_fill",
        "hair_under_hat_fill",
        "legs_under_skirt_fill",
    ]
    spec_tools = ["watering_can", "trowel", "shears", "flower_basket_empty",
                  "flower_basket_filled", "notebook"]
    spec_faces = ["eyes_open", "eyes_blink", "eyes_smile", "mouth_smile"]
    spec_rig = ["joint_coordinates.json", "rig_layer_diagram.png"]

    all_ok = True
    for name in spec_separated:
        path = os.path.join(SEPARATED, f"{name}.png")
        if not os.path.exists(path):
            print(f"  ✗ MISSING separated_layers/{name}.png")
            all_ok = False
        else:
            img = Image.open(path)
            ap = get_alpha_coverage(img)
            if ap < 1.0:
                print(f"  ⚠ LOW ALPHA {name}: {ap}%")
            # else: ok (silent)

    for name in spec_repaired:
        path = os.path.join(REPAIRED, f"{name}.png")
        if not os.path.exists(path):
            print(f"  ✗ MISSING repaired_hidden_parts/{name}.png")
            all_ok = False

    for name in spec_tools:
        path = os.path.join(TOOLS, f"{name}.png")
        if not os.path.exists(path):
            print(f"  ✗ MISSING tool_variants/{name}.png")
            all_ok = False

    for name in spec_faces:
        path = os.path.join(FACE, f"{name}.png")
        if not os.path.exists(path):
            print(f"  ✗ MISSING face_variants/{name}.png")
            all_ok = False

    for name in spec_rig:
        path = os.path.join(RIG, name)
        if not os.path.exists(path):
            print(f"  ✗ MISSING rig_reference/{name}")
            all_ok = False

    manifest_path = os.path.join(CLEAN, "manifest.json")
    if not os.path.exists(manifest_path):
        print(f"  ✗ MISSING clean_rgba_assets/manifest.json")
        all_ok = False
    else:
        try:
            with open(manifest_path) as f:
                json.load(f)
            print(f"  ✓ manifest.json valid")
        except json.JSONDecodeError as e:
            print(f"  ✗ manifest.json invalid: {e}")
            all_ok = False

    # Count files per dir
    for label, d in [("separated_layers", SEPARATED), ("repaired_hidden_parts", REPAIRED),
                     ("clean_rgba_assets", CLEAN), ("tool_variants", TOOLS),
                     ("face_variants", FACE), ("rig_reference", RIG)]:
        n = len([f for f in os.listdir(d) if not f.endswith(".import")])
        print(f"  {label}: {n} files")

    if all_ok:
        print("\n  🎉 GATE 0 VERIFICATION: ALL SPEC FILES PRESENT ✓")
    else:
        print("\n  ⚠ GATE 0 INCOMPLETE — see missing files above")

    return all_ok


# ─── Entry Point ──────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("GATE 0 — LILY ASSET PREPARATION PIPELINE v2")
    print("=" * 60)

    ensure_dirs()

    body_m = step_extract_body()
    tool_m = step_extract_tools()
    face_m = step_extract_faces()
    step_repair_hidden_parts()
    step_build_manifest(body_m, tool_m, face_m)
    step_rig_diagram()

    ok = step_verify()

    print("\n" + "=" * 60)
    if ok:
        print("GATE 0 COMPLETE — all outputs ready for Gate 1")
    else:
        print("GATE 0 PARTIAL — check warnings above")
    print("=" * 60)


if __name__ == "__main__":
    main()
