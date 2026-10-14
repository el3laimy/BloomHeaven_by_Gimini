# FlowerRush asset reuse in BloomHeaven by Gemini

## Transfer status (2026-10-14)

Verified in this branch: **131 / 131** pinned assets, all retaining the exact source Git blob SHA: 100 Flora-C flower PNGs, 8 garden PNGs, 15 HUD icons, and 8 tool sprites.

The final garden image, `assets/environment/integrated_garden_v1/garden_grass_owner_v1.png` (2,661,166 bytes, source blob `2e4e4c7a05b0ba814e0859e60acbdf476c851a40`), was copied directly from the pinned FlowerRush source commit and verified before staging. The separately uploaded preview has different encoded bytes and was not substituted for the pinned original.

This completes the byte-verified image transfer. Technical and visual approval of the art in Godot and Android remains a separate step. The destination is public. The owner has explicitly authorized use of these newly created, wholly owner-owned image assets across the two projects.

Source: private el3laimy/FlowerRush at 7560d08460cfbf9fa84bfd58c55219898d3646f4
Destination: public el3laimy/BloomHeaven_by_Gimini. These are owner-created artwork assets under visual/technical review, not awaiting a third-party art license.

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

## Asset ownership declaration (product owner, 2026-10-13)

The product owner explicitly states that **all selected art assets are 100% owned by the product owner, newly created for these projects, and do not reuse any earlier third-party or external artwork**. The owner has requested copying these original assets from FlowerRush into BloomHeaven by Gemini for use in the game. This is a recorded owner statement; it is not an independent legal provenance audit.

Accordingly, **there is no third-party artwork licensing review gate for the 131 PNGs in this transfer manifest**, on the basis of the owner's declaration. Do not infer the same statement about unrelated files (for example, third-party fonts), which are excluded from this transfer. The destination repository is public, including this branch; the product owner has been made aware of that visibility.

The outstanding acceptance work is **technical/visual**, not an asserted ownership blocker: import and test the assets in Godot, check mobile quality and performance, and wire the selected art into the game's existing flower resolver only after visual review. No gameplay code has been modified by this transfer.
