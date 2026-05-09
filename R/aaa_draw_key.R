# R/aaa_draw_key.R
# ------------------------------------------------------------
# Prefixed with 'aaa_' so it sorts first alphabetically and
# is guaranteed to load before any geom_*.R file that references
# draw_key_pattern.
# ------------------------------------------------------------

#' @importFrom grid rectGrob gpar grobTree unit
NULL

#' Legend key for pattern aesthetics
#'
#' Draws a filled rectangle with the pattern overlay for use in legends.
#' @param data,params,size Passed from ggplot2 internals.
#' @keywords internal
draw_key_pattern <- function(data, params, size) {
  bg <- grid::rectGrob(
    width  = unit(0.9, "npc"),
    height = unit(0.9, "npc"),
    gp = grid::gpar(
      fill = data$fill %||% "white",
      col  = data$colour %||% NA
    )
  )

  pattern_name <- warn_na_patterns(data$pattern %||% "none")
  pattern_fn   <- get_pattern_fn(pattern_name)

  # null_na_default guards against both NULL (unmapped) and NA (mapped but
  # missing in the legend key data row) for every pattern param.
  extra_gp <- grid::gpar(
    pattern_colour    = null_na_default(data$pattern_colour,    "black"),
    pattern_linewidth = null_na_default(data$pattern_linewidth, 1)
  )

  # Use wider spacing in legend keys so patterns aren't a dense blob.
  legend_params <- list(
    pattern_spacing   = null_na_default(data$pattern_spacing,   0.08) * 2.5,
    pattern_angle     = null_na_default(data$pattern_angle,     45),
    pattern_size      = null_na_default(data$pattern_size,      0.35),
    pattern_linewidth = null_na_default(data$pattern_linewidth, 1)
  )

  overlay <- pattern_fn(
    x = 0.05, y = 0.05, width = 0.9, height = 0.9,
    gp     = extra_gp,
    params = legend_params
  )

  grid::grobTree(bg, overlay)
}