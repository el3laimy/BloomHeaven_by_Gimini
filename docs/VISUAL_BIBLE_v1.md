# 📖 BloomHaven Visual Bible v1.0
## Handcrafted Storybook & Botanical Aesthetic Design Document

> **Project:** BloomHaven (Commercial Viable Prototype — CVP)  
> **Engine:** Godot 4.7.1-stable  
> **Renderer:** GL Compatibility (OpenGL 4.6 Core)  
> **Target Screen Canvas:** 1280 x 720 (Mode: `canvas_items`, Aspect: `expand`)  
> **Aesthetic Pillar:** *Cozy Hand-Illustrated Storybook + 2.5D Isometric Floral Living Sanctuary*  

---

## 🎨 1. Visual Philosophy & Core Pillars

### 1.1 The "Living Picture-Book" Feeling
BloomHaven does not use harsh, flat geometry or neon pixel colors. Every element looks like an illustration from a vintage European botanical encyclopedia or a nostalgic fairy tale:
- **Soft Contours:** Clean organic silhouettes with subtle hand-inked line weight.
- **Warm Lighting:** Gentle late-morning sunshine with warm rim lights, soft ambient shadows, and drifting breeze petals.
- **Tactile Materiality:** Wood looks aged and carved; parchment looks weathered; soil looks rich, dark, and loamy when wet; copper tools reflect warm golden highlights.

---

## 🌈 2. Master Color Palette

| Category | Tone Name | Hex / RGBA Sample | Role / Usage |
|---|---|---|---|
| **Parchment / Paper** | Aged Cream | `#F8F3E6` | Modal backgrounds, dialogue cards, lore |
| **Parchment Border** | Toasted Sienna | `#4A3525` | Outer wooden frames, header borders |
| **Flora: Crimson** | Velvety Rose | `#EB3847` | Red Rose, Crown Petal, strawberry accents |
| **Flora: Sunny Gold** | Morning Daylight | `#FFD224` | Sunny Daisy, Sunburst Daisy, Coins (🪙) |
| **Flora: Twilight** | English Lavender | `#AD80E0` | Lavender, Velvet Dusk, Twilight Bell |
| **Flora: Pastel Tulip** | Golden Apricot | `#FAAA1F` | Pastel Tulip, warm citrus floral notes |
| **Soil: Dry** | Sandy Loam | `#B3885C` | Unwatered garden plot soil |
| **Soil: Wet** | Rich Moist Humus | `#634426` | Watered soil (dark, fertile, glistening) |
| **Nature: Foliage** | Olive Forest Sage | `#3D8547` | Shrubbery, oak canopy, weed foliage |
| **Nature: Island Cliff** | Mossy Sandstone | `#9E8A68` | 2.5D Island base rock strata and cliffs |

---

## 📏 3. Per-Asset-Class Rules & Resolution Targets

To protect both visual crispness and memory/draw-call budgets on mobile and integrated GPUs, assets follow strict class boundaries:

```
┌─────────────────┬─────────────────┬────────────────┬───────────────────────────┐
│ Asset Class     │ Master Source   │ Runtime Canvas │ Scaling & Filtering       │
├─────────────────┼─────────────────┼────────────────┼───────────────────────────┤
│ Lily (Focal)    │ 512x512 PNG     │ ~88px tall     │ 0.455x Scale, Mipmaps ON  │
│ Tool Props      │ 256x256 PNG     │ 16-24px visual │ Held tool overlay anchor  │
│ Flower Sprites  │ 256x256 PNG     │ 64x64px plot   │ Single Master Sprite Rule │
│ Environment     │ 512x512-1024x   │ Scaled island  │ Y-Sorted 2.5D Layers      │
│ UI Panels / 9S  │ 128x128 9-slice │ Variable       │ Clean CanvasItems, No VRAM│
└─────────────────┴─────────────────┴────────────────┴───────────────────────────┘
```

---

## 👒 4. Lily Caretaker Character Specifications

- **Silhouette & Persona:** Lily is a warm, capable cottage botanist wearing a wide-brimmed straw hat with ribbon, emerald apron over an earth-tone linen dress, and sturdy gardener boots.
- **Visual Scale:** Calibrated at `0.455x` from 256x256 source to render at **~88px tall grounded height**.
- **Animation Strategy:** Frame-by-frame flipbook motion with 4-way facing (Down, Up, Left, Right with horizontal mirroring).
- **Held Tool Anchors:**
  - `water`: Copper watering can gripped at top handle `(92, 42)`.
  - `plant`: Hand trowel angled down along apron skirt.
  - `prune`: Pruning shears angled ready for clipping.
  - `harvest`: Woven flower basket resting against Lily's waist.

---

## 🌹 5. Flower Visual Hierarchy & The Hero Bloom Rule (★★★)

### 5.1 Single Master Sprite Rule (Art Budget Protection)
To avoid needing 40+ separate sprites for quality variations:
- Each flower species uses **one approved master sprite**.
- Quality differentiation is communicated purely through procedural juice:

```
Normal Bloom (1.0x Value)   ──> Standard Master Sprite
Fine Bloom   (1.25x Value)  ──> Scale 1.02x + Soft sparkle shimmer
Perfect Bloom(1.5x Value)   ──> Scale 1.05x + Silver glint particle
Hero Bloom ★ (2.5x Value)   ──> Scale 1.08x + Golden aura + 3-Star Badge + Chime
```

---

## 🏡 6. Garden Environment Composition

- **Meadow Island:** Suspended 2.5D grassy island floating amidst cozy ambient woodland atmosphere.
- **Cottage:** Stone base with red tiled roof covered in climbing pink rambling roses. Roof fades to 40% opacity when Lily approaches behind it.
- **Ancient Oak:** Y-sorted solid trunk at foot level with swaying breeze canopy overhead.
- **Starter Bed A:** Compact 2x3 wooden raised bed. Clearly separated plots to eliminate clicking confusion.

---

## 🖼️ 7. UI / HUD Design Language

- **Storybook Parchment & Carved Wood:** Panels are styled with wooden borders, parchment inner margins, and gold serif/sans typography.
- **Non-Obtrusive Layout:** Top 75% of screen is clear for the garden vista; controls stay grouped in the bottom tool dock and top status bar.
- **Flower Stand:** Accessible from the top right `[🌸 Stand & Satchel]` button, displaying all harvested flora with individual unit prices, `[Sell 1]` buttons, and a one-click `[Quick Sell All]` footer.
