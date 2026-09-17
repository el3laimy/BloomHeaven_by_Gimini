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

const STATE_SEED := "seed"
const STATE_SPROUT := "sprout"
const STATE_VEG_SINGLE := "vegetative_single"
const STATE_VEG_BRANCHING := "vegetative_branching"
const STATE_BLOOM_STANDARD := "bloom_standard"
const STATE_BLOOM_HERO := "bloom_hero"


## Resolves the canonical visual state key for a given growth stage and state.
static func resolve_visual_state(stage: int, is_pruned: bool, quality: String = "standard") -> String:
	match stage:
		Stage.SEED:
			return STATE_SEED
		Stage.SPROUT:
			return STATE_SPROUT
		Stage.VEGETATIVE:
			return STATE_VEG_SINGLE if is_pruned else STATE_VEG_BRANCHING
		Stage.BLOOMING:
			if is_pruned or quality == "hero":
				return STATE_BLOOM_HERO
			return STATE_BLOOM_STANDARD
		_:
			return ""
