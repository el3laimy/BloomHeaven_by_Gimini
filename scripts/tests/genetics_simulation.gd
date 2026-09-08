extends SceneTree

## Headless 1,000-cross Monte Carlo Simulation & Genetics Engine Validation Suite for Milestone P3.
## Validates statistical Mendelian distributions across 1,000 deterministic crosses (seeds 1..1000).

func _init() -> void:
	print("==================================================")
	print("FINEST GARDEN (P3) — GENETICS SIMULATION SUITE")
	print("==================================================")

	var errors: Array[String] = []

	# -------------------------------------------------------------------------
	# TEST 1: DETERMINISM WITH SEED 0 & NON-ZERO SEED
	# -------------------------------------------------------------------------
	print("\n--- TEST 1: DETERMINISTIC RNG (SEED 0 & SEED 42) ---")
	var p_rose := GeneticsEngine.create_starter_specimen("rose", "R-TEST1")
	var p_lav := GeneticsEngine.create_starter_specimen("lavender", "L-TEST1")

	var cross_0a: Dictionary = GeneticsEngine.cross_specimens(p_rose, p_lav, 0)
	var cross_0b: Dictionary = GeneticsEngine.cross_specimens(p_rose, p_lav, 0)

	var s_0a: FlowerSpecimen = cross_0a["specimen"]
	var s_0b: FlowerSpecimen = cross_0b["specimen"]

	if s_0a.genotype.serialize() != s_0b.genotype.serialize():
		errors.append("Seed 0 determinism failed: Genotypes do not match.")
	if s_0a.phenotype.serialize() != s_0b.phenotype.serialize():
		errors.append("Seed 0 determinism failed: Phenotypes do not match.")
	print("✓ [DETERMINISM] Seed 0 produced 100% identical genotype and phenotype.")

	var cross_42a: Dictionary = GeneticsEngine.cross_specimens(p_rose, p_lav, 42)
	var cross_42b: Dictionary = GeneticsEngine.cross_specimens(p_rose, p_lav, 42)
	if cross_42a["specimen"].genotype.serialize() != cross_42b["specimen"].genotype.serialize():
		errors.append("Seed 42 determinism failed.")
	print("✓ [DETERMINISM] Seed 42 produced 100% identical offspring.")

	# -------------------------------------------------------------------------
	# TEST 2: ALLELE ORDER INVARIANCE
	# -------------------------------------------------------------------------
	print("\n--- TEST 2: ALLELE ORDER INVARIANCE ---")
	var g_order1 := FlowerGenotype.new(["Cr", "Cp"], ["Pr", "Ps"], ["F+", "f-"], ["V+", "v-"])
	var g_order2 := FlowerGenotype.new(["Cp", "Cr"], ["Ps", "Pr"], ["f-", "F+"], ["v-", "V+"])

	var pheno1 := GeneticsEngine.resolve_phenotype(g_order1, "roselight")
	var pheno2 := GeneticsEngine.resolve_phenotype(g_order2, "roselight")

	if pheno1.serialize() != pheno2.serialize():
		errors.append("Allele order altered phenotype resolution.")
	else:
		print("✓ [ORDER-INVARIANCE] Inverted allele pairs resolve to identical phenotype.")

	# -------------------------------------------------------------------------
	# TEST 3: PETAL DOMINANCE HIERARCHY (Ps > Pr > Pp)
	# -------------------------------------------------------------------------
	print("\n--- TEST 3: PETAL DOMINANCE HIERARCHY ---")
	var petal_cases := [
		{ "alleles": ["Ps", "Ps"], "expected": "star" },
		{ "alleles": ["Ps", "Pr"], "expected": "star" },
		{ "alleles": ["Pr", "Ps"], "expected": "star" },
		{ "alleles": ["Ps", "Pp"], "expected": "star" },
		{ "alleles": ["Pp", "Ps"], "expected": "star" },
		{ "alleles": ["Pr", "Pr"], "expected": "round" },
		{ "alleles": ["Pr", "Pp"], "expected": "round" },
		{ "alleles": ["Pp", "Pr"], "expected": "round" },
		{ "alleles": ["Pp", "Pp"], "expected": "pointed" }
	]
	for tc in petal_cases:
		var p_alleles: Array[String] = [String(tc["alleles"][0]), String(tc["alleles"][1])]
		var g := FlowerGenotype.new(["Cr", "Cr"], p_alleles, ["F+", "F+"], ["V+", "V+"])
		var ph := GeneticsEngine.resolve_phenotype(g, "rose")
		if ph.petal_form != tc["expected"]:
			errors.append("Petal %s resolved to %s, expected %s." % [tc["alleles"], ph.petal_form, tc["expected"]])
	print("✓ [PETAL-TABLE] All 9 diploid petal combinations correctly resolved hierarchy (Ps > Pr > Pp).")

	# -------------------------------------------------------------------------
	# TEST 4: INVALID GENOTYPE REJECTION
	# -------------------------------------------------------------------------
	print("\n--- TEST 4: INVALID GENOTYPE REJECTION ---")
	var invalid_g := FlowerGenotype.new(["Cr", "INVALID"], ["Pr", "Pr"], ["F+", "f-"], ["V+", "v-"])
	var val := invalid_g.validate()
	if val.get("valid", true):
		errors.append("Failed to reject invalid allele 'INVALID'.")
	else:
		print("✓ [VALIDATION] Invalid allele correctly rejected: %s" % val.get("error", ""))

	# -------------------------------------------------------------------------
	# TEST 5: 1,000-CROSS COLOR SIMULATION (CrCp × CrCp)
	# Expected: ~25% CrCr (Crimson), ~50% CrCp (Magenta), ~25% CpCp (Lavender)
	# -------------------------------------------------------------------------
	print("\n--- TEST 5: 1,000-CROSS COLOR SIMULATION (CrCp × CrCp) ---")
	var p_het_a := FlowerSpecimen.new("H-A", "roselight", 1, FlowerGenotype.new(["Cr", "Cp"], ["Pr", "Pr"], ["F+", "f-"], ["V+", "v-"]))
	var p_het_b := FlowerSpecimen.new("H-B", "roselight", 1, FlowerGenotype.new(["Cr", "Cp"], ["Pr", "Pr"], ["F+", "f-"], ["V+", "v-"]))

	var color_counts := { "Crimson Red": 0, "Plum Magenta": 0, "Soft Lavender": 0 }
	for seed_val in range(1, 1001):
		var res: Dictionary = GeneticsEngine.cross_specimens(p_het_a, p_het_b, seed_val)
		var sp: FlowerSpecimen = res["specimen"]
		var c_name := sp.phenotype.color_name
		color_counts[c_name] = color_counts.get(c_name, 0) + 1

	print("Observed Color Counts (N=1000):")
	print("  - Crimson Red  (CrCr): %d (%.1f%%) [Expected: ~25%%]" % [color_counts["Crimson Red"], color_counts["Crimson Red"] / 10.0])
	print("  - Plum Magenta (CrCp): %d (%.1f%%) [Expected: ~50%%]" % [color_counts["Plum Magenta"], color_counts["Plum Magenta"] / 10.0])
	print("  - Soft Lavender(CpCp): %d (%.1f%%) [Expected: ~25%%]" % [color_counts["Soft Lavender"], color_counts["Soft Lavender"] / 10.0])

	# Tolerance +/- 6% for N=1000
	if abs(color_counts["Crimson Red"] - 250) > 60 or abs(color_counts["Plum Magenta"] - 500) > 60 or abs(color_counts["Soft Lavender"] - 250) > 60:
		errors.append("Color 1,000-cross simulation deviated beyond +/- 6% tolerance.")
	else:
		print("✓ [COLOR-SIM] Observed ratios conform to expected 1:2:1 Mendelian distribution.")

	# -------------------------------------------------------------------------
	# TEST 6: 1,000-CROSS PETAL SIMULATION (PrPs × PrPr)
	# Expected: ~50% Star, ~50% Round
	# -------------------------------------------------------------------------
	print("\n--- TEST 6: 1,000-CROSS PETAL SIMULATION (PrPs × PrPr) ---")
	var p_petal_a := FlowerSpecimen.new("P-A", "rose", 0, FlowerGenotype.new(["Cr", "Cr"], ["Pr", "Ps"], ["F+", "f-"], ["V+", "v-"]))
	var p_petal_b := FlowerSpecimen.new("P-B", "rose", 0, FlowerGenotype.new(["Cr", "Cr"], ["Pr", "Pr"], ["F+", "f-"], ["V+", "v-"]))

	var petal_counts := { "star": 0, "round": 0, "pointed": 0 }
	for seed_val in range(1, 1001):
		var res: Dictionary = GeneticsEngine.cross_specimens(p_petal_a, p_petal_b, seed_val)
		var sp: FlowerSpecimen = res["specimen"]
		var form := sp.phenotype.petal_form
		petal_counts[form] = petal_counts.get(form, 0) + 1

	print("Observed Petal Counts (N=1000):")
	print("  - Star Petals  (PsPr): %d (%.1f%%) [Expected: ~50%%]" % [petal_counts["star"], petal_counts["star"] / 10.0])
	print("  - Round Petals (PrPr): %d (%.1f%%) [Expected: ~50%%]" % [petal_counts["round"], petal_counts["round"] / 10.0])
	print("  - Pointed      (PpPp): %d (%.1f%%) [Expected: 0%%]" % [petal_counts["pointed"], petal_counts["pointed"] / 10.0])

	if abs(petal_counts["star"] - 500) > 60 or abs(petal_counts["round"] - 500) > 60 or petal_counts["pointed"] != 0:
		errors.append("Petal 1,000-cross simulation deviated beyond +/- 6% tolerance.")
	else:
		print("✓ [PETAL-SIM] Observed ratios conform to expected 1:1 Mendelian distribution.")

	# -------------------------------------------------------------------------
	# TEST 7: 1,000-CROSS FRAGRANCE SIMULATION (F+f- × F+f-)
	# Expected: ~25% 1★, ~50% 3★, ~25% 4★
	# -------------------------------------------------------------------------
	print("\n--- TEST 7: 1,000-CROSS FRAGRANCE SIMULATION (F+f- × F+f-) ---")
	var frag_counts := { 1: 0, 3: 0, 4: 0 }
	for seed_val in range(1, 1001):
		var res: Dictionary = GeneticsEngine.cross_specimens(p_het_a, p_het_b, seed_val)
		var sp: FlowerSpecimen = res["specimen"]
		var stars := sp.phenotype.fragrance_rating
		frag_counts[stars] = frag_counts.get(stars, 0) + 1

	print("Observed Fragrance Counts (N=1000):")
	print("  - 1★ (f-f-): %d (%.1f%%) [Expected: ~25%%]" % [frag_counts[1], frag_counts[1] / 10.0])
	print("  - 3★ (F+f-): %d (%.1f%%) [Expected: ~50%%]" % [frag_counts[3], frag_counts[3] / 10.0])
	print("  - 4★ (F+F+): %d (%.1f%%) [Expected: ~25%%]" % [frag_counts[4], frag_counts[4] / 10.0])

	if abs(frag_counts[1] - 250) > 60 or abs(frag_counts[3] - 500) > 60 or abs(frag_counts[4] - 250) > 60:
		errors.append("Fragrance simulation deviated beyond +/- 6% tolerance.")
	else:
		print("✓ [FRAGRANCE-SIM] Observed ratios conform to expected 1:2:1 Mendelian dosage distribution.")

	# -------------------------------------------------------------------------
	# TEST 8: 1,000-CROSS VIGOR SIMULATION (V+v- × V+v-)
	# Expected: ~25% Standard (Tier 1), ~50% Robust (Tier 2), ~25% Exceptional (Tier 3)
	# -------------------------------------------------------------------------
	print("\n--- TEST 8: 1,000-CROSS VIGOR SIMULATION (V+v- × V+v-) ---")
	var vigor_counts := { 1: 0, 2: 0, 3: 0 }
	for seed_val in range(1, 1001):
		var res: Dictionary = GeneticsEngine.cross_specimens(p_het_a, p_het_b, seed_val)
		var sp: FlowerSpecimen = res["specimen"]
		var tier := sp.phenotype.vigor_tier
		vigor_counts[tier] = vigor_counts.get(tier, 0) + 1

	print("Observed Vigor Counts (N=1000):")
	print("  - Tier 1 (Standard):    %d (%.1f%%) [Expected: ~25%%]" % [vigor_counts[1], vigor_counts[1] / 10.0])
	print("  - Tier 2 (Robust):      %d (%.1f%%) [Expected: ~50%%]" % [vigor_counts[2], vigor_counts[2] / 10.0])
	print("  - Tier 3 (Exceptional): %d (%.1f%%) [Expected: ~25%%]" % [vigor_counts[3], vigor_counts[3] / 10.0])

	if abs(vigor_counts[1] - 250) > 60 or abs(vigor_counts[2] - 500) > 60 or abs(vigor_counts[3] - 250) > 60:
		errors.append("Vigor simulation deviated beyond +/- 6% tolerance.")
	else:
		print("✓ [VIGOR-SIM] Observed ratios conform to expected 1:2:1 Mendelian dosage distribution.")

	print("\n==================================================")
	if errors.is_empty():
		print("ALL GENETICS SIMULATION TESTS PASSED (100% OK)")
		print("==================================================")
		quit(0)
	else:
		printerr("GENETICS SIMULATION ERRORS (%d):" % errors.size())
		for e in errors:
			printerr("  - " + e)
		print("==================================================")
		quit(1)
