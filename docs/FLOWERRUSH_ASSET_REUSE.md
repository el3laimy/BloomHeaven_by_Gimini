# FlowerRush asset reuse in BloomHeaven by Gemini

## Transfer status (2026-10-13)

Verified in the GitHub branch: **130 / 131** pinned assets, all retaining the exact source Git blob SHA: 100 Flora-C flower PNGs, 7/8 garden PNGs, 15 HUD icons, and 8 tool sprites.

**One missing source image:** `assets/environment/integrated_garden_v1/garden_grass_owner_v1.png` (2,661,166 bytes, source blob `2e4e4c7a05b0ba814e0859e60acbdf476c851a40`). GitHub's contents interface exposes its SHA but no base64 body because this binary exceeds the small-file Contents API representation limit. It has **not** been copied, and should never be replaced with an empty or approximate image.

The documented local importer will copy this last file from the private source checkout in an opt-in run, validating bytes and Git SHA before writing. Do not mark the migration as fully finished until the 131/131 comparison passes. The target public repository and its branches expose copied artwork; review redistribution and release rights before merge.

Source: private el3laimy/FlowerRush at 7560d08460cfbf9fa84bfd58c55219898d3646f4
Destination: public el3laimy/BloomHeaven_by_Gimini. Candidate assets only; not cleared for commercial release.

## Selection

- 100 PNG flower images, covering 10 species × 10 stages/icons, from Flora-C cultivation runtime.
- 8 PNGs for the integrated garden environment.
- 8 PNG tools.
- 15 PNGs for the garden HUD.
- Total: 131 files pinned to Git blob SHA and size in tools/flowerrush_asset_inventory.json.

## Safety and source-of-truth

All imported images live under assets/reused/flowerrush, leaving the prototype's assets/flowers, assets/environment, assets/ui and Lily character untouched. This is a staged art library, not an automatic replacement of game art. No scenes, scripts, gameplay rules, saves, or catalog entries have been modified.

Source-only masters, quarantine assets, historical drafts, models, references, fonts and Reem (who is a different character from Lily) are excluded.

## Resume local import of any remaining image

Clone both projects next to one another with GitHub access to private FlowerRush, then run from the Gemini project folder:

    python3 tools/import_flowerrush_runtime.py --source ../FlowerRush
    python3 tools/import_flowerrush_runtime.py --source ../FlowerRush --apply
    python3 -m unittest discover -s tests/tools -p 'test_import_flowerrush_runtime.py' -v

The default is dry-run. The importer verifies all input bytes against the pinned source Git SHA-1 before copying a single file. Exact identical existing target images are skipped; collisions, absent sources or modified source bytes abort the batch without overwriting. The source directory is never edited. Godot regenerates per-file import metadata for the copied PNGs.

## Future usage with the target's FlowerAssetResolver

The Gemini prototype currently has 6 procedurally represented hybrids that have corresponding production-candidate sprites in this package: blushbell, velvet_dusk, twilight_bell, sunburst_daisy, crown_petal and meadow_mist.

Only after visual QA, review an explicit mapping from the Flora-C growth roles to the 6-stage visual_profile structure in data/flowers.json. Candidate mapping to inspect (not approved or activated): sprout=seedling, vegetative_branching=young, vegetative_single=buds, vegetative_late_unpruned=buds, bloom_standard=cluster, bloom_hero=single. Confirm image transparency, foot anchor, target height, and consistency on the phone. No sunflower image is supplied by FlowerRush and Lily's character art is intentionally unchanged.

## Publication and rights

Important: this GitHub repository is public, including its branches. Source art in FlowerRush is identified as development candidates, not release-cleared. Check author rights, provenance, redistribution scope and appropriate notices before promoting or publishing additional images. An asset copied into a project is not automatically licensed for commercial release.
