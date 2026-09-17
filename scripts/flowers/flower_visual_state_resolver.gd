class_name FlowerVisualStateResolver
extends RefCounted

## BloomHaven - Flower Visual State Resolver
## Pure deterministic state mapping: (stage, is_pruned, quality) -> visual_state_key.
## Completely decoupled from asset file paths, textures, and SceneTree rendering.

enum Stage {
	SEED = 0,
	SPROUT = 1,
	VEGETATIVE = 2,
	BLOOMING = 3
}

## Architectural Contract: Stage.SEED is intentionally and universally procedural across all flower species.
## It renders a contextual soil mound with organic soil crumbs, seed marker, and mystery shimmer.
## It does not require or load a sprite asset stage.
const STATE_SEED := "seed"
const STATE_SPROUT := "sprout"
const STATE_VEG_SINGLE := "vegetative_single"
const STATE_VEG_BRANCHING := "vegetative_branching"
const STATE_VEG_LATE_UNPRUNED := "vegetative_late_unpruned"
const STATE_BLOOM_STANDARD := "bloom_standard"
const STATE_BLOOM_HERO := "bloom_hero"


## Resolves the canonical visual state key for a given growth stage and state.
## Consumes canonical domain progression from GardenPlot without duplicating thresholds.
static func resolve_visual_state(
	stage: int,
	is_pruned: bool,
	quality: String = "standard",
	growth_progress: float = -1.0,
	is_late_unpruned: bool = false
) -> String:
	match stage:
		Stage.SEED:
			return STATE_SEED
		Stage.SPROUT:
			return STATE_SPROUT
		Stage.VEGETATIVE:
			if is_pruned:
				return STATE_VEG_SINGLE
			var late := is_late_unpruned
			if not late and growth_progress >= 0.0:
				late = (growth_progress > GardenPlot.PRUNE_WINDOW_END)
			return STATE_VEG_LATE_UNPRUNED if late else STATE_VEG_BRANCHING
		Stage.BLOOMING:
			if is_pruned or quality == "hero":
				return STATE_BLOOM_HERO
			return STATE_BLOOM_STANDARD
		_:
			return ""
