from PIL import Image

def crop_transparent(image_path, output_path):
    img = Image.open(image_path)
    img = img.convert("RGBA")
    
    # Get the bounding box of the non-transparent area
    bbox = img.getbbox()
    
    if bbox:
        # Crop the image to the bounding box
        cropped_img = img.crop(bbox)
        
        # Save the cropped image
        cropped_img.save(output_path, "PNG")
        print(f"Cropped image saved to {output_path}")
    else:
        print("Image is entirely transparent.")

crop_transparent("website/public/logo_transparent.png", "website/public/favicon.png")
