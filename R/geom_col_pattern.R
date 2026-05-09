# R/geom_col_pattern.R
# ------------------------------------------------------------
# geom_col_pattern() and geom_bar_pattern() — bar/col charts
# with pattern overlays mapped to a variable.
#
# GeomColPattern extends GeomRectPattern (not GeomRect directly)
# so that draw_panel is shared with geom_rect_pattern and
# geom_tile_pattern.  Only setup_data differs: bars arrive with
# x/y from stat + position, so we derive xmin/xmax/ymin/ymax here
# before the shared draw_panel runs.
# ------------------------------------------------------------

#' @include geom_rect_pattern.R
#' @importFrom ggplot2 ggproto GeomRect layer aes
NULL

# ---- Core Geom -------------------------------------------------------------

#' @rdname geom_col_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomColPattern <- ggplot2::ggproto(
  "GeomColPattern",
  GeomRectPattern,

  # required_aes overrides GeomRect's alternative form because bars arrive
  # with x/y (not xmin/xmax) and setup_data below converts them.
  required_aes = c("x", "y"),

  # aesthetics and default_aes are inherited from GeomRectPattern unchanged.

  # GeomRectPattern (and GeomRect) expect xmin/xmax/ymin/ymax already present.
  # For bars, data arrives with just x/y from stat + position, so derive the
  # corners here.  The * 0.9 shrink gives bars a gap between them; without it
  # adjacent bars would be flush (resolution() returns the grid spacing).
  setup_data = function(self, data, params) {
    if (!("xmin" %in% names(data))) {
      w <- params$width %||% (ggplot2::resolution(data$x, FALSE) * 0.9)
      data$xmin <- data$x - w / 2
      data$xmax <- data$x + w / 2
      data$ymin <- pmin(data$y, 0)
      data$ymax <- pmax(data$y, 0)
    }
    data
  }
)

# ---- User-facing layer functions -------------------------------------------

#' Bar and column charts with pattern overlays
#'
#' These are drop-in replacements for [ggplot2::geom_col()] and
#' [ggplot2::geom_bar()] that add support for a `pattern` aesthetic.
#' Map `pattern` to a discrete variable using [scale_pattern_manual()] or
#' [scale_pattern_discrete()].
#'
#' @section Pattern aesthetics:
#' In addition to all aesthetics accepted by [ggplot2::geom_col()], these
#' geoms accept:
#' \describe{
#'   \item{`pattern`}{Character name of the pattern. One of `"none"`,
#'     `"hatch"`, `"crosshatch"`, `"horizontal"`, `"vertical"`, `"dots"`,
#'     `"weave"`, or a custom pattern registered with [register_pattern()].}
#'   \item{`pattern_colour`}{Colour of pattern lines/dots. Default `"black"`.}
#'   \item{`pattern_linewidth`}{Line width for line-based patterns. Default `1`.}
#'   \item{`pattern_spacing`}{Spacing between pattern elements as a fraction
#'     of the bar width/height (npc units). Default `0.08`.}
#'   \item{`pattern_angle`}{Angle in degrees for hatch patterns. Default `45`.}
#'   \item{`pattern_size`}{Dot diameter in mm for the `"dots"` pattern.
#'     Default `0.4`.}
#' }
#'
#' @param mapping Aesthetic mappings created by [ggplot2::aes()].
#' @param data Data frame.
#' @param position Position adjustment. Default `"stack"`.
#' @param ... Other arguments passed to the layer.
#' @param width Bar width, as a proportion of the bin width.
#' @param na.rm If `FALSE` (default), missing values are removed with a warning.
#' @param show.legend Logical. Should this layer be included in the legend?
#' @param inherit.aes If `FALSE`, overrides the default aesthetics.
#'
#' @return A ggplot2 layer.
#' @export
#' @examples
#' library(ggplot2)
#'
#' # geom_bar_pattern uses stat="count" automatically
#' ggplot(mpg, aes(class, fill = class, pattern = class)) +
#'   geom_bar_pattern() +
#'   scale_pattern_discrete() +
#'   theme_minimal()
#'
#' # geom_col_pattern needs x and y (pre-summarised data)
#' df <- data.frame(
#'   group = c("A", "B", "C"),
#'   value = c(3, 5, 4)
#' )
#' ggplot(df, aes(group, value, fill = group, pattern = group)) +
#'   geom_col_pattern() +
#'   scale_pattern_manual(values = c(A = "hatch", B = "dots", C = "crosshatch")) +
#'   scale_fill_brewer(palette = "Pastel1")
geom_col_pattern <- function(
    mapping  = NULL,
    data     = NULL,
    position = "stack",
    ...,
    width      = NULL,
    na.rm      = FALSE,
    show.legend = NA,
    inherit.aes = TRUE
) {
  # Only pass `width` through if the user supplied it. Passing `width = NULL`
  # triggers ggplot2's "Ignoring empty aesthetic: `width`" warning during
  # compute_geom_2, because it treats the param slot as an unmapped aesthetic.
  params <- rlang::list2(na.rm = na.rm, ...)
  if (!is.null(width)) params$width <- width

  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = "identity",
    geom        = GeomColPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = params
  )
}

#' @rdname geom_col_pattern
#' @export
geom_bar_pattern <- function(
    mapping  = NULL,
    data     = NULL,
    position = "stack",
    ...,
    width      = NULL,
    na.rm      = FALSE,
    show.legend = NA,
    inherit.aes = TRUE
) {
  params <- rlang::list2(na.rm = na.rm, ...)
  if (!is.null(width)) params$width <- width

  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = "count",
    geom        = GeomColPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = params
  )
}
