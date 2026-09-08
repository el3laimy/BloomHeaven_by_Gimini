from PIL import Image
import os

base_dir = '/home/el3laimy/.gemini/antigravity-ide/brain/eb1af34d-36d1-4c02-afee-20db3b1389ab/.user_uploaded/'

# Let's inspect images and find the visual components
sheets = {
    'sheet0': base_dir + 'media_1788468908645.jpg',
    'sheet1': base_dir + 'media_1788468908673.jpg',
    'sheet2': base_dir + 'media_1788468908703.jpg',
    'sheet3': base_dir + 'media_1788468908726.jpg',
    'sheet4': base_dir + 'media_1788468908753.jpg'
}

for k, v in sheets.items():
    im = Image.open(v)
    print(f'{k}: {im.size}')
