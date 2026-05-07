# R/patterns.R
# ------------------------------------------------------------
# Low-level grid grob constructors for each pattern type.
# Each function takes a bounding box (x, y, width, height in
# native units) and returns a grob clipped to that region.
# ------------------------------------------------------------

#' @importFrom grid linesGrob pointsGrob rectGrob gTree gList clipGrob
#' @importFrom grid viewport unit gpar nullGrob grobTree polylineGrob
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

# Generate hatch lines across a unit square, optionally at multiple angles.
# Returns a polylineGrob (all lines as one grob for efficiency).
hatch_lines <- function(angle_deg = 45, spacing_npc = 0.08, gp = grid::gpar()) {
  angle_rad <- angle_deg * pi / 180
  # We generate lines long enough to cover the unit square at any angle.
  # Strategy: sweep offsets perpendicular to the line direction.
  dx <- cos(angle_rad)
  dy <- sin(angle_rad)
  # perpendicular direction
  px <- -dy
  py <-  dx

  # How many lines do we need? At most sqrt(2) / spacing across the diagonal.
  n_lines <- ceiling(sqrt(2) / spacing_npc) + 2
  offsets <- seq(-n_lines, n_lines) * spacing_npc

  xs <- ys <- xe <- ye <- numeric(length(offsets))
  for (i in seq_along(offsets)) {
    ox <- px * offsets[i]
    oy <- py * offsets[i]
    # Line through (ox, oy) in direction (dx, dy), clipped to [-1,2] range
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
      hatch_lines(angle_deg = angle, spacing_npc = spacing, gp = line_gp)
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
      hatch_lines(angle_deg = angle,       spacing_npc = spacing, gp = line_gp),
      hatch_lines(angle_deg = angle + 90,  spacing_npc = spacing, gp = line_gp)
    )
  })

  # horizontal — flat lines
  register_pattern("horizontal", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.08
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 1,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg = 0, spacing_npc = spacing, gp = line_gp)
    )
  })

  # vertical — straight-up lines
  register_pattern("vertical", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.08
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 1,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg = 90, spacing_npc = spacing, gp = line_gp)
    )
  })

  # dots — grid of small circles
  register_pattern("dots", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.1
    size    <- params$pattern_size    %||% 0.4  # in mm
    dot_gp  <- grid::gpar(col = NA,
                          fill = gp$pattern_colour %||% "black")
    xs <- seq(0, 1, by = spacing)
    ys <- seq(0, 1, by = spacing)
    grid_coords <- expand.grid(x = xs, y = ys)
    clipped_grob(x, y, width, height,
      grid::pointsGrob(
        x    = unit(grid_coords$x, "npc"),
        y    = unit(grid_coords$y, "npc"),
        pch  = 19,
        size = unit(size, "mm"),
        gp   = dot_gp
      )
    )
  })

  # weave — horizontal + diagonal for a woven look
  register_pattern("weave", function(x, y, width, height, gp, params) {
    spacing <- params$pattern_spacing %||% 0.07
    line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                          lwd = gp$pattern_linewidth %||% 0.8,
                          lty = "solid")
    clipped_grob(x, y, width, height,
      hatch_lines(angle_deg =  45, spacing_npc = spacing * 2, gp = line_gp),
      hatch_lines(angle_deg = -45, spacing_npc = spacing * 2, gp = line_gp),
      hatch_lines(angle_deg =  0,  spacing_npc = spacing,     gp = line_gp)
    )
  })
}
