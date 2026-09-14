class_name FlowerQuality
extends RefCounted

## Domain definition for Flower Quality tiers, pricing multipliers, and validation.

enum Tier {
	NORMAL = 1,
	FINE = 2,
	PERFECT = 3,
	HERO = 4
}

const MULTIPLIERS: Dictionary = {
	Tier.NORMAL: 1.00,
	Tier.FINE: 1.25,
	Tier.PERFECT: 1.50,
	Tier.HERO: 2.50
}

const TIER_NAMES: Dictionary = {
	Tier.NORMAL: "Normal",
	Tier.FINE: "Fine",
	Tier.PERFECT: "Perfect",
	Tier.HERO: "Hero"
}

const TIER_BADGES: Dictionary = {
	Tier.NORMAL: "★",
	Tier.FINE: "★★",
	Tier.PERFECT: "★★★",
	Tier.HERO: "★★★★"
}


static func is_valid(tier: int) -> bool:
	return MULTIPLIERS.has(tier)


static func get_multiplier(tier: int) -> float:
	return float(MULTIPLIERS.get(tier, 1.0))


static func get_tier_name(tier: int) -> String:
	return str(TIER_NAMES.get(tier, "Normal"))


static func get_tier_badge(tier: int) -> String:
	return str(TIER_BADGES.get(tier, "★"))
