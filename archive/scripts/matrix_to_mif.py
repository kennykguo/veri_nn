import csv

# Parameters
depth = 3920     # 5 images with 784 pixels each
width = 8        # 8 bits per pixel

with open('matrix.mif', 'w') as mif_file, open('train.csv', 'r') as csv_file:
    # Load pixel data from CSV
    reader = csv.reader(csv_file)
    next(reader)  # Skip header row
    
    address = 0
    for i, row in enumerate(reader):
        if i >= 5:  # Only process first 5 images
            break
        pixels = row[1:]  # Skip the label column
        for pixel in pixels:
            # Convert pixel to hex, pad with six zeros to make it 8 digits
            hex_pixel = f"{int(pixel):02X}".zfill(8)
            mif_file.write(f"{hex_pixel}\n")
            address += 1
    
    # Fill remaining memory with zeros if needed
    while address < depth:
        mif_file.write("00000000\n")
        address += 1
