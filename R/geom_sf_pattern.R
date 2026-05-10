# R/geom_sf_pattern.R
# ------------------------------------------------------------
# geom_sf_pattern() — sf polygon maps with pattern overlays.
#
# GeomSfPattern extends GeomSf and overrides draw_panel. The base
# grob is produced by the parent (which handles all geometry types,
# CRS, graticule, etc.); pattern overlays are added independently.
#
# Coordinate handling: GeomSf$draw_panel calls coord$transform
# internally, normalising geometry to panel [0,1] NPC via
# sf_rescale01 / sf::st_normalize. We call coord$transform again on
# the original `data` to obtain the same [0,1] NPC coordinates for
# pattern computation — same pattern used by GeomRibbonPattern.
#
# POLYGON:          outer ring (L1 == 1); inner rings (holes) ignored.
# MULTIPOLYGON:     each sub-polygon (unique L2) outer ring separately.
# GEOMETRYCOLLECTION: base grob rendered; pattern skipped with warning.
# All other types:  base grob rendered; pattern silently skipped.
# ------------------------------------------------------------

#' @importFrom ggplot2 ggproto ggproto_parent aes layer
#' @importFrom grid nullGrob grobTree gList gTree pathGrob gpar unit viewport as.path
NULL

# ---- GeomSfPattern ---------------------------------------------------------

#' @rdname geom_sf_pattern
#' @format NULL
#' @usage NULL
#' @export
GeomSfPattern <- ggplot2::ggproto(
  "GeomSfPattern",
  ggplot2::GeomSf,

  draw_key = draw_key_pattern,

  aesthetics = function(self) {
    c(
      ggplot2::GeomSf$aesthetics(),
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
    shape     = NULL,
    colour    = NULL,
    fill      = NULL,
    size      = NULL,
    linewidth = NULL,
    linetype  = 1,
    alpha     = NA,
    stroke    = 0.5,
    pattern                  = "none",
    pattern_colour           = "black",
    pattern_linewidth        = 1,
    pattern_spacing          = 5,
    pattern_angle            = 45,
    pattern_size             = 0.5,
    pattern_contrast_check   = 0,
    pattern_contrast_correct = FALSE
  ),

  draw_panel = function(self, data, panel_params, coord, legend = NULL,
                        lineend = "butt", linejoin = "round", linemitre = 10,
                        arrow = NULL, arrow.fill = NULL, na.rm = TRUE) {
    # Render all geometry types via parent (handles CRS, graticule, etc.).
    # GeomSf$draw_panel calls coord$transform internally on its own copy.
    base_grob <- ggplot2::ggproto_parent(ggplot2::GeomSf, self)$draw_panel(
      data, panel_params, coord, legend = legend,
      lineend = lineend, linejoin = linejoin, linemitre = linemitre,
      arrow = arrow, arrow.fill = arrow.fill, na.rm = na.rm
    )

    if (!requireNamespace("sf", quietly = TRUE)) return(base_grob)

    # `data` above is the original untransformed parameter — same data the
    # parent already transformed internally. We transform again here to get
    # the geometry vertices in panel [0,1] NPC (via sf_rescale01).
    # Do NOT apply x_range/y_range rescaling on top of this — that step is
    # already baked into coord$transform for sf coords.
    transformed <- coord$transform(data, panel_params)
    transformed$pattern <- warn_na_patterns(
      transformed$pattern %||% rep("none", nrow(transformed))
    )

    has_geocollection  <- FALSE
    overlay_grobs      <- vector("list", nrow(transformed))
    n_overlays         <- 0L
    .contrast_failures <- character(0)

    for (i in seq_len(nrow(transformed))) {
      pat <- transformed$pattern[i]
      if (is.na(pat) || pat == "none") next

      geom_i   <- transformed$geometry[[i]]
      type_str <- as.character(sf::st_geometry_type(geom_i))

      if (type_str == "GEOMETRYCOLLECTION") {
        has_geocollection <- TRUE
        next
      }
      if (!type_str %in% c("POLYGON", "MULTIPOLYGON")) next

      pat_fn <- get_pattern_fn(pat)

      # ---- Contrast check / correction ----------------------------------------
      {
        check_val <- transformed$pattern_contrast_check[i] %||% 0
        if (isTRUE(check_val)) check_val <- 3.0
        threshold <- as.numeric(check_val)

        correct <- isTRUE(transformed$pattern_contrast_correct[i] %||% FALSE)
        if (correct && threshold == 0) threshold <- 3.0

        pc   <- transformed$pattern_colour[i] %||% "black"
        fill <- transformed$fill[i] %||% NA_character_

        if (!is.na(fill) && fill != "transparent") {
          if (correct && threshold > 0) {
            pc <- .apply_contrast_correction(pc, fill, threshold)
          }
          if (threshold > 0) {
            ratio <- pattern_contrast(pc, fill)
            if (ratio < threshold) {
              .contrast_failures <- c(.contrast_failures,
                sprintf("contrast %.2f:1 (pattern_colour=%s, fill=%s)", ratio, pc, fill))
            }
          }
        }
      }
      # -------------------------------------------------------------------------

      base_gp <- grid::gpar(
        pattern_colour    = pc,
        pattern_linewidth = transformed$pattern_linewidth[i] %||% 1
      )
      params_base <- list(
        pattern_spacing   = transformed$pattern_spacing[i]   %||% 5,
        pattern_angle     = transformed$pattern_angle[i]     %||% 45,
        pattern_size      = transformed$pattern_size[i]      %||% 0.5,
        pattern_linewidth = transformed$pattern_linewidth[i] %||% 1
      )

      coords <- sf::st_coordinates(geom_i)

      if (type_str == "POLYGON") {
        grob <- .sf_ring_pattern(coords, "L1", pat_fn, base_gp, params_base)
        if (!is.null(grob)) {
          n_overlays <- n_overlays + 1L
          overlay_grobs[[n_overlays]] <- grob
        }
      } else {
        # MULTIPOLYGON: L2 indexes sub-polygons; L1 indexes rings within each.
        for (sub_i in unique(coords[, "L2"])) {
          sub  <- coords[coords[, "L2"] == sub_i, , drop = FALSE]
          grob <- .sf_ring_pattern(sub, "L1", pat_fn, base_gp, params_base)
          if (!is.null(grob)) {
            n_overlays <- n_overlays + 1L
            overlay_grobs[[n_overlays]] <- grob
          }
        }
      }
    }

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

    # has_geocollection flag ensures at most one warning per draw_panel call,
    # regardless of how many GEOMETRYCOLLECTION rows are present.
    if (has_geocollection) {
      rlang::warn(
        paste0(
          "geom_sf_pattern() skipped pattern overlays for GEOMETRYCOLLECTION ",
          "geometries. Base geometry was rendered."
        ),
        call = NULL
      )
    }

    if (n_overlays == 0L) return(base_grob)

    grid::grobTree(base_grob, do.call(grid::gList, overlay_grobs[seq_len(n_overlays)]))
  }
)

# Extract outer ring (ring_col == 1) from a coordinate matrix, normalize to
# bbox-relative [0,1], and apply pat_fn. Returns NULL if degenerate (<3 pts
# or zero-area bbox). Geometry coordinates must already be in panel [0,1] NPC.
.sf_ring_pattern <- function(coords, ring_col, pat_fn, gp, params) {
  outer <- coords[coords[, ring_col] == 1L, , drop = FALSE]
  if (nrow(outer) < 3L) return(NULL)

  x_npc <- outer[, "X"]
  y_npc <- outer[, "Y"]
  x_rng <- range(x_npc)
  y_rng <- range(y_npc)
  bw    <- diff(x_rng)
  bh    <- diff(y_rng)
  if (bw < 1e-9 || bh < 1e-9) return(NULL)

  pattern_grob <- pat_fn(
    x      = x_rng[1],
    y      = y_rng[1],
    width  = bw,
    height = bh,
    gp     = gp,
    params = c(params, list(
      poly_x = (x_npc - x_rng[1]) / bw,
      poly_y = (y_npc - y_rng[1]) / bh
    ))
  )

  if (.has_clip_path_support()) {
    clip_path_grob <- grid::pathGrob(
      x    = grid::unit(x_npc, "npc"),
      y    = grid::unit(y_npc, "npc"),
      rule = "evenodd",
      gp   = grid::gpar(fill = "black", col = NA)
    )
    vp <- grid::viewport(clip = grid::as.path(clip_path_grob))
    grid::gTree(children = grid::gList(pattern_grob), vp = vp)
  } else {
    pattern_grob
  }
}

# ---- User-facing layer function --------------------------------------------

#' SF polygon maps with pattern overlays
#'
#' A drop-in replacement for [ggplot2::geom_sf()] that adds a `pattern`
#' aesthetic. Patterns are clipped to the exact polygon boundary using the
#' same device-independent in-R geometry as [geom_polygon_pattern()].
#' Requires the `sf` package.
#'
#' @section Pattern aesthetics:
#' In addition to all aesthetics accepted by [ggplot2::geom_sf()], this geom
#' accepts:
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
#' @section Geometry type support:
#' POLYGON and MULTIPOLYGON features receive pattern overlays. POINT and
#' LINESTRING features render correctly via the base [ggplot2::geom_sf()] but
#' without pattern overlays (silently skipped). Mixed geometry types in the
#' same layer are supported.
#'
#' @note
#' **GEOMETRYCOLLECTION**: rows with GEOMETRYCOLLECTION geometry produce a
#' warning and no pattern overlay; the base geometry is still rendered.
#'
#' **Holes in polygons**: inner rings (holes / donuts) are silently ignored —
#' the pattern fills the entire outer boundary including hole areas. This is a
#' limitation of the in-R polygon clipping approach.
#'
#' @param mapping Aesthetic mappings created by [ggplot2::aes()].
#' @param data An sf data frame or compatible object.
#' @param stat Statistical transformation. Default `"sf"`.
#' @param position Position adjustment. Default `"identity"`.
#' @param ... Other arguments passed to the layer.
#' @param na.rm If `FALSE` (default), missing values are removed with a warning.
#' @param show.legend Logical or character. Should this layer be included in
#'   the legends?
#' @param inherit.aes If `FALSE`, overrides the default aesthetics.
#'
#' @return A ggplot2 layer.
#' @export
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   library(ggplot2)
#'   library(sf)
#'
#'   sq1 <- st_polygon(list(cbind(c(0,1,1,0,0), c(0,0,1,1,0))))
#'   sq2 <- st_polygon(list(cbind(c(1,2,2,1,1), c(0,0,1,1,0))))
#'   df  <- data.frame(
#'     region  = c("A", "B"),
#'     pattern = c("hatch", "dots"),
#'     geometry = st_sfc(sq1, sq2, crs = 4326)
#'   )
#'   sf::st_geometry(df) <- "geometry"
#'
#'   ggplot(df) +
#'     geom_sf_pattern(aes(fill = region, pattern = pattern)) +
#'     scale_pattern_identity(guide = "legend") +
#'     scale_fill_brewer(palette = "Pastel1") +
#'     theme_minimal()
#' }
geom_sf_pattern <- function(
    mapping     = ggplot2::aes(),
    data        = NULL,
    stat        = "sf",
    position    = "identity",
    ...,
    na.rm       = FALSE,
    show.legend = NA,
    inherit.aes = TRUE
) {
  if (!requireNamespace("sf", quietly = TRUE))
    stop(
      "geom_sf_pattern() requires the 'sf' package.\n",
      "Install it with: install.packages(\"sf\")",
      call. = FALSE
    )

  # Mirror ggplot2::geom_sf exactly: use LayerSf (not Layer) so that
  # setup_layer() auto-maps the sf geometry column to the `geometry`
  # aesthetic when the data is an sf object. Return the layer bundled
  # with a default coord_sf() so the plot coordinate system is set
  # automatically — identical to what geom_sf() does.
  layer <- ggplot2::layer(
    data        = data,
    mapping     = mapping,
    stat        = stat,
    geom        = GeomSfPattern,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = rlang::list2(na.rm = na.rm, ...),
    layer_class = ggplot2:::LayerSf  # nolint: triple_colon_linter
  )
  c(layer, ggplot2::coord_sf(default = TRUE))
}
