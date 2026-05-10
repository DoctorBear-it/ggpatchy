# R/geom_polygon_pattern.R
# ------------------------------------------------------------
# geom_polygon_pattern() — patterns clipped to arbitrary polygons.
# This is the hard one: non-rectangular clipping.
# ------------------------------------------------------------

#' @importFrom ggplot2 ggproto GeomPolygon layer aes .pt
#' @importFrom grid gTree gList polygonGrob pathGrob gpar nullGrob unit viewport as.path
#' @importFrom scales alpha
NULL

#' @rdname geom_polygon_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomPolygonPattern <- ggplot2::ggproto(
  "GeomPolygonPattern",
  ggplot2::GeomPolygon,

  aesthetics = function(self) {
    c(
      ggplot2::GeomPolygon$aesthetics(),
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
    colour    = "grey20",
    fill      = "white",
    linewidth = 0.5,
    linetype  = 1,
    alpha     = NA,
    pattern                  = "none",
    pattern_colour           = "black",
    pattern_linewidth        = 1,
    pattern_spacing          = 5,
    pattern_angle            = 45,
    pattern_size             = 0.5,
    pattern_contrast_check   = 0,
    pattern_contrast_correct = FALSE
  ),

  draw_panel = function(self, data, panel_params, coord, rule = "evenodd") {
    n <- nrow(data)
    if (n == 0) return(grid::nullGrob())

    coords <- coord$transform(data, panel_params)
    coords$pattern <- warn_na_patterns(coords$pattern)

    # Draw base filled polygons directly — avoids ggproto dispatch issues
    # with GeomPolygon$draw_panel(self, ...) in ggplot2 4.0
    groups <- split(coords, coords$group)

    base_grobs <- lapply(groups, function(grp) {
      grid::polygonGrob(
        x  = grp$x,
        y  = grp$y,
        gp = grid::gpar(
          col  = grp$colour[1]   %||% "grey20",
          fill = scales::alpha(grp$fill[1] %||% "white", grp$alpha[1] %||% NA),
          lwd  = (grp$linewidth[1] %||% 0.5) * ggplot2::.pt,
          lty  = grp$linetype[1]  %||% 1
        )
      )
    })

    .contrast_failures <- character(0)

    overlay_grobs <- lapply(groups, function(grp) {
      pattern_name <- grp$pattern[1] %||% "none"
      if (pattern_name == "none") return(grid::nullGrob())

      x_range <- range(grp$x, na.rm = TRUE)
      y_range <- range(grp$y, na.rm = TRUE)
      bx <- x_range[1]; by <- y_range[1]
      bw <- diff(x_range); bh <- diff(y_range)
      if (bw <= 0 || bh <= 0) return(grid::nullGrob())

      pattern_fn <- get_pattern_fn(pattern_name)

      # ---- Contrast check / correction ----------------------------------------
      {
        check_val <- grp$pattern_contrast_check[1] %||% 0
        if (isTRUE(check_val)) check_val <- 3.0
        threshold <- as.numeric(check_val)

        correct <- isTRUE(grp$pattern_contrast_correct[1] %||% FALSE)
        if (correct && threshold == 0) threshold <- 3.0

        pc   <- grp$pattern_colour[1] %||% "black"
        fill <- grp$fill[1]           %||% "white"

        if (correct && threshold > 0) {
          pc <- .apply_contrast_correction(pc, fill, threshold)
        }

        if (threshold > 0) {
          ratio <- pattern_contrast(pc, fill)
          if (ratio < threshold) {
            .contrast_failures <<- c(.contrast_failures,
              sprintf("contrast %.2f:1 (pattern_colour=%s, fill=%s)", ratio, pc, fill))
          }
        }
      }
      # -------------------------------------------------------------------------

      base_gp <- grid::gpar(
        pattern_colour    = pc,
        pattern_linewidth = grp$pattern_linewidth[1] %||% 1
      )
      params <- list(
        pattern_spacing = grp$pattern_spacing[1] %||% 5,
        pattern_angle   = grp$pattern_angle[1]   %||% 45,
        pattern_size    = grp$pattern_size[1]     %||% 0.5,
        poly_x = (grp$x - bx) / bw,
        poly_y = (grp$y - by) / bh
      )

      pattern_grob <- pattern_fn(bx, by, bw, bh, gp = base_gp, params = params)

      if (.has_clip_path_support()) {
        clip_path_grob <- grid::pathGrob(
          x    = grid::unit(grp$x, "npc"),
          y    = grid::unit(grp$y, "npc"),
          rule = rule,
          gp   = grid::gpar(fill = "black", col = NA)
        )
        vp <- grid::viewport(clip = grid::as.path(clip_path_grob))
        grid::gTree(children = grid::gList(pattern_grob), vp = vp)
      } else {
        pattern_grob
      }
    })

    if (length(.contrast_failures) > 0) {
      n   <- length(.contrast_failures)
      low <- .contrast_failures[
        which.min(as.numeric(sub("contrast ([0-9.]+):1.*", "\\1",
                                 .contrast_failures)))
      ]
      rlang::warn(
        paste0(
          n, " shape", if (n > 1) "s", " ",
          if (n > 1) "have" else "has",
          " pattern contrast below threshold. ",
          "Lowest: ", low, ". ",
          "Set pattern_contrast_correct = TRUE to auto-adjust."
        ),
        call = NULL
      )
    }

    grid::gTree(
      children = do.call(grid::gList, c(base_grobs, overlay_grobs))
    )
  },

  draw_key = draw_key_pattern
)

#' Polygons with pattern overlays
#'
#' A drop-in replacement for [ggplot2::geom_polygon()] that adds a `pattern`
#' aesthetic. Patterns are correctly clipped to the polygon boundary using
#' device-independent in-R geometry: line patterns via parametric
#' segment-polygon intersection, dot patterns via ray-casting point-in-polygon.
#' No special R version or device support is required.
#'
#' @param mapping Aesthetic mappings created by [ggplot2::aes()].
#' @param data Data frame.
#' @param stat Statistical transformation. Default `"identity"`.
#' @param position Position adjustment. Default `"identity"`.
#' @param rule Fill rule for polygon winding: `"evenodd"` or `"winding"`.
#' @param ... Other arguments passed to the layer.
#' @param na.rm If `FALSE` (default), missing values are removed with a warning.
#' @param show.legend Logical. Should this layer be included in the legend?
#' @param inherit.aes If `FALSE`, overrides the default aesthetics.
#' @export
geom_polygon_pattern <- function(
    mapping     = NULL,
    data        = NULL,
    stat        = "identity",
    position    = "identity",
    rule        = "evenodd",
    ...,
    na.rm       = FALSE,
    show.legend = NA,
    inherit.aes = TRUE
) {
  ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomPolygonPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = rlang::list2(rule = rule, na.rm = na.rm, ...)
  )
}