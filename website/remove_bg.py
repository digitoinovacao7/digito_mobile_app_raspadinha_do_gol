from PIL import Image

def remove_background(input_path, output_path, bg_color=(11, 18, 24), threshold=40):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        r, g, b, a = item
        # Calculate distance from background color
        dist = ((r - bg_color[0])**2 + (g - bg_color[1])**2 + (b - bg_color[2])**2)**0.5
        
        if dist < threshold:
            # Make fully transparent if very close to background
            new_data.append((255, 255, 255, 0))
        elif dist < threshold + 20:
            # Soft edge (partial transparency)
            alpha_factor = (dist - threshold) / 20.0
            new_data.append((r, g, b, int(255 * alpha_factor)))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

remove_background("public/logo.png", "public/logo_transparent.png")
