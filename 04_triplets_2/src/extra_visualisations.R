# most of the visualisations for this project are contained in compare_embeddings.R. However, we need to
# make a few plots that are not about embedding comparison - naming scores and psycholinguistic variables, 
# for example. 
# Written with the help of Claude.


# Setup -------------------------------------------------------------------

library(ggplot2)
library(ggbeeswarm)  # Adds swarm-plot layers to ggplot2: geom_beeswarm() and geom_quasirandom().
library(dplyr)       
library(tidyr)       # Tools for reshaping data; we use pivot_longer().
library(rstatix)     # Friendly wrappers for stats tests that return tidy data frames: kruskal_test(), dunn_test(), etc.
library(ggpubr)      # We use just one function from here: stat_pvalue_manual(), which draws significance brackets.

# Plot naming accuracies --------------------------------------------------

# load naming accuracies for 24 participants for just those 60 stimuli
naming_data <- read.csv('./work/naming_data.csv', header = TRUE)

# set axis limits
x_min <- 0.8 
x_max <- 1
y_min <- 0
y_max <- 40

# plot histogram
naming_accuracies <- ggplot(        # start a new plot
  data = naming_data,               # say which data to plot
  mapping = aes(x = accuracy)          # aes() = "aesthetic mapping": the 'value' column goes on the x-axis. A histogram
) +                                 # add the next layer
  geom_histogram(                   # draw a histogram
    binwidth = 0.025,               # set the width of the bin (N.B. not the total number of bins) 
    boundary = 0,                   # Bin edges line up with 0, so bins are 0-0.1, 0.1-0.2, etc.
    closed   = "left",              # Each bin includes its LEFT edge but not its right: [0, 0.1), [0.1, 0.2)...
    fill     = "#002060",           # Colour inside the bars.
    colour   = "#FFFFFF",           # Colour of the bar outlines.
    linewidth = 0.3                 # Thickness of the outlines.

  ) +
  
  scale_x_continuous(                 # Customise the x-axis (a continuous numeric axis).
    limits = c(x_min, x_max),         # Axis range from x_min to x_max.
    breaks = seq(x_min, x_max, by = 0.05),  # Where the tick marks go: 0, 0.1, 0.2, ... 1.
    expand = c(0, 0)                  # Removes the small default padding at the axis ends, so bars sit flush with the axis. Delete this line to restore it.
  ) +
  
  scale_y_continuous(                 # Customise the y-axis (the counts).
    expand = expansion(mult = c(0, 0.05)),  # No gap below 0 (bars start right on the axis), 5% headroom above the
    # tallest bar so it doesn't touch the top.
    breaks = seq(y_min, y_max, by = 5),    # Optional: set your own tick marks.
    limits = c(0, y_max)               # Optional: fix the y range, e.g. to keep
    # several plots on the same scale.
  ) +
  
  labs(                               # Text labels
    x     = "Naming accuracy",        # x-axis title
    y     = "Number of stimuli",      # y-axis title
    title = NULL                      # Plot title
  ) +                                 
  
  theme_bw(                      # A ready-made theme: white background,
                                      # plain axis lines, no gridlines. Others
                                      # to try: theme_bw(), theme_minimal(),
                                      # theme_grey() (the default), theme_classic()
    base_size = 14                    # Base font size for all text in points.
  ) +
  
  theme(                              # Fine-tune individual elements AFTER the ready-made theme (important, since these will override)
    # the ready-made theme (order matters:
    # later layers override earlier ones).
    plot.title = element_text(        # Style the title text...
      face  = "bold",                 # ...bold...
      hjust = 0.5,                    # ...centred (0 = left, 1 = right).
  ),
    axis.text = element_text(         # Style the tick-mark numbers...
      #colour = "black"                # ...black rather than the default grey.
    ),
  plot.margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "cm")
  )
naming_accuracies

ggsave(
  filename = './derivatives/figures/naming_accuracies.png',  # File name
  plot     = naming_accuracies,              # Which plot object to save.
  width    = 8,                         # Width...
  height   = 5,                         # ...and height...
  units    = "in",                      # ...in inches ("cm" and "mm" also work).
  dpi      = 300                        # Resolution: 300 is standard for
)                                       # publication. Ignored for .pdf/.svg.

# Plot psycholinguistic variables -----------------------------------------

# load psycholinguistic variable data for 24 participants for just those 60 stimuli
plvs <- read.csv('./work/psycholinguistic_variables.csv', header = TRUE)

# also add category labels
category_labels <- c("Mammals", "Birds", "Other animals", "Person actions", "Vehicles", "Musical instruments", "Appliances", "Other inanimate")

# and initialise a variable to keep track of the psycholinguistiv variables that we want to plot
variables <- c("Frequency", "Concreteness", "Age.of.Acquisition", "Semantic.Diversity")

plvs <- plvs |>                     
  mutate(                                   # mutate() changes or adds columns.
    Category = factor(Category)             # Turn 1-8 into a FACTOR. This is essential: otherwise R treats the categories as numbers on a continuous scale, not as groups.
  )  |>                                      
  pivot_longer(                             # Reshape wide -> long:
    cols      = all_of(variables),          # the 4 measure columns...
    names_to  = "measure",                  # ...have their NAMES moved into a
                                            # new column called "measure"...
    values_to = "value"                     # ...and their NUMBERS moved into a
  ) |>                                      # new column called "value".
  mutate(
    measure = factor(measure, levels = variables)  # Keep the measures in your chosen order
  )                                                  

# Apply custom category labels, if you supplied them.
if (!is.null(category_labels)) {                       # Only if not NULL...
  levels(plvs$Category) <- category_labels             # ...rename levels 1-8.
}

# Count how many stimuli are in each category (worth checking!).
plvs |>
  filter(measure == variables[1]) |>        # One measure only, to count each
  count(Category)                           # stimulus once; count() tallies
                                            # rows in each category.

# Do a Kruskal-Wallis test for each measure (like an ANOVA, this establishes whether there is a difference, 
# but not which groups drive that difference).

kw_results <- plvs |>
  group_by(measure) |>                      # Do the next step separately for
                                            # each of the 4 measures.
  kruskal_test(value ~ Category)            # Formula "value ~ category" reads
                                            # "value as explained by category".
                                            # Returns: n, statistic (H),
                                            # df (= groups - 1), p.

# Effect size: epsilon-squared-style "eta2[H]", from 0 to 1. A rough
# guide: ~0.01 small, ~0.06 moderate, >=0.14 large. Worth reporting
# alongside p-values.
kw_effsize <- plvs |>
  group_by(measure) |>
  kruskal_effsize(value ~ Category)         # Returns effsize and magnitude.

# We run 4 Kruskal-Wallis tests (one per measure), so correct those.
kw_results <- kw_results |>
  adjust_pvalue(method = "fdr") |>         # Adds a column 'p.adj'.
  add_significance("p.adj")                 # Adds stars: ns, *, **, ***, ****.

print(kw_results)                           # Show the results table.
print(kw_effsize)

# Do Dunn's post-hoc tests to compare each pair of categories and find where the differences lie

dunn_results <- plvs |>
  group_by(measure) |>                      # Separately for each measure.
  dunn_test(
    value ~ Category,                       # Same formula as before.
    p.adjust.method = "fdr"                 # Correct for the 28 comparisons
  )                                         # within each measure. Other

# Columns of interest: group1, group2 (the pair), statistic (z),
# p (uncorrected), p.adj (corrected), p.adj.signif (stars).

# Print just the significant pairs, for reading.
dunn_results |>
  filter(p.adj < 0.05) |>
  select(measure, group1, group2, statistic, p.adj, p.adj.signif) |>
  print(n = Inf)  

# Define a function to make swarm plots.

make_swarm_plot <- function(measure_name) {
  
  # Keep only this measure's rows.
  plot_data <- plvs |>
    filter(measure == measure_name)
  
  # Start the plot.
  p <- ggplot(
    data = plot_data,
    mapping = aes(
      x      = Category,                   # Categories along the x-axis.
      y      = value,                      # Values up the y-axis.
      colour = Category                    # Colour each point by its
    )                                      # category. Because this is INSIDE
  ) +                                      # aes(), it's linked to the data.
    
    geom_beeswarm(                         # The swarm layer: one dot per
                                           # stimulus, nudged sideways to
                                           # avoid overlap.
      size     = 2,                        # Dot size.
      alpha    = 1,                      # Dot transparency.
      cex      = 2                         # Spacing between dots: increase
                                           # if dots overlap, decrease if the
                                           # swarm is too wide.

    ) +
    
    scale_colour_manual(                   
      values = c("#429656", "#B1743F", "#7E3E88", "#CA7676",   
                 "#5FC3C6", "#B3AACB", "#4E2206", "#B2B2B2")                 
    ) +
    
    labs(
      x     = "Category",                  # x-axis title.
      y     = gsub(".", " ", measure_name, fixed = TRUE),                # y-axis title = the measure name. Get rid of errant full stops!
      title = gsub(".", " ", measure_name, fixed = TRUE)                 # Plot title.
    ) +
    
    theme_bw(base_size = 12) +        # Clean white theme, 14pt text.
    theme(
      legend.position = "none",            # Hide the legend: the x-axis
                                           # already names the categories.
      plot.title = element_text(face = "bold", hjust = 0.5),
      axis.text  = element_text(colour = "black"),
      plot.margin = margin(t = 1, r = 1, b = 1, l = 1, unit = "cm")
      
)
  
  # Optionally add a median line for each category.
  p <- p +
    stat_summary(                        # stat_summary() calculates a
      # summary per x-group and draws it.
      fun       = median,                # The summary to calculate.
      geom      = "crossbar",            # Draw it as a horizontal bar.
      width     = 0.5,                   # Width of the bar (1 = full slot).
      colour    = "black",               # Black, so it stands out.
      linewidth = 0.4                    # Line thickness.
    )
  # Add significance brackets, if this measure had any significant pairs.
  sig_pairs <- dunn_results |>
    filter(measure == measure_name,        # This measure only...
           p.adj < 0.05)                   # ...significant pairs only.
  # With 8 groups, showing all 28
  # pairs would be unreadable.
  
  if (nrow(sig_pairs) > 0) {               # Only if there's something to draw.
    
    sig_pairs <- sig_pairs |>
      add_xy_position(                     # Works out where each bracket goes:
        data = plot_data,                  # which x positions it spans, and a
        formula = value ~ Category,        # y height above the data, stacking
        x = "Category",                    # brackets so they don't overlap.
        step.increase = 0.2               # Vertical gap between brackets, as
      )                                    # a fraction of the y range.
    
    p <- p +
      stat_pvalue_manual(                  # Draw the brackets.
        sig_pairs,                         # Table of pairs + positions.
        label        = "p.adj.signif",     # Text above each bracket: stars.
        # Use "p.adj" to show the number
        # instead, or "p = {p.adj}" for
        # "p = 0.003" style labels.
        tip.length   = 0.01,               # Length of the bracket's end ticks.
        hide.ns      = TRUE,               # Don't draw non-significant ones.
        bracket.nudge.y = 0.1,              # space the brackets a little from the swarms
        inherit.aes  = FALSE               # Don't apply the colour mapping
      ) +                                  # from ggplot() to the brackets.
      scale_y_continuous(
        breaks = pretty(plot_data$value),
        expand = expansion(mult = c(0.05, 0.1))# Extra headroom at the top so brackets aren't clipped.
        )                                          
  }
  
  return(p)                                # Hand back the finished plot.
}

# Make a function for fixing the size of the panels, so that they can be stacked neatly
fix_panel_size <- function(p, width = unit(8, "in"), height = unit(4, "in")) {
  g <- ggplotGrob(p)                                  # Convert the plot into
                                                      # its underlying layout
                                                      # table of rows/columns.
  panel <- g$layout[g$layout$name == "panel", ]       # Find which row and
                                                      # column hold the panel.
  g$widths[panel$l]  <- width                         # Set that column's width...
  g$heights[panel$t] <- height                        # ...and that row's height.
  g                                                   # Return the modified layout.
}

# Plot each variable and save

p <- make_swarm_plot("Frequency")
p
p <- fix_panel_size(p)
ggsave(
  filename = './derivatives/figures/frequency.png',  
  plot     = p,              
  width    = grid::convertWidth(sum(p$widths), "in", valueOnly = TRUE),
  height   = grid::convertHeight(sum(p$heights), "in", valueOnly = TRUE),                      
  units    = "in",                     
  dpi      = 300                        
)                                       

p <- make_swarm_plot("Concreteness")
p
p <- fix_panel_size(p)
ggsave(
  filename = './derivatives/figures/concreteness.png',  
  plot     = p,              
  width    = grid::convertWidth(sum(p$widths), "in", valueOnly = TRUE),
  height   = grid::convertHeight(sum(p$heights), "in", valueOnly = TRUE),                      
  units    = "in",                     
  dpi      = 300                        
) 

p <- make_swarm_plot("Age.of.Acquisition")
p
p <- fix_panel_size(p)
ggsave(
  filename = './derivatives/figures/age_of_acquisition.png',  
  plot     = p,              
  width    = grid::convertWidth(sum(p$widths), "in", valueOnly = TRUE),
  height   = grid::convertHeight(sum(p$heights), "in", valueOnly = TRUE),                      
  units    = "in",                     
  dpi      = 300                        
) 

p <- make_swarm_plot("Semantic.Diversity")
p
p <- fix_panel_size(p)
ggsave(
  filename = './derivatives/figures/semantic_diversity.png',  
  plot     = p,              
  width    = grid::convertWidth(sum(p$widths), "in", valueOnly = TRUE),
  height   = grid::convertHeight(sum(p$heights), "in", valueOnly = TRUE),                           
  units    = "in",                     
  dpi      = 300                        
) 

