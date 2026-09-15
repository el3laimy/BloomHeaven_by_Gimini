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
	var sprite_path: String = f_data.get("master_sprite", "")

	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		push_warning("FlowerAssetResolver: Missing asset for '%s' at '%s'. Returning missing placeholder." % [canon_id, sprite_path])
		return get_missing_texture()

	var tex := load(sprite_path) as Texture2D
	if tex == null:
		push_warning("FlowerAssetResolver: Failed to load texture at '%s' for flower '%s'." % [sprite_path, canon_id])
		return get_missing_texture()

	_texture_cache[canon_id] = tex
	return tex


## Clears runtime texture cache (useful during testing/reloads)
static func clear_cache() -> void:
	_texture_cache.clear()
