class_name FlowerAssetResolver
extends RefCounted

## BloomHaven - Flower Asset Resolver (Single Source of Truth)
## Sole responsibility: flower_id -> canonical asset definition -> cached Texture2D.
## Never falls back to Rose or any gameplay flower upon missing assets or invalid IDs.

static var _texture_cache: Dictionary = {}
static var _missing_texture: ImageTexture = null


## Generates an unmistakable, neutral missing-texture placeholder (magenta/black checkerboard)
static func get_missing_texture() -> ImageTexture:
	if _missing_texture != null:
		return _missing_texture

	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var is_magenta: bool = ((x / 8) + (y / 8)) % 2 == 0
			img.set_pixel(x, y, Color(1.0, 0.0, 1.0, 1.0) if is_magenta else Color(0.12, 0.12, 0.12, 1.0))

	_missing_texture = ImageTexture.create_from_image(img)
	return _missing_texture


## Resolves and caches canonical flower texture from data/flowers.json
static func resolve_flower_texture(flower_id: String) -> Texture2D:
	var canon_id := FlowerData.get_canonical_id(flower_id)
	if canon_id.is_empty():
		push_warning("FlowerAssetResolver: Unknown or invalid flower ID '%s'. Returning missing placeholder." % flower_id)
		return get_missing_texture()

	# Cache hit by canonical ID (aliases automatically share the canonical texture instance)
	if _texture_cache.has(canon_id):
		return _texture_cache[canon_id]

	var f_data := FlowerData.get_flower(canon_id)
	var icon_path: String = f_data.get("visual_profile", {}).get("icon", {}).get("sprite", "")
	var sprite_path: String = icon_path if (not icon_path.is_empty() and ResourceLoader.exists(icon_path)) else f_data.get("master_sprite", "")

	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		push_warning("FlowerAssetResolver: Missing asset for '%s' at '%s'. Returning missing placeholder." % [canon_id, sprite_path])
		return get_missing_texture()

	var tex := load(sprite_path) as Texture2D
	if tex == null:
		push_warning("FlowerAssetResolver: Failed to load texture at '%s' for flower '%s'." % [sprite_path, canon_id])
		return get_missing_texture()

	_texture_cache[canon_id] = tex
	return tex


## Resolves the canonical UI icon for a flower species.
## Returns the dedicated icon texture from visual_profile.icon if defined, else falls back to resolve_flower_texture.
static func resolve_flower_icon(flower_id: String) -> Texture2D:
	var canon_id := FlowerData.get_canonical_id(flower_id)
	if canon_id.is_empty():
		return get_missing_texture()

	var icon_cache_key := "icon_" + canon_id
	if _texture_cache.has(icon_cache_key):
		return _texture_cache[icon_cache_key]

	var f_data := FlowerData.get_flower(canon_id)
	var icon_info: Dictionary = f_data.get("visual_profile", {}).get("icon", {})
	var icon_path: String = icon_info.get("sprite", "")

	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var tex := load(icon_path) as Texture2D
		if tex != null:
			_texture_cache[icon_cache_key] = tex
			return tex

	var fallback_tex := resolve_flower_texture(canon_id)
	_texture_cache[icon_cache_key] = fallback_tex
	return fallback_tex


## Returns true ONLY if the flower ID is valid and its visual_profile is explicitly configured as procedural.
static func is_procedural_flower(flower_id: String) -> bool:
	var canon_id := FlowerData.get_canonical_id(flower_id)
	if canon_id.is_empty():
		return false
	var f_data := FlowerData.get_flower(canon_id)
	if f_data.is_empty():
		return false
	var profile: Dictionary = f_data.get("visual_profile", {})
	return profile.get("mode", "") == "procedural"


## Resolves stage-specific visual assets and configuration from the flower's visual_profile.
## Returns Dictionary with { texture: Texture2D, target_height: float, offset: Vector2, ground_anchor: Vector2, ground_position_y: float, sway_intensity: float }
## or {} if procedural or missing. Never falls back to Rose or silent default flowers.
static func resolve_visual_stage_asset(flower_id: String, visual_state_key: String) -> Dictionary:
	if visual_state_key.is_empty():
		push_warning("FlowerAssetResolver: Empty visual_state_key requested for '%s'." % flower_id)
		return {}

	# Stage.SEED is by contract universally procedural across all flowers; returns {} cleanly without warning.
	if visual_state_key == FlowerVisualStateResolver.STATE_SEED:
		return {}

	var canon_id := FlowerData.get_canonical_id(flower_id)
	if canon_id.is_empty():
		push_warning("FlowerAssetResolver: Unknown flower ID '%s'. Resolution failed." % flower_id)
		return {}

	var f_data := FlowerData.get_flower(canon_id)
	if f_data.is_empty():
		push_warning("FlowerAssetResolver: No flower data found for '%s'. Resolution failed." % canon_id)
		return {}

	var profile: Dictionary = f_data.get("visual_profile", {})
	if profile.is_empty():
		push_warning("FlowerAssetResolver: Missing visual_profile for flower '%s'. Resolution failed." % canon_id)
		return {}

	var mode: String = profile.get("mode", "sprite")
	if mode == "procedural":
		# Explicit procedural mode: expected to return empty stage asset so procedural renderer draws it.
		return {}
	elif mode != "sprite":
		push_warning("FlowerAssetResolver: Invalid visual_profile mode '%s' for flower '%s'." % [mode, canon_id])
		return {}

	var stages: Dictionary = profile.get("stages", {})
	if not stages.has(visual_state_key):
		push_warning("FlowerAssetResolver: Stage '%s' not defined in visual_profile for flower '%s'." % [visual_state_key, canon_id])
		return {}

	var stage_info = stages[visual_state_key]
	if stage_info is not Dictionary:
		push_warning("FlowerAssetResolver: Stage '%s' definition for flower '%s' is not a dictionary." % [visual_state_key, canon_id])
		return {}

	var sprite_path: String = stage_info.get("sprite", "")
	if sprite_path.is_empty():
		push_warning("FlowerAssetResolver: Empty sprite path for flower '%s' stage '%s'." % [canon_id, visual_state_key])
		return {}

	if not ResourceLoader.exists(sprite_path):
		push_warning("FlowerAssetResolver: Sprite path '%s' missing on disk for flower '%s' stage '%s'." % [sprite_path, canon_id, visual_state_key])
		return {}

	var tex: Texture2D = null
	if _texture_cache.has(sprite_path):
		tex = _texture_cache[sprite_path]
	else:
		tex = load(sprite_path) as Texture2D
		if tex != null:
			_texture_cache[sprite_path] = tex

	if tex == null:
		push_warning("FlowerAssetResolver: Failed to load texture at '%s' for flower '%s' at stage '%s'." % [sprite_path, canon_id, visual_state_key])
		return {}

	var target_height: float = float(stage_info.get("target_height", 64.0))

	var offset_vec := Vector2.ZERO
	if stage_info.has("offset"):
		var raw_offset = stage_info["offset"]
		if raw_offset is Array and raw_offset.size() >= 2:
			offset_vec = Vector2(float(raw_offset[0]), float(raw_offset[1]))
		elif raw_offset is Vector2:
			offset_vec = raw_offset

	var ground_anchor_vec := Vector2(0.5, 1.0)
	var raw_anchor = stage_info.get("ground_anchor", profile.get("ground_anchor", [0.5, 1.0]))
	if raw_anchor is Array and raw_anchor.size() >= 2:
		ground_anchor_vec = Vector2(float(raw_anchor[0]), float(raw_anchor[1]))
	elif raw_anchor is Vector2:
		ground_anchor_vec = raw_anchor

	var ground_pos_y: float = float(stage_info.get("ground_position_y", profile.get("ground_position_y", 2.0)))
	var sway_intensity: float = float(stage_info.get("sway_intensity", profile.get("sway_intensity", 1.0)))

	return {
		"texture": tex,
		"target_height": target_height,
		"offset": offset_vec,
		"ground_anchor": ground_anchor_vec,
		"ground_position_y": ground_pos_y,
		"sway_intensity": sway_intensity
	}


## Clears runtime texture cache (useful during testing/reloads)
static func clear_cache() -> void:
	_texture_cache.clear()

