# 🏛️ BloomHaven — Architecture & Design Decision Records (ADRs)

### ADR-001: Commercial Viable Prototype (CVP) Pivot
- **Date:** 2026-09-09
- **Status:** APPROVED
- **Context:** The codebase contained early prototypes of numerous expansive systems (genetics engines, perfume distillation, multi-layout grids, customer queues, beehives) before the visual identity, core art assets, and starter onboarding loop were locked.
- **Decision:** Shift from a monolithic feature list to a razor-sharp Commercial Viable Prototype (CVP) focusing exclusively on the first 30–45 minutes of delightful gameplay.
- **Consequences:** Scope frozen for non-CVP features. Starting plots set to 6 starter beds. 4 Base flowers + 6 Curated Hybrids locked as the CVP species scope.

### ADR-002: Curated Handcrafted Breeding over Procedural Genetics
- **Date:** 2026-09-09
- **Status:** APPROVED
- **Context:** Procedural genetics generated unpredictable petal/color combinations that clashed with handcrafted storybook art direction and required complex procedural sprite assembly.
- **Decision:** Replace RNG Mendelian allele calculation with authored Curated Breeding Matrix (4 Base -> 6 Handcrafted Hybrids).
- **Consequences:** Every hybrid is authored with dedicated artwork, poetical lore, and clear player discovery gratification.

### ADR-003: Single Approved Master Sprite per Flower Quality
- **Date:** 2026-09-09
- **Status:** APPROVED
- **Context:** Creating 4 separate unique art assets for every quality tier (Normal, Fine, Perfect, Hero) would quadruple art production costs.
- **Decision:** Use a single approved master sprite for each flower species. Quality differences are communicated via subtle scale micro-boost, gold particle motes, UI rank badge, and price multipliers.
- **Consequences:** 75% reduction in flower sprite art budget while retaining high-impact player dopamine upon cultivating a Hero Bloom (★★★).

### ADR-004: Two-Tier Economy (Quick Sell + Order Templates)
- **Date:** 2026-09-09
- **Status:** APPROVED
- **Context:** Customer order timers and deadlines create friction during the first 10 minutes of initial learning.
- **Decision:** Implement a permanent **Flower Stand / Quick Sell** in Phase 2 for instant, low-risk coin income. In Phase 4, introduce **Customer Order Templates** for higher rewards, tips, and timed challenge.
- **Consequences:** Eliminates early player frustration; gives both casual and optimization-focused players distinct economic loops.
