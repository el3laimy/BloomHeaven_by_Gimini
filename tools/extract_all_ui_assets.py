import os
import math
from collections import deque
from PIL import Image

BASE_DIR = '/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab/.user_uploaded/'

SHEET_FILES = [
    BASE_DIR + 'media_1788468908645.jpg',  # Sheet 0: Top-Left Wood & Currencies
    BASE_DIR + 'media_1788468908673.jpg',  # Sheet 1: Bottom Dock & Lily
    BASE_DIR + 'media_1788468908703.jpg',  # Sheet 2: Seed Cabinet
    BASE_DIR + 'media_1788468908726.jpg',  # Sheet 3: Plot Info
    BASE_DIR + 'media_1788468908753.jpg',  # Sheet 4: Customer Orders
]

def remove_bg_floodfill(im, tolerance=48, feather=15):
    """Cleanly removes surrounding parchment background using boundary floodfill."""
    im = im.convert('RGBA')
    w, h = im.size
    pix = im.load()
    
    # Sample corner pixels for average background parchment color
    corner_samples = [
        pix[0, 0][:3], pix[w-1, 0][:3], pix[0, h-1][:3], pix[w-1, h-1][:3],
        pix[min(5, w-1), 0][:3], pix[0, min(5, h-1)][:3],
        pix[max(0, w-6), h-1][:3], pix[w-1, max(0, h-6)][:3]
    ]
    bg_r = sum(p[0] for p in corner_samples) / len(corner_samples)
    bg_g = sum(p[1] for p in corner_samples) / len(corner_samples)
    bg_b = sum(p[2] for p in corner_samples) / len(corner_samples)
    target_bg = (bg_r, bg_g, bg_b)
    
    visited = set()
    queue = deque()
    
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))
        
    alpha_mask = Image.new('L', (w, h), 255)
    mask_pix = alpha_mask.load()
    
    def color_dist(c1, c2):
        return math.sqrt((c1[0]-c2[0])**2 + (c1[1]-c2[1])**2 + (c1[2]-c2[2])**2)
        
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        
        c = pix[x, y][:3]
        dist = color_dist(c, target_bg)
        
        if dist < tolerance:
            mask_pix[x, y] = 0
            for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    queue.append((nx, ny))
        elif dist < tolerance + feather:
            ratio = (dist - tolerance) / float(feather)
            mask_pix[x, y] = int(255 * ratio)
            
    r, g, b, _ = im.split()
    return Image.merge('RGBA', (r, g, b, alpha_mask))

def extract_and_save(sheet_idx, crop_box, dest_path, apply_bg_removal=True, tolerance=48):
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    sheet_img = Image.open(SHEET_FILES[sheet_idx])
    cropped = sheet_img.crop(crop_box)
    if apply_bg_removal:
        cropped = remove_bg_floodfill(cropped, tolerance=tolerance)
    cropped.save(dest_path)
    print(f"✓ Saved {dest_path} ({cropped.size[0]}x{cropped.size[1]})")

def main():
    print("==================================================")
    print("EXTRACTING BLOOMHAVEN MASTER UI ASSETS")
    print("==================================================")

    # ----------------------------------------------------
    # SHEET 0: TOP-LEFT WOOD & CURRENCIES
    # ----------------------------------------------------
    print("\n[Sheet 0: Top-Left Wood & Currencies]")
    extract_and_save(0, (35, 95, 585, 380), 'assets/ui/top_left/wood_sign_bloomhaven.png', True, 45)
    extract_and_save(0, (615, 182, 965, 340), 'assets/ui/top_left/wood_pill_frame.png', True, 45)
    extract_and_save(0, (90, 570, 230, 715), 'assets/ui/top_left/icon_gold_coin.png', True, 45)
    extract_and_save(0, (280, 570, 425, 715), 'assets/ui/top_left/icon_leaf.png', True, 45)
    extract_and_save(0, (470, 580, 595, 715), 'assets/ui/top_left/icon_plus_btn.png', True, 45)
    extract_and_save(0, (700, 520, 890, 730), 'assets/ui/top_left/wood_gear_btn.png', True, 45)

    # ----------------------------------------------------
    # SHEET 1: BOTTOM DOCK & LILY HUB
    # ----------------------------------------------------
    print("\n[Sheet 1: Bottom Dock & Lily Hub]")
    extract_and_save(1, (45, 195, 610, 380), 'assets/ui/dock/dock_base.png', True, 45)
    extract_and_save(1, (63, 445, 188, 620), 'assets/ui/dock/token_trowel.png', True, 45)
    extract_and_save(1, (200, 445, 325, 620), 'assets/ui/dock/token_watering_can.png', True, 45)
    extract_and_save(1, (338, 445, 462, 620), 'assets/ui/dock/token_shears.png', True, 45)
    extract_and_save(1, (472, 445, 595, 620), 'assets/ui/dock/token_basket.png', True, 45)
    extract_and_save(1, (215, 515, 380, 700), 'assets/ui/dock/token_water_glow.png', True, 40)
    extract_and_save(1, (645, 365, 930, 770), 'assets/ui/dock/lily_cameo_portrait.png', True, 45)

    # ----------------------------------------------------
    # SHEET 2: SEED BOX CABINET
    # ----------------------------------------------------
    print("\n[Sheet 2: Seed Box Cabinet]")
    extract_and_save(2, (95, 145, 530, 545), 'assets/ui/seeds/seed_cabinet_frame.png', True, 45)
    extract_and_save(2, (572, 175, 732, 510), 'assets/ui/seeds/seed_card_blank.png', True, 45)
    extract_and_save(2, (112, 595, 272, 920), 'assets/ui/seeds/seed_packet_rose.png', True, 45)
    extract_and_save(2, (312, 595, 472, 920), 'assets/ui/seeds/seed_packet_lavender.png', True, 45)
    extract_and_save(2, (512, 595, 672, 920), 'assets/ui/seeds/seed_packet_sunflower.png', True, 45)
    extract_and_save(2, (742, 625, 874, 915), 'assets/ui/seeds/slot_locked.png', True, 45)

    # ----------------------------------------------------
    # SHEET 3: PLOT INFO CARD
    # ----------------------------------------------------
    print("\n[Sheet 3: Plot Info Card]")
    extract_and_save(3, (55, 195, 315, 605), 'assets/ui/plot_info/parchment_plot_card.png', True, 45)
    extract_and_save(3, (325, 20, 680, 130), 'assets/ui/plot_info/header_plot_info.png', True, 45)
    extract_and_save(3, (700, 205, 745, 285), 'assets/ui/plot_info/droplet_blue.png', True, 45)
    extract_and_save(3, (790, 205, 835, 285), 'assets/ui/plot_info/droplet_gray.png', True, 45)
    extract_and_save(3, (682, 438, 875, 525), 'assets/ui/plot_info/badge_pruned.png', True, 45)
    # 4 stages
    extract_and_save(3, (75, 735, 138, 860), 'assets/ui/plot_info/stage_sprout.png', True, 45)
    extract_and_save(3, (160, 742, 235, 860), 'assets/ui/plot_info/stage_bush.png', True, 45)
    extract_and_save(3, (255, 735, 320, 860), 'assets/ui/plot_info/stage_bud.png', True, 45)
    extract_and_save(3, (345, 735, 415, 860), 'assets/ui/plot_info/stage_bloom.png', True, 45)
    extract_and_save(3, (440, 735, 520, 880), 'assets/ui/plot_info/stage_active_box.png', True, 45)

    # ----------------------------------------------------
    # SHEET 4: CUSTOMER ORDERS
    # ----------------------------------------------------
    print("\n[Sheet 4: Customer Orders]")
    extract_and_save(4, (30, 80, 365, 655), 'assets/ui/orders/parchment_orders_board.png', True, 45)
    extract_and_save(4, (38, 740, 185, 920), 'assets/ui/orders/gift_deliver_btn.png', True, 45)
    extract_and_save(4, (220, 740, 315, 920), 'assets/ui/orders/pocket_watch.png', True, 45)
    # Character portraits
    extract_and_save(4, (405, 125, 545, 395), 'assets/ui/orders/portrait_emma.png', True, 45)
    extract_and_save(4, (580, 125, 720, 395), 'assets/ui/orders/portrait_harris.png', True, 45)
    extract_and_save(4, (755, 125, 895, 395), 'assets/ui/orders/portrait_nora.png', True, 45)
    extract_and_save(4, (370, 415, 510, 650), 'assets/ui/orders/portrait_sara.png', True, 45)
    extract_and_save(4, (520, 415, 660, 650), 'assets/ui/orders/portrait_thomas.png', True, 45)
    extract_and_save(4, (670, 415, 810, 650), 'assets/ui/orders/portrait_jack.png', True, 45)
    extract_and_save(4, (820, 415, 960, 650), 'assets/ui/orders/portrait_laila.png', True, 45)

    print("\n==================================================")
    print("ALL ASSETS EXTRACTED & TRANSPARENCIES GENERATED 100% OK!")
    print("==================================================")

if __name__ == '__main__':
    main()
