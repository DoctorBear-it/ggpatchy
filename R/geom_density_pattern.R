# R/geom_density_pattern.R
# ------------------------------------------------------------
# geom_density_pattern() — kernel density estimates with pattern
# overlays clipped to the density area polygon.
#
# GeomDensityPattern extends GeomAreaPattern.  stat_density produces
# x (evaluation points) and y (density values); GeomAreaPattern's
# setup_data sets ymin = 0, ymax = y and orders rows by x, producing
# the closed area polygon that the pattern clipper works against.
#
# orientation = "y" (horizontal densities, flipped_aes = TRUE) is not
# supported for the pattern overlay — the base area renders correctly
# but the pattern is silently skipped, consistent with the same
# limitation in GeomAreaPattern / GeomRibbonPattern.
# ------------------------------------------------------------

#' @include geom_ribbon_pattern.R
#' @importFrom ggplot2 ggproto layer aes
NULL

# ---- GeomDensityPattern ----------------------------------------------------

#' @rdname geom_density_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomDensityPattern <- ggplot2::ggproto("GeomDensityPattern", GeomAreaPattern)

# ---- User-facing layer function --------------------------------------------

#' Kernel density estimates with pattern overlays
#'
#' A drop-in replacement for [ggplot2::geom_density()] that adds a `pattern`
#' aesthetic. The pattern is clipped to the filled area under the density
#' curve using the same device-independent in-R geometry as
#' [geom_ribbon_pattern()].
#'
#' @section Pattern aesthetics:
#' In addition to all aesthetics accepted by [ggplot2::geom_density()], this
#' geom accepts:
#' \describe{
#'   \item{`pattern`}{Character name of the pattern. One of `"none"`,
#'     `"hatch"`, `"crosshatch"`, `"horizontal"`, `"vertical"`, `"dots"`,
#'     `"weave"`, or a custom pattern registered with [register_pattern()].}
#'   \item{`pattern_colour`}{Colour of pattern lines/dots. Default `"black"`.}
#'   \item{`pattern_linewidth`}{Line width for line-based patterns. Default `1`.}
#'   \item{`pattern_spacing`}{Spacing relative to the density bounding box
#'     (npc units). Default `0.08`.}
#'   \item{`pattern_angle`}{Angle in degrees for hatch patterns. Default `45`.}
#'   \item{`pattern_size`}{Dot diameter in mm for the `"dots"` pattern.
#'     Default `0.4`.}
#' }
#'
#' @section Limitations:
#' `orientation = "y"` (horizontal densities) is not supported for the pattern
#' overlay. The base density area renders correctly, but the pattern is
#' silently skipped. Use `coord_flip()` on a vertical density as a workaround.
#'
#' `position = "stack"` is supported: stacked densities are filled from 0 to
#' the cumulative density, and the pattern follows the same filled region.
#'
#' @param mapping Aesthetic mappings created by [ggplot2::aes()].
#' @param data Data frame.
#' @param stat Statistical transformation. Default `"density"`.
#' @param position Position adjustment. Default `"identity"`.
#' @param ... Additional arguments passed to [ggplot2::stat_density()] (e.g.
#'   `bw`, `adjust`, `kernel`, `n`).
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
#' # Single density with hatch pattern
#' ggplot(faithful, aes(waiting)) +
#'   geom_density_pattern(pattern = "hatch", fill = "lightblue") +
#'   theme_minimal()
#'
#' # Multiple groups with different patterns
#' ggplot(mpg, aes(hwy, fill = drv, pattern = drv)) +
#'   geom_density_pattern(alpha = 0.6) +
#'   scale_pattern_manual(values = c("4" = "hatch", "f" = "crosshatch",
#'                                   "r" = "dots")) +
#'   scale_fill_brewer(palette = "Pastel1") +
#'   theme_minimal()
geom_density_pattern <- function(
    mapping     = NULL,
    data        = NULL,
    stat        = "density",
    position    = "identity",
    ...,
    na.rm       = FALSE,
    orientation = NA,
    show.legend = NA,
    inherit.aes = TRUE
) {
  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomDensityPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = rlang::list2(na.rm = na.rm, orientation = orientation, ...)
  )
}
