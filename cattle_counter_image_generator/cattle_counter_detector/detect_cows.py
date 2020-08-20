#TODO clean up this script so that it doesn't use global variables
# you'll need to clone tensorflow to get the object_detection module 
import io
import scipy.misc
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import os 
import math
import tensorflow as tf
from object_detection.utils import label_map_util
from object_detection.utils import config_util
from object_detection.utils import visualization_utils as viz_utils
from object_detection.builders import model_builder
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("-i", "--image", type=str, required=True,
	help="path to input image for detections")
ap.add_argument("-o", "--output", type=str, required=True,
	help="path to the output image")
args = vars(ap.parse_args())

#TODO check if input is actually an image
input_image_path = args['image']
output_image_path = args['output']

DRONE_IMAGE_WIDTH = 4096
DRONE_IMAGE_HEIGHT = 2160

pipeline_config = 'fine_tuned_model/pipeline.config'

model_dir = 'fine_tuned_model/checkpoint/ckpt-0' 
configs = config_util.get_configs_from_pipeline_file(pipeline_config)
model_config = configs['model']
detection_model = model_builder.build(
      model_config=model_config, is_training=False)

# Restore checkpoint
ckpt = tf.compat.v2.train.Checkpoint(
      model=detection_model)
ckpt.restore(os.path.join('fine_tuned_model/checkpoint/ckpt-0'))


def get_model_detection_function(model):
  """Get a tf.function for detection."""

  @tf.function
  def detect_fn(image):
    """Detect objects in image."""

    image, shapes = model.preprocess(image)
    prediction_dict = model.predict(image, shapes)
    detections = model.postprocess(prediction_dict, shapes)

    return detections, prediction_dict, tf.reshape(shapes, [-1])

  return detect_fn

detect_fn = get_model_detection_function(detection_model)

#map labels for inference decoding
label_map_path = configs['eval_input_config'].label_map_path
label_map = label_map_util.load_labelmap(label_map_path)
categories = label_map_util.convert_label_map_to_categories(
    label_map,
    max_num_classes=label_map_util.get_max_label_map_index(label_map),
    use_display_name=True
)
category_index = label_map_util.create_category_index(categories)
label_map_dict = label_map_util.get_label_map_dict(label_map, use_display_name=True)


def get_detections_and_scores(image, threshold, x_offset, y_offset):
    (img_width, img_height) = image.size
    image_np = np.asarray(image).reshape(
        (img_height, img_width, 3)).astype(np.uint8)
    input_tensor = tf.convert_to_tensor(
        np.expand_dims(image_np, 0), dtype=tf.float32)
    detections, predictions_dict, shapes = detect_fn(input_tensor)

    boxes = detections['detection_boxes'][0].numpy()
    scores = detections['detection_scores'][0].numpy()
    object_detections = []
    object_scores = []
    for i in range(0, len(scores)):
        if(scores[i] > threshold):
            # move coordinates of box so that they apply in the larger image
            box_left = boxes[i][1] * DRONE_IMAGE_WIDTH + x_offset
            box_top = boxes[i][0] * DRONE_IMAGE_HEIGHT + y_offset
            box_right = boxes[i][3] * DRONE_IMAGE_WIDTH + x_offset
            box_bottom = boxes[i][2] * DRONE_IMAGE_HEIGHT + y_offset
            object_detections.append(
                [box_top, box_left, box_bottom, box_right]
            )
            object_scores.append(scores[i])

    return (object_detections, object_scores)

# detect all the cows in the stitched image by processing sections of the image
input_image = Image.open(input_image_path)
(img_width, img_height) = input_image.size
x_iterations = math.floor(img_width / 4096)
y_iterations = math.floor(img_width / 2160)

detections = []
scores = []

for i in range(0, x_iterations):
    for j in range(0, y_iterations):
        section = input_image.crop((
            (DRONE_IMAGE_WIDTH *  i),
            (DRONE_IMAGE_HEIGHT  * j),
            DRONE_IMAGE_WIDTH + (DRONE_IMAGE_WIDTH  * i),
            DRONE_IMAGE_HEIGHT + (DRONE_IMAGE_HEIGHT * j)
        ))
        section_detections, section_scores = get_detections_and_scores(
            section, 0.7, (DRONE_IMAGE_WIDTH *  i), (DRONE_IMAGE_HEIGHT  * j)
        )
        detections.extend(section_detections)
        scores.extend(section_scores)

image_np = np.asarray(input_image).reshape(
        (img_height, img_width, 3)).astype(np.uint8)

viz_utils.visualize_boxes_and_labels_on_image_array(
        image_np,
        np.array(detections),
        (np.zeros(len(detections)) + 1).astype(int),
        np.array(scores),
        category_index,
        use_normalized_coordinates=False,
        max_boxes_to_draw=200,
        min_score_thresh=.7,
        agnostic_mode=False,
)

annotated_image = Image.fromarray(image_np)
print('Number of cows: {num_cows}'.format(num_cows = len(detections)))
annotated_image.save(output_image_path)
