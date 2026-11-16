# Takes tidy JATOS data and creates embeddings - one representing semantic 
# structure estimated from triplet judgements of pictures, and one representing 
# semantic structure estimated from triplet judgements of natural sounds. 

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

# initialise a list to store stimuli
image_stimuli <- list()
# get list of images
image_list <- list.files('src/img/')
# load each one
for (i in c(1:length(image_list))){
  image_stimuli[[i]] <- load.image(paste('src/img/', image_list[i], sep = ""))
}

# Load and format data ----------------------------------------------------

# load image data
image_data <- read.csv(paste(input_directory, "/", input_triplet_filename, "_image.csv", sep = ""))
# reformat it into a nested list with one data frame per participant
image_data <- split(image_data, image_data$worker_id)

# do the same with sound data
sound_data <- read.csv(paste(input_directory, "/", input_triplet_filename, "_sound.csv", sep = ""))
# reformat it into a nested list with one data frame per participant
sound_data <- split(sound_data, sound_data$worker_id)

# set all validation trials to be in the test set
for (i in c(1:length(image_data))){
  image_data[[i]]$sampleSet[image_data[[i]]$sampleAlg == "validation"] <- "test"
}
for (i in c(1:length(sound_data))){
  sound_data[[i]]$sampleSet[sound_data[[i]]$sampleAlg == "validation"] <- "test"
}

# Estimate dimensionality of embedding ------------------------------------

# do images (using default parameters)
image_dim_est <- estimate_dimensionality(
  triplet_list = image_data,
  dims         = 1:8,       # dimensionalities to evaluate
  n_restarts   = 10L,       # independent random restarts per d
  max_epochs   = 50000L,
  seed         = 42L
  )

# do sounds (using default parameters)
sound_dim_est <- estimate_dimensionality(
  triplet_list = sound_data,
  dims         = 1:8,       # dimensionalities to evaluate
  n_restarts   = 10L,       # independent random restarts per d
  max_epochs   = 50000L,
  seed         = 42L
)

# Embed using the best number of dimensions -------------------------------

image_embedding <- run_group_embedding_from_list(
  triplet_list = image_data,
  d            = 4L,       # number of dimensions
  max_epochs   = 50000L
)

sound_embedding <- run_group_embedding_from_list(
  triplet_list = sound_data,
  d            = 4L,       # number of dimensions
  max_epochs   = 50000L
)

# Check convergence  ------------------------------------------------------

# if the models have not flattened well before max_epochs, max_epochs needs to be increased.

plot(image_embedding$history$epoch, image_embedding$history$test_loss,
     type = "l", col = "steelblue",
     xlab = "Epoch", ylab = "Test loss",
     main = "Group embedding – training curve")

plot(sound_embedding$history$epoch, sound_embedding$history$test_loss,
     type = "l", col = "steelblue",
     xlab = "Epoch", ylab = "Test loss",
     main = "Group embedding – training curve")

# visualise the embedding

plot_pics(image_embedding$embedding[, c(1,2)], 
  image_stimuli,
  xlim = c(-0.5,0.5),
  ylim = c(-0.5,0.5),
  psize = 0.04,
  xlab  = "Dimension 1",
  ylab  = "Dimension 2",
  main  = "Group embedding")

plot_pics(sound_embedding$embedding[, c(1,2)], 
  image_stimuli,
  psize = 0.04,
  xlab  = "Dimension 1",
  ylab  = "Dimension 2",
  main  = "Group embedding")


# Save embeddings ---------------------------------------------------------

write.table(image_embedding$embedding, file = 'work/image_triplet_embedding.txt', sep = ",", row.names = FALSE, col.names = FALSE)
write.table(sound_embedding$embedding, file = 'work/sound_triplet_embedding.txt', sep = ",", row.names = FALSE, col.names = FALSE)

# check holdout accuracy

# check interrater reliability


# "interpret" dimensions


# Work in progress --------------------------------------------------------



# predict within modality 
pred_image_from_image <- rep(0, times = length(image_data))
for (i in c(1:length(image_data))){
  pred_image_from_image[i] <- get.hoacc(image_embedding$embedding, image_data[[i]])
}
mean(pred_image_from_image)

pred_sound_from_sound <- rep(0, times = length(sound_data))
for (i in c(1:length(sound_data))){
  pred_sound_from_sound[i] <- get.hoacc(sound_embedding$embedding,sound_data[[i]])
}
mean(pred_sound_from_sound)

# predict across modality
pred_sound_from_image <- rep(0, times = length(sound_data))
for (i in c(1:length(sound_data))){
  pred_sound_from_image[i] <- get.hoacc(image_embedding$embedding, sound_data[[i]])
}
mean(pred_sound_from_image)

pred_image_from_sound <- rep(0, times = length(image_data))
for (i in c(1:length(image_data))){
  pred_image_from_sound[i] <- get.hoacc(sound_embedding$embedding,image_data[[i]])
}
mean(pred_image_from_sound)

# check validation trials
image_validation <- make.vmat(image_data)$majority
image_validation
mean(image_validation$pmaj)

sound_validation <- make.vmat(sound_data)$majority
sound_validation
mean(sound_validation$pmaj)

