# 📋 BloomHaven — CVP Scope Manifest
## Single Source of Truth for Feature Inclusion & Boundaries

> **⚠️ The Golden Rule:**  
> *"Does this feature improve the first 30–45 minutes of BloomHaven? If NO, it goes directly to POST_CVP_BACKLOG.md."*

---

## 1. Core Principles
1. **Vertical Slice, Not a Tech Demo:** Deliver a complete, polished, commercially appealing 30–45 minute gameplay slice.
2. **Quality Over Quantity:** 10 exquisitely crafted flowers (4 Base + 6 Curated Hybrids) are commercially superior to 50 unpolished procedural assets.
3. **Pacing First:** The player must experience their first planting, watering, harvest, sale, and upgrade within the first 10 minutes without confusion.

---

## 2. IN SCOPE — CVP (Phases 0 through 6)

### 🌿 Garden & World
- **Starter Grid:** 6 Starter plots (2×3 Bed A) with 2.5D isometric loam soil furrows.
- **Progression Expansion:** Upgrading to 12 plots (Bed B) via the Shop upgrade.
- **Hero Showcase Bed:** Plot #24 reserved for the ultimate Hero Bloom achievement.
- **Handcrafted Environment:** 2.5D Meadow Island base, rustic boundary fences, ancient breeze-swayed oak tree, layered cottage with see-through roof occlusion, and decorative foliage bushes.

### 👒 Character (Lily)
- **Focal Hero:** Crisp, hand-illustrated character matching the world style.
- **Movement & Controls:** 8-directional smooth pathfinding, 4-way facing direction, and responsive click-to-move / WASD.
- **Held Tools:** Visible animated props (Trowel, Watering Can, Pruning Shears).

### 🌸 Botanical Life Cycle & Flowers
- **4 Base Flowers (Tier 1):**
  - 🌹 `crimson_rose` (Crimson Rose)
  - 🌼 `sunny_daisy` (Sunny Daisy)
  - 💜 `english_lavender` (English Lavender)
  - 🌷 `pastel_tulip` (Pastel Tulip)
- **4 Crystal-Clear Growth Stages:**
  1. **Seed (بذرة)**
  2. **Sprout (برعم)**
  3. **Growing / Vegetative (شجيرة خضراء)** — contains the Hero Bloom pruning window.
  4. **Bloom (تزهير كامل)**.
- **Hero Bloom Mechanic (★★★):** Pruning during the vegetative stage produces a Hero Bloom with visual sparkles, badge, and 2.5x market value.
- **Single Master Sprite Asset Rule:** Flower species share one approved visual master; quality levels (Normal, Fine, Perfect, Hero) are expressed through micro-scale, sparkle VFX, badge, and gold multiplier, protecting the art budget.

### 🧬 Discovery & Curated Breeding
- **Strict Cap:** Exactly 10 flowers (4 Base + 6 Handcrafted Hybrids).
- **Zero RNG:** Deterministic authored recipes:
  - Rose + Daisy = `blushbell`
  - Rose + Lavender = `velvet_dusk`
  - Lavender + Tulip = `twilight_bell`
  - Daisy + Tulip = `sunburst_daisy`
  - Rose + Tulip = `crown_petal`
  - Daisy + Lavender = `meadow_mist`
- **Botanical Journal:** Elegant storybook entries unlocked as players discover new hybrids.

### 💰 Economy & Progression
- **Flower Stand / Quick Sell (Phase 2):** Immediate fixed-price coin conversion for harvested flowers, providing a safe, accessible financial baseline.
- **Order Templates & Archetypes (Phase 4):**
  - Single Flower Demand
  - Mixed Meadow Request
  - Quality Connoisseur
  - Botanist Rarity
  - Simple Bouquet (3 flowers)
  - Premium Bouquet
- **5 Core Upgrades:**
  1. Golden Dual Sprinkler / Moisture Retention
  2. Garden Bed Expansion (6 -> 12 plots)
  3. Deep Seed Satchel (Storage boost)
  4. Golden Pruning Shears (Expanded Hero Bloom window)
  5. Swift Boots (+35% walking speed)

### 💾 Core Systems & UX
- **Save V2:** Fault-tolerant JSON persistence with backward compatibility.
- **Audio:** Cozy garden background loop + 8 polyphonic responsive SFX.
- **Performance Budget:** Rock-solid 60 FPS on baseline target hardware (GL Compatibility, <250 MB RAM).

---

## 3. OUT OF SCOPE — POST-CVP BACKLOG

The following systems are quarantined and strictly deferred until after commercial validation:

| System | Deferral Reason |
|---|---|
| **Beehives & Honey Processing** | Adds secondary processing complexity before crop loop is proven. |
| **Perfume Distillery Lab** | Requires separate liquid bottle mechanics and customer tiers. |
| **Regional Garden Contests** | High UI/AI burden; belongs in Full Release endgame. |
| **Complex Random Pedestrian Visitors** | Pathfinding and AI queueing clutter the cozy focused slice. |
| **Procedural Mendelian Genetics** | Random allele segregation produces unpredictable visual soup; replaced by Curated Breeding. |
| **Dynamic Seasons & Weather System** | Art asset multiplier; CVP takes place in eternal Spring/Summer. |
| **Multiplayer / Co-op Visiting** | Massive netcode overhead; purely single-player cozy slice. |
| **100+ Flower Roster** | Production dilution; CVP focuses on 10 immaculate flowers. |
