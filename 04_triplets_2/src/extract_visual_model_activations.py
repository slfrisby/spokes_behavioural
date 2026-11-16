# Get visual model activations for the images. Written with the assistance of Claude.

# N.B. Needs to run inside the thingsvision conda environment, so start with ctrl+shift+p > Python: Select interpreter > thingsvision. 
# If get_extractor fails, open Anaconda prompt and run:
# conda activate thingsvision
# python -m pip install "protobuf==3.20.3"

# %% ---------------------------------------------------------------------------
# STEP 1: Imports and setup
# -----------------------------------------------------------------------------

import os 

# get_extractor is the main thingsvision function. You give it the name of a
# model and it returns an "extractor": an object that can run images through
# that model and pull out features.
from thingsvision import get_extractor
 
# save_features writes the extracted features to a file on your computer.
from thingsvision.utils.storing import save_features
 
# ImageDataset reads images from a folder and prepares them for the model.
# DataLoader feeds those images to the model in small groups ("batches").
from thingsvision.utils.data import ImageDataset, DataLoader

# make output folder
os.makedirs('Z:\\Saskia\\spokes_behavioural\\04_triplets_2\\work\\vision_model_features', exist_ok = True)

 # %% ---------------------------------------------------------------------------
# STEP 2: Parameters
# -----------------------------------------------------------------------------
 
 # Which neural network to use
model_name = "simclr-rn50"
 
# Where the model comes from
source = "ssl"
 
# Which layer of the network to take features from (Step 4 shows how to list all layer names for any model)
module_name = "avgpool"
 
# How many images to process at once. Larger batches are faster but use more
# memory. If your computer runs out of memory, lower this number (e.g. 8).
batch_size = 8
 
# Choose where the computation runs. "cuda" means an NVIDIA graphics card (GPU),
# which is much faster. "cpu" is the normal processor, slower but always works.
# This line picks the GPU if one is available and otherwise falls back to CPU.
device = "cpu"

# %% ---------------------------------------------------------------------------
# STEP 3: Load the model
# -----------------------------------------------------------------------------
 
# Build the extractor. The first time you run this, the model's weights are
# downloaded from the internet, so it can take a little while and needs a
# connection.
extractor = get_extractor(
    model_name=model_name,  # which model to load (set above)
    source=source,          # which library to load it from (set above)
    device=device,          # run on GPU or CPU (set above)
    pretrained=True,        # use weights already trained on a large image
                            # dataset (ImageNet), rather than a blank network
)

# %% ---------------------------------------------------------------------------
# STEP 4 (optional): Look at the model's layers
# -----------------------------------------------------------------------------
 
# Prints the whole architecture of the model, including the name of every layer.
# Use this to choose a different module_name in Step 2. The names in brackets,
# like (features) followed by (10), combine into "features.10".
# Remove the "#" at the start of the next line to run it.
# extractor.show_model()

# %% ---------------------------------------------------------------------------
# STEP A5: Prepare the .png files of written words
# -----------------------------------------------------------------------------

# Point the script at the folder containing .png of written words. It can contain subfolders; thingsvision will
# find the images inside them. The r before the quote marks tells Python to
# treat backslashes literally, which matters for Windows paths.
root = 'Z:\\Saskia\\spokes_behavioural\\04_triplets_2\\src\\writtenword\\'
 
# Folder where the results will be saved
out_path = 'Z:\\Saskia\\spokes_behavioural\\04_triplets_2\\work\\vision_model_features\\writtenword\\'
 
# Create two objects: a dataset and a dataloader.  

# ImageDataset finds all the images in "root" and prepares each one for the model.
dataset = ImageDataset(
    root=root,                                    # folder of images (set above)
    out_path=out_path,                            # output folder; thingsvision
                                                  # also uses it to keep track of
                                                  # your image file names
    backend=extractor.get_backend(),              # tells the dataset which deep
                                                  # learning library the model
                                                  # uses (here, PyTorch)
    transforms=extractor.get_transformations(),   # the resizing, cropping and
                                                  # colour normalising this
                                                  # particular model expects
)
 
# DataLoader hands the images to the model in groups of "batch_size"
batches = DataLoader(
    dataset=dataset,                              # the images prepared above
    batch_size=batch_size,                        # images per group (set above)
    backend=extractor.get_backend(),              # same library as before
)

 # %% ---------------------------------------------------------------------------
# STEP A6: Extract the features
# -----------------------------------------------------------------------------
 
# Run every batch of images through the network and record the output of the
# layer named in module_name. This is the slow step, especially on a CPU.
features = extractor.extract_features(
    batches=batches,          # the images to process
    module_name=module_name,  # which layer's output to record
    flatten_acts=True,        # a convolutional layer's output is a stack of 2D
                              # grids per image. True flattens that into one
                              # long list of numbers per image, which is easier
                              # to analyse later.
)
 
# "features" is now a table of numbers: one row per image, one column per
# feature. Print its shape to check. You should see (number of images, number
# of features). For AlexNet at features.10 that is 43264 features
# per image (256 channels x 13 x 13).
print("Feature shape:", features.shape)

# %% ---------------------------------------------------------------------------
# STEP A7: Save the features to disk
# -----------------------------------------------------------------------------
 
# Write the features to the output folder. "npy" is NumPy's file format, which
# you can reload later in Python with numpy.load(). Other options include
# "txt" and "mat".
save_features(
    features,                 # the numbers to save
    out_path=out_path,        # folder to save into (set above)
    file_format="txt",        # file type
) 
print("Saved features to:", out_path)

# %% ---------------------------------------------------------------------------
# STEP B5: Prepare the .png files of images
# -----------------------------------------------------------------------------

root = 'Z:\\Saskia\\spokes_behavioural\\04_triplets_2\\src\\image\\'
 
# Folder where the results will be saved
out_path = 'Z:\\Saskia\\spokes_behavioural\\04_triplets_2\\work\\vision_model_features\\image\\'
 
# Create a dataset and a dataloader.  
dataset = ImageDataset(
    root=root,                                    
    out_path=out_path,                                                                     
    backend=extractor.get_backend(),                                                         
    transforms=extractor.get_transformations(),                                               
)
 
batches = DataLoader(
    dataset=dataset,                              
    batch_size=batch_size,                        
    backend=extractor.get_backend(),              
)

 # %% ---------------------------------------------------------------------------
# STEP A6: Extract the features
# -----------------------------------------------------------------------------
 
# Run every batch of images through the network and record the output of the
# layer named in module_name. This is the slow step, especially on a CPU.
features = extractor.extract_features(
    batches=batches,          # the images to process
    module_name=module_name,  # which layer's output to record
    flatten_acts=True,        # a convolutional layer's output is a stack of 2D
                              # grids per image. True flattens that into one
                              # long list of numbers per image, which is easier
                              # to analyse later.
)
 
# "features" is now a table of numbers: one row per image, one column per
# feature. Print its shape to check. You should see (number of images, number
# of features). For AlexNet at features.10 that is 43264 features
# per image (256 channels x 13 x 13).
print("Feature shape:", features.shape)

# %% ---------------------------------------------------------------------------
# STEP A7: Save the features to disk
# -----------------------------------------------------------------------------
 
# Write the features to the output folder. "npy" is NumPy's file format, which
# you can reload later in Python with numpy.load(). Other options include
# "txt" and "mat".
save_features(
    features,                 # the numbers to save
    out_path=out_path,        # folder to save into (set above)
    file_format="txt",        # file type
) 
print("Saved features to:", out_path)
 