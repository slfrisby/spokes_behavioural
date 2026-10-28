# compares embeddings (and RSMs) from models and from triplet judgements.


# Load all embeddings -----------------------------------------------------

image_model_embedding <- read.csv('./work/image_model_embedding.txt', header = FALSE)
image_triplet_embedding <- read.csv('./work/image_triplet_embedding.txt', header = FALSE)
sound_model_embedding <- read.csv('./work/sound_model_embedding.txt', header = FALSE)
sound_triplet_embedding <- read.csv('./work/sound_triplet_embedding.txt', header = FALSE)

# ca