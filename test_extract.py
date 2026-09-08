import sys
from PIL import Image, ImageDraw, ImageFilter, ImageMath
import os

src_path = 'assets/character/sheets/lily_game_ready_sheet.jpg'
out_dir = 'assets/character/lily_production'
os.makedirs(out_dir, exist_ok=True)

print("Loading image...")
img = Image.open(src_path).convert("RGBA")
w, h = img.size
pixels = img.load()

# 1. Create a mask of non-black pixels
mask = [[0 for _ in range(w)] for _ in range(h)]
for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        # Ignore text labels which are also bright. We'll filter them by size or position.
        # Background is black, let's say threshold > 25
        if max(r, g, b) > 25:
            mask[y][x] = 1

# 2. Find connected components using BFS
visited = [[False for _ in range(w)] for _ in range(h)]
components = []

print("Finding components...")
for y in range(h):
    for x in range(w):
        if mask[y][x] == 1 and not visited[y][x]:
            # Start BFS
            comp_pixels = []
            queue = [(x, y)]
            visited[y][x] = True
            
            while queue:
                cx, cy = queue.pop(0)
                comp_pixels.append((cx, cy))
                
                # Check neighbors
                for dx, dy in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        if mask[ny][nx] == 1 and not visited[ny][nx]:
                            visited[ny][nx] = True
                            queue.append((nx, ny))
                            
            if len(comp_pixels) > 500: # Filter out small noise and text
                components.append(comp_pixels)

print(f"Found {len(components)} components.")

# Sort components roughly top-to-bottom, left-to-right
components.sort(key=lambda c: (min(p[1] for p in c), min(p[0] for p in c)))

# 3. Extract and clean each component
for i, comp in enumerate(components):
    xs = [p[0] for p in comp]
    ys = [p[1] for p in comp]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    
    comp_w = max_x - min_x + 1
    comp_h = max_y - min_y + 1
    
    # Filter out text labels which are wide and short
    if comp_w > 50 and comp_h < 30:
        continue
        
    part_img = Image.new("RGBA", (comp_w, comp_h), (0, 0, 0, 0))
    p_pixels = part_img.load()
    
    for px, py in comp:
        r, g, b, a = pixels[px, py]
        # Defringing: if pixel is near black (edge), we boost its brightness based on neighbors or just clamp alpha
        # Simple high-quality alpha extraction:
        brightness = max(r, g, b)
        if brightness < 50:
            # Semi-transparent edge
            alpha = int((brightness - 25) * (255 / 25.0))
            alpha = max(0, min(255, alpha))
            
            # Boost color to prevent black halo
            if brightness > 0:
                factor = 50.0 / max(1, brightness)
                r = min(255, int(r * factor))
                g = min(255, int(g * factor))
                b = min(255, int(b * factor))
            
            p_pixels[px - min_x, py - min_y] = (r, g, b, alpha)
        else:
            p_pixels[px - min_x, py - min_y] = (r, g, b, 255)
            
    # Save the raw extracted part for inspection
    part_img.save(os.path.join(out_dir, f"part_{i}.png"))
    
print("Done.")
