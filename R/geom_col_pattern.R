# R/geom_col_pattern.R
# ------------------------------------------------------------
# geom_col_pattern() and geom_bar_pattern() — bar/col charts
# with pattern overlays mapped to a variable.
#
# We inherit from GeomRect rather than GeomBar because ggplot2 4.0
# restructured GeomBar to no longer expose a draw_panel method we
# can safely override. GeomRect draws filled rectangles from
# xmin/xmax/ymin/ymax, which is exactly what bars are after the
# stat + position stack has run.
# ------------------------------------------------------------

#' @importFrom ggplot2 ggproto GeomRect GeomBar layer aes .pt
#' @importFrom grid gTree gList unit gpar nullGrob rectGrob
#' @importFrom scales alpha
NULL

# ---- Core Geom -------------------------------------------------------------

#' @rdname geom_col_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomColPattern <- ggplot2::ggproto(
  "GeomColPattern",
  ggplot2::GeomRect,

  # GeomRect requires ymin/ymax but we compute them in setup_data from y.
  # Override required_aes so ggplot2 doesn't reject the data before setup_data runs.
  required_aes = c("x", "y"),

  # Declare the extra aesthetics this geom understands
  aesthetics = function(self) {
    c(
      ggplot2::GeomRect$aesthetics(),
      "pattern",
      "pattern_colour",
      "pattern_linewidth",
      "pattern_spacing",
      "pattern_angle",
      "pattern_size"
    )
  },

  default_aes = ggplot2::aes(
    colour    = NA,
    fill      = "grey35",
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

  # GeomRect$setup_data calls resolve_rect() which requires ymin/ymax already
  # present. For the bar case (stat="count"), data arrives with just x/y,
  # so we compute xmin/xmax/ymin/ymax ourselves before passing to GeomRect.
  setup_data = function(self, data, params) {
    if (!("xmin" %in% names(data))) {
      w <- params$width %||% (ggplot2::resolution(data$x, FALSE) * 0.9)
      data$xmin <- data$x - w / 2
      data$xmax <- data$x + w / 2
      data$ymin <- pmin(data$y, 0)
      data$ymax <- pmax(data$y, 0)
    }
    data
  },

  draw_panel = function(self, data, panel_params, coord, ...) {
    # Transform coordinates to npc [0,1] space
    coords <- coord$transform(data, panel_params)

    # Draw base filled rectangles directly — avoids ggproto dispatch issues
    # with GeomRect$draw_panel(self, ...) in ggplot2 4.0
    rect_grobs <- lapply(seq_len(nrow(coords)), function(i) {
      row <- coords[i, ]
      grid::rectGrob(
        x      = row$xmin,
        y      = row$ymin,
        width  = row$xmax - row$xmin,
        height = row$ymax - row$ymin,
        just   = c("left", "bottom"),
        gp     = grid::gpar(
          col      = row$colour   %||% NA,
          fill     = scales::alpha(row$fill %||% "grey35", row$alpha %||% NA),
          lwd      = (row$linewidth %||% 0.5) * ggplot2::.pt,
          lty      = row$linetype  %||% 1
        )
      )
    })

    # Draw pattern overlays on top
    pattern_grobs <- lapply(seq_len(nrow(coords)), function(i) {
      row <- coords[i, ]

      pattern_name <- row$pattern %||% "none"
      if (is.null(pattern_name) || is.na(pattern_name)) pattern_name <- "none"
      if (pattern_name == "none") return(grid::nullGrob())

      pattern_fn <- get_pattern_fn(pattern_name)

      bar_w <- row$xmax - row$xmin
      bar_h <- row$ymax - row$ymin
      if (bar_w <= 0 || bar_h <= 0) return(grid::nullGrob())

      base_gp <- grid::gpar(
        pattern_colour    = row$pattern_colour    %||% "black",
        pattern_linewidth = row$pattern_linewidth %||% 1
      )
      params <- list(
        pattern_spacing = row$pattern_spacing %||% 0.08,
        pattern_angle   = row$pattern_angle   %||% 45,
        pattern_size    = row$pattern_size    %||% 0.4
      )

      pattern_fn(row$xmin, row$ymin, bar_w, bar_h, gp = base_gp, params = params)
    })

    grid::gTree(
      children = do.call(grid::gList, c(rect_grobs, pattern_grobs))
    )
  },

  draw_key = draw_key_pattern
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