# Takes tidy JATOS data and creates four embedding, each representing semantic structure
# estimated from one modality (written words, spoken words, images, natural sounds).

# Follows tidy_JATOS_data.R .

# Setup -------------------------------------------------------------------

# ensure that the paths to reticulate (which enables interfacing with python)
# are set correctly. For more information, see 
# https://knowledge-and-concepts-lab.github.io/tripletTools/articles/embedding_vignette.html#step-1-one-time-python-environment-setup
reticulate::use_condaenv(
  "triplet-embeddings",
  conda = "C:/Users/sf02/AppData/Local/anaconda3/condabin/conda.bat",
  required = TRUE
)

# set libraries
library(tripletTools)
library(imager)

# set filename variables
input_directory <- "derivatives"
input_triplet_filename <- "tidy_triplets"

# Load images for visualisation -------------------------------------------

# initialise a list to store image stimuli (useful for plotting later)
image_stimuli <- list()
# get list of images
image_list <- list.files('src/image/')
# load each one
for (i in c(1:length(image_list))){
  image_stimuli[[i]] <- load.image(paste('src/image/', image_list[i], sep = ""))
}

# Load and format data ----------------------------------------------------

data <- list()

# load written word data
data$written_word <- read.csv(paste(input_directory, "/", input_triplet_filename, "_written_word.csv", sep = ""))
# reformat it into a nested list with one data frame per participant
data$written_word <- split(data$written_word, data$written_word$worker_id)

# do the same for other modalities
data$spoken_word <- read.csv(paste(input_directory, "/", input_triplet_filename, "_spoken_word.csv", sep = ""))
data$spoken_word <- split(data$spoken_word, data$spoken_word$worker_id)

data$image <- read.csv(paste(input_directory, "/", input_triplet_filename, "_image.csv", sep = ""))
data$image <- split(data$image, data$image$worker_id)

data$sound <- read.csv(paste(input_directory, "/", input_triplet_filename, "_sound.csv", sep = ""))
data$sound <- split(data$sound, data$sound$worker_id)

# set all validation trials to be in the test set
for (i in c(1:length(data$written_word))){
  data$written_word[[i]]$sampleSet[data$written_word[[i]]$sampleAlg == "validation"] <- "test"
  data$spoken_word[[i]]$sampleSet[data$spoken_word[[i]]$sampleAlg == "validation"] <- "test"
  data$image[[i]]$sampleSet[data$image[[i]]$sampleAlg == "validation"] <- "test"
  data$sound[[i]]$sampleSet[data$sound[[i]]$sampleAlg == "validation"] <- "test"
}

# Estimate dimensionality of embedding ------------------------------------

dim_est <- list()

# do written words
dim_est$written_word <- estimate_dimensionality(
  triplet_list = data$written_word,
  dims         = 1:8,       # dimensionalities to evaluate
  n_restarts   = 10L,       # independent random restarts per d
  max_epochs   = 50000L,
  seed         = 42L
)

# repeat for other modalities
dim_est$spoken_word <- estimate_dimensionality(
  triplet_list = data$spoken_word,
  dims         = 1:8,       
  n_restarts   = 10L,      
  max_epochs   = 50000L,
  seed         = 42L
)

dim_est$image <- estimate_dimensionality(
  triplet_list = data$image,
  dims         = 1:8,       
  n_restarts   = 10L,       
  max_epochs   = 50000L,
  seed         = 42L
)

dim_est$sound <- estimate_dimensionality(
  triplet_list = data$sound,
  dims         = 1:8,       
  n_restarts   = 10L,       
  max_epochs   = 50000L,
  seed         = 42L
)

# to check the dimensionality, run dim_est$written_word$summary (or equivalent for other modalities).

# Here, we get 4D for visual modalities and 3D for auditory modalities.

# Embed using the best number of dimensions -------------------------------

embeddings <- list()

embeddings$written_word_triplet <- run_group_embedding_from_list(
  triplet_list = data$written_word,
  d            = 4L, 
  max_epochs   = 50000L
)

embeddings$spoken_word_triplet <- run_group_embedding_from_list(
  triplet_list = data$spoken_word,
  d            = 4L,
  max_epochs   = 50000L
)

embeddings$image_triplet <- run_group_embedding_from_list(
  triplet_list = data$image,
  d            = 4L,       
  max_epochs   = 50000L
)

embeddings$sound_triplet <- run_group_embedding_from_list(
  triplet_list = data$sound,
  d            = 4L,       
  max_epochs   = 50000L
)

# Check convergence  ------------------------------------------------------

plot(embeddings$written_word_triplet$history$epoch, embeddings$written_word_triplet$history$test_loss,
  type = "l", col = "steelblue",
  xlab = "Epoch", ylab = "Test loss",
  main = "Group embedding – training curve"
)

plot(embeddings$spoken_word_triplet$history$epoch, embeddings$spoken_word_triplet$history$test_loss,
  type = "l", col = "steelblue",
  xlab = "Epoch", ylab = "Test loss",
  main = "Group embedding – training curve"
)

plot(embeddings$image_triplet$history$epoch, embeddings$image_triplet$history$test_loss,
  type = "l", col = "steelblue",
  xlab = "Epoch", ylab = "Test loss",
  main = "Group embedding – training curve"
)

plot(embeddings$sound_triplet$history$epoch, embeddings$sound_triplet$history$test_loss,
  type = "l", col = "steelblue",
  xlab = "Epoch", ylab = "Test loss",
  main = "Group embedding – training curve"
)

# Save embeddings ---------------------------------------------------------

write.table(embeddings$written_word_triplet$embedding, file = 'work/written_word_triplet_embedding.txt', sep = ",", row.names = FALSE, col.names = FALSE)
write.table(embeddings$spoken_word_triplet$embedding, file = 'work/spoken_word_triplet_embedding.txt', sep = ",", row.names = FALSE, col.names = FALSE)
write.table(embeddings$image_triplet$embedding, file = 'work/image_triplet_embedding.txt', sep = ",", row.names = FALSE, col.names = FALSE)
write.table(embeddings$sound_triplet$embedding, file = 'work/sound_triplet_embedding.txt', sep = ",", row.names = FALSE, col.names = FALSE)

dim_est$written_word$summary
dim_est$spoken_word$summary
dim_est$image$summary
dim_est$sound$summary