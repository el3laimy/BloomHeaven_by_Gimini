#!/usr/bin/env python3
import os
import glob
from PIL import Image

def audit_assets():
    all_files = glob.glob('assets/**/*', recursive=True)
    images = [f for f in all_files if f.endswith(('.png', '.jpg', '.jpeg', '.webp')) and not f.endswith('.import')]
    
    text_content = ''
    for ext in ('.gd', '.tscn', '.json'):
        for path in glob.glob('scripts/**/*' + ext, recursive=True) + glob.glob('scenes/**/*' + ext, recursive=True) + glob.glob('data/**/*' + ext, recursive=True):
            try:
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    text_content += f.read() + ' '
            except Exception:
                pass

    report = []
    report.append('# 🔍 BloomHaven Master Asset Audit (Phase 0)')
    report.append('| Path | Resolution | Size (KB) | In-Engine Status | Classification |')
    report.append('|---|---|---|---|---|')

    summary = {'Approved': 0, 'Needs Fix': 0, 'Unused/Archive': 0, 'Reference Only': 0}

    for img_path in sorted(images):
        size_kb = round(os.path.getsize(img_path) / 1024.0, 1)
        try:
            with Image.open(img_path) as im:
                res = f"{im.width}x{im.height}"
        except Exception:
            res = "Unknown"

        base = os.path.basename(img_path)
        is_used = (base in text_content) or (img_path in text_content)

        if is_used:
            classification = 'Approved'
            summary['Approved'] += 1
        elif any(k in img_path for k in ['Lily_Source', 'rig_preview', 'sheets', 'test_crops', 'poses', 'Lily_Source_Backup']):
            classification = 'Reference Only'
            summary['Reference Only'] += 1
        else:
            classification = 'Unused / Archive'
            summary['Unused/Archive'] += 1

        import_exists = os.path.exists(img_path + '.import')
        engine_status = 'Imported' if import_exists else 'Missing .import'

        report.append(f"| `{img_path}` | {res} | {size_kb} | {engine_status} | **{classification}** |")

    report.append('\n## 📊 Summary')
    report.append(f"- **Total Image Assets Scanned:** {len(images)}")
    report.append(f"- **Active & Approved in Runtime:** {summary['Approved']}")
    report.append(f"- **Reference Only / Source Art:** {summary['Reference Only']}")
    report.append(f"- **Unused Candidates for Cleanup:** {summary['Unused/Archive']}")

    os.makedirs('docs', exist_ok=True)
    with open('docs/ASSET_AUDIT_REPORT.md', 'w', encoding='utf-8') as f:
        f.write('\n'.join(report))

    print(f"Asset Audit Complete. {len(images)} assets audited. Report saved to docs/ASSET_AUDIT_REPORT.md")
    print("Summary:", summary)

if __name__ == '__main__':
    audit_assets()
