# R/patterns.R
# ------------------------------------------------------------
# Low-level grid grob constructors for each pattern type.
# Each function takes a bounding box (x, y, width, height in
# native units) and returns a grob clipped to that region.
# ------------------------------------------------------------

#' @importFrom grid linesGrob pointsGrob rectGrob gTree gList clipGrob
#' @importFrom grid viewport unit gpar nullGrob grobTree polylineGrob circleGrob
NULL

# Package-level default for pattern_spacing.  All built-in pattern functions
# fall back to this value when pattern_spacing is NULL.  Named density
# variants (hatch_dense, etc.) are expressed as multiples of this constant.
.PATTERN_SPACING_DEFAULT <- 0.08

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

# Coalesce NULL *and* NA to a scalar default — used in draw_key_pattern
# where mapped aesthetics (pattern_spacing etc.) may arrive as NA from the
# scale rather than NULL.
null_na_default <- function(x, default) {
  if (is.null(x) || (length(x) == 1L && is.na(x))) default else x
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

# Inset a simple polygon by distance r (in the same coordinate units as
# vx/vy) using proper edge offsetting. Each edge is moved inward by r
# perpendicular to its direction; adjacent offset edges are intersected
# to find new vertices. This guarantees every point on every inset edge
# is exactly r from the original edge — unlike centroid-based shrinking,
# which over-insets at corners and under-insets at edge midpoints.
#
# Assumes a simple (non-self-intersecting) polygon. Works for both convex
# and mildly concave polygons; may produce a degenerate result for very
# concave polygons with r larger than the polygon's inradius, in which
# case the original polygon is returned (fallback, no crash).
#
# The winding direction is auto-detected: the signed area determines
# whether "inward" means +90° or -90° rotation of the edge normal.
inset_poly <- function(vx, vy, r) {
  n <- length(vx)
  if (n < 3L || r <= 0) return(list(x = vx, y = vy))

  # Signed area via shoelace — positive = CCW, negative = CW
  signed_area <- sum(vx * c(vy[-1], vy[1]) - c(vx[-1], vx[1]) * vy) / 2
  # For CCW winding, inward normal is +90° from edge direction (left normal)
  # For CW winding, inward normal is -90° from edge direction (right normal)
  normal_sign <- if (signed_area > 0) 1 else -1

  # Compute offset lines for each edge.
  # Each edge i goes from vertex i to vertex i+1 (mod n).
  # The offset line is the edge shifted inward by r.
  ox <- numeric(n)  # point on offset line (x)
  oy <- numeric(n)  # point on offset line (y)
  ex <- numeric(n)  # edge direction (x), normalised
  ey <- numeric(n)  # edge direction (y), normalised

  for (i in seq_len(n)) {
    j <- if (i < n) i + 1L else 1L
    dx <- vx[j] - vx[i]
    dy <- vy[j] - vy[i]
    d  <- sqrt(dx^2 + dy^2)
    if (d < 1e-10) {
      ex[i] <- 0; ey[i] <- 0
      ox[i] <- vx[i]; oy[i] <- vy[i]
      next
    }
    # Unit edge direction
    ux <- dx / d; uy <- dy / d
    ex[i] <- ux; ey[i] <- uy
    # Inward normal: rotate edge direction by normal_sign * 90°
    nx <- -uy * normal_sign
    ny <-  ux * normal_sign
    # A point on the offset line (shift midpoint of edge inward by r)
    mx <- (vx[i] + vx[j]) / 2 + nx * r
    my <- (vy[i] + vy[j]) / 2 + ny * r
    ox[i] <- mx; oy[i] <- my
  }

  # Intersect adjacent offset lines to find inset vertices.
  # Offset line i: passes through (ox[i], oy[i]) with direction (ex[i], ey[i])
  # Offset line for edge i-1 (previous): intersect with edge i's offset line
  vx_in <- numeric(n)
  vy_in <- numeric(n)

  for (i in seq_len(n)) {
    prev <- if (i > 1L) i - 1L else n

    # Line A: previous offset edge (direction ex[prev], ey[prev])
    # Line B: current offset edge  (direction ex[i],    ey[i])
    # Solve for intersection using 2D line intersection formula
    ax <- ox[prev]; ay <- oy[prev]; adx <- ex[prev]; ady <- ey[prev]
    bx <- ox[i];    by <- oy[i];    bdx <- ex[i];    bdy <- ey[i]

    denom <- adx * bdy - ady * bdx
    if (abs(denom) < 1e-10) {
      # Parallel edges — use midpoint of offset points as fallback
      vx_in[i] <- (ax + bx) / 2
      vy_in[i] <- (ay + by) / 2
    } else {
      t <- ((bx - ax) * bdy - (by - ay) * bdx) / denom
      vx_in[i] <- ax + t * adx
      vy_in[i] <- ay + t * ady
    }
  }

  # Sanity check: if inset polygon has collapsed or inverted (r too large),
  # return original polygon rather than a degenerate result.
  inset_area <- abs(sum(vx_in * c(vy_in[-1], vy_in[1]) -
                          c(vx_in[-1], vx_in[1]) * vy_in) / 2)
  orig_area  <- abs(signed_area)
  if (inset_area < 1e-10 || inset_area > orig_area) {
    return(list(x = vx, y = vy))
  }

  list(x = vx_in, y = vy_in)
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
    spacing <- params$pattern_spacing %||% .PATTERN_SPACING_DEFAULT
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
    spacing <- params$pattern_spacing %||% .PATTERN_SPACING_DEFAULT
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
    spacing <- params$pattern_spacing %||% .PATTERN_SPACING_DEFAULT
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
    spacing <- params$pattern_spacing %||% .PATTERN_SPACING_DEFAULT
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
    spacing <- params$pattern_spacing %||% .PATTERN_SPACING_DEFAULT
    size    <- params$pattern_size    %||% 0.35
    dot_gp  <- grid::gpar(col = NA, fill = gp$pattern_colour %||% "black")

    # Dot radius in viewport-relative npc — used for both the circle size and
    # the inset margin when filtering to polygon interior.
    r_npc <- size * spacing / 2

    # Centre the dot grid symmetrically in [0, 1].
    # seq(spacing/2, 1-spacing/2, by=spacing) anchors the first dot at the
    # near edge but leaves a larger remainder gap at the far edge when spacing
    # does not divide evenly into 1. Generating from 0 and recentering ensures
    # equal margins on all four sides of the viewport.
    xs_raw <- seq(0, 1, by = spacing)
    xs     <- xs_raw - mean(range(xs_raw)) + 0.5
    ys_raw <- seq(0, 1, by = spacing)
    ys     <- ys_raw - mean(range(ys_raw)) + 0.5

    if (length(xs) == 0 || length(ys) == 0) return(grid::nullGrob())
    gc <- expand.grid(x = xs, y = ys)
    if (!is.null(params$poly_x)) {
      px <- params$poly_x
      py <- params$poly_y
      n  <- length(px)
      # Strip closing duplicate vertex (sf closed rings repeat the first
      # vertex at the end). inset_poly produces bad results for zero-length
      # edges; pip handles open polygons correctly without it.
      if (n > 1 && abs(px[n] - px[1]) < 1e-10 && abs(py[n] - py[1]) < 1e-10) {
        px <- px[-n]
        py <- py[-n]
      }
      # Inset the polygon by the dot radius before pip filtering so that no
      # dot centre is close enough to the boundary that its radius bleeds
      # outside (or appears as a partial circle on geoms with clip paths).
      inset <- inset_poly(px, py, r_npc)
      keep  <- pip(gc$x, gc$y, inset$x, inset$y)
      gc    <- gc[keep, , drop = FALSE]
    }
    if (nrow(gc) == 0) return(grid::nullGrob())
    clipped_grob(x, y, width, height,
      grid::circleGrob(
        x  = grid::unit(gc$x, "npc"),
        y  = grid::unit(gc$y, "npc"),
        r  = grid::unit(r_npc, "npc"),
        gp = dot_gp
      )
    )
  })

  # weave — horizontal + diagonal for a woven look (angles fixed; composite
  # structure defines the pattern, not a single orientation angle)
  register_pattern("weave", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% .PATTERN_SPACING_DEFAULT
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 0.8,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg =  45, spacing_npc = spacing * 2, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y),
      hatch_lines(angle_deg = -45, spacing_npc = spacing * 2, gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y),
      hatch_lines(angle_deg =   0, spacing_npc = spacing,     gp = line_gp,
                  poly_x = params$poly_x, poly_y = params$poly_y)
    )
  })

  # ---- Named density variants --------------------------------------------
  # Each variant is a thin wrapper that bakes in a pattern_spacing default.
  # The base pattern function is called directly; no logic is duplicated.
  # Users can still override pattern_spacing explicitly — %||% only fires
  # when pattern_spacing is NULL.

  .make_density_variant <- function(base_name, multiplier) {
    force(base_name)
    force(multiplier)
    function(x, y, width, height, gp, params) {
      params$pattern_spacing <- params$pattern_spacing %||%
        (.PATTERN_SPACING_DEFAULT * multiplier)
      get_pattern_fn(base_name)(x, y, width, height, gp, params)
    }
  }

  for (.base in c("hatch", "crosshatch", "horizontal",
                  "vertical", "dots", "weave")) {
    register_pattern(paste0(.base, "_dense"),
                     .make_density_variant(.base, 0.5))
    register_pattern(paste0(.base, "_sparse"),
                     .make_density_variant(.base, 2.0))
  }
  rm(.base)
}