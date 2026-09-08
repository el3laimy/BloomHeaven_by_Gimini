# Finest Garden — Experimental Prototype (P0)

This is the standalone experimental prototype repository for **Finest Garden**. It serves as an interactive sandbox to test game feel, UX flow, visual juice, responsive layout, camera navigation, planting, watering, growth, and harvest mechanics before Codex implements production domain systems.

## Milestone P0 Scope

- **12 Interactive Planting Plots (3x4 Grid)** with rich soil rendering, hover feedback, and selection rings.
- **Smooth 2D Camera**: Pan via right-click/middle-click/touch drag, smooth zoom via mouse wheel or buttons, and bounded travel.
- **3 Prototype Flower Types**:
  - 🌹 **Rose**: Classic crimson bloom with layered petals.
  - 🪻 **Lavender**: Slender purple floral stalks.
  - 🌻 **Sunflower**: Radiant golden petals with dark seed center.
- **4 Visual Growth Stages**:
  1. Mounded Soil / Sown Seed
  2. Young Sprout (Cotyledon)
  3. Vegetative / Stalk & Leaf Stage
  4. Radiant Blooming Stage (with idle wind sway animation)
- **Watering Mechanic**: Animated droplet particles, soil moisture darkening, and sparkle feedback.
- **Harvest Mechanic**: Burst particles, floating harvest feedback, and inventory counter increments.
- **HUD & Tools**:
  - Mode Switcher: Plant / Water / Harvest.
  - Seed Selector with icons and tooltips.
  - Inventory counter badges.
  - Plot details card with live moisture & progress bar.
- **Responsive Layout**: Works across standard landscape resolutions and adapts smoothly to window resizing.

## Running the Prototype

```bash
godot --path finest-garden-prototype
```
