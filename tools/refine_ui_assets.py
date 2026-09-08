import os
import math
from collections import deque
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = '/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab/.user_uploaded/'

SHEET_FILES = [
    BASE_DIR + 'media_1788468908645.jpg',  # Sheet 0: Top-Left Wood & Currencies
    BASE_DIR + 'media_1788468908673.jpg',  # Sheet 1: Bottom Dock & Lily
    BASE_DIR + 'media_1788468908703.jpg',  # Sheet 2: Seed Cabinet
    BASE_DIR + 'media_1788468908726.jpg',  # Sheet 3: Plot Info
    BASE_DIR + 'media_1788468908753.jpg',  # Sheet 4: Customer Orders
]

def remove_bg_floodfill(im, tolerance=46, feather=10):
    """Cleanly removes surrounding parchment background using boundary floodfill."""
    im = im.convert('RGBA')
    w, h = im.size
    pix = im.load()
    
    corner_samples = [
        pix[0, 0][:3], pix[w-1, 0][:3], pix[0, h-1][:3], pix[w-1, h-1][:3],
        pix[min(4, w-1), 0][:3], pix[0, min(4, h-1)][:3],
        pix[max(0, w-5), h-1][:3], pix[w-1, max(0, h-5)][:3]
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

def extract_and_save(sheet_idx, crop_box, dest_path, apply_bg_removal=True, tolerance=46):
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    sheet_img = Image.open(SHEET_FILES[sheet_idx])
    cropped = sheet_img.crop(crop_box)
    if apply_bg_removal:
        cropped = remove_bg_floodfill(cropped, tolerance=tolerance)
    cropped.save(dest_path)
    print(f"✓ Saved {dest_path} ({cropped.size[0]}x{cropped.size[1]})")

def make_english_header_plaque():
    # Sheet 3 top header plaque is at (325, 20, 680, 115)
    im = Image.open(SHEET_FILES[3])
    cropped = im.crop((325, 20, 680, 115))
    cropped = remove_bg_floodfill(cropped, tolerance=45)
    
    w, h = cropped.size
    draw = ImageDraw.Draw(cropped)
    # Patch center area with deep rich carved oak
    draw.rounded_rectangle((w//2 - 95, 18, w//2 + 95, h - 22), radius=8, fill=(65, 42, 25, 255))
    
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 26)
    except:
        font = ImageFont.load_default()
        
    text = "Plot Info"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2
    ty = (h - th) // 2 - 2
    
    draw.text((tx + 2, ty + 2), text, font=font, fill=(20, 10, 5, 240))
    draw.text((tx, ty), text, font=font, fill=(255, 225, 130, 255))
    draw.text((tx, ty - 1), text, font=font, fill=(255, 245, 190, 200))
    
    dest_path = 'assets/ui/plot_info/header_plot_info.png'
    cropped.save(dest_path)
    print(f"✓ Saved English {dest_path}")

def make_english_orders_board():
    im = Image.open(SHEET_FILES[4])
    cropped = im.crop((30, 80, 365, 655))
    cropped = remove_bg_floodfill(cropped, tolerance=45)
    w, h = cropped.size
    
    draw = ImageDraw.Draw(cropped)
    # Cleanly cover the top Arabic header "طلبات الزبائن"
    draw.rectangle((w//2 - 105, 38, w//2 + 105, 82), fill=(245, 235, 210, 255))
    
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 18)
    except:
        font = ImageFont.load_default()
        
    text = "Customer Orders"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2
    ty = 48
    
    draw.text((tx + 1, ty + 1), text, font=font, fill=(50, 30, 18, 190))
    draw.text((tx, ty), text, font=font, fill=(70, 42, 22, 255))
    
    dest_path = 'assets/ui/orders/parchment_orders_board.png'
    cropped.save(dest_path)
    print(f"✓ Saved English {dest_path}")

def make_clean_seed_cabinet():
    im = Image.open(SHEET_FILES[2])
    cropped = im.crop((95, 115, 530, 412))
    cropped = remove_bg_floodfill(cropped, tolerance=45)
    w, h = cropped.size
    
    draw = ImageDraw.Draw(cropped)
    # Patch the Arabic header on top arch
    draw.rounded_rectangle((w//2 - 90, 16, w//2 + 90, 48), radius=6, fill=(70, 44, 25, 255))
    
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 16)
    except:
        font = ImageFont.load_default()
        
    text = "Seed Box"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2
    ty = 22
    
    draw.text((tx + 1, ty + 1), text, font=font, fill=(20, 10, 5, 240))
    draw.text((tx, ty), text, font=font, fill=(255, 225, 130, 255))
    
    dest_path = 'assets/ui/seeds/seed_cabinet_frame.png'
    cropped.save(dest_path)
    print(f"✓ Saved Clean {dest_path}")

def main():
    print("==================================================")
    print("REFINING ALL ASSETS WITH VERIFIED BOUNDS & ENGLISH TEXT")
    print("==================================================")

    # Sheet 0: Top-Left Wood & Currencies
    extract_and_save(0, (40, 45, 585, 280), 'assets/ui/top_left/wood_sign_bloomhaven.png', True, 45)
    extract_and_save(0, (615, 142, 965, 260), 'assets/ui/top_left/wood_pill_frame.png', True, 45)
    extract_and_save(0, (90, 570, 230, 705), 'assets/ui/top_left/icon_gold_coin.png', True, 45)
    extract_and_save(0, (280, 570, 420, 705), 'assets/ui/top_left/icon_leaf.png', True, 45)
    extract_and_save(0, (470, 580, 595, 700), 'assets/ui/top_left/icon_plus_btn.png', True, 45)
    extract_and_save(0, (700, 520, 890, 700), 'assets/ui/top_left/wood_gear_btn.png', True, 45)

    # Sheet 1: Bottom Dock & Lily
    extract_and_save(1, (45, 155, 610, 295), 'assets/ui/dock/dock_base.png', True, 45)
    extract_and_save(1, (60, 360, 185, 485), 'assets/ui/dock/token_trowel.png', True, 45)
    extract_and_save(1, (200, 360, 325, 485), 'assets/ui/dock/token_watering_can.png', True, 45)
    extract_and_save(1, (340, 360, 465, 485), 'assets/ui/dock/token_shears.png', True, 45)
    extract_and_save(1, (475, 360, 600, 485), 'assets/ui/dock/token_basket.png', True, 45)
    extract_and_save(1, (645, 280, 930, 588), 'assets/ui/dock/lily_cameo_portrait.png', True, 45)

    # Sheet 2: Seed Cabinet
    make_clean_seed_cabinet()
    extract_and_save(2, (110, 520, 275, 715), 'assets/ui/seeds/seed_packet_rose.png', True, 45)
    extract_and_save(2, (310, 520, 475, 715), 'assets/ui/seeds/seed_packet_lavender.png', True, 45)
    extract_and_save(2, (510, 520, 675, 715), 'assets/ui/seeds/seed_packet_sunflower.png', True, 45)
    extract_and_save(2, (735, 520, 875, 715), 'assets/ui/seeds/slot_locked.png', True, 45)

    # Sheet 3: Plot Info
    extract_and_save(3, (55, 165, 315, 460), 'assets/ui/plot_info/parchment_plot_card.png', True, 45)
    make_english_header_plaque()
    extract_and_save(3, (700, 205, 745, 285), 'assets/ui/plot_info/droplet_blue.png', True, 45)
    extract_and_save(3, (790, 205, 835, 285), 'assets/ui/plot_info/droplet_gray.png', True, 45)
    extract_and_save(3, (670, 330, 880, 420), 'assets/ui/plot_info/badge_pruned.png', True, 45)
    # The 4 TRUE growth stages from strip (y=570..665)
    extract_and_save(3, (80, 570, 155, 665), 'assets/ui/plot_info/stage_sprout.png', True, 45)
    extract_and_save(3, (165, 570, 245, 665), 'assets/ui/plot_info/stage_bush.png', True, 45)
    extract_and_save(3, (255, 570, 335, 665), 'assets/ui/plot_info/stage_bud.png', True, 45)
    extract_and_save(3, (345, 570, 425, 665), 'assets/ui/plot_info/stage_bloom.png', True, 45)
    extract_and_save(3, (440, 570, 525, 665), 'assets/ui/plot_info/stage_active_box.png', True, 45)

    # Sheet 4: Customer Orders
    make_english_orders_board()
    extract_and_save(4, (40, 580, 185, 715), 'assets/ui/orders/gift_deliver_btn.png', True, 45)
    extract_and_save(4, (190, 580, 330, 715), 'assets/ui/orders/pocket_watch.png', True, 45)
    extract_and_save(4, (405, 125, 545, 360), 'assets/ui/orders/portrait_emma.png', True, 45)
    extract_and_save(4, (580, 125, 720, 360), 'assets/ui/orders/portrait_harris.png', True, 45)
    extract_and_save(4, (755, 125, 895, 360), 'assets/ui/orders/portrait_nora.png', True, 45)
    extract_and_save(4, (370, 415, 510, 625), 'assets/ui/orders/portrait_sara.png', True, 45)
    extract_and_save(4, (520, 415, 660, 625), 'assets/ui/orders/portrait_thomas.png', True, 45)
    extract_and_save(4, (670, 415, 810, 625), 'assets/ui/orders/portrait_jack.png', True, 45)
    extract_and_save(4, (820, 415, 960, 625), 'assets/ui/orders/portrait_laila.png', True, 45)

    print("\n✓ ALL REFINED SPRITES EXTRACTED & SAVED SUCCESSFULLY!")

if __name__ == '__main__':
    main()
