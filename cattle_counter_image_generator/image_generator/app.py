from PIL import Image
from collections import namedtuple
import sys
import getopt
from getopt import GetoptError
import math
import random 
import os 
# constants 
DRONE_IMAGE_WIDTH = 4096
DRONE_IMAGE_HEIGHT = 2160
cow_image = Image.open('assets/cow.jpg')
grass_image = Image.open('assets/grass.jpg')
Point = namedtuple('Point', ['x','y'])

def main(argv):
    try:
        opts, args = getopt.getopt(
            argv,
            "w:h:",
            [
                "grid_width=",
                "grid_height="
            ]
        )
        if(len(opts) < 2):
           raise GetoptError("")
    except getopt.GetoptError:
        print("python3 app.py -w <grid_width in  drone images> -h <grid_height in drone images>")
        sys.exit(1)

    grid_width = 0
    grid_height = 0

    for opt, arg in opts:
        if(opt == '-w'):
            grid_width = int(arg)
        elif(opt == '-h'):
            grid_height = int(arg)

    if(grid_width == 0 or grid_height == 0):
        raise Exception("Can't have grid of size 0x0. grid size is in number of drone images")
    
    generate_drone_images(grid_width, grid_height)
    
def generate_drone_images(grid_width, grid_height):
    image_width = DRONE_IMAGE_WIDTH * grid_width
    image_height = DRONE_IMAGE_HEIGHT * grid_height
    img = Image.new("RGB", (image_width, image_height), "#000000")
    place_background(img, grass_image)
    cow_image_width, cow_image_height = cow_image.size
    randomly_place_object(
        img,
        cow_image, 
        0.2, 
        .1 * cow_image_width, 
        .1 * cow_image_height
    )
    img.show()
    make_dir_if_not_exists('output')
    split_into_individual_drone_images(img, 'output')
    img.save('full.jpg')

def place_background(img, background_tile):
    background_width, background_height = background_tile.size
    img_width, img_hieght = img.size
    num_x_iterations = math.ceil(
        float(img_width) / float(background_width)
    )
    num_y_iterations = math.ceil(
        float(img_hieght) / float(background_height)
    )
    x_offset = 0 
    y_offset = 0
    for i in range(0, num_x_iterations):
        for j in range(0, num_y_iterations):
            img.paste(background_tile, (x_offset, y_offset))
            y_offset += background_height
        x_offset += background_width
        y_offset = 0

def randomly_place_object(img, object_img, object_background_ratio, x_offset=0, y_offset=0):
    obj_img_width, obj_img_height = object_img.size
    img_width, img_height = img.size
    # region of image where an object can be placed will be placed in  center of the region
    region_width = obj_img_width 
    region_height = obj_img_height
    num_x_iterations = math.ceil(
        float(img_width) / float(region_width)
    )
    num_y_iterations = math.ceil(
        float(img_height) / float(region_height)
    )

    possible_object_locations = []
    for i in range(0, num_x_iterations):
        for j in range(0, num_y_iterations):
            point = Point(
                int(x_offset),
                int(y_offset)
            )
            possible_object_locations.append(point)
            y_offset += obj_img_height
        y_offset = 0 
        x_offset += obj_img_width
    
    # shuffle the list so the objects are randomly placed
    random.shuffle(possible_object_locations)
    random.shuffle(possible_object_locations)
    num_objects = math.floor(len(possible_object_locations) * object_background_ratio)
    print("Number of objects in image:{num_objects}".format(num_objects= num_objects))
    placed_images = []
    for i in range(0, num_objects):
        img.paste(
            object_img,
            (int(possible_object_locations[i].x), int(possible_object_locations[i].y))
        )

def split_into_individual_drone_images(img, output_dir, overlap = 0.9):
    img_width, img_height = img.size
    num_x_iterations = 1 + math.floor(
        (float(img_width) - float(DRONE_IMAGE_WIDTH)) / (float((1-overlap)) * float(DRONE_IMAGE_WIDTH))
    )
    num_y_iterations = 1 + math.floor(
        (float(img_height) - float(DRONE_IMAGE_HEIGHT)) / (float((1-overlap)) * float(DRONE_IMAGE_HEIGHT))
    )
    top = 0
    bottom = DRONE_IMAGE_HEIGHT
    left = 0
    right = DRONE_IMAGE_WIDTH
    for i in range(0, num_x_iterations):    
        for j in range(0, num_y_iterations):
            cropped_image = img.crop((
                left + (DRONE_IMAGE_WIDTH * (1-overlap) * i),
                top + (DRONE_IMAGE_HEIGHT * (1-overlap) * j),
                right + (DRONE_IMAGE_WIDTH * (1-overlap) * i),
                bottom + (DRONE_IMAGE_HEIGHT * (1-overlap) * j)
            ))
            cropped_image.save(output_dir + '/{x}_{y}.jpg'.format(x = i, y = j))

def make_dir_if_not_exists(dir):
    if not os.path.exists(dir):
        os.makedirs(dir)

if __name__ == "__main__":
    main(sys.argv[1:])