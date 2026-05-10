# R/geom_violin_pattern.R
# ------------------------------------------------------------
# geom_violin_pattern() — violin plots with pattern overlays
# clipped to the violin outline polygon.
#
# GeomViolinPattern extends GeomViolin and overrides draw_group.
# The base violin is rendered by the parent; the pattern overlay
# is built by reconstructing the violin polygon from the same
# xminv/xmaxv arithmetic that GeomViolin uses internally, then
# feeding it through the existing clip_segments_to_poly / pip
# pattern clipper.
#
# Note: orientation = "y" (horizontal violins, flipped_aes = TRUE)
# is not supported for the pattern overlay — the base violin still
# renders, but the pattern is skipped.
# ------------------------------------------------------------

#' @importFrom ggplot2 ggproto GeomViolin layer aes
#' @importFrom grid gpar nullGrob grobTree
NULL

# ---- GeomViolinPattern -----------------------------------------------------

#' @rdname geom_violin_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomViolinPattern <- ggplot2::ggproto(
  "GeomViolinPattern",
  ggplot2::GeomViolin,

  aesthetics = function(self) {
    c(
      ggplot2::GeomViolin$aesthetics(),
      "pattern",
      "pattern_colour",
      "pattern_linewidth",
      "pattern_spacing",
      "pattern_angle",
      "pattern_size",
      "pattern_contrast_check",
      "pattern_contrast_correct"
    )
  },

  default_aes = ggplot2::aes(
    weight    = 1,
    colour    = "grey20",
    fill      = "white",
    linewidth = 0.5,
    linetype  = 1,
    alpha     = NA,
    width     = 0.9,
    pattern                  = "none",
    pattern_colour           = "black",
    pattern_linewidth        = 1,
    pattern_spacing          = 5,
    pattern_angle            = 45,
    pattern_size             = 0.5,
    pattern_contrast_check   = 0,
    pattern_contrast_correct = FALSE
  ),

  draw_group = function(self, data, panel_params, coord, ...,
                        quantile_gp = list(linetype = 0),
                        flipped_aes = FALSE) {
    # Guard: violinwidth is computed by stat_ydensity and is required to
    # reconstruct the violin polygon. It will be absent if the user supplies
    # stat = "identity" with pre-computed data that lacks the column.
    # GeomViolin's draw_group also needs it, so we must bail before calling it.
    if (!"violinwidth" %in% names(data)) {
      message(
        "geom_violin_pattern: 'violinwidth' column not found in data; ",
        "cannot draw violin. Make sure stat_ydensity (the default) ",
        "or another stat that computes 'violinwidth' is used."
      )
      return(grid::nullGrob())
    }

    base_grob <- ggplot2::ggproto_parent(ggplot2::GeomViolin, self)$draw_group(
      data, panel_params, coord, ...,
      quantile_gp = quantile_gp, flipped_aes = flipped_aes
    )

    pattern_name <- warn_na_patterns(data$pattern[1L] %||% "none")
    if (pattern_name == "none") return(base_grob)

    # Horizontal violins (flipped_aes = TRUE) are not supported for the
    # pattern overlay — the polygon reconstruction assumes x is the position
    # axis and y is the density axis. Fall back to base violin only.
    if (isTRUE(flipped_aes)) return(base_grob)

    # Reconstruct the violin polygon — mirrors GeomViolin$draw_group internals.
    # xminv/xmaxv are the left/right npc x positions at each KDE y level.
    data <- transform(data,
      xminv = x - violinwidth * (x - xmin),
      xmaxv = x + violinwidth * (xmax - x)
    )
    poly_data <- rbind(
      transform(data, x = xminv)[order(data$y), ],
      transform(data, x = xmaxv)[order(data$y, decreasing = TRUE), ]
    )
    poly_data <- rbind(poly_data, poly_data[1L, ])

    # Transform to screen npc.
    coords <- coord$transform(poly_data, panel_params)
    coords <- coords[stats::complete.cases(coords[c("x", "y")]), , drop = FALSE]
    if (nrow(coords) < 3L) return(base_grob)

    x_range <- range(coords$x, na.rm = TRUE)
    y_range <- range(coords$y, na.rm = TRUE)
    bx <- x_range[1]; by <- y_range[1]
    bw <- diff(x_range); bh <- diff(y_range)
    if (bw <= 0 || bh <= 0) return(base_grob)

    pattern_fn <- get_pattern_fn(pattern_name)

    # ---- Contrast check / correction ------------------------------------------
    {
      check_val <- data$pattern_contrast_check[1] %||% 0
      if (isTRUE(check_val)) check_val <- 3.0
      threshold <- as.numeric(check_val)

      correct <- isTRUE(data$pattern_contrast_correct[1] %||% FALSE)
      if (correct && threshold == 0) threshold <- 3.0

      pc   <- data$pattern_colour[1] %||% "black"
      fill <- data$fill[1]           %||% "white"

      if (correct && threshold > 0) {
        pc <- .apply_contrast_correction(pc, fill, threshold)
      }

      if (threshold > 0) {
        ratio <- pattern_contrast(pc, fill)
        if (ratio < threshold) {
          rlang::warn(
            paste0(
              "1 shape has pattern contrast below threshold. ",
              sprintf("contrast %.2f:1 (pattern_colour=%s, fill=%s)", ratio, pc, fill),
              ". Set pattern_contrast_correct = TRUE to auto-adjust."
            ),
            call = NULL
          )
        }
      }
    }
    # ---------------------------------------------------------------------------

    base_gp <- grid::gpar(
      pattern_colour    = pc,
      pattern_linewidth = data$pattern_linewidth[1] %||% 1
    )
    params <- list(
      pattern_spacing = data$pattern_spacing[1] %||% 5,
      pattern_angle   = data$pattern_angle[1]   %||% 45,
      pattern_size    = data$pattern_size[1]     %||% 0.5,
      poly_x = (coords$x - bx) / bw,
      poly_y = (coords$y - by) / bh
    )

    overlay <- pattern_fn(bx, by, bw, bh, gp = base_gp, params = params)
    grid::grobTree(base_grob, overlay)
  },

  draw_key = draw_key_pattern
)

# ---- User-facing layer function --------------------------------------------

#' Violin plots with pattern overlays
#'
#' A drop-in replacement for [ggplot2::geom_violin()] that adds a `pattern`
#' aesthetic. The pattern is clipped to the exact violin outline using the same
#' device-independent in-R geometry as [geom_polygon_pattern()].
#'
#' @section Pattern aesthetics:
#' In addition to all aesthetics accepted by [ggplot2::geom_violin()], this
#' geom accepts:
#' \describe{
#'   \item{`pattern`}{Character name of the pattern. One of `"none"`,
#'     `"hatch"`, `"crosshatch"`, `"horizontal"`, `"vertical"`, `"dots"`,
#'     `"weave"`, or a custom pattern registered with [register_pattern()].
#'     Each base pattern (except `"none"`) also has `_dense` and `_sparse`
#'     variants (e.g. `"hatch_dense"`, `"dots_sparse"`) for pre-set tighter
#'     or looser spacing.}
#'   \item{`pattern_colour`}{Colour of pattern lines/dots. Default `"black"`.}
#'   \item{`pattern_linewidth`}{Line width for line-based patterns. Default `1`.}
#'   \item{`pattern_spacing`}{Spacing between pattern elements in millimetres.
#'     Default `5`. Smaller values produce denser patterns; larger values produce
#'     sparser patterns. Named density variants (e.g. \code{"hatch_dense"}) bake
#'     in a pre-set spacing multiplier but still respect explicit
#'     \code{pattern_spacing} values.}
#'   \item{`pattern_angle`}{Angle in degrees for hatch patterns. Default `45`.}
#'   \item{`pattern_size`}{Dot radius in millimetres for the \code{"dots"}
#'     pattern. Default \code{0.5}.}
#' }
#'
#' @section Limitations:
#' **`stat = "identity"` requires a `violinwidth` column.** The default stat
#' (`"ydensity"`) computes `violinwidth` automatically. If you supply
#' `stat = "identity"` with pre-computed density data, your data frame must
#' include a `violinwidth` column (values in \[0, 1\] representing the
#' normalized half-width at each `y` level). If the column is absent,
#' `geom_violin_pattern()` emits a message and draws nothing for that group.
#' Note: `geom_violin()` itself also requires `violinwidth` and would silently
#' produce incorrect output in this scenario; `geom_violin_pattern()` makes
#' the requirement explicit.
#'
#' **`orientation = "y"` (horizontal violins) is not supported** for the
#' pattern overlay. The base violin renders correctly, but the pattern is
#' silently skipped. Use `coord_flip()` on a vertical violin as a workaround.
#'
#' **Pattern spacing is in millimetres.** `pattern_spacing = 5` means 5mm
#' between pattern elements regardless of violin size, so density is
#' physically consistent across violins of any width.
#'
#' @param mapping Aesthetic mappings created by [ggplot2::aes()].
#' @param data Data frame.
#' @param stat Statistical transformation. Default `"ydensity"`.
#' @param position Position adjustment. Default `"dodge"`.
#' @param ... Other arguments passed to the layer.
#' @param trim If `TRUE` (default), trim the tails of the violin to the range
#'   of the data.
#' @param bounds A length-2 numeric vector defining the minimum and maximum
#'   allowed values for the data. Default `c(-Inf, Inf)`.
#' @param scale How to scale the maximum width of each violin. One of
#'   `"area"` (default), `"count"`, or `"width"`.
#' @param quantile.colour,quantile.color Colour for quantile lines.
#'   Default `NULL` (inherits from `colour`).
#' @param quantile.linetype Line type for quantile lines. `0` (default) means
#'   no lines are drawn.
#' @param quantile.linewidth Line width for quantile lines. Default `NULL`.
#' @param na.rm If `FALSE` (default), missing values are removed with a warning.
#' @param orientation Orientation of the layer. Default `NA` (automatic).
#' @param show.legend Logical. Should this layer be included in the legend?
#' @param inherit.aes If `FALSE`, overrides the default aesthetics.
#'
#' @return A ggplot2 layer.
#' @export
#' @examples
#' library(ggplot2)
#'
#' # Basic violin with hatch pattern per group
#' ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl),
#'                    pattern = factor(cyl))) +
#'   geom_violin_pattern() +
#'   scale_pattern_manual(values = c("hatch", "crosshatch", "dots")) +
#'   scale_fill_brewer(palette = "Pastel1") +
#'   theme_minimal()
#'
#' # With quantile lines — exercises the quantile overlay path
#' ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl),
#'                    pattern = factor(cyl))) +
#'   geom_violin_pattern(
#'     quantile.linetype = 1,
#'     quantile.linewidth = 0.5,
#'     quantile.colour = "grey20"
#'   ) +
#'   scale_pattern_manual(values = c("hatch", "crosshatch", "dots")) +
#'   scale_fill_brewer(palette = "Pastel1") +
#'   theme_minimal()
geom_violin_pattern <- function(
    mapping           = NULL,
    data              = NULL,
    stat              = "ydensity",
    position          = "dodge",
    ...,
    trim              = TRUE,
    bounds            = c(-Inf, Inf),
    scale             = "area",
    quantile.colour   = NULL,
    quantile.color    = NULL,
    quantile.linetype = 0L,
    quantile.linewidth = NULL,
    na.rm             = FALSE,
    orientation       = NA,
    show.legend       = NA,
    inherit.aes       = TRUE
) {
  quantile_gp <- list(
    colour    = quantile.color %||% quantile.colour,
    linetype  = quantile.linetype,
    linewidth = quantile.linewidth
  )
  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomViolinPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = rlang::list2(
      trim        = trim,
      scale       = scale,
      na.rm       = na.rm,
      orientation = orientation,
      bounds      = bounds,
      quantile_gp = quantile_gp,
      ...
    )
  )
}
