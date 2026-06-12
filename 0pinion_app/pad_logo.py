from PIL import Image

def zoom_out_logo(image_path):
    im = Image.open(image_path)
    old_width, old_height = im.size
    
    # 0.5x zoom out means the original image is 50% of the new canvas
    new_width = old_width * 2
    new_height = old_height * 2
    
    # Create a new transparent image
    new_im = Image.new("RGBA", (new_width, new_height), (0,0,0,0))
    
    # Paste the original image into the center
    paste_x = (new_width - old_width) // 2
    paste_y = (new_height - old_height) // 2
    new_im.paste(im, (paste_x, paste_y))
    
    new_im.save(image_path)
    print("Logo padded for 0.5x zoom out successfully")

zoom_out_logo('assets/logo.png')
