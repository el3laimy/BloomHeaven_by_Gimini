#!/usr/bin/env python3
import os
import sys
import shutil
from PIL import Image

INCOMING_DIR = '/home/el3laimy/Downloads/Assets'
PROJECT_ROOT = '/home/el3laimy/Downloads/finest-garden-bootstrap-0.0.1/finest-garden-prototype'

ASSET_MAP = {
    # Character - Idle Poses
    'lily_idle_front': {
        'dest': 'assets/character/frames/lily_idle_front.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_idle_back': {
        'dest': 'assets/character/frames/lily_idle_back.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_idle_side': {
        'dest': 'assets/character/frames/lily_idle_side.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },

    # Character - Walk Down Cycle (Full 4-Beats)
    'lily_walk_down_01': {
        'dest': 'assets/character/frames/lily_walk_down_01.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_down_pass1': {
        'dest': 'assets/character/frames/lily_walk_down_pass1.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_down_02': {
        'dest': 'assets/character/frames/lily_walk_down_02.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_down_pass2': {
        'dest': 'assets/character/frames/lily_walk_down_pass2.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },

    # Character - Walk Up Cycle (Full 4-Beats)
    'lily_walk_up_01': {
        'dest': 'assets/character/frames/lily_walk_up_01.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_up_02': {
        'dest': 'assets/character/frames/lily_walk_up_02.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_up_03': {
        'dest': 'assets/character/frames/lily_walk_up_03.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },

    # Character - Walk Side Cycle (Full 4-Beats)
    'lily_walk_side_01': {
        'dest': 'assets/character/frames/lily_walk_side_01.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_side_02': {
        'dest': 'assets/character/frames/lily_walk_side_02.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_side_03': {
        'dest': 'assets/character/frames/lily_walk_side_03.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_side_04': {
        'dest': 'assets/character/frames/lily_walk_side_04.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },

    # Character - Legacy frame fallbacks
    'lily_walk_stride': {
        'dest': 'assets/character/frames/lily_walk_stride.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_step': {
        'dest': 'assets/character/frames/lily_walk_step.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_walk_pass': {
        'dest': 'assets/character/frames/lily_walk_pass.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },

    # Character - Actions
    'lily_action_water': {
        'dest': 'assets/character/poses/action_water.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_action_plant': {
        'dest': 'assets/character/poses/action_plant.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_action_harvest': {
        'dest': 'assets/character/poses/action_harvest.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },
    'lily_action_celebrate': {
        'dest': 'assets/character/poses/action_celebrate.png',
        'type': 'character',
        'size': (256, 256),
        'feet_y': 240,
        'char_h': 194
    },

    # UI & Storybook Assets
    'parchment_orders_board': {
        'dest': 'assets/ui/orders/parchment_orders_board.png',
        'type': 'ui',
        'size': (420, 630)
    },
    'seed_cabinet_frame': {
        'dest': 'assets/ui/seeds/seed_cabinet_frame.png',
        'type': 'ui',
        'size': (560, 260)
    },
    'wood_gear_btn': {
        'dest': 'assets/ui/top_left/wood_gear_btn.png',
        'type': 'ui',
        'size': (128, 128)
    },
    'dock_base': {
        'dest': 'assets/ui/dock/dock_base.png',
        'type': 'ui',
        'size': (380, 80)
    },

    # Flowers
    'master_roselight': {
        'dest': 'assets/flowers/master_roselight.png',
        'type': 'flower',
        'size': (256, 256)
    }
}

def process_character_pose(im, spec):
    bbox = im.getbbox()
    if not bbox:
        return im
    feet_y = bbox[3]
    head_y = bbox[1]
    char_h = feet_y - head_y
    center_x = (bbox[0] + bbox[2]) / 2.0
    
    target_char_h = spec.get('char_h', 194)
    target_feet_y = spec.get('feet_y', 240)
    target_size = spec.get('size', (256, 256))
    
    scale = target_char_h / float(char_h)
    new_w = int(im.size[0] * scale)
    new_h = int(im.size[1] * scale)
    
    resized = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    new_feet_y = int(feet_y * scale)
    new_center_x = int(center_x * scale)
    
    paste_x = (target_size[0] // 2) - new_center_x
    paste_y = target_feet_y - new_feet_y
    
    canvas = Image.new('RGBA', target_size, (0, 0, 0, 0))
    canvas.paste(resized, (paste_x, paste_y), resized)
    return canvas

def process_generic_asset(im, spec):
    target_size = spec.get('size')
    if target_size and im.size != target_size:
        return im.resize(target_size, Image.Resampling.LANCZOS)
    return im

def run_ingestion():
    if not os.path.exists(INCOMING_DIR):
        print(f'[ERROR] Incoming directory {INCOMING_DIR} does not exist!')
        return 0

    files = sorted(os.listdir(INCOMING_DIR))
    processed_count = 0

    for fname in files:
        if not fname.lower().endswith(('.png', '.jpg', '.jpeg')):
            continue

        full_path = os.path.join(INCOMING_DIR, fname)
        base_name = os.path.splitext(fname)[0].lower()

        matched_key = None
        # Explicit user-named files or specific known timestamps
        if '09_37_29' in base_name:
            matched_key = 'lily_idle_front'
        elif '09_53_39' in base_name:
            matched_key = 'lily_walk_down_01'
        elif '11_59_41' in base_name:
            matched_key = 'lily_walk_up_01'
        elif '11_59_42' in base_name:
            matched_key = 'lily_idle_back'
        elif '11_59_43' in base_name:
            matched_key = 'lily_walk_up_02'
        elif '11_59_44' in base_name:
            matched_key = 'lily_walk_up_03'
        elif '11_52_40' in base_name and '(1)' in base_name:
            matched_key = 'lily_walk_down_01'
        elif '11_52_40' in base_name and '(2)' in base_name:
            matched_key = 'lily_walk_down_pass1'
        elif '11_52_40' in base_name and '(3)' in base_name:
            matched_key = 'lily_walk_down_02'
        elif '11_52_41' in base_name and '(4)' in base_name:
            matched_key = 'lily_walk_down_pass2'
        elif '12_22_03' in base_name and '(1)' in base_name:
            matched_key = 'lily_walk_side_01'
        elif '12_22_03' in base_name and '(2)' in base_name:
            matched_key = 'lily_walk_side_02'
        elif '12_22_03' in base_name and '(3)' in base_name:
            matched_key = 'lily_walk_side_03'
        elif '12_22_04' in base_name and '(4)' in base_name:
            matched_key = 'lily_walk_side_04'
        elif '12_25_55' in base_name and '(1)' in base_name:
            matched_key = 'lily_action_water'
        elif '12_25_55' in base_name and '(2)' in base_name:
            matched_key = 'lily_action_plant'
        elif '12_29_42' in base_name:
            matched_key = 'lily_action_celebrate'
        else:
            # Longest match first to avoid prefix collisions (e.g. walk_down_02 vs walk_down_01)
            for k in sorted(ASSET_MAP.keys(), key=lambda x: -len(x)):
                if k in base_name:
                    matched_key = k
                    break

        if not matched_key:
            print(f'[SKIP] Unknown asset mapping for: {fname}')
            continue

        spec = ASSET_MAP[matched_key]
        dest_rel = spec['dest']
        dest_full = os.path.join(PROJECT_ROOT, dest_rel)

        im = Image.open(full_path).convert('RGBA')
        if spec['type'] == 'character':
            res = process_character_pose(im, spec)
        else:
            res = process_generic_asset(im, spec)

        os.makedirs(os.path.dirname(dest_full), exist_ok=True)
        res.save(dest_full, 'PNG')
        print(f'[INGESTED] {fname} -> {dest_rel} (Size: {res.size}, Bbox: {res.getbbox()})')
        processed_count += 1

    return processed_count

if __name__ == '__main__':
    count = run_ingestion()
    print(f'\n[DONE] Ingested {count} assets successfully into Godot project.')

