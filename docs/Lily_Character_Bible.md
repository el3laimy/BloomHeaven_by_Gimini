# Lily Character Bible — Bloomhaven

## 1. Character Identity

**Name:** Lily  
**Role:** Gardener / Player Character  
**Age:** ~12-14 (young girl)  
**Personality:** Warm, curious, gentle, nature-loving  
**Art Style:** Storybook illustration, semi-realistic painterly, warm soft lighting

---

## 2. Color Palette

| Element | Color | Hex | Notes |
|---------|-------|-----|-------|
| Skin | Warm peach | `#EBA579` | Consistent warm undertone |
| Hair | Copper auburn | `#8B4513` → `#A0522D` | Rich brown with reddish highlights |
| Eyes | Warm brown | `#5C3A1E` | Large, expressive |
| Blouse | Cream/off-white | `#F5F0E1` | Puffy sleeves, soft fabric |
| Apron (front) | Olive green | `#6B7B3A` | Embroidered with small flowers |
| Apron (back) | Same olive | `#6B7B3A` | Cross-strap design |
| Belt | Brown leather | `#8B6914` | With brass buckle |
| Pouches | Dark brown leather | `#6B4E2E` | Attached to belt |
| Gloves | Brown leather | `#7B5B3A` | Gardening work gloves |
| Underskirt | Cream lace | `#F0E8D8` | Longer than apron, decorative hem |
| Socks | Cream knit | `#F0E8D8` | Knee-high, slightly scrunched |
| Boots | Warm brown | `#8B6B3A` | Lace-up, sturdy, mid-calf |
| Hat | Golden straw | `#C8A84E` | Wide brim, decorated with flowers |
| Hat ribbon | Olive green | `#5A6B2E` | Bow on hat |
| Necklace | Gold pendant | `#B8860B` | Small floral pendant |

---

## 3. Proportions (Head = 1 unit = ~128px)

| Measurement | Heads | Pixels |
|-------------|-------|--------|
| Total height | ~4.5 heads | ~576px |
| Head (crown to chin) | 1 head | 128px |
| Neck | 0.15 head | ~20px |
| Torso (neck to waist) | 1.2 heads | ~154px |
| Skirt (waist to hem) | 1.2 heads | ~154px |
| Legs (hem to sole) | 1.0 head | ~128px |
| Arm total span | 1.5 heads | ~192px |
| Upper arm | 0.7 head | ~90px |
| Forearm | 0.6 head | ~77px |
| Hand | 0.35 head | ~45px |
| Hat brim width | 1.2 heads | ~154px |
| Shoulder width | 1.0 head | ~128px |

### Target Game Size
- **In-game character height:** ~80px (matching garden plot scale)
- **Rig scale factor:** `80 / 576 ≈ 0.139`
- **Assets are drawn at production scale (576px tall), scaled down in Godot**

---

## 4. Clothing & Material Details

### Blouse
- Cream/off-white cotton, puffy bishop sleeves
- Gathered at wrists with elastic/button cuff
- Peter Pan collar or simple fold collar

### Apron (Front)
- Olive green cotton/linen, embroidered with small wildflowers
- Square neckline with shoulder straps
- Large front pocket, reaches mid-thigh

### Apron (Back)
- Same material, cross-strap design forming X, tied bow at waist

### Belt
- Brown leather ~2cm wide, brass buckle, two small tool pouches on sides

### Underskirt
- Cream cotton with delicate lace hem, full A-line, shows below apron

### Boots
- Brown leather lace-up, mid-calf, chunky sole

### Gloves
- Brown leather gardening gloves, past wrist, slightly worn

### Hat
- Wide-brim straw, decorated with flowers around crown, olive green bow

---

## 5. Hair Details

- Wavy/curly, auburn-copper
- Side braid from left temple over left shoulder
- Front: loose curls framing face on both sides
- Braid: 3-segment chain (top → middle → tip)
- Braid tip: small green ribbon, slight curl
- Back: loose curls visible from behind

---

## 6. Joint Overlap Requirements

Every part extends 15-20px past its joint boundary:

| Part | Overlap Direction | Amount |
|------|-------------------|--------|
| Head | Neck extends down into torso | 20px |
| Upper arm | Shoulder extends into torso side | 15px |
| Lower arm | Elbow extends up into upper arm | 15px |
| Hand | Wrist extends into forearm | 10px |
| Torso | Extends down past waist | 15px |
| Leg | Hip extends up into skirt area | 15px |
| Boot | Ankle extends up into leg | 10px |
| Braid segments | Each overlaps next by | 15px |

---

## 7. Z-Index Layer Order (front view)

```
Z-Index   Layer
  -3      hair_back
  -2      apron_back (back view only)
  -1      leg_R, boot_R (far leg)
   0      skirt_back (cream underskirt)
   1      torso
   2      skirt_front (green apron)
   3      belt
   4      leg_L, boot_L (near leg)
   5      arm_R (far arm group)
   7      arm_L (near arm group)
   9      hair_front
  10      head
  11      hat
  12      braid chain
```
