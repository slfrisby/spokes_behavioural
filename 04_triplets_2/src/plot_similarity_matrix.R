# Written by Claude.

# ---------------------------------------------------------------------------
# plot_matrix(): draw a matrix (e.g. of correlations) as a grid of coloured
# cells, optionally with the value written in each cell. Row 1 is at the
# top, as when you print the matrix.
#
# Arguments (all except m have defaults, so you only give the ones you want
# to change):
#   m              the matrix to plot (values expected between -1 and 1)
#   row_names      labels for the rows (a vector, one per row).        (CHANGED)
#                  If not given, the rows have no labels.
#                  Tip: row_names = rownames(m) uses the matrix's own names.
#   col_names      labels for the columns, same rules as row_names     (CHANGED)
#   neg, zero, pos fill colours for -1, 0 and 1. Values in between     (CHANGED)
#                  get shades blended between these.
#   limits         Colour bar limits
#   show_numbers   TRUE = write the value in each cell; FALSE = don't  (NEW)
#   digits         number of decimal places shown in each cell
#   text_size      size of the numbers in the cells
#   text_switch    cells further from zero than this (in either direction)
#                  get white text instead of black, so the numbers stay
#                  readable on dark cells
#   border_colour  colour of the line around the whole matrix
#                  (use NA for no border)
#   border_width   thickness of that line
#   col_angle      angle of the column names: 90 = vertical, 0 = horizontal
# ---------------------------------------------------------------------------
plot_matrix <- function(m, row_names = NULL, col_names = NULL,
                        neg = "#2166AC", zero = "white", pos = "#B2182B", limits = c(-1,1), # CHANGED
                        show_numbers = TRUE,                              # NEW
                        digits = 2, text_size = 4, text_switch = 0.6,
                        border_colour = "#B2B2B2", border_width = 0.8,
                        col_angle = 90) {
  
  # ---- 1. Reshape the matrix into a data frame ----------------------------
  # ggplot doesn't take matrices. It needs a data frame with one row per
  # thing to draw. Here that means one row per cell, with three columns:
  # the cell's row number, its column number and its value.
  #   row(m) gives a matrix of the same shape holding each cell's row number;
  #   col(m) does the same for column numbers.
  #   as.vector() flattens each of these into a single long vector. All three
  #   are flattened in the same order, so the values stay matched up.
  df <- data.frame(
    row   = as.vector(row(m)),
    col   = as.vector(col(m)),
    value = as.vector(m)
  )
  if (show_numbers) {
    df$label <- formatC(df$value, format = "f", digits = digits)
  } else {
    df$label <- ""
  }
  
  # ---- 2. Axis labels (CHANGED) -------------------------------------------
  # If names were passed in, check there's one per row/column and put a
  # tick mark at each row/column. If no names were passed in, set the tick
  # positions ("breaks") to NULL, which tells ggplot to draw no ticks and
  # no labels on that axis.
  if (is.null(row_names)) {
    y_breaks <- NULL
  } else {
    if (length(row_names) != nrow(m)) {
      stop("row_names has ", length(row_names), " entries but m has ",
           nrow(m), " rows")
    }
    y_breaks <- seq_len(nrow(m))
  }
  
  if (is.null(col_names)) {
    x_breaks <- NULL
  } else {
    if (length(col_names) != ncol(m)) {
      stop("col_names has ", length(col_names), " entries but m has ",
           ncol(m), " columns")
    }
    x_breaks <- seq_len(ncol(m))
  }
  
  # ---- 3. Build the plot, one layer at a time -----------------------------
  # Layers are drawn in the order they are added, so later layers appear
  # on top of earlier ones.
  
  # ggplot() sets up the plot. It doesn't draw anything yet.
  #   The first argument is the data frame to use.
  #   aes() ("aesthetics") links columns of the data frame to visual
  #   properties: column number -> horizontal position (x), row number ->
  #   vertical position (y), value -> fill colour. Every layer added below
  #   inherits these links.
  ggplot(df, aes(x = col, y = row, fill = value)) +
    
    # Layer 1: the coloured cells.
    # geom_tile() draws one rectangle per row of df, centred at (x, y) and
    # filled according to 'value'. There is no 'colour' argument, so the
    # individual cells have no borders.
    geom_tile() +
    
    # Layer 2 (CHANGED: now optional): the numbers written in the cells.
    # 'if (show_numbers) ...' gives the text layer when show_numbers is TRUE,
    # and NULL (nothing) when it is FALSE. Adding NULL to a ggplot does
    # nothing, so the layer simply disappears.
    # The brackets around the whole 'if (...)' are essential. Without them,
    # R would treat everything after it (all the '+ ...' lines below) as
    # part of the if, and those lines would vanish too when it is FALSE.
    #
    # Inside geom_text(), aes() adds two more links:
    #   label  = the text to write. formatC(..., format = "f", digits = 2)
    #            formats each number with a fixed number of decimals,
    #            e.g. 0.5 -> "0.50", -0.3 -> "-0.30".
    #   colour = text colour. abs() is the absolute value (distance from
    #            zero, ignoring the sign), so dark cells at both ends of the
    #            scale get TRUE. The colour scale further down turns
    #            TRUE/FALSE into white/black.                         (CHANGED)
    # size = text size (fixed, so outside aes()).
    # show.legend = FALSE stops this layer adding an entry to the legend.
    geom_text(aes(label  = label,
                  colour = abs(value - mean(limits)) > text_switch),
              size = text_size, show.legend = FALSE) +
    
    # ---- Scales: how data values become colours and positions -------------
  
  # Text colour: turn FALSE/TRUE (from the colour link above) into actual
  # colours. Change "black"/"white" here to recolour the numbers.
  # (If show_numbers = FALSE this scale has nothing to apply to, which
  # is harmless.)
  scale_colour_manual(values = c("FALSE" = "black", "TRUE" = "white")) +
    
    # Cell fill colour (CHANGED): a diverging scale with three anchor colours.
    #   low  = colour at the bottom of the limits (-1)
    #   mid  = colour at the midpoint
    #   high = colour at the top of the limits (1)
    #   midpoint = 0 puts the 'mid' colour (white) exactly at zero.
    #   limits = c(-1, 1) fixes the scale to the full range of possible
    #            correlations, so a given shade means the same value in
    #            every matrix you plot. Without it, the scale would stretch
    #            to each matrix's own smallest and largest values.
    #   guide = "none" removes the colour key (legend).
    # Values outside -1 to 1 (or missing values) would appear grey.
    scale_fill_gradient2(low = neg, mid = zero, high = pos,
                         midpoint = mean(limits), limits = limits,
                         oob = scales::squish,
                         guide = "none") +
    
    # y axis: scale_y_reverse() flips the axis so row 1 is at the top.
    #   breaks = where the tick marks go: one per row, or NULL for none.
    #   labels = the text at each tick mark (ignored when breaks is NULL).
    #   expand = c(0, 0) removes the empty margin ggplot normally adds,
    #            so the cells touch the edges of the plotting area. This
    #            also means the border added below sits exactly on the
    #            edge of the matrix.
    scale_y_reverse(breaks = y_breaks, labels = row_names,           # CHANGED
                    expand = c(0, 0)) +
    
    # x axis: same idea, but not reversed.
    # position = "top" puts the column labels above the grid.
    scale_x_continuous(breaks = x_breaks, labels = col_names,        # CHANGED
                       position = "top", expand = c(0, 0)) +
    
    # ---- Overall shape -----------------------------------------------------
  
  # coord_fixed() keeps one unit on the x axis the same length as one unit
  # on the y axis, so cells are square. Remove it to let the cells stretch
  # to fill the plot.
  coord_fixed() +
    
    # ---- Titles and labels -------------------------------------------------
  
  # labs() sets text labels. NULL means no label.
  # You can also add title = "...", subtitle = "..." or caption = "...".
  labs(x = NULL, y = NULL) +
    
    # ---- Appearance (anything not linked to the data) ---------------------
  
  # theme_minimal() is a ready-made style: white background, no box around
  # the plot. Others to try: theme_classic(), theme_bw(), theme_void().
  # base_size changes the size of all the text at once,
  # e.g. theme_minimal(base_size = 14).
  theme_minimal() +
    
    # theme() adjusts individual parts of the style. It must come after the
    # ready-made theme, or that theme will overwrite it.
    theme(
      # Remove the background grid lines, which would otherwise show through
      # the cells. element_blank() removes an element entirely.
      panel.grid = element_blank(),
      
      # Row and column labels: size in points, and colour.
      # (theme_minimal() makes them dark grey and slightly smaller than
      # the base text size by default.)
      axis.text = element_text(size = 12, colour = "black"),
      
      # Border around the whole matrix.
      # The "panel" is the area where the data are drawn. Because the axes
      # have no extra margin (expand = c(0, 0) above), the panel is exactly
      # the size of the matrix, so its border goes round the matrix.
      #   element_rect() describes a rectangle:
      #     colour    = line colour
      #     linewidth = line thickness (in ggplot2 versions before 3.4.0,
      #                 this argument is called 'size' instead)
      #     fill = NA = don't fill it. This is essential: a filled panel
      #                 border is drawn on top of the data and would hide
      #                 the cells.
      panel.border = element_rect(colour = border_colour,
                                  linewidth = border_width, fill = NA),
      
      # Rotate the column names.
      # 'axis.text.x.top' means the tick labels on the x axis when it is at
      # the top of the plot. (If you move the axis to the bottom, change this
      # to 'axis.text.x.bottom' and use hjust = 1, so the labels end at the
      # axis instead of starting there.)
      #   angle = rotation in degrees, anticlockwise (90 = reads bottom to top)
      #   hjust = alignment along the text's own direction. 0 = the text
      #           starts at the axis and runs away from the matrix.
      #   vjust = alignment across the text. 0.5 = centred on the tick mark,
      #           i.e. on the middle of the column.
      axis.text.x.top = element_text(angle = col_angle, hjust = 0,
                                     vjust = 0.5)
      
      # Other examples you could add here (separate each with a comma):
      #   axis.text = element_text(size = 12, colour = "black")
      #   plot.title = element_text(face = "bold", hjust = 0.5)
    )
  
  # The plot built above is the last thing in the function, so the function
  # returns it. Printing it (e.g. typing plot_matrix(m) at the console)
  # draws it.
}
