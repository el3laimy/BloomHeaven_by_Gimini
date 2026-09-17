#!/usr/bin/env python3
"""
Automated Visual QA & Black-Frame Detector for BloomHaven.
Verifies rendered captures against empty/black buffer regressions:
- Resolution & dimensions
- Mean luminance (0-255)
- Near-black pixel percentage (RGB <= 5)
- Unique color count
- Gate criteria: Fail if >95% near-black, unique_colors < 5, or mean_lum < 1.0.
"""

import sys
import os
import json
from PIL import Image

def analyze_image(path):
    if not os.path.exists(path):
        return False, {"file": path, "error": "File not found"}
    
    try:
        im = Image.open(path).convert("RGB")
    except Exception as e:
        return False, {"file": path, "error": str(e)}

    w, h = im.size
    pixels = list(im.getdata())
    total = len(pixels)
    
    near_black = 0
    luminance_sum = 0.0
    color_set = set()
    
    for r, g, b in pixels:
        lum = 0.299 * r + 0.587 * g + 0.114 * b
        luminance_sum += lum
        if r <= 5 and g <= 5 and b <= 5:
            near_black += 1
        color_set.add((r, g, b))
        
    mean_lum = luminance_sum / total if total > 0 else 0.0
    pct_black = (near_black / total) * 100.0 if total > 0 else 100.0
    non_black = total - near_black
    unique_colors = len(color_set)
    
    passed = (pct_black < 95.0) and (unique_colors >= 5) and (mean_lum >= 1.0)
    verdict = "PASS" if passed else "FAIL"
    
    stats = {
        "file": os.path.basename(path),
        "path": path,
        "width": w,
        "height": h,
        "dimensions": f"{w}x{h}",
        "total_pixels": total,
        "near_black_pixels": near_black,
        "pct_near_black": round(pct_black, 2),
        "non_black_pixels": non_black,
        "mean_luminance": round(mean_lum, 2),
        "unique_colors": unique_colors,
        "passed": passed,
        "verdict": verdict
    }
    return passed, stats

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/visual_qa/black_frame_detector.py <image1> [image2 ...]")
        print("       python3 tools/visual_qa/black_frame_detector.py --json <image1> [image2 ...]")
        sys.exit(1)
        
    output_json = False
    args = sys.argv[1:]
    if "--json" in args:
        output_json = True
        args.remove("--json")
        
    all_passed = True
    results = []
    
    for p in args:
        passed, stats = analyze_image(p)
        if not passed:
            all_passed = False
        results.append(stats)
        
    if output_json:
        print(json.dumps(results, indent=2))
    else:
        print(f"{'Image File':<36} | {'Dimensions':<10} | {'Mean Lum':<8} | {'% Black':<8} | {'Colors':<8} | {'Verdict'}")
        print("-" * 90)
        for r in results:
            if "error" in r:
                print(f"{r['file']:<36} | ERROR: {r['error']}")
            else:
                print(f"{r['file']:<36} | {r['dimensions']:<10} | {r['mean_luminance']:<8.2f} | {r['pct_near_black']:<7.2f}% | {r['unique_colors']:<8} | {r['verdict']}")
        print("-" * 90)
        print(f"Overall Status: {'ALL PASS' if all_passed else 'FAILURES DETECTED'}")
        
    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
