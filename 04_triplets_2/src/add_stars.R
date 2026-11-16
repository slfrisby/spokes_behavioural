# By Claude.

# ---------------------------------------------------------------------------
# add_stars(): add a star to the text of each cell where 'sig' is TRUE.
#
# Arguments:
#   p     a plot made by plot_similarity_matrix()
#   sig   a matrix the same size as the one plotted. Cells containing TRUE
#         get a star; anything else (NaN, NA, FALSE) is left alone.
#   star  the text to add (default "*"; could be e.g. "**" or "†")
#
# Returns the updated plot, so use it like:  p2 <- add_stars(p, sig)
# ---------------------------------------------------------------------------
add_stars <- function(p, sig, star = "*") {
  
  # Get the data frame stored inside the plot. It has one row per cell,
  # with columns row, col, value and label (made by plot_matrix()).
  df <- p$data
  
  # Stop with a clear message if 'sig' is a different size from the plot.
  if (nrow(sig) != max(df$row) || ncol(sig) != max(df$col)) {
    stop("sig is ", nrow(sig), " x ", ncol(sig), " but the plot is ",
         max(df$row), " x ", max(df$col))
  }
  
  # Flatten 'sig' in the same order plot_matrix() used to flatten the
  # original matrix, so each entry lines up with the right row of df.
  sig_vec <- as.vector(sig)
  
  # TRUE for cells that should get a star.
  #   !is.na(sig_vec) excludes NaN and NA (is.na() is TRUE for both).
  #   sig_vec == TRUE picks out the TRUEs. A matrix that mixes TRUE and NaN
  #   is stored as numbers, with TRUE as 1, and 1 == TRUE is still TRUE,
  #   so this works either way.
  is_sig <- !is.na(sig_vec) & sig_vec == TRUE
  
  # Add the star to the end of the label in just those cells.
  # paste0() joins text with no space, e.g. "0.45" + "*" -> "0.45*".
  df$label[is_sig] <- paste0(df$label[is_sig], star)
  
  # Put the updated data back into the plot and return it. Every layer
  # then redraws from the new data. The way to swap a plot's data changed
  # in ggplot2 version 4.0.0, so this checks which version you have.
  if (utils::packageVersion("ggplot2") >= "4.0.0") {
    p + df
  } else {
    p %+% df
  }
}