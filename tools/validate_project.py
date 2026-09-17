#!/usr/bin/env python3
import os
import json
import re
import sys

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(ROOT_DIR, "data")
ASSETS_DIR = os.path.join(ROOT_DIR, "assets")
SCRIPTS_DIR = os.path.join(ROOT_DIR, "scripts")
SCENES_DIR = os.path.join(ROOT_DIR, "scenes")

errors = []

def log_ok(msg):
    print(f"  ✓ {msg}")

def log_err(msg):
    print(f"  ❌ {msg}")
    errors.append(msg)

print("==================================================")
print("🌿 FINEST GARDEN — COMPREHENSIVE PROJECT VALIDATOR 🌿")
print("==================================================")

# 1. Validate flowers.json & Sprites
print("\n[1] Checking data/flowers.json & Asset Sprites...")
flowers_fp = os.path.join(DATA_DIR, "flowers.json")
flowers = {}
if not os.path.exists(flowers_fp):
    log_err("data/flowers.json does not exist!")
else:
    try:
        with open(flowers_fp, "r", encoding="utf-8") as f:
            fdata = json.load(f)
        flowers = fdata.get("flowers", {})
        log_ok(f"Loaded {len(flowers)} flowers: {list(flowers.keys())}")
    except Exception as e:
        log_err(f"Failed to parse flowers.json: {e}")

if flowers:
    VALID_STATUSES = {"cvp_base", "cvp_hybrid", "legacy", "alias"}
    status_counts = {"cvp_base": 0, "cvp_hybrid": 0, "legacy": 0, "alias": 0, "unclassified": 0}
    
    # Expected core sets
    EXPECTED_CVP_BASE = {"rose", "lavender", "tulip", "daisy"}
    EXPECTED_CVP_HYBRID = {"blushbell", "velvet_dusk", "twilight_bell", "sunburst_daisy", "crown_petal", "meadow_mist"}
    
    for fid, fdef in flowers.items():
        st = fdef.get("status")
        if st in VALID_STATUSES:
            status_counts[st] += 1
        else:
            status_counts["unclassified"] += 1
            log_err(f"Flower '{fid}' has invalid or missing status: '{st}'")
        
        if st == "alias":
            target = fdef.get("alias_of", "")
            if not target:
                log_err(f"Alias flower '{fid}' missing 'alias_of'")
            elif target == fid:
                log_err(f"Alias flower '{fid}' has self-referential cycle")
            elif target not in flowers:
                log_err(f"Alias flower '{fid}' points to nonexistent target '{target}'")
            elif flowers[target].get("status") == "alias":
                log_err(f"Alias flower '{fid}' points to chained alias '{target}'")
        else:
            if "display_name" not in fdef:
                log_err(f"Flower '{fid}' missing display_name")
            if "base_growth_seconds" not in fdef or fdef["base_growth_seconds"] <= 0:
                log_err(f"Flower '{fid}' missing or invalid base_growth_seconds")
            
            # Check master sprite for every non-alias flower
            if "master_sprite" in fdef:
                ms = fdef["master_sprite"]
                if not ms.startswith("res://"):
                    log_err(f"Flower '{fid}' master_sprite must start with 'res://': {ms}")
                if "ArtSource" in ms:
                    log_err(f"Flower '{fid}' master_sprite references ArtSource: {ms}")
                rel = ms.replace("res://", "")
                full = os.path.join(ROOT_DIR, rel)
                if not os.path.exists(full):
                    log_err(f"Flower '{fid}' master_sprite missing on disk: {full}")
            
            # Check visual_profile
            if "visual_profile" in fdef:
                vprof = fdef["visual_profile"]
                vmode = vprof.get("mode", "sprite")
                if vmode not in {"sprite", "procedural"}:
                    log_err(f"Flower '{fid}' visual_profile has invalid mode '{vmode}'")
                elif vmode == "sprite":
                    # Validate icon if present
                    if "icon" in vprof and isinstance(vprof["icon"], dict):
                        icon_sp = vprof["icon"].get("sprite", "")
                        if not icon_sp.startswith("res://"):
                            log_err(f"Flower '{fid}' icon sprite must start with 'res://': {icon_sp}")
                        elif "ArtSource" in icon_sp:
                            log_err(f"Flower '{fid}' icon sprite references ArtSource: {icon_sp}")
                        else:
                            icon_full = os.path.join(ROOT_DIR, icon_sp.replace("res://", ""))
                            if not os.path.exists(icon_full):
                                log_err(f"Flower '{fid}' icon sprite missing on disk: {icon_full}")
                    # Validate ground_anchor
                    if "ground_anchor" in vprof:
                        ga = vprof["ground_anchor"]
                        if not (isinstance(ga, list) and len(ga) == 2 and all(isinstance(x, (int, float)) for x in ga)):
                            log_err(f"Flower '{fid}' visual_profile ground_anchor must be a 2-element numeric array: {ga}")
                    # Validate ground_position_y
                    if "ground_position_y" in vprof:
                        gpy = vprof["ground_position_y"]
                        if not isinstance(gpy, (int, float)):
                            log_err(f"Flower '{fid}' visual_profile ground_position_y must be numeric: {gpy}")
                    # Validate sway_intensity
                    if "sway_intensity" in vprof:
                        si = vprof["sway_intensity"]
                        if not isinstance(si, (int, float)):
                            log_err(f"Flower '{fid}' visual_profile sway_intensity must be numeric: {si}")

                    if "stages" not in vprof or not isinstance(vprof["stages"], dict):
                        log_err(f"Flower '{fid}' visual_profile (sprite mode) missing 'stages' dict")
                    else:
                        vstages = vprof["stages"]
                        for sname, sdef in vstages.items():
                            if not isinstance(sdef, dict):
                                log_err(f"Flower '{fid}' stage '{sname}' is not a dict")
                                continue
                            if "sprite" not in sdef:
                                log_err(f"Flower '{fid}' stage '{sname}' missing 'sprite'")
                            else:
                                sp = sdef["sprite"]
                                if not sp.startswith("res://"):
                                    log_err(f"Flower '{fid}' stage '{sname}' sprite path must start with 'res://': {sp}")
                                if "ArtSource" in sp:
                                    log_err(f"Flower '{fid}' stage '{sname}' sprite references ArtSource: {sp}")
                                rel = sp.replace("res://", "")
                                full = os.path.join(ROOT_DIR, rel)
                                if not os.path.exists(full):
                                    log_err(f"Flower '{fid}' stage '{sname}' sprite missing: {full}")
                            if "target_height" not in sdef or not isinstance(sdef["target_height"], (int, float)) or sdef["target_height"] <= 0:
                                log_err(f"Flower '{fid}' stage '{sname}' missing or invalid target_height")
                            if "offset" in sdef:
                                off = sdef["offset"]
                                if not (isinstance(off, list) and len(off) == 2 and all(isinstance(x, (int, float)) for x in off)):
                                    log_err(f"Flower '{fid}' stage '{sname}' offset must be a 2-element numeric array: {off}")
                            if "ground_anchor" in sdef:
                                sga = sdef["ground_anchor"]
                                if not (isinstance(sga, list) and len(sga) == 2 and all(isinstance(x, (int, float)) for x in sga)):
                                    log_err(f"Flower '{fid}' stage '{sname}' ground_anchor must be a 2-element numeric array: {sga}")
                elif vmode == "procedural":
                    pstyle = vprof.get("procedural_style")
                    if pstyle is not None and pstyle not in {"rose", "lavender", "sunflower", "roselight", "golden_rose", "sunflare_spike"}:
                        log_err(f"Flower '{fid}' visual_profile has unknown procedural_style '{pstyle}'")

    for expected in EXPECTED_CVP_BASE:
        if expected not in flowers or flowers[expected].get("status") != "cvp_base":
            log_err(f"Expected CVP base flower '{expected}' missing or not classified as cvp_base")
        else:
            fdef = flowers[expected]
            if "visual_profile" not in fdef:
                log_err(f"CVP base flower '{expected}' missing visual_profile")
            else:
                vstages = fdef["visual_profile"].get("stages", {})
                for req_stage in ["sprout", "vegetative_single", "vegetative_branching", "vegetative_late_unpruned", "bloom_standard", "bloom_hero"]:
                    if req_stage not in vstages:
                        log_err(f"CVP base flower '{expected}' missing required visual stage '{req_stage}'")

    for expected in EXPECTED_CVP_HYBRID:
        if expected not in flowers or flowers[expected].get("status") != "cvp_hybrid":
            log_err(f"Expected CVP hybrid flower '{expected}' missing or not classified as cvp_hybrid")
        else:
            fdef = flowers[expected]
            if "visual_profile" not in fdef or fdef["visual_profile"].get("mode") != "procedural":
                log_err(f"CVP hybrid flower '{expected}' missing procedural visual_profile")

    if status_counts["unclassified"] > 0:
        log_err(f"Found {status_counts['unclassified']} unclassified flowers!")
    else:
        log_ok(f"Flower classifications valid: {status_counts} (Total: {len(flowers)})")

# 2. Validate bouquets.json
print("\n[2] Checking data/bouquets.json...")
bouquets_fp = os.path.join(DATA_DIR, "bouquets.json")
bouquets = {}
if not os.path.exists(bouquets_fp):
    log_err("data/bouquets.json does not exist!")
else:
    try:
        with open(bouquets_fp, "r", encoding="utf-8") as f:
            bdata = json.load(f)
        bouquets = bdata.get("bouquets", {})
        log_ok(f"Loaded {len(bouquets)} bouquets: {list(bouquets.keys())}")
        for bid, bdef in bouquets.items():
            if "display_name" not in bdef:
                log_err(f"Bouquet '{bid}' missing display_name")
            if "base_value" not in bdef or bdef["base_value"] <= 0:
                log_err(f"Bouquet '{bid}' missing or invalid base_value")
            ings = bdef.get("ingredients", {})
            if not ings:
                log_err(f"Bouquet '{bid}' has empty ingredients")
            for ing_id, qty in ings.items():
                if ing_id not in flowers:
                    log_err(f"Bouquet '{bid}' references unknown ingredient flower '{ing_id}'")
                elif qty <= 0:
                    log_err(f"Bouquet '{bid}' has non-positive quantity for ingredient '{ing_id}'")
    except Exception as e:
        log_err(f"Failed to parse bouquets.json: {e}")

# 3. Validate perfumes.json
print("\n[3] Checking data/perfumes.json...")
perfumes_fp = os.path.join(DATA_DIR, "perfumes.json")
perfumes = {}
if not os.path.exists(perfumes_fp):
    log_err("data/perfumes.json does not exist!")
else:
    try:
        with open(perfumes_fp, "r", encoding="utf-8") as f:
            pdata = json.load(f)
        perfumes = pdata.get("perfumes", {})
        log_ok(f"Loaded {len(perfumes)} perfumes: {list(perfumes.keys())}")
        for pid, pdef in perfumes.items():
            if "display_name" not in pdef:
                log_err(f"Perfume '{pid}' missing display_name")
            if "base_value" not in pdef or pdef["base_value"] <= 0:
                log_err(f"Perfume '{pid}' missing or invalid base_value")
            if "distillation_seconds" not in pdef or pdef["distillation_seconds"] <= 0:
                log_err(f"Perfume '{pid}' missing or invalid distillation_seconds")
            p_ings = pdef.get("ingredients", {})
            if not p_ings:
                log_err(f"Perfume '{pid}' has empty ingredients")
            for ing_id, qty in p_ings.items():
                if ing_id not in flowers:
                    log_err(f"Perfume '{pid}' references unknown ingredient flower '{ing_id}'")
                elif qty <= 0:
                    log_err(f"Perfume '{pid}' has non-positive quantity for ingredient '{ing_id}'")
    except Exception as e:
        log_err(f"Failed to parse perfumes.json: {e}")

# 4. Validate requests.json
print("\n[4] Checking data/requests.json...")
requests_fp = os.path.join(DATA_DIR, "requests.json")
requests = {}
if not os.path.exists(requests_fp):
    log_err("data/requests.json does not exist!")
else:
    try:
        with open(requests_fp, "r", encoding="utf-8") as f:
            rdata = json.load(f)
        requests = rdata.get("requests", {})
        log_ok(f"Loaded {len(requests)} customer requests: {list(requests.keys())}")
        for rid, rdef in requests.items():
            if "patience_max_seconds" not in rdef:
                log_err(f"Request '{rid}' missing canonical patience_max_seconds")
            elif rdef["patience_max_seconds"] <= 0:
                log_err(f"Request '{rid}' has non-positive patience_max_seconds: {rdef['patience_max_seconds']}")
            else:
                log_ok(f"Request '{rid}' canonical patience: {rdef['patience_max_seconds']}s")
            
            rtype = rdef.get("type", "")
            req_items = rdef.get("required_items", {})
            if not req_items:
                log_err(f"Request '{rid}' has empty required_items")
            
            for item_id, count in req_items.items():
                if count <= 0:
                    log_err(f"Request '{rid}' requires non-positive amount ({count}) for '{item_id}'")
                if rtype == "flowers":
                    if item_id not in flowers:
                        log_err(f"Request '{rid}' references unknown flower '{item_id}'")
                elif rtype == "bouquet":
                    if item_id not in bouquets:
                        log_err(f"Request '{rid}' references unknown bouquet '{item_id}'")
                elif rtype == "perfume":
                    if item_id not in perfumes:
                        log_err(f"Request '{rid}' references unknown perfume '{item_id}'")
                else:
                    log_err(f"Request '{rid}' has unknown request type '{rtype}'")
    except Exception as e:
        log_err(f"Failed to parse requests.json: {e}")

# 5. Validate upgrades.json
print("\n[5] Checking data/upgrades.json...")
upgrades_fp = os.path.join(DATA_DIR, "upgrades.json")
if not os.path.exists(upgrades_fp):
    log_err("data/upgrades.json does not exist!")
else:
    try:
        with open(upgrades_fp, "r", encoding="utf-8") as f:
            udata = json.load(f)
        upgrades_list = udata.get("upgrades", [])
        log_ok(f"Loaded {len(upgrades_list)} tool upgrades: {[u.get('id') for u in upgrades_list]}")
        for u in upgrades_list:
            uid = u.get("id", "")
            if not uid:
                log_err("Upgrade entry missing 'id'")
            if "name" not in u:
                log_err(f"Upgrade '{uid}' missing 'name'")
            cost = u.get("cost", 0)
            if cost <= 0:
                log_err(f"Upgrade '{uid}' has invalid or missing cost: {cost}")
    except Exception as e:
        log_err(f"Failed to parse upgrades.json: {e}")

# 6. Check Core and UI Scenes & Scan for Broken External Resources
print("\n[6] Checking All Scenes & External Resource Linkages...")
scenes_checked = 0
broken_scene_deps = 0
for root, _, files in os.walk(SCENES_DIR):
    for f in files:
        if f.endswith(".tscn"):
            scenes_checked += 1
            sc_path = os.path.join(root, f)
            rel_path = os.path.relpath(sc_path, ROOT_DIR)
            try:
                with open(sc_path, "r", encoding="utf-8") as fh:
                    txt = fh.read()
                for m in re.finditer(r'path=\"res://([^\"]+)\"', txt):
                    target_rel = m.group(1)
                    target_full = os.path.join(ROOT_DIR, target_rel)
                    if not os.path.exists(target_full):
                        log_err(f"Scene '{rel_path}' references missing resource: res://{target_rel}")
                        broken_scene_deps += 1
            except Exception as e:
                log_err(f"Failed to read scene '{rel_path}': {e}")

if broken_scene_deps == 0:
    log_ok(f"All {scenes_checked} scenes scanned: 0 broken external resources found.")

# 7. Check Core and Gameplay Scripts
print("\n[7] Checking Core, Genetics, Garden, Character & UI Scripts...")
scripts_to_check = [
    "scripts/main.gd",
    "scripts/core/save_manager.gd",
    "scripts/core/order_manager.gd",
    "scripts/core/upgrade_manager.gd",
    "scripts/core/audio_manager.gd",
    "scripts/domain/flower_quality.gd",
    "scripts/domain/flower_inventory.gd",
    "scripts/domain/seed_inventory.gd",
    "scripts/domain/breeding_service.gd",
    "scripts/genetics/genetics_engine.gd",
    "scripts/genetics/flower_genotype.gd",
    "scripts/genetics/flower_phenotype.gd",
    "scripts/genetics/flower_specimen.gd",
    "scripts/character/gardener_character.gd",
    "scripts/character/lily.gd",
    "scripts/garden/garden_grid.gd",
    "scripts/garden/garden_plot.gd",
    "scripts/garden/garden_environment.gd",
    "scripts/garden/garden_layout_manager.gd",
    "scripts/flowers/flower_data.gd",
    "scripts/flowers/flower_asset_resolver.gd",
    "scripts/flowers/flower_visual_state_resolver.gd",
    "scripts/flowers/flower_visual.gd",
    "scripts/flowers/modular_flower_visual.gd",
    "scripts/crafting/bouquet_data.gd",
    "scripts/crafting/perfume_data.gd",
    "scripts/requests/florist_request_data.gd",
    "scripts/ui/hud_controller.gd",
    "scripts/ui/main_menu.gd",
    "scripts/ui/pause_menu.gd",
    "scripts/ui/settings_menu.gd",
    "scripts/ui/tutorial_overlay.gd",
    "scripts/ui/hud/side_order_rail.gd",
    "scripts/ui/hud/lily_hub_popup.gd",
    "scripts/ui/hud/inventory_drawer.gd",
    "scripts/ui/hud/top_left_cluster.gd",
    "scripts/ui/modals/breeding_modal.gd",
    "scripts/ui/modals/bouquet_modal.gd",
    "scripts/ui/modals/requests_modal.gd",
    "scripts/ui/modals/upgrades_modal.gd",
    "scripts/ui/modals/journal_modal.gd"
]
for sc in scripts_to_check:
    fp = os.path.join(ROOT_DIR, sc)
    if os.path.exists(fp):
        log_ok(f"Script exists: {sc}")
    else:
        log_err(f"Script missing: {sc}")

# 8. Check Audio Assets & Godot Imports
print("\n[8] Checking Audio SFX & Music Assets (.wav + .import)...")
CANONICAL_SFX_IDS = ["click", "coin", "plant", "water", "prune", "harvest", "upgrade", "error", "step"]
for sfx_id in CANONICAL_SFX_IDS:
    rel_wav = f"assets/audio/sfx/sfx_{sfx_id}.wav"
    wav_fp = os.path.join(ROOT_DIR, rel_wav)
    import_fp = wav_fp + ".import"
    if not os.path.exists(wav_fp):
        log_err(f"SFX file missing: {rel_wav}")
    elif not os.path.exists(import_fp):
        log_err(f"SFX import definition missing: {rel_wav}.import")
    else:
        log_ok(f"Canonical SFX '{sfx_id}' verified with .import.")

music_wav = os.path.join(ROOT_DIR, "assets/audio/music/bgm_garden_loop.wav")
if not os.path.exists(music_wav):
    log_err("Music track missing: assets/audio/music/bgm_garden_loop.wav")
elif not os.path.exists(music_wav + ".import"):
    log_err("Music import definition missing: bgm_garden_loop.wav.import")
else:
    log_ok("Garden BGM track verified with .import.")

# 9. Check 25 Growth Stage Assets
print("\n[9] Checking 25 Growth Stage Assets across 5 Species...")
species_list = ["rose_crimson", "rose_cream", "lavender", "tulip", "daisy"]
stages_list = ["sprout", "veg_bush", "veg_single", "bloom_standard", "bloom_premium"]
for sp in species_list:
    for st in stages_list:
        p = os.path.join(ROOT_DIR, "assets", "flowers", "growth_stages", f"{sp}_{st}.png")
        if os.path.exists(p):
            log_ok(f"Growth stage sprite exists: {sp}_{st}.png")
        else:
            log_err(f"Missing growth stage sprite: {sp}_{st}.png")

# 10. Clean-Game Content Reachability Fixed-Point Closure Validator (SSoT)
print("\n[10] Checking Clean-Game Content Reachability (Fixed-Point Closure)...")
if flowers:
    reachable_flowers = set()
    for fid, fdef in flowers.items():
        if fdef.get("status") == "cvp_base":
            reachable_flowers.add(fid)
    
    # Fixed-point iteration for reachable hybrids
    changed = True
    iteration = 0
    while changed:
        changed = False
        iteration += 1
        for fid, fdef in flowers.items():
            if fdef.get("status") == "cvp_hybrid" and fid not in reachable_flowers:
                parents = fdef.get("parents", [])
                if parents and all(p in reachable_flowers for p in parents):
                    reachable_flowers.add(fid)
                    changed = True

    log_ok(f"Fixed-point progression closure converged in {iteration} rounds. Reachable flowers ({len(reachable_flowers)}): {sorted(list(reachable_flowers))}")

    # Validate active customer requests
    for rid, rdef in requests.items():
        rtype = rdef.get("type", "")
        req_items = rdef.get("required_items", {})
        if rtype == "flowers":
            for fid in req_items:
                if fid not in reachable_flowers:
                    log_err(f"Active request '{rid}' demands unreachable flower '{fid}' from clean new game!")
                else:
                    log_ok(f"Request '{rid}' flower '{fid}' is reachable.")
        elif rtype == "bouquet":
            for bid in req_items:
                if bid not in bouquets:
                    log_err(f"Active request '{rid}' demands nonexistent bouquet '{bid}'")
                    continue
                bdef = bouquets[bid]
                b_ings = bdef.get("ingredients", {})
                for ing_id in b_ings:
                    if ing_id not in reachable_flowers:
                        log_err(f"Active request '{rid}' bouquet '{bid}' requires unreachable ingredient '{ing_id}'!")
                    else:
                        log_ok(f"Request '{rid}' bouquet '{bid}' ingredient '{ing_id}' is reachable.")
        elif rtype == "perfume":
            for pid in req_items:
                if pid not in perfumes:
                    log_err(f"Active request '{rid}' demands nonexistent perfume '{pid}'")
                    continue
                pdef = perfumes[pid]
                p_ings = pdef.get("ingredients", {})
                for ing_id in p_ings:
                    if ing_id not in reachable_flowers:
                        log_err(f"Active request '{rid}' perfume '{pid}' requires unreachable ingredient '{ing_id}'!")
                    else:
                        log_ok(f"Request '{rid}' perfume '{pid}' ingredient '{ing_id}' is reachable.")

    # Validate solar_grandeur exclusion from active CVP
    if "solar_grandeur" in bouquets:
        sg = bouquets["solar_grandeur"]
        if sg.get("status") != "legacy":
            log_err("Bouquet 'solar_grandeur' must be explicitly classified as 'legacy' / post-CVP.")
        else:
            log_ok("Bouquet 'solar_grandeur' correctly isolated as 'legacy' post-CVP.")

# 11. Production Flower Pack Validation (Red Rose)
print("\n[11] Checking Production Flower Pack (Red Rose)...")
try:
    from PIL import Image
except ImportError:
    Image = None

ACTIVE_ROSE_SPRITES = [
    "assets/flowers/rose/shared/plant_rose_shared_young.png",
    "assets/flowers/rose/shared/plant_rose_shared_branching.png",
    "assets/flowers/rose/red/plant_rose_red_prime_bud.png",
    "assets/flowers/rose/red/plant_rose_red_cluster_buds.png",
    "assets/flowers/rose/red/plant_rose_red_cluster_bloom.png",
    "assets/flowers/rose/red/plant_rose_red_prime_bloom.png",
    "assets/flowers/rose/red/icon_rose_red.png"
]

RESERVED_REGROWTH_SPRITES = [
    "plant_rose_shared_prime_harvested.png",
    "plant_rose_shared_cluster_harvested.png",
    "plant_rose_shared_regrowth_branching.png"
]

# Check active production derivatives
for rel_path in ACTIVE_ROSE_SPRITES:
    full_path = os.path.join(ROOT_DIR, rel_path)
    import_path = full_path + ".import"
    if not os.path.exists(full_path):
        log_err(f"Active Red Rose sprite missing: {rel_path}")
    elif not os.path.exists(import_path):
        log_err(f"Active Red Rose sprite import definition missing: {rel_path}.import")
    else:
        if Image:
            try:
                with Image.open(full_path) as im:
                    if im.size != (512, 512):
                        log_err(f"Active Red Rose sprite '{rel_path}' has non-standard size {im.size} (expected 512x512)")
                    elif im.mode != "RGBA":
                        log_err(f"Active Red Rose sprite '{rel_path}' has non-RGBA mode '{im.mode}'")
                    else:
                        log_ok(f"Production sprite verified (512x512 RGBA + .import): {os.path.basename(rel_path)}")
            except Exception as e:
                log_err(f"Failed to inspect image '{rel_path}': {e}")
        else:
            log_ok(f"Production sprite verified on disk (+ .import): {os.path.basename(rel_path)}")

# Guard: Ensure reserved regrowth/harvested assets do NOT leak into runtime repository
for root, _, files in os.walk(os.path.join(ROOT_DIR, "assets")):
    for f in files:
        if f in RESERVED_REGROWTH_SPRITES:
            log_err(f"Reserved regrowth/harvested asset '{f}' leaked into runtime assets: {os.path.join(root, f)}")

# Guard: Ensure no unscaled 1254x1254 masters exist in Red Rose production pack directories
if Image:
    for sub in ["shared", "red"]:
        pack_dir = os.path.join(ROOT_DIR, "assets", "flowers", "rose", sub)
        if os.path.exists(pack_dir):
            for root, _, files in os.walk(pack_dir):
                for f in files:
                    if f.lower().endswith(".png"):
                        fp = os.path.join(root, f)
                        try:
                            with Image.open(fp) as im:
                                if im.size == (1254, 1254):
                                    log_err(f"Unscaled 1254x1254 master leaked into runtime assets: {os.path.relpath(fp, ROOT_DIR)}")
                                elif im.size != (512, 512):
                                    log_err(f"Production sprite '{os.path.relpath(fp, ROOT_DIR)}' has unexpected dimensions {im.size} (expected 512x512)")
                        except Exception:
                            pass

# Guard: Verify rose visual_profile configuration in data/flowers.json
if flowers and "rose" in flowers:
    rose_prof = flowers["rose"].get("visual_profile", {})
    rose_icon = rose_prof.get("icon", {}).get("sprite", "")
    if rose_icon != "res://assets/flowers/rose/red/icon_rose_red.png":
        log_err(f"Rose visual_profile icon sprite mismatch: '{rose_icon}' (expected res://assets/flowers/rose/red/icon_rose_red.png)")
    else:
        log_ok("Rose visual_profile icon correctly wired to icon_rose_red.png")

    rose_stages = rose_prof.get("stages", {})
    expected_stage_sprites = {
        "sprout": "res://assets/flowers/rose/shared/plant_rose_shared_young.png",
        "vegetative_branching": "res://assets/flowers/rose/shared/plant_rose_shared_branching.png",
        "vegetative_single": "res://assets/flowers/rose/red/plant_rose_red_prime_bud.png",
        "vegetative_late_unpruned": "res://assets/flowers/rose/red/plant_rose_red_cluster_buds.png",
        "bloom_standard": "res://assets/flowers/rose/red/plant_rose_red_cluster_bloom.png",
        "bloom_hero": "res://assets/flowers/rose/red/plant_rose_red_prime_bloom.png"
    }
    for st_name, exp_sp in expected_stage_sprites.items():
        act_sp = rose_stages.get(st_name, {}).get("sprite", "")
        if act_sp != exp_sp:
            log_err(f"Rose stage '{st_name}' sprite mismatch: got '{act_sp}', expected '{exp_sp}'")
        else:
            log_ok(f"Rose stage '{st_name}' correctly wired to {os.path.basename(act_sp)}")


print("\n==================================================")
if errors:
    print(f"❌ VALIDATION FAILED WITH {len(errors)} ERRORS.")
    sys.exit(1)
else:
    print("🎉 ALL COMPREHENSIVE VALIDATION CHECKS PASSED (0 ERRORS)!")
    print("==================================================")
    sys.exit(0)
