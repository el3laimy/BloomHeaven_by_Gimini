# 🏡 Bloomhaven — Garden Cottage Environment Kit & Production Blueprint
*(الدليل المعماري والفني الشامل لبيئة حديقة الكوخ ونظام التموضع الحر)*

> **الفلسفة الأساسية:**  
> **«نحن نصمم المكان الجميل، واللاعب يصمم الحديقة داخله»**  
> لا نبني Farm Grid ظاهر، ولا محرر بلاطات معقد (TileMap Editor)، ولا نرسم الحديقة كاملة كصورة واحدة مغلقة. بل نوفر **مسرحاً بيانياً ساحراً (Curated Painted Stage)** يمثل ~30% من المشهد (ثابت وجمالي)، ونمنح اللاعب مساحة حرية بنسبة ~70% لزراعة التربة، وتنسيق الزهور، ووضع خلايا النحل، ومحطات العمل، والديكورات.

---

## 🏗️ 1. المعمارية الهيكلية رباعية الطبقات (The 4-Level Pipeline)

تنقسم كافة أصول البيئة في Godot إلى 4 مستويات صارمة لتحقيق عمق 2.5D ديوراما واقعي وسلس:

```text
LEVEL 1: Background (خلفية ثابتة غير تفاعلية)
         Sky / Distant Mountains / Valley Lake / Far Forest Horizon
────────────────────────────────────────────────────────────────────────
LEVEL 2: Ground & Terrain (الأرضية وتفاصيل السطح)
         Garden Ground Base / Stream Bed / Ground Detail Overlays
────────────────────────────────────────────────────────────────────────
LEVEL 3: World (عالم اللعبة التفاعلي مع تفعيل Y-Sort)
         Cottage Body / Tree Trunks / Rocks / Fences / Bridge Floor
         [Player Objects: Soil Patches, Flowers, Beehives, Props]
         Lily (الشخصية مع نقطة ارتكاز عند القدمين)
────────────────────────────────────────────────────────────────────────
LEVEL 4: Foreground & Overhangs (المقدمة والإطارات الأمامية)
         Cottage Roof Front Lip / Tree Canopies Front / Bridge Front Rail / Framing Leaves
```

---

## 🌳 2. شجرة المشهد في Godot (`GardenCottage.tscn`)

```text
GardenCottage (Node2D)
│
├── Background (CanvasLayer / Parallax2D / Node2D - z_index: -100)
│   ├── Sky (Sprite2D - bg_sky_day.png)
│   ├── Mountains (Sprite2D - bg_mountains_far.png)
│   ├── Valley (Sprite2D - bg_valley_lake.png)
│   └── FarForest (Sprite2D - bg_forest_horizon.png)
│
├── Ground (Node2D - z_index: -50)
│   ├── GardenBase (Sprite2D - ground_garden_base.png)
│   ├── Stream (Node2D - stream_base.png + water_foam.png)
│   └── GroundDetails (Node2D - Overlays: Grass, earth, moss, fallen leaves)
│
├── World (Node2D - y_sort_enabled = true)
│   │
│   ├── FixedEnvironment (Node2D - y_sort_enabled = true)
│   │   ├── CottageBody (StaticBody2D / Sprite2D - cottage_base.png)
│   │   ├── TreeTrunks (Node2D - tree_trunk sprites with collision)
│   │   ├── Rocks (Node2D - rock_medium / rock_large with collisions)
│   │   ├── Fences (Node2D - fence segments)
│   │   └── Bridge (Node2D - bridge_base + bridge_back_rail)
│   │
│   ├── Placeables (Node2D - y_sort_enabled = true)
│   │   ├── SoilPatches (SoilPatch nodes: dry/moist)
│   │   ├── Flowers (FlowerPlant nodes with stages: sprout -> bloom)
│   │   ├── Machines (Beehives, Seed Chests, Workbenches, Compost)
│   │   └── Decorations (Pots, Benches, Lanterns, Birdhouses)
│   │
│   └── Lily (CharacterBody2D - y_sort_enabled = true)
│       ├── Sprite / AnimatedSprite2D (Pivot at feet: X)
│       ├── CollisionShape2D
│       └── ToolHolders (Watering can, shovel, pruner)
│
├── Foreground (Node2D - z_index: 50)
│   ├── CottageRoofFront (Sprite2D - cottage_roof_front.png)
│   ├── TreeCanopiesFront (Node2D - tree canopies covering Lily)
│   ├── BridgeFrontRail (Sprite2D - bridge_front_rail.png)
│   └── ForegroundLeaves (Node2D - leaves_top_left, leaves_top_right, branches)
│
├── NavigationSystem (Node2D - Hidden AStarGrid2D logic)
├── PlacementSystem (Node2D - Ghost preview, valid/invalid feedback)
├── GardenState / SaveManager (Node - Data persistence)
│
├── FX (Node2D - Dig dust, water droplets, pollen, petals, smoke)
│
└── HUD (CanvasLayer)
    ├── ToolDock (Shovel, Water, Prune, Harvest)
    ├── SeedBar / Inventory
    ├── OrderRail
    └── StatusTopBar (Coins, Bloom Score)
```

---

## 🎨 3. تفكيك أصول بيئة الكوخ (Garden Cottage Asset Breakdown)

### A. Stage Foundation (أساس المرحلة — 5 أصول)
| الأصل | الملف المقترح | النوع | الغرض الفني |
|---|---|---|---|
| السماء | `bg_sky_day.png` | Static RGB | خلفية نقية بلون نهار دافئ |
| الجبال البعيدة | `bg_mountains_far.png` | Transparent RGBA | تلال متدرجة بدرجات الأزرق والبنفسجي الضبابي |
| الوادي والبحيرة | `bg_valley_lake.png` | Transparent RGBA | مسطح مائي وقرية ريفية بعيدة تعطي عمقاً للمشهد |
| خط الغابة البعيد | `bg_forest_horizon.png` | Transparent RGBA | أشجار ضبابية ناعمة تلتف خلف حديقة الكوخ |
| أرضية الحديقة | `ground_garden_base.png` | Static RGB/RGBA | مساحة العشب والتربة الأساسية فقط (بدون أي مبانٍ أو أشجار أو أحواض) |

> **قاعدة صارمة:** `ground_garden_base.png` خالية تماماً من الكوخ، الأشجار، الصخور، أو الأحواض لضمان استقلالية كل عنصر.

---

### B. Ground Detail Kit (أصول تفاصيل الأرض — ~25 أصلاً)
مجموعات شفافة متناثرة تكسر تكرار العشب وتضفي طابعاً طبيعياً مرسوماً يدوياً:
* **Grass Patches (Light & Dark):** بقع عشبية فاتحة وظلال ناعمة (4 فاتح + 4 غامق).
* **Bare Earth Patches:** مساحات ترابية دافئة طبيعية (4 أصول).
* **Fallen Leaves & Tiny Stones:** أوراق شجر متساقطة حول جذوع الأشجار وحصى صغيرة (5 أحجار + 4 أوراق).
* **Wild Flowers & Moss:** أزهار برية صغيرة ثابتة غير قابلة للحصاد ونباتات الطحالب (6 أزهار برية + 4 طحالب).

---

### C. Cottage Kit (أصول الكوخ المفككة — 10 أصول)
بدلاً من رسم الكوخ ككتلة واحدة مصمتة، يتم تفكيكه لخدمة عمق المنظور:
1. `cottage_base.png`: الجدران الخشبية والحجرية، الشبابيك، الدرج، والتجويف السفلي.
2. `cottage_roof.png`: سقف القرميد الأساسي (خلف Lily).
3. `cottage_roof_front.png`: شفة السقف الأمامية (Foreground Layer — تختفي ليلي تحتها عند السير بمحاذاة الواجهة).
4. `cottage_door.png`: الباب الخشبي (مغلق ومفتوح).
5. `cottage_windows.png` + `cottage_window_glow.png`: شباك بقاعدة مستقلة وطبقة إضاءة ليلية منفصلة.
6. `cottage_chimney.png`: المدخنة مع نقطة ربط لمؤثر الدخان `chimney_smoke.png`.
7. `cottage_ivy_back.png` & `cottage_ivy_front.png`: نبات اللبلاب المتسلق المتداخل مع السقف والجدران.
8. `cottage_shadow.png`: ظل ملامسة الكوخ للأرض منفصل لتثبيته في البيئة.

---

### D. Tree Kit (أصول الأشجار ثنائية العمق — ~20 قطعة)
كل شجرة تتكون من شقين:
* **Trunk (`tree_XX_trunk.png`):** يدخل في عالم `World` مع تفعيل Y-Sort و Collision لمنع مرور ليلي خلال الجذع.
* **Canopy Front (`tree_XX_canopy_front.png`):** طبقة الأوراق العلوية توضع في الـ `Foreground` بحيث تمشي ليلي خلف الجذع وتحت الأوراق طبيعياً.
* **Shadow (`tree_XX_shadow.png`):** ظل ناعم مستقل على الأرض.
* **العدد الأولي:** 5 أشجار (2 كبيرة، 2 متوسطة، 1 صغيرة/مزهرة).

---

### E. Bush & Foliage Kit (الشجيرات وحواف البيئة — ~25 أصلاً)
* **Low / Medium / Flowering Bushes:** شجيرات منخفضة ومتوسطة ومزهرة لحماية حدود المنظور (15 أصلاً).
* **Edge Foliage (`foliage_edge_top/left/right.png`):** أشرطة نباتية كثيفة توضع على أطراف الكاميرا لإخفاء حدود مساحة اللعب دون الحاجة لجدران مصمتة.

---

### F. Water, Rocks & Bridge Kit (الماء، الصخور، والجسر — ~20 أصلاً)
* **Stream Bed & Foam:** مجرى مائي مائل مع رغوة متحركة وخامات لمعان الماء (`water_shimmer.png`).
* **Rocks Family (8 أصول):** 3 صغيرة، 3 متوسطة، 2 ضخمة مع طحالب ناعمة.
* **Bridge Modular Kit (4 قطع):**
  - `bridge_base.png` (أرضية الجسر الخشبية).
  - `bridge_back_rail.png` (السياج الخلفي - تسير ليلي أمامه).
  - `bridge_front_rail.png` (السياج الأمامي - يسير خلفه قدم ليلي، في الـ Foreground!).
  - `bridge_shadow.png`.

---

### G. Fences & Entrance Kit (الأسوار والمدخل — ~17 أصلاً)
* **Fence Segments:** قطع مستقيمة قصيرة وطويلة، زوايا، بوابات مفتوحة ومغلقة، وتداخلات لبلاب.
* **Entrance Kit:** أعمدة حجرية، قوس خشبي للمدخل، فوانيس معلقة، ولافتة قابلة للكتابة أو التعديل.

---

### H. Gameplay Soil & Props Kit (عناصر اللعب والتربة)
* **Soil Patches:**
  - `soil_small_dry_01/02.png` (تربة جافة بحواف ناعمة مدمجة مع العشب).
  - `soil_small_moist_01/02.png` (تربة رطبة داكنة بعد الري).
  - أحواض خشبية وحجرية كترقيات وديكورات إضافية (`bed_wood_small`, `bed_stone_premium`).
* **Utility Props:**
  - `water_barrel_01.png`, `water_pump_01.png` (مصادر المياه).
  - `seed_chest_01.png`, `seed_basket_01.png` (مخازن البذور).
  - `beehive_01.png`, `beehive_02.png` (خلايا النحل للتلقيح المتبادل).
  - `workbench_base.png` (طاولة تنسيق الباقات والأشغال).
  - `compost_bin.png` (صندوق التسميد العضوي).
* **Decorations (15–20 أصلاً):** أواني فخارية، مقاعد حديقة، فوانيس ريفية، عربة زراعية خشبية، بيوت طيور.

---

### I. Foreground Frame & FX Kit
* **Foreground Frame:** أغصان شجر متدلية وأوراق في الزوايا العلوية (`leaves_top_left.png`, `leaves_top_right.png`) لتأطير المشهد وإعطاء انطباع النظر داخل ديوراما حية.
* **FX Kit:** غبار الحفر (`dig_dust.png`)، قطرات الرش (`water_splash.png`)، غبار حبوب اللقاح (`pollen.png`)، بتلات متطايرة (`petals.png`)، ودخان المدخنة (`chimney_smoke.png`).

---

## ⚙️ 4. القواعد التقنية ومعايير الإنتاج (Production Standards)

1. **نقطة الارتكاز (Pivot Point Rule):**  
   كل كائن في اللعبة (شجرة، زهرة، ليلي، برميل، كوخ) يجب أن تكون نقطة ارتكازه `Pivot` عند **ملامسة الأرض تماماً (Bottom-Center)** وليس في مركز الصورة. هذا هو الضامن الفني لعمل نظام `Y-Sorting` بدقة متناهية.

2. **اتجاه الإضاءة الموحد (Unified Sun Lighting):**  
   جميع الأصول تُرسم بمصدر إضاءة واحد ثابت: **من أعلى اليسار إلى أسفل اليمين (Top-Left ➔ Bottom-Right)** مع ظلال تلامس أرضية ناعمة.

3. **الظلال غير المحروقة (No Baked Global Shadows):**  
   السبرايت لا يحتوي على ظله الأرضي مدمجاً في الرسمة بشكل دائم، بل يُفصل الظل لطبقة مستقلة تحت الكائن (`Shadow Sprite`) ليسمح بتحريكه وتغيير أرضيته بسلاسة.

4. **الملاحة والذكاء الاصطناعي (Hidden AStarGrid2D):**  
   - شبكة منطقية مخفية بدون أي ظهور للاعب.
   - عند وضع أو تحريك عنصر (مثل خلية نحل)، يتم تحديث الخلية في الشبكة لتصبح غير صالحة للمرور (`set_point_solid`).
   - ليلي تبحث عن مسار ناعم عبر `AStarGrid2D` وتسير بخطوات انسيابية دون أي مظهر شبكي مصطنع.

5. **المحاذاة الناعمة (Internal Soft Snapping):**  
   - شبكة خفية صغيرة جداً (مثلاً `8px` أو `16px`) لمنع تداخل أصول التربة والأشياء بشكل شاذ، مع منح اللاعب شعوراً بالحرية التامة في ترتيب حديقته.

6. **التفاعل الفيزيائي غير اللحظي (Physical Non-Instant Actions):**  
   - ضغط اللاعب ➔ انتقال ليلي إلى الموقع ➔ تشغيل أنميشن الفعل (حفر، ري، قطف، تقليم) ➔ اكتمال المهمة.
   - هذا يعطي قيمة استراتيجية حقيقية لتنظيم الحديقة وقرب مصادر الماء والبذور من أحواض الزهور.

---

## 🚀 5. الشريحة العمودية الأولية (MVP 10 Assets Vertical Slice)

للتحقق الفوري من التناسق البصري، المقاييس، زاوية الكاميرا، و Y-Sorting داخل Godot، نبدأ بإنتاج وتجميع **10 أصول رئيسية فقط**:

```text
1. ground_garden_base.png          (أرضية العشب الأساسية)
2. env_cottage_base.png            (جدران الكوخ والباب والشبابيك)
3. env_cottage_roof.png            (سقف الكوخ الخلفي)
4. fg_cottage_roof_front.png       (حافة السقف الأمامية - Foreground)
5. env_tree_large (Trunk + Canopy) (شجرة واحدة مقسمة جذع + مظلة)
6. env_bush_medium.png             (شجيرة محيطية للأطراف)
7. env_fence_segment.png           (قطعة سور مع وتد)
8. soil_patch_dry / moist.png      (بقعة تربة جافة ورطبة)
9. prop_beehive_01.png             (خلية نحل قابلة للتحريك والوضع)
10. fg_leaves_top_corner.png       (أوراق المقدمة لتأطير الكاميرا)
```

بتركيب هذه الأصول الـ 10 مع شخصية ليلي (Lily) و 3 زهور (Daisy, Rose, Tulip)، نحصل على **Vertical Slice كامل وقابل للاختبار** يُثبت نجاح التجربة قبل التوسع في باقي الـ 150 أصلاً.
