# R/geom_ribbon_pattern.R
# ------------------------------------------------------------
# geom_ribbon_pattern() and geom_area_pattern() — ribbon/area
# charts with pattern overlays clipped to the ribbon polygon.
#
# GeomRibbonPattern extends GeomRibbon and overrides draw_group.
# The base ribbon is rendered by GeomRibbon$draw_group; the
# pattern overlay is built independently by reconstructing the
# ribbon polygon from coord-transformed ymin/ymax columns.
#
# Note: orientation = "y" (horizontal ribbons) is not supported
# for the pattern overlay — the base ribbon still renders, but
# the pattern is skipped when flipped_aes = TRUE.
# ------------------------------------------------------------

#' @importFrom ggplot2 ggproto GeomRibbon layer aes
#' @importFrom grid gpar nullGrob grobTree
NULL

# ---- GeomRibbonPattern -----------------------------------------------------

#' @rdname geom_ribbon_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomRibbonPattern <- ggplot2::ggproto(
  "GeomRibbonPattern",
  ggplot2::GeomRibbon,

  aesthetics = function(self) {
    c(
      ggplot2::GeomRibbon$aesthetics(),
      "pattern",
      "pattern_colour",
      "pattern_linewidth",
      "pattern_spacing",
      "pattern_angle",
      "pattern_size"
    )
  },

  default_aes = ggplot2::aes(
    colour    = "grey20",
    fill      = "grey80",
    linewidth = 0.5,
    linetype  = 1,
    alpha     = NA,
    pattern           = "none",
    pattern_colour    = "black",
    pattern_linewidth = 1,
    pattern_spacing   = 0.08,
    pattern_angle     = 45,
    pattern_size      = 0.4
  ),

  draw_group = function(self, data, panel_params, coord,
                        lineend = "butt", linejoin = "round", linemitre = 10,
                        na.rm = FALSE, flipped_aes = FALSE,
                        outline.type = "both") {
    base_grob <- ggplot2::ggproto_parent(ggplot2::GeomRibbon, self)$draw_group(
      data, panel_params, coord,
      lineend = lineend, linejoin = linejoin, linemitre = linemitre,
      na.rm = na.rm, flipped_aes = flipped_aes, outline.type = outline.type
    )

    pattern_name <- warn_na_patterns(data$pattern[1L] %||% "none")
    if (pattern_name == "none") return(base_grob)

    # Horizontal ribbons (flipped_aes = TRUE) are not supported for the
    # pattern overlay because coord$transform would give us the pre-flipped
    # column layout; fall back to base ribbon only.
    if (isTRUE(flipped_aes)) return(base_grob)

    # Transform to screen npc — coord$transform handles ymin/ymax columns.
    coords <- coord$transform(data, panel_params)

    # Drop NA rows (ribbon gaps) before building the polygon.
    complete <- stats::complete.cases(coords[c("x", "ymin", "ymax")])
    coords <- coords[complete, , drop = FALSE]
    if (nrow(coords) < 2) return(base_grob)

    # Ribbon polygon: upper edge (left → right at ymax) then
    # lower edge (right → left at ymin).
    poly_x <- c(coords$x, rev(coords$x))
    poly_y <- c(coords$ymax, rev(coords$ymin))

    x_range <- range(poly_x, na.rm = TRUE)
    y_range <- range(poly_y, na.rm = TRUE)
    bx <- x_range[1]; by <- y_range[1]
    bw <- diff(x_range); bh <- diff(y_range)
    if (bw <= 0 || bh <= 0) return(base_grob)

    pattern_fn <- get_pattern_fn(pattern_name)
    base_gp <- grid::gpar(
      pattern_colour    = data$pattern_colour[1]    %||% "black",
      pattern_linewidth = data$pattern_linewidth[1] %||% 1
    )
    params <- list(
      pattern_spacing = data$pattern_spacing[1] %||% 0.08,
      pattern_angle   = data$pattern_angle[1]   %||% 45,
      pattern_size    = data$pattern_size[1]     %||% 0.4,
      poly_x = (poly_x - bx) / bw,
      poly_y = (poly_y - by) / bh
    )

    overlay <- pattern_fn(bx, by, bw, bh, gp = base_gp, params = params)
    grid::grobTree(base_grob, overlay)
  },

  draw_key = draw_key_pattern
)

# ---- GeomAreaPattern -------------------------------------------------------

#' @rdname geom_ribbon_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomAreaPattern <- ggplot2::ggproto(
  "GeomAreaPattern",
  GeomRibbonPattern,

  required_aes = c("x|y", "y|x"),

  # Same as GeomArea$setup_data: set ymin = 0, ymax = y.
  # flipped_aes / orientation = "y" not supported in pattern overlay.
  setup_data = function(data, params) {
    data <- data[order(data$PANEL, data$group, data$x), , drop = FALSE]
    data <- transform(data, ymin = 0, ymax = y)
    data
  }
)

# ---- User-facing layer functions -------------------------------------------

#' Ribbon and area charts with pattern overlays
#'
#' Drop-in replacements for [ggplot2::geom_ribbon()] and [ggplot2::geom_area()]
#' that add a `pattern` aesthetic. Patterns are clipped to the ribbon polygon
#' using the same device-independent in-R geometry as [geom_polygon_pattern()].
#'
#' @section Pattern aesthetics:
#' In addition to all aesthetics accepted by [ggplot2::geom_ribbon()], these
#' geoms accept:
#' \describe{
#'   \item{`pattern`}{Character name of the pattern. One of `"none"`,
#'     `"hatch"`, `"crosshatch"`, `"horizontal"`, `"vertical"`, `"dots"`,
#'     `"weave"`, or a custom pattern registered with [register_pattern()].
#'     Each base pattern (except `"none"`) also has `_dense` and `_sparse`
#'     variants (e.g. `"hatch_dense"`, `"dots_sparse"`) for pre-set tighter
#'     or looser spacing.}
#'   \item{`pattern_colour`}{Colour of pattern lines/dots. Default `"black"`.}
#'   \item{`pattern_linewidth`}{Line width for line-based patterns. Default `1`.}
#'   \item{`pattern_spacing`}{Spacing between pattern elements as a fraction
#'     of the ribbon bounding box (npc units). Default `0.08`.}
#'   \item{`pattern_angle`}{Angle in degrees for hatch patterns. Default `45`.}
#'   \item{`pattern_size`}{Dot diameter in mm for the `"dots"` pattern.
#'     Default `0.4`.}
#' }
#'
#' @section Limitations:
#' `orientation = "y"` (horizontal ribbons/areas) is not supported for the
#' pattern overlay. The base ribbon renders correctly, but the pattern is
#' silently skipped.
#'
#' NA gaps in the ribbon data collapse into the surrounding polygon rather than
#' producing separate pattern segments.
#'
#' @param mapping Aesthetic mappings created by [ggplot2::aes()].
#' @param data Data frame.
#' @param stat Statistical transformation. Default `"identity"`.
#' @param position Position adjustment. Default `"identity"` for
#'   `geom_ribbon_pattern()`, `"stack"` for `geom_area_pattern()`.
#' @param outline.type Which sides of the ribbon to draw. One of `"both"`
#'   (default), `"upper"`, `"lower"`, or `"full"`.
#' @param ... Other arguments passed to the layer.
#' @param na.rm If `FALSE` (default), missing values are removed with a warning.
#' @param show.legend Logical. Should this layer be included in the legend?
#' @param inherit.aes If `FALSE`, overrides the default aesthetics.
#'
#' @return A ggplot2 layer.
#' @export
#' @examples
#' library(ggplot2)
#'
#' # Confidence band around a sine wave
#' x <- seq(0, 2 * pi, length.out = 60)
#' df <- data.frame(x = x, ymin = sin(x) - 0.3, ymax = sin(x) + 0.3)
#' ggplot(df, aes(x, ymin = ymin, ymax = ymax)) +
#'   geom_ribbon_pattern(pattern = "hatch", fill = "lightblue") +
#'   theme_minimal()
#'
#' # Stacked area chart with patterns
#' df2 <- data.frame(
#'   x       = c(1:5, 1:5),
#'   y       = c(1, 2, 3, 2, 1, 2, 1, 3, 2, 1),
#'   group   = rep(c("A", "B"), each = 5),
#'   pattern = rep(c("hatch", "crosshatch"), each = 5)
#' )
#' ggplot(df2, aes(x, y, fill = group, pattern = pattern)) +
#'   geom_area_pattern(position = "stack") +
#'   scale_pattern_identity(guide = "legend") +
#'   theme_minimal()
geom_ribbon_pattern <- function(
    mapping      = NULL,
    data         = NULL,
    stat         = "identity",
    position     = "identity",
    ...,
    outline.type = "both",
    na.rm        = FALSE,
    show.legend  = NA,
    inherit.aes  = TRUE
) {
  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomRibbonPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = rlang::list2(outline.type = outline.type, na.rm = na.rm, ...)
  )
}

#' @rdname geom_ribbon_pattern
#' @export
geom_area_pattern <- function(
    mapping      = NULL,
    data         = NULL,
    stat         = "identity",
    position     = "stack",
    ...,
    outline.type = "upper",
    na.rm        = FALSE,
    show.legend  = NA,
    inherit.aes  = TRUE
) {
  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomAreaPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = rlang::list2(outline.type = outline.type, na.rm = na.rm, ...)
  )
}
