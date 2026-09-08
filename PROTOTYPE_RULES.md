# Prototype Rules and Constraints (P0)

1. **PROTOTYPE_ONLY Values:**
   - Growth times are accelerated (e.g. 5-8 seconds total per flower) for immediate visual testing.
   - Initial flower inventory begins at 0 and increments on harvest.
   - Water increases plot moisture and accelerates growth by 2.0x.

2. **DESIGN DECISION REQUIRED:**
   - **Screen Orientation:** Currently tested on a responsive landscape canvas (1280x720 base), with anchor-based UI scaling to ensure it adapts to mobile aspect ratios without fixing portrait/landscape prematurely.
   - **Growth Mechanism:** Real-world time vs tick-based active time. Prototype uses delta-time simulated growth.
   - **Water Depletion Rate:** How long a plot stays watered before drying out. Prototype dries out after 10-15s if not replanted.
   - **Seed Economy:** Unlimited seeds in P0 for experimentation vs consumable seed packet economy.

3. **No Unapproved Mechanics:**
   - No genetics / allele simulation yet.
   - No currency / shops / order fulfillment.
   - No cloud saves or migrations.
