# script designed to generate many images of stops signs in differnet locations in the image
# and different sizes of stop signs 
from PIL import Image
import random
import os
import csv
#constants

# size of image captured from livestream on iphone 11
GENERATED_IMAGE_WIDTH = 724
GENERATED_IMAGE_HEIGHT = 322

# stop sign image used for image generation

stop_sign_image = Image.open('stop_sign.jpg')

# Randomly place the object on the image 
def generate_image(object_image, new_image_path):
    img = Image.new("RGB", (GENERATED_IMAGE_WIDTH, GENERATED_IMAGE_HEIGHT), "#FFFFFF")
    # Randomly resize the image
    random_size = int(random.randrange(int(0.1 * GENERATED_IMAGE_HEIGHT), int(0.9 * GENERATED_IMAGE_HEIGHT)))
    resized_image = object_image.resize((random_size, random_size))
    # randomly place object on the image but make sure the entire object fits on the image
    x_coordinate = int(random.randrange(0, GENERATED_IMAGE_WIDTH - random_size))
    y_coordinate = int(random.randrange(0, GENERATED_IMAGE_HEIGHT - random_size))
    img.paste(resized_image, (x_coordinate, y_coordinate))
    img.save(new_image_path)
    object_info = {
        "xmin": x_coordinate, 
        "ymin": y_coordinate,
        "xmax": x_coordinate + random_size,
        "ymax": y_coordinate + random_size,
        "width": random_size,
        "height": random_size
    }
    return object_info


def generate_training_images_with_annotations(num_images, object_image):
    with open('annotations.csv', 'wt') as annotation_file:
        annotation_writer = csv.writer(annotation_file, delimiter=',')
        annotation_writer.writerow(['filename','width','height','class','xmin','ymin','xmax','ymax'])
        os.makedirs('training_images',exist_ok=True)
        for i in range(0, num_images):
            image_name = 'image_{}.jpg'.format(i)
            info = generate_image(object_image, 'training_images/' + image_name)
            annotation_writer.writerow([
                image_name,
                info["width"],
                info['height'],
                'stop sign',
                info['xmin'],
                info['ymin'],
                info['xmax'],
                info['ymax']]
            )

generate_training_images_with_annotations(10, stop_sign_image)