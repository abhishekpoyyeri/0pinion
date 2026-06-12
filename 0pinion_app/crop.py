from PIL import Image

def trim_transparency(image_path):
    im = Image.open(image_path)
    if im.mode != 'RGBA':
        im = im.convert('RGBA')
    # Get the alpha channel
    alpha = im.getchannel('A')
    # Threshold the alpha channel to ignore faint border noise
    threshold_alpha = alpha.point(lambda p: 255 if p > 10 else 0)
    bbox = threshold_alpha.getbbox()
    if bbox:
        im = im.crop(bbox)
        im.save(image_path)
        print(f"Image cropped successfully. New size: {im.size}")
    else:
        print("No cropping needed")

trim_transparency('assets/title.png')
