# R/geom_rect_pattern.R
# ------------------------------------------------------------
# GeomRectPattern  — shared draw_panel for all rectangle-based
#                    pattern geoms (rect, tile, col/bar).
# GeomTilePattern  — extends GeomRectPattern; converts center/size
#                    aesthetics (x, y, width, height) to corners.
# geom_rect_pattern()  — explicit corner aesthetics.
# geom_tile_pattern()  — center + size aesthetics.
# ------------------------------------------------------------

#' @importFrom ggplot2 ggproto GeomRect layer aes .pt resolution
#' @importFrom grid gTree gList unit gpar nullGrob rectGrob
#' @importFrom scales alpha
NULL

# ---- GeomRectPattern -------------------------------------------------------

#' @rdname geom_rect_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomRectPattern <- ggplot2::ggproto(
  "GeomRectPattern",
  ggplot2::GeomRect,

  # required_aes inherited from GeomRect:
  #   c("x|width|xmin|xmax", "y|height|ymin|ymax")
  # GeomRect$setup_data normalises any valid combination to xmin/xmax/ymin/ymax
  # before draw_panel runs, so the draw code can rely on all four being present.

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

  draw_panel = function(self, data, panel_params, coord, ...) {
    coords <- coord$transform(data, panel_params)

    # Base filled rectangles — avoids ggproto dispatch issues with
    # GeomRect$draw_panel(self, ...) in ggplot2 4.0.
    rect_grobs <- lapply(seq_len(nrow(coords)), function(i) {
      row <- coords[i, ]
      grid::rectGrob(
        x      = row$xmin,
        y      = row$ymin,
        width  = row$xmax - row$xmin,
        height = row$ymax - row$ymin,
        just   = c("left", "bottom"),
        gp     = grid::gpar(
          col  = row$colour   %||% NA,
          fill = scales::alpha(row$fill %||% "grey35", row$alpha %||% NA),
          lwd  = (row$linewidth %||% 0.5) * ggplot2::.pt,
          lty  = row$linetype  %||% 1
        )
      )
    })

    coords$pattern <- warn_na_patterns(coords$pattern)

    pattern_grobs <- lapply(seq_len(nrow(coords)), function(i) {
      row <- coords[i, ]

      pattern_name <- row$pattern %||% "none"
      if (pattern_name == "none") return(grid::nullGrob())

      pattern_fn <- get_pattern_fn(pattern_name)

      w <- row$xmax - row$xmin
      h <- row$ymax - row$ymin
      if (w <= 0 || h <= 0) return(grid::nullGrob())

      base_gp <- grid::gpar(
        pattern_colour    = row$pattern_colour    %||% "black",
        pattern_linewidth = row$pattern_linewidth %||% 1
      )
      params <- list(
        pattern_spacing = row$pattern_spacing %||% 0.08,
        pattern_angle   = row$pattern_angle   %||% 45,
        pattern_size    = row$pattern_size    %||% 0.4
      )

      pattern_fn(row$xmin, row$ymin, w, h, gp = base_gp, params = params)
    })

    grid::gTree(children = do.call(grid::gList, c(rect_grobs, pattern_grobs)))
  },

  draw_key = draw_key_pattern
)

# ---- GeomTilePattern -------------------------------------------------------

#' @rdname geom_rect_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomTilePattern <- ggplot2::ggproto(
  "GeomTilePattern",
  GeomRectPattern,

  required_aes = c("x", "y"),

  # Tiles allow width/height to come from the aesthetic, from params, or to be
  # computed automatically as the resolution of x/y (the smallest gap between
  # adjacent values).  This mirrors GeomTile's setup_data without calling the
  # internal compute_data_size() helper.
  setup_data = function(self, data, params) {
    data$width  <- data$width  %||% params$width  %||%
      ggplot2::resolution(data$x, zero = FALSE)
    data$height <- data$height %||% params$height %||%
      ggplot2::resolution(data$y, zero = FALSE)
    transform(data,
      xmin = x - width  / 2, xmax = x + width  / 2, width  = NULL,
      ymin = y - height / 2, ymax = y + height / 2, height = NULL
    )
  }
)

# ---- User-facing layer functions -------------------------------------------

#' Rectangle and tile charts with pattern overlays
#'
#' Drop-in replacements for [ggplot2::geom_rect()] and [ggplot2::geom_tile()]
#' that add a `pattern` aesthetic. Patterns are drawn on top of a filled
#' rectangle and clipped to its bounding box.
#'
#' `geom_rect_pattern()` requires explicit corner aesthetics (`xmin`, `xmax`,
#' `ymin`, `ymax`). `geom_tile_pattern()` accepts center + size aesthetics
#' (`x`, `y` plus optional `width` and `height`; widths/heights default to the
#' resolution of the x/y values so tiles tessellate without gaps).
#'
#' @section Pattern aesthetics:
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
#'     of the rectangle width/height (npc units). Default `0.08`.}
#'   \item{`pattern_angle`}{Angle in degrees for hatch patterns. Default `45`.}
#'   \item{`pattern_size`}{Dot diameter in mm for the `"dots"` pattern.
#'     Default `0.4`.}
#' }
#'
#' @param mapping Aesthetic mappings created by [ggplot2::aes()].
#' @param data Data frame.
#' @param stat Statistical transformation. Default `"identity"`.
#' @param position Position adjustment. Default `"identity"`.
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
#' # Explicit corner coordinates
#' df <- data.frame(
#'   xmin = c(0, 1, 2), xmax = c(0.8, 1.8, 2.8),
#'   ymin = 0, ymax = c(1, 3, 2),
#'   pattern = c("hatch", "crosshatch", "dots")
#' )
#' ggplot(df, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
#'                fill = pattern, pattern = pattern)) +
#'   geom_rect_pattern() +
#'   scale_pattern_identity() +
#'   scale_fill_brewer(palette = "Pastel1") +
#'   theme_minimal()
geom_rect_pattern <- function(
    mapping  = NULL,
    data     = NULL,
    stat     = "identity",
    position = "identity",
    ...,
    na.rm       = FALSE,
    show.legend = NA,
    inherit.aes = TRUE
) {
  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomRectPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = rlang::list2(na.rm = na.rm, ...)
  )
}

#' @rdname geom_rect_pattern
#' @param width,height Tile width and height in data units. If `NULL`
#'   (default), computed as the resolution of `x`/`y`.
#' @export
#' @examples
#'
#' # Heatmap-style tile chart
#' df2 <- expand.grid(x = 1:4, y = 1:4)
#' df2$pattern <- rep(c("hatch", "crosshatch", "dots", "none"), 4)
#' df2$fill_g  <- rep(letters[1:4], each = 4)
#' ggplot(df2, aes(x, y, fill = fill_g, pattern = pattern)) +
#'   geom_tile_pattern() +
#'   scale_pattern_identity() +
#'   scale_fill_brewer(palette = "Pastel2") +
#'   theme_minimal()
geom_tile_pattern <- function(
    mapping  = NULL,
    data     = NULL,
    stat     = "identity",
    position = "identity",
    ...,
    width       = NULL,
    height      = NULL,
    na.rm       = FALSE,
    show.legend = NA,
    inherit.aes = TRUE
) {
  params <- rlang::list2(na.rm = na.rm, ...)
  if (!is.null(width))  params$width  <- width
  if (!is.null(height)) params$height <- height

  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomTilePattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = params
  )
}
