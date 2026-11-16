# compares embeddings (and RSMs) from models and from triplet judgements.

# Setup -------------------------------------------------------------------

# set libraries
library(tripletTools)
library(imager)
library(stringr)
library(ggplot2)

# get functions
plot_similarity_matrix <- dget("./src/plot_similarity_matrix.R")
add_stars <- dget("./src/add_stars.R")

# set filename variables
input_directory <- "derivatives"
input_triplet_filename <- "tidy_triplets"

# Load all data -----------------------------------------------------

# load embeddings

embeddings <- list()

# load low-level model features
embeddings$written_word_model <- read.csv('./work/writtenword_features.txt', header = FALSE)
embeddings$spoken_word_model <- read.csv('./work/spokenword_features.txt', header = FALSE)
embeddings$image_model <- read.csv('./work/image_features.txt', header = FALSE)
embeddings$sound_model <- read.csv('./work/sound_features.txt', header = FALSE)

# load embeddings
embeddings$written_word_triplet <- read.csv('./work/written_word_triplet_embedding.txt', header = FALSE)
embeddings$spoken_word_triplet <- read.csv('./work/spoken_word_triplet_embedding.txt', header = FALSE)
embeddings$image_triplet <- read.csv('./work/image_triplet_embedding.txt', header = FALSE)
embeddings$sound_triplet <- read.csv('./work/sound_triplet_embedding.txt', header = FALSE)

# load stimuli names as a character vector
stimuli <- readLines('./src/stimuli.csv')

# convert to data frames
for (e in c(1:length(embeddings))){
  embeddings[[e]] <- as.data.frame(embeddings[[e]], row.names = stimuli)
}

# sort the rows by category. Load category indices
categories <- read.csv('./work/category_index.csv', header = FALSE)
# transpose to a column vector
categories <- t(categories)

# and sort
for (e in c(1:length(embeddings))){
  embeddings[[e]] <- embeddings[[e]][order(categories[,1]),]
}

# then load all triplet data

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


# Load images for visualisation -------------------------------------------

# initialise a list to store stimuli
image_stimuli <- list()
# get list of images
image_list <- list.files('src/image/')
# load each one
for (i in c(1:length(image_list))){
  image_stimuli[[i]] <- load.image(paste('./src/image/', image_list[i], sep = ""))
}

# Test 1: Do the RSMs correlate? ------------------------------------------

# Initialise output variables
RSM <- list()
RSMsize <- dim(embeddings$written_word_model)[1]

RSM$written_word_model <- matrix(0, RSMsize, RSMsize)
RSM$spoken_word_model <- matrix(0, RSMsize, RSMsize)
RSM$image_model <- matrix(0, RSMsize, RSMsize)
RSM$sound_model <- matrix(0, RSMsize, RSMsize)

RSM$written_word_triplet <- matrix(0, RSMsize, RSMsize)
RSM$spoken_word_triplet <- matrix(0, RSMsize, RSMsize)
RSM$image_triplet <- matrix(0, RSMsize, RSMsize)
RSM$sound_triplet <- matrix(0, RSMsize, RSMsize)

# calculate RSMs
for (r in c(1:RSMsize)){
  for (c in c(1:RSMsize)){
    
    RSM$written_word_model[r,c] <- cor(as.numeric(embeddings$written_word_model[r,]),as.numeric(embeddings$written_word_model[c,]))
    RSM$spoken_word_model[r,c] <- cor(as.numeric(embeddings$spoken_word_model[r,]),as.numeric(embeddings$spoken_word_model[c,]))
    RSM$image_model[r,c] <- cor(as.numeric(embeddings$image_model[r,]),as.numeric(embeddings$image_model[c,]))
    RSM$sound_model[r,c] <- cor(as.numeric(embeddings$sound_model[r,]),as.numeric(embeddings$sound_model[c,]))
    
    RSM$written_word_triplet[r,c] <- cor(as.numeric(embeddings$written_word_triplet[r,]),as.numeric(embeddings$written_word_triplet[c,]))
    RSM$spoken_word_triplet[r,c] <- cor(as.numeric(embeddings$spoken_word_triplet[r,]),as.numeric(embeddings$spoken_word_triplet[c,]))
    RSM$image_triplet[r,c] <- cor(as.numeric(embeddings$image_triplet[r,]),as.numeric(embeddings$image_triplet[c,]))
    RSM$sound_triplet[r,c] <- cor(as.numeric(embeddings$sound_triplet[r,]),as.numeric(embeddings$sound_triplet[c,]))
  }
}

# get a lower triangle filter (applying this to each RSM will get just the lower triangle, which can then be correlated)
lt <- lower.tri(RSM$written_word_model)

# calculate all the correlations
all_correlations <- matrix(0,length(embeddings),length(embeddings))
for (r in c(1:length(embeddings))){
  for (c in c(1:length(embeddings))){
    all_correlations[r,c] <- cor(RSM[[r]][lt], RSM[[c]][lt])
  }
}
all_correlations

# plot

# set axis labels
model_names <- c("Written words (low-level)", "Spoken words (low-level)", "Images (low-level)", "Sounds (low-level)", "Written words (semantic)", "Spoken words (semantic)", "Images (semantic)", "Sounds (semantic)")

# plot each RSM
for (e in c(1:length(embeddings))){
  p <- plot_similarity_matrix(RSM[[e]],show_numbers = FALSE)
  p
  # set filename
  fname <- paste('./derivatives/figures/RSM_', model_names[e], '.png', sep = "")
  fname <- gsub(" ", "_", fname, fixed = TRUE)
  ggsave(
    filename = fname,                     # File name
    plot     = p,                         # Which plot object to save.
    width    = 8,                         # Width...
    height   = 8,                         # ...and height...
    units    = "in",                      # ...in inches ("cm" and "mm" also work).
    dpi      = 300                        # Resolution: 300 is standard for
  )                                       # publication. Ignored for .pdf/.svg.
}

# plot correlations between RSMs
p <- plot_similarity_matrix(all_correlations, row_names = model_names, col_names = model_names)
p
# save
ggsave(
  filename = './derivatives/figures/correlations_between_RDMs.png',  # File name
  plot     = p,                         # Which plot object to save.
  width    = 8,                         # Width...
  height   = 8,                         # ...and height...
  units    = "in",                      # ...in inches ("cm" and "mm" also work).
  dpi      = 300                        # Resolution: 300 is standard for
)                                       # publication. Ignored for .pdf/.svg.


# Test 3: Predict one from another ----------------------------------------

# the task here is predicting triplets, so we are really testing to see whether (a)
# the semantic embeddings are comparable, and (b) the "unimodal embeddings do
# anywhere near as well as the "semantic" ones.

# get an index of which embeddings are triplet embeddings
embedding_names <- names(embeddings)
istriplet <- str_detect(names(embeddings),"triplet")

# initialise array - the rows will be the models used for training, the columns will be used for testing, and the z-direction is the number of participants
predictions <- array(NA, dim = c(length(embeddings),length(embeddings), length(data[[1]])))

# initialise matrix for testing whether there is a significant difference in predictive power between embeddings
significance <- list()
significance$triplet_vs_triplet <- matrix(NA, length(embeddings), length(embeddings))
significance$triplet_vs_model <- matrix(NA, length(embeddings), length(embeddings))

# for each kind of training embedding
for (r in c(1:length(embeddings))){
  # for each kind of testing data
  for (c in c(1:length(embeddings))){
    
    # if these data are triplet data (i.e. suitable to use for testing)
    if (istriplet[c]){
      # use the embedding in that row for training and the data in that column for testing.
      
      # loop over participants
      for (p in c(1:length(data[[1]]))){
        # get prediction accuracy for each person
        predictions[r,c,p] <- get.hoacc(embeddings[[r]], data[[c - 4]][[p]])
      }
    }
  }
}

# show the average predictions
meanpredictions <- apply(predictions, c(1,2), mean)
meanpredictions

# plot them
p <- plot_similarity_matrix(meanpredictions[,5:8], row_names = model_names, col_names = model_names[5:8], limits = c(0,1))
p

# stats
for (r in c(1:length(embeddings))){
  # for each kind of testing data
  for (c in c(1:length(embeddings))){
    # if both these data are triplet data
    if (istriplet[r]){
      if (istriplet[c]){
        
        # test for a significant difference between that model tested on its own modality of data and the model tested on another modality of data
        stats <- t.test(predictions[r,c,], predictions[r,r,])
        significance$triplet_vs_triplet[r,c] <- stats$p.value
        
        # test for a significant difference between predictions with the triplet embedding and predictions with the corresponding model embedding
        stats <- t.test(predictions[r,c,], predictions[(r - 4), c, ])
        significance$triplet_vs_model[r,c] <- stats$p.value
        
      }
    }
  }
}
# control the false discovery rate
significance$triplet_vs_triplet <- matrix(p.adjust(significance$triplet_vs_triplet, method = "fdr"), length(embeddings), length(embeddings))
significance$triplet_vs_model <- matrix(p.adjust(significance$triplet_vs_model, method = "fdr"), length(embeddings), length(embeddings))

# inspect
significance$triplet_vs_triplet
significance$triplet_vs_triplet < 0.05
significance$triplet_vs_model
significance$triplet_vs_model < 0.05

# add stars to show where the triplets differ in predictive power
s1 <- significance$triplet_vs_model < 0.05
s1 <- s1[,5:8]
s2 <- significance$triplet_vs_triplet < 0.05
s2 <- s2[,5:8]
p <- add_stars(add_stars(p, s1, '*'), s2, '†')

# save
ggsave(
  filename = './derivatives/figures/predictions.png',  # File name
  plot     = p,                         # Which plot object to save.
  width    = 8,                         # Width...
  height   = 8,                         # ...and height...
  units    = "in",                      # ...in inches ("cm" and "mm" also work).
  dpi      = 300                        # Resolution: 300 is standard for
)                                       # publication. Ignored for .pdf/.svg.


# Test 4: Predict "majority votes" ----------------------------------------

# Rationale:
# Sometimes participants disagree about which is the right answer for a triplet. Tim writes (slack):
# "Imagine that, for all triplets, about 70% of participants agree on the "winning" candidate.
# If you use your embedding to predict EACH INDIVIDUAL PARTICIPANT'S DECISION on the validation
# triplets, then you can't do better than 70%, because that is the level of inter-subject
# agreement. However, your embedding COULD in principle successfully predict which 
# option is the majority-vote winner with 100% accuracy."
# So inspect this for the validation triplets.

# make a validation matrix containing each type of data 
vmat <- list()

vmat$written_word_triplet <- make.vmat(data$written_word)[[1]]
vmat$spoken_word_triplet <- make.vmat(data$spoken_word)[[1]]
vmat$image_triplet <- make.vmat(data$image)[[1]]
vmat$sound_triplet <- make.vmat(data$sound)[[1]]

# initialise an output matrix

majority_vote_predictions <- matrix(NA, length(embeddings),length(embeddings))

# for each kind of training embedding
for (r in c(1:length(embeddings))){
  # for each kind of testing data
  for (c in c(1:length(embeddings))){
    
    # if these data are triplet data (i.e. suitable to use for testing)
    if (istriplet[c]){
      # use the embedding in that row for predicting and the data in that column for testing.
      validation <- test.model(embeddings[[r]],vmat[[c - 4]])
      majority_vote_predictions[r,c] <- mean(validation$majority == validation$embeddings..r..)
      
    }
  }
}

majority_vote_predictions

