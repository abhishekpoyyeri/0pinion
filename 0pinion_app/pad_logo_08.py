from PIL import Image

def zoom_out_logo(image_path):
    im = Image.open(image_path)
    old_width, old_height = im.size
    
    # 0.8x zoom out means the original image is 80% of the new canvas
    new_width = int(old_width * 1.25)
    new_height = int(old_height * 1.25)
    
    # Create a new transparent image
    new_im = Image.new("RGBA", (new_width, new_height), (0,0,0,0))
    
    # Paste the original image into the center
    paste_x = (new_width - old_width) // 2
    paste_y = (new_height - old_height) // 2
    new_im.paste(im, (paste_x, paste_y))
    
    new_im.save(image_path)
    print("Logo padded for 0.8x zoom out successfully")

zoom_out_logo('assets/logo.png')
