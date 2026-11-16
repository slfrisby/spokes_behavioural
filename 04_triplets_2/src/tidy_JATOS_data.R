# Read JATOS data into R and tidy it ready for use with tripletTools.

# Setup -------------------------------------------------------------------

# set libraries
library(tidyverse)
library(tripletTools)

# set filename variables
raw_data_directory <- "data"
output_directory <- "derivatives"
output_triplet_filename <- "tidy_triplets"

# Load data ---------------------------------------------------------------

# list all .txt files in the raw data directory - there should just be one
# N.B. \\ means that . is treated as a dot character, not a wildcard. $ means that the file should END with this string
data_file <- list.files(path = raw_data_directory, pattern = "\\.txt$")
# load the .txt file
raw_data <- read.csv(paste(raw_data_directory, "/", data_file, sep = ""))

# Get just triplet trials (no fixations etc.) -----------------------------

data <-  raw_data |> 
  # get only trials marked as "random", "check", or "validation"
  filter(trial_category %in% c("random", "check", "validation")) |> 
  # just get the relevant columns - Prolific ID, trial index, reaction time, stimulus modality, stimulus, choices, response, and trial category
  dplyr::select(PROLIFIC_PID, trial_index, rt, stimulus_type, stimulus, choices, coded_response, trial_category)

# Tidy file names ---------------------------------------------------------
# N.B. after this point stimulus names do not incude .img or .wav - task contains modality information

data <- data |>
  dplyr::mutate(
    # get rid of square brackets, file paths, quotation marks and file extensions
    choices  = stringr::str_replace_all(choices,  c("\\[|\\]" = "", "assets/writtenword/" = "", "assets/spokenword/" = "", "assets/image/" = "", "assets/sound/" = "", '"' = "", "\\.wav" = "", "\\.png" = "")),
    stimulus = stringr::str_replace_all(stimulus, c("\\[|\\]" = "", "assets/writtenword/" = "", "assets/spokenword/" = "", "assets/image/" = "", "assets/sound/" = "", '"' = "", "\\.wav" = "", "\\.png" = "")),
  ) |>
  # rename "stimulus" to "head"
  rename(head = stimulus)

# Split choices into winner and loser -------------------------------------

# make a variable which takes the "choices" string and splits it into two pieces, delimited by the comma
choices_split <- stringr::str_split_fixed(data$choices, ",", 2)

data <- data |> 
  dplyr::mutate(
    # if the response is 0 (meaning left), assign the left-hand stimulus as the winner, else assign the right-hand stimulus as the winner
    winner = dplyr::if_else(coded_response == 0, choices_split[, 1], choices_split[, 2]),
    # if the response is 0 (meaning left), assign the right-hand stimulus as the loser, else assign the left-hand stimulus as the loser
    loser  = dplyr::if_else(coded_response == 0, choices_split[, 2], choices_split[, 1]),
    # keep track of which stimuli were presented on the left and right
    left   = choices_split[, 1],
    right  = choices_split[, 2]
  )

# Filter participants who fail catch trials -------------------------------
# There are 12 catch trials and participants who fail more than one will be excluded. 

catch_data <- data |> 
  dplyr::group_by(PROLIFIC_PID) |> 
  dplyr::summarise(
    # count times when the target and one of the stimuli were identical, but the participant didn't pick that stimulus
    wrong = sum(head == loser),
    # count times when the target and one of the stimuli were identical and the participant DID pick that stimulus
    correct = sum(head == winner),
    # NOTE: only catch trials can contribute to either of these counts. For random and validation trials, the target doesn't match either of the options, 
    # so the counts aren't updated. 
    # calculate the proportion incorrect
    proportion_wrong = wrong / (wrong + correct),
    # remove the grouping from failed_catch
    .groups = "drop"
  )

# get a list of participants whose proportion of incorrect catch trials is greater than 0.17 (i.e. two or more trials incorrect)
exclusions <- catch_data |> 
  dplyr::filter(proportion_wrong > 0.17) |> 
    pull(PROLIFIC_PID)

# remove those participants from the main data
data <- data |> 
  dplyr::filter(!PROLIFIC_PID %in% exclusions)

# Create final dataset ----------------------------------------------------

# recompute choices_split after participants have been excluded
choices_split <- stringr::str_split_fixed(data$choices, ",", 2)
# also get all the stimuli in alphabetical order. This is used to assign each stimulus a numeric ID
unique_labels  <- unique(c(data$head, data$winner, data$loser)) |> 
  sort()

# create one large data frame
data <- data.frame(
  # convert each stimulus label into a factor (categorical variable). Using 
  # unique_labels means that the categories are in the same order across columns.
  # Using - 1 means that we use zero-indexing.
  head      = as.numeric(factor(data$head,   levels = unique_labels)) - 1,
  winner    = as.numeric(factor(data$winner, levels = unique_labels)) - 1,
  loser     = as.numeric(factor(data$loser,  levels = unique_labels)) - 1,
  worker_id = data$PROLIFIC_PID,
  modality  = data$stimulus_type,
  rt        = data$rt,
  Center    = data$head,
  Left      = choices_split[, 1],
  Right     = choices_split[, 2],
  Answer    = data$winner,
  sampleAlg = data$trial_category
) 


# split the data into visual and auditory, then assign trials to train and test sets
written_word_data <- data |> 
  filter(data$modality == "written_word") |>
  tripletTools::assign_sample_sets()

spoken_word_data <- data |> 
  filter(data$modality == "spoken_word") |>
  tripletTools::assign_sample_sets()

image_data <- data |> 
  filter(data$modality == "image") |>
  tripletTools::assign_sample_sets()

sound_data <- data |> 
  filter(data$modality == "sound") |>
  tripletTools::assign_sample_sets()

# save the results as .csv
write_csv(written_word_data, paste(output_directory, "/", output_triplet_filename, "_written_word.csv", sep = ""))
write_csv(spoken_word_data, paste(output_directory, "/", output_triplet_filename, "_spoken_word.csv", sep = ""))
write_csv(image_data, paste(output_directory, "/", output_triplet_filename, "_image.csv", sep = ""))
write_csv(sound_data, paste(output_directory, "/", output_triplet_filename, "_sound.csv", sep = ""))

