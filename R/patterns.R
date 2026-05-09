# R/patterns.R
# ------------------------------------------------------------
# Low-level grid grob constructors for each pattern type.
# Each function takes a bounding box (x, y, width, height in
# native units) and returns a grob clipped to that region.
# ------------------------------------------------------------

#' @importFrom grid linesGrob pointsGrob rectGrob gTree gList clipGrob
#' @importFrom grid viewport unit gpar nullGrob grobTree polylineGrob circleGrob
NULL

# ---- Internal pattern registry -----------------------------------------

.pattern_registry <- new.env(parent = emptyenv())

#' Register a custom pattern function
#'
#' @param name Character name for the pattern (used in `scale_pattern_*`).
#' @param fn A function with signature `fn(x, y, width, height, gp, params)`
#'   that returns a grid grob. `x/y/width/height` are in **npc** units
#'   (0–1 relative to the parent viewport). `gp` is the base `gpar()` from
#'   the geom. `params` is a named list of extra parameters from the scale.
#' @export
register_pattern <- function(name, fn) {
  stopifnot(is.character(name), is.function(fn))
  assign(name, fn, envir = .pattern_registry)
}

get_pattern_fn <- function(name) {
  if (exists(name, envir = .pattern_registry, inherits = FALSE)) {
    get(name, envir = .pattern_registry, inherits = FALSE)
  } else {
    rlang::warn(paste0("Unknown pattern '", name, "', falling back to 'none'."))
    get("none", envir = .pattern_registry, inherits = FALSE)
  }
}

# Replace NA values in a pattern vector with "none", warning once if any found.
warn_na_patterns <- function(pattern_vec) {
  n_na <- sum(is.na(pattern_vec))
  if (n_na > 0L) {
    rlang::warn(paste0(
      n_na,
      if (n_na == 1L) " missing value in the `pattern` aesthetic was"
      else            " missing values in the `pattern` aesthetic were",
      " replaced with \"none\"."
    ))
    pattern_vec[is.na(pattern_vec)] <- "none"
  }
  pattern_vec
}

# ---- Helpers ---------------------------------------------------------------

# Build a viewport clipped to a rectangle, run `expr`, pop it.
# Returns a gTree whose children are rendered inside the clipped vp.
clipped_grob <- function(x, y, width, height, ...) {
  children <- list(...)
  vp <- grid::viewport(
    x = x, y = y,
    width = width, height = height,
    just = c("left", "bottom"),
    clip = "on"
  )
  grid::gTree(children = do.call(grid::gList, children), vp = vp)
}

# Ray-casting point-in-polygon test. Works for convex and concave simple
# (non-self-intersecting) polygons. px/py may be vectors.
pip <- function(px, py, vx, vy) {
  n <- length(vx)
  inside <- logical(length(px))
  j <- n
  for (k in seq_len(n)) {
    xi <- vx[k]; yi <- vy[k]
    xj <- vx[j]; yj <- vy[j]
    cross <- ((yi > py) != (yj > py)) &
      (px < (xj - xi) * (py - yi) / (yj - yi) + xi)
    inside <- xor(inside, cross)
    j <- k
  }
  inside
}

# Clip line segments to a simple polygon (convex or concave, non-self-intersecting).
# Finds all intersections of each segment with polygon edges, then uses a
# midpoint PIP test to keep only sub-segments inside the polygon. A concave
# polygon may produce multiple disjoint sub-segments from a single input line.
# xs/ys: segment start coords; xe/ye: segment end coords (all same length).
# Returns list(xs, ys, xe, ye) of clipped segments.
clip_segments_to_poly <- function(xs, ys, xe, ye, vx, vy) {
  n_edges <- length(vx)
  out_xs <- out_ys <- out_xe <- out_ye <- numeric(0)

  for (i in seq_along(xs)) {
    x0 <- xs[i]; y0 <- ys[i]; x1 <- xe[i]; y1 <- ye[i]
    dx <- x1 - x0; dy <- y1 - y0
    ts <- c(0, 1)

    for (k in seq_len(n_edges)) {
      j <- if (k < n_edges) k + 1L else 1L
      ex <- vx[j] - vx[k]; ey <- vy[j] - vy[k]
      denom <- dy * ex - dx * ey
      if (abs(denom) < 1e-10) next
      t <- ((vy[k] - y0) * ex - (vx[k] - x0) * ey) / denom
      u <- (dx * (vy[k] - y0) - dy * (vx[k] - x0)) / denom
      if (t > 1e-10 && t < 1 - 1e-10 && u >= 0 && u <= 1)
        ts <- c(ts, t)
    }
    ts <- sort(unique(ts))

    for (m in seq_len(length(ts) - 1)) {
      tm <- (ts[m] + ts[m + 1]) / 2
      if (pip(x0 + tm * dx, y0 + tm * dy, vx, vy)) {
        out_xs <- c(out_xs, x0 + ts[m]       * dx)
        out_ys <- c(out_ys, y0 + ts[m]       * dy)
        out_xe <- c(out_xe, x0 + ts[m + 1]   * dx)
        out_ye <- c(out_ye, y0 + ts[m + 1]   * dy)
      }
    }
  }
  list(xs = out_xs, ys = out_ys, xe = out_xe, ye = out_ye)
}

# Generate hatch lines across a unit square, optionally at multiple angles.
# If poly_x/poly_y are supplied (polygon vertices in 0-1 npc coords matching
# the bounding box), lines are clipped to the polygon before building the grob.
# Returns a polylineGrob or nullGrob (if no segments survive clipping).
hatch_lines <- function(angle_deg = 45, spacing_npc = 0.08, gp = grid::gpar(),
                        poly_x = NULL, poly_y = NULL) {
  angle_rad <- angle_deg * pi / 180
  dx <- cos(angle_rad)
  dy <- sin(angle_rad)
  px <- -dy
  py <-  dx

  n_lines <- ceiling(sqrt(2) / spacing_npc) + 2
  offsets <- seq(-n_lines, n_lines) * spacing_npc

  xs <- ys <- xe <- ye <- numeric(length(offsets))
  for (i in seq_along(offsets)) {
    ox <- px * offsets[i]
    oy <- py * offsets[i]
    t_vals <- c(
      if (abs(dx) > 1e-9) c((-1 - ox) / dx, (2 - ox) / dx) else c(-1e9, 1e9),
      if (abs(dy) > 1e-9) c((-1 - oy) / dy, (2 - oy) / dy) else c(-1e9, 1e9)
    )
    t_min <- max(min(t_vals[t_vals > -1e8]), -10)
    t_max <- min(max(t_vals[t_vals <  1e8]),  10)
    xs[i] <- ox + dx * t_min
    ys[i] <- oy + dy * t_min
    xe[i] <- ox + dx * t_max
    ye[i] <- oy + dy * t_max
  }

  if (!is.null(poly_x)) {
    clipped <- clip_segments_to_poly(xs, ys, xe, ye, poly_x, poly_y)
    xs <- clipped$xs; ys <- clipped$ys
    xe <- clipped$xe; ye <- clipped$ye
  }

  if (length(xs) == 0) return(grid::nullGrob())

  grid::polylineGrob(
    x = unit(c(rbind(xs, xe, NA)), "npc"),
    y = unit(c(rbind(ys, ye, NA)), "npc"),
    gp = gp
  )
}

# ---- Built-in pattern definitions -----------------------------------------

.register_builtin_patterns <- function() {

  # none — transparent, no overlay
  register_pattern("none", function(x, y, width, height, gp, params) {
    grid::nullGrob()
  })

  # hatch — single diagonal lines (default 45°)
  register_pattern("hatch", function(x, y, width, height, gp, params) {
    angle   <- params$pattern_angle   %||% 45
    spacing <- params$pattern_spacing %||% 0.08
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 1,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg = angle, spacing_npc = spacing, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y)
    )
  })

  # crosshatch — two sets of lines at 90° to each other
  register_pattern("crosshatch", function(x, y, width, height, gp, params) {
    angle   <- params$pattern_angle   %||% 45
    spacing <- params$pattern_spacing %||% 0.08
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 1,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg = angle,      spacing_npc = spacing, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y),
      hatch_lines(angle_deg = angle + 90, spacing_npc = spacing, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y)
    )
  })

  # horizontal — flat lines (angle fixed at 0°; name defines orientation)
  register_pattern("horizontal", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.08
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 1,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg = 0, spacing_npc = spacing, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y)
    )
  })

  # vertical — straight-up lines (angle fixed at 90°; name defines orientation)
  register_pattern("vertical", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.08
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 1,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg = 90, spacing_npc = spacing, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y)
    )
  })

  # dots — grid of small circles; positions filtered to polygon interior when
  # poly_x/poly_y are supplied.
  register_pattern("dots", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.1
    size    <- params$pattern_size    %||% 0.35
    dot_gp  <- grid::gpar(col = NA, fill = gp$pattern_colour %||% "black")
    xs <- seq(spacing / 2, 1 - spacing / 2, by = spacing)
    ys <- seq(spacing / 2, 1 - spacing / 2, by = spacing)
    gc <- expand.grid(x = xs, y = ys)
    if (!is.null(params$poly_x)) {
      keep <- pip(gc$x, gc$y, params$poly_x, params$poly_y)
      gc <- gc[keep, , drop = FALSE]
    }
    if (nrow(gc) == 0) return(grid::nullGrob())
    clipped_grob(x, y, width, height,
      grid::circleGrob(
        x = grid::unit(gc$x, "npc"),
        y = grid::unit(gc$y, "npc"),
        r = grid::unit(size * spacing / 2, "snpc"),
        gp = dot_gp
      )
    )
  })

  # weave — horizontal + diagonal for a woven look (angles fixed; composite
  # structure defines the pattern, not a single orientation angle)
  register_pattern("weave", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.07
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 0.8,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg =  45, spacing_npc = spacing * 2, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y),
      hatch_lines(angle_deg = -45, spacing_npc = spacing * 2, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y),
      hatch_lines(angle_deg =  0,  spacing_npc = spacing,     gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y)
    )
  })
}