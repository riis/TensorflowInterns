
# Cattle Counter Detector

- The purpose of this program is to be able to detect more than 100 cows from 
a fully stitched image. Make sure that the stitched image you send in can be divided 
into sections of 4096 x 2160 

- First you need to install the tensorflow object detection library:
1. git clone https://github.com/tensorflow/models.git
2. cd models/research/
3.  protoc object_detection/protos/*.proto --python_out=.
4. cp object_detection/packages/tf2/setup.py .
5. python -m pip install .

- Then install numpy, PIL, argparse, and tensorflow using pip

- To run the program use: python3 detect_cows.py -i full_stitched_image.jpg -o output.jpg
