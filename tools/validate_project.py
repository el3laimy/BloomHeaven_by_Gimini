#!/usr/bin/env python3
import os
import json
import re

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

# 1. Validate flowers.json
print("\n[1] Checking data/flowers.json...")
flowers_fp = os.path.join(DATA_DIR, "flowers.json")
if not os.path.exists(flowers_fp):
    log_err("data/flowers.json does not exist!")
else:
    with open(flowers_fp, "r", encoding="utf-8") as f:
        fdata = json.load(f)
    flowers = fdata.get("flowers", {})
    log_ok(f"Loaded {len(flowers)} flowers: {list(flowers.keys())}")
    for fid, fdef in flowers.items():
        if "display_name" not in fdef:
            log_err(f"Flower {fid} missing display_name")
        if "base_growth_seconds" not in fdef:
            log_err(f"Flower {fid} missing base_growth_seconds")
        
        # check sprite paths
        if "master_sprite" in fdef:
            rel = fdef["master_sprite"].replace("res://", "")
            full = os.path.join(ROOT_DIR, rel)
            if not os.path.exists(full):
                log_err(f"Flower {fid} master_sprite missing on disk: {full}")
            else:
                log_ok(f"Found master sprite for {fid}: {rel}")
        
        if "branching_stages" in fdef:
            bstages = fdef["branching_stages"]
            for sname, spath in bstages.items():
                rel = spath.replace("res://", "")
                full = os.path.join(ROOT_DIR, rel)
                if not os.path.exists(full):
                    log_err(f"Flower {fid} branching stage '{sname}' sprite missing: {full}")
                else:
                    log_ok(f"Found branching sprite for {fid} ({sname}): {rel}")

# 2. Validate bouquets.json
print("\n[2] Checking data/bouquets.json...")
bouquets_fp = os.path.join(DATA_DIR, "bouquets.json")
with open(bouquets_fp, "r", encoding="utf-8") as f:
    bdata = json.load(f)
bouquets = bdata.get("bouquets", {})
log_ok(f"Loaded {len(bouquets)} bouquets: {list(bouquets.keys())}")

# 3. Validate perfumes.json
print("\n[3] Checking data/perfumes.json...")
perfumes_fp = os.path.join(DATA_DIR, "perfumes.json")
with open(perfumes_fp, "r", encoding="utf-8") as f:
    pdata = json.load(f)
perfumes = pdata.get("perfumes", {})
log_ok(f"Loaded {len(perfumes)} perfumes: {list(perfumes.keys())}")

# 4. Validate requests.json
print("\n[4] Checking data/requests.json...")
requests_fp = os.path.join(DATA_DIR, "requests.json")
with open(requests_fp, "r", encoding="utf-8") as f:
    rdata = json.load(f)
requests = rdata.get("requests", {})
log_ok(f"Loaded {len(requests)} customer requests: {list(requests.keys())}")

# 5. Validate upgrades.json
print("\n[5] Checking data/upgrades.json...")
upgrades_fp = os.path.join(DATA_DIR, "upgrades.json")
with open(upgrades_fp, "r", encoding="utf-8") as f:
    udata = json.load(f)
upgrades_list = udata.get("upgrades", [])
log_ok(f"Loaded {len(upgrades_list)} tool upgrades: {[u.get('id') for u in upgrades_list]}")

# 6. Check Core and UI Scenes (19 Scenes)
print("\n[6] Checking All Scenes...")
scenes_to_check = [
    "scenes/main.tscn",
    "scenes/character/lily.tscn",
    "scenes/ui/main_menu.tscn",
    "scenes/ui/pause_menu.tscn",
    "scenes/ui/settings_menu.tscn",
    "scenes/ui/tutorial_overlay.tscn",
    "scenes/ui/tool_dock.tscn",
    "scenes/ui/seed_bar.tscn",
    "scenes/ui/plot_card.tscn",
    "scenes/ui/hud_top_bar.tscn",
    "scenes/ui/hud/top_left_cluster.tscn",
    "scenes/ui/hud/side_order_rail.tscn",
    "scenes/ui/hud/lily_hub_popup.tscn",
    "scenes/ui/hud/inventory_drawer.tscn",
    "scenes/ui/modals/breeding_modal.tscn",
    "scenes/ui/modals/bouquet_modal.tscn",
    "scenes/ui/modals/requests_modal.tscn",
    "scenes/ui/modals/upgrades_modal.tscn",
    "scenes/ui/modals/journal_modal.tscn"
]
for sc in scenes_to_check:
    fp = os.path.join(ROOT_DIR, sc)
    if os.path.exists(fp):
        log_ok(f"Scene exists: {sc}")
    else:
        log_err(f"Scene missing: {sc}")

# 7. Check Core and Gameplay Scripts
print("\n[7] Checking Core, Genetics, Garden, Character & UI Scripts...")
scripts_to_check = [
    "scripts/main.gd",
    "scripts/core/save_manager.gd",
    "scripts/core/order_manager.gd",
    "scripts/core/upgrade_manager.gd",
    "scripts/core/audio_manager.gd",
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

# 8. Check Audio Assets
print("\n[8] Checking Audio SFX and Music Assets...")
audio_to_check = [
    "assets/audio/music/bgm_garden_loop.wav",
    "assets/audio/sfx/sfx_click.wav",
    "assets/audio/sfx/sfx_plant.wav",
    "assets/audio/sfx/sfx_water.wav",
    "assets/audio/sfx/sfx_prune.wav",
    "assets/audio/sfx/sfx_harvest.wav",
    "assets/audio/sfx/sfx_coin.wav",
    "assets/audio/sfx/sfx_upgrade.wav",
    "assets/audio/sfx/sfx_error.wav",
    "assets/audio/sfx/sfx_step.wav"
]
for a in audio_to_check:
    fp = os.path.join(ROOT_DIR, a)
    if os.path.exists(fp):
        log_ok(f"Audio asset exists: {a}")
    else:
        log_err(f"Audio asset missing: {a}")

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

print("\n==================================================")
if errors:
    print(f"❌ VALIDATION FAILED WITH {len(errors)} ERRORS.")
    exit(1)
else:
    print("🎉 ALL COMPREHENSIVE VALIDATION CHECKS PASSED (0 ERRORS)!")
    print("==================================================")
    exit(0)
