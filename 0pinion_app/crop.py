from PIL import Image, ImageChops

def trim(im):
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

def trim_transparency(image_path):
    im = Image.open(image_path)
    # Get the bounding box of the non-transparent alpha channel
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
        im.save(image_path)
        print("Image cropped successfully")
    else:
        print("No cropping needed")

trim_transparency('assets/title.png')
