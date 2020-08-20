
# Cattle Counter Image Generator 

- To run the script use the following command: 
- python3 app.py -w 2 -h 2 
- w is the width in images the size of 4096, 2160 to use and h is the height of the grid. 
- The default for the generator is to generate drone images with 90% overlap to be used for stitching with OpenCV
- You can change this in the split_into_individual_drone_images function
- The output of this program should be a folder called output containing the individual drone images
    and an image called full.jpg showing the fully generated map of cows. 

