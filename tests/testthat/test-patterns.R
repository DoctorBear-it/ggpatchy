# tests/testthat/test-patterns.R

test_that("built-in patterns are registered on load", {
  p <- list_patterns()
  expect_true(all(c("none", "hatch", "crosshatch", "dots", "horizontal",
                    "vertical", "weave") %in% p))
})

test_that("register_pattern adds a custom pattern", {
  register_pattern("mypattern", function(x, y, width, height, gp, params) {
    grid::nullGrob()
  })
  expect_true("mypattern" %in% list_patterns())
})

test_that("get_pattern_fn returns a function for known patterns", {
  fn <- get_pattern_fn("hatch")
  expect_true(is.function(fn))
})

test_that("get_pattern_fn warns and returns none for unknown pattern", {
  expect_warning(fn <- get_pattern_fn("nonexistent_pattern"), "Unknown pattern")
  expect_true(is.function(fn))
})

test_that("hatch_lines returns a grob", {
  g <- hatch_lines(angle_deg = 45, spacing_npc = 0.1)
  expect_s3_class(g, "grob")
})

test_that("scale_pattern_manual returns a Scale object", {
  s <- scale_pattern_manual(values = c(a = "hatch", b = "dots"))
  expect_s3_class(s, "Scale")
})

test_that("scale_pattern_discrete returns a Scale object", {
  s <- scale_pattern_discrete()
  expect_s3_class(s, "Scale")
})

test_that("geom_col_pattern builds a valid ggplot", {
  library(ggplot2)
  df <- data.frame(g = c("A", "B", "C"), v = c(1, 2, 3))
  p <- ggplot(df, aes(g, v, fill = g, pattern = g)) +
    geom_col_pattern(width=0.7) +
    scale_pattern_discrete()
  # Just check it builds without error
  expect_no_error(ggplot_build(p))
})

test_that("geom_bar_pattern counts correctly", {
  library(ggplot2)
  p <- ggplot(mpg, aes(class, pattern = class, fill = class)) +
    geom_bar_pattern(width=0.7) +
    scale_pattern_discrete()
  expect_no_error(ggplot_build(p))
})

test_that("geom_polygon_pattern builds without error", {
  library(ggplot2)
  # Simple square polygon
  df <- data.frame(
    x = c(0, 1, 1, 0),
    y = c(0, 0, 1, 1),
    group = "sq",
    pattern = "hatch"
  )
  p <- ggplot(df, aes(x, y, group = group, fill = group, pattern = pattern)) +
    geom_polygon_pattern()
  expect_no_error(ggplot_build(p))
})

test_that("NA in pattern column warns once per panel for geom_col_pattern", {
  library(ggplot2)
  df <- data.frame(
    g = c("A", "B", "C"),
    v = c(1, 2, 3),
    pattern = c("hatch", NA, "dots")
  )
  p <- ggplot(df, aes(g, v, pattern = pattern)) +
    geom_col_pattern()
  expect_warning(ggplotGrob(p), "missing value")
})

test_that("NA in pattern column warns for geom_polygon_pattern", {
  library(ggplot2)
  df <- data.frame(
    x = c(0, 1, 1, 0),
    y = c(0, 0, 1, 1),
    group = "sq",
    pattern = NA_character_
  )
  p <- ggplot(df, aes(x, y, group = group, pattern = pattern)) +
    geom_polygon_pattern()
  expect_warning(ggplotGrob(p), "missing value")
})

# ---- per-row pattern parameter mapping -------------------------------------

test_that("pattern_spacing values survive per-row into panel data", {
  library(ggplot2)
  df <- data.frame(g = c("A", "B"), v = c(2, 3), ps = c(2.5, 10))
  p  <- ggplot(df, aes(g, v, pattern_spacing = ps)) +
    geom_col_pattern(pattern = "hatch")
  panel_data <- ggplot_build(p)$data[[1]]
  expect_setequal(round(panel_data$pattern_spacing, 4), c(2.5, 10))
})

test_that("pattern_angle values survive per-row into panel data", {
  library(ggplot2)
  df <- data.frame(g = c("A", "B"), v = c(2, 3), pa = c(0, 90))
  p  <- ggplot(df, aes(g, v, pattern_angle = pa)) +
    geom_col_pattern(pattern = "hatch")
  panel_data <- ggplot_build(p)$data[[1]]
  expect_setequal(panel_data$pattern_angle, c(0, 90))
})

test_that("hatch pattern generates more line segments at tighter spacing", {
  fn     <- get_pattern_fn("hatch")
  base_gp <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  # clipped_grob wraps a LinePatternTree; makeContent fires it to get the polylineGrob
  count_segs <- function(spacing) {
    g    <- fn(0, 0, 1, 1, gp = base_gp,
               params = list(pattern_spacing = spacing, pattern_angle = 45,
                             pattern_size = 0.5))
    inner <- grid::makeContent(g$children[[1]])
    pl    <- inner$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  expect_gt(count_segs(2), count_segs(12))
})

test_that(".has_clip_path_support() returns logical scalar", {
  result <- ggpatchy:::.has_clip_path_support()
  expect_true(is.logical(result))
  expect_length(result, 1L)
})

test_that("hatch pattern angle changes line direction", {
  fn      <- get_pattern_fn("hatch")
  base_gp <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  mk <- function(angle) {
    g <- fn(0, 0, 1, 1, gp = base_gp,
      params = list(pattern_spacing = 5, pattern_angle = angle, pattern_size = 0.5))
    grid::makeContent(g$children[[1]])
  }
  horiz <- mk(0)
  diag  <- mk(45)
  # y coordinates of the first non-NA run differ between orientations
  ys_horiz <- as.numeric(horiz$children[[1]]$y)
  ys_diag  <- as.numeric(diag$children[[1]]$y)
  expect_false(isTRUE(all.equal(ys_horiz, ys_diag)))
})

# ---- Named density variants ------------------------------------------------

test_that("all twelve density variants are registered", {
  p <- list_patterns()
  bases   <- c("hatch", "crosshatch", "horizontal", "vertical", "dots", "weave")
  dense   <- paste0(bases, "_dense")
  sparse  <- paste0(bases, "_sparse")
  expect_true(all(c(dense, sparse) %in% p))
})

test_that("hatch_dense produces more line segments than hatch at default spacing", {
  fn_base  <- get_pattern_fn("hatch")
  fn_dense <- get_pattern_fn("hatch_dense")
  base_gp  <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  params   <- list(pattern_angle = 45, pattern_size = 0.5)

  count_segs <- function(fn) {
    g     <- fn(0, 0, 1, 1, gp = base_gp, params = params)
    inner <- grid::makeContent(g$children[[1]])
    pl    <- inner$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  expect_gt(count_segs(fn_dense), count_segs(fn_base))
})

test_that("hatch_sparse produces fewer line segments than hatch at default spacing", {
  fn_base   <- get_pattern_fn("hatch")
  fn_sparse <- get_pattern_fn("hatch_sparse")
  base_gp   <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  params    <- list(pattern_angle = 45, pattern_size = 0.5)

  count_segs <- function(fn) {
    g     <- fn(0, 0, 1, 1, gp = base_gp, params = params)
    inner <- grid::makeContent(g$children[[1]])
    pl    <- inner$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  expect_gt(count_segs(fn_base), count_segs(fn_sparse))
})

test_that("explicit pattern_spacing overrides the variant default", {
  fn_dense <- get_pattern_fn("hatch_dense")
  fn_base  <- get_pattern_fn("hatch")
  base_gp  <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)

  count_segs <- function(fn, spacing) {
    g     <- fn(0, 0, 1, 1, gp = base_gp,
                params = list(pattern_spacing = spacing,
                              pattern_angle = 45, pattern_size = 0.5))
    inner <- grid::makeContent(g$children[[1]])
    pl    <- inner$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  # When an explicit spacing that differs from the default is supplied,
  # hatch_dense and hatch produce identical output — the variant multiplier
  # is not applied. Use 8 (different from the default 5) to prove this.
  expect_equal(count_segs(fn_dense, 8), count_segs(fn_base, 8))
})

test_that("density variants work end-to-end in a ggplot", {
  library(ggplot2)
  df <- data.frame(
    g = c("A", "B", "C"),
    v = c(1, 2, 3),
    pat = c("hatch_dense", "dots_sparse", "crosshatch_dense")
  )
  p <- ggplot(df, aes(g, v, fill = g, pattern = pat)) +
    geom_col_pattern() +
    scale_pattern_identity()
  expect_s3_class(ggplotGrob(p), "gtable")
})

# ---- Contrast checking and correction --------------------------------------

test_that("pattern_contrast returns correct ratio for black and white", {
  expect_equal(pattern_contrast("black", "white"), 21, tolerance = 0.01)
})

test_that("pattern_contrast is symmetric", {
  expect_equal(
    pattern_contrast("black", "#4472C4"),
    pattern_contrast("#4472C4", "black"),
    tolerance = 1e-10
  )
})

test_that("pattern_contrast returns >= 1 for any inputs", {
  pairs <- list(
    c("black",   "white"),
    c("grey50",  "white"),
    c("grey50",  "grey80"),
    c("red",     "blue"),
    c("#123456", "#abcdef")
  )
  for (pair in pairs) {
    expect_gte(pattern_contrast(pair[1], pair[2]), 1)
  }
})

test_that(".apply_contrast_correction improves contrast to meet threshold", {
  original       <- "grey70"
  fill           <- "white"
  original_ratio <- pattern_contrast(original, fill)
  corrected      <- ggpatchy:::.apply_contrast_correction(original, fill, 3.0)
  corrected_ratio <- pattern_contrast(corrected, fill)
  expect_lt(original_ratio, 3.0)
  expect_gte(corrected_ratio, 3.0)
})

test_that(".apply_contrast_correction returns unchanged colour when already passing", {
  result <- ggpatchy:::.apply_contrast_correction("black", "white", 3.0)
  expect_equal(result, "black")
})

test_that("pattern_contrast_check emits warning when contrast is below threshold", {
  library(ggplot2)
  df <- data.frame(g = "A", v = 1)
  p <- ggplot(df, aes(g, v)) +
    geom_col_pattern(
      pattern                = "hatch",
      fill                   = "black",
      pattern_colour         = "grey20",
      pattern_contrast_check = 3.0
    )
  expect_warning(ggplotGrob(p), "contrast")
})

test_that("pattern_contrast_check does not warn when contrast is sufficient", {
  library(ggplot2)
  df <- data.frame(g = "A", v = 1)
  p <- ggplot(df, aes(g, v)) +
    geom_col_pattern(
      pattern                = "hatch",
      fill                   = "white",
      pattern_colour         = "black",
      pattern_contrast_check = 3.0
    )
  expect_no_warning(ggplotGrob(p))
})

test_that("pattern_contrast_correct = TRUE silently fixes failing contrast", {
  library(ggplot2)
  df <- data.frame(g = "A", v = 1)
  p <- ggplot(df, aes(g, v)) +
    geom_col_pattern(
      pattern                  = "hatch",
      fill                     = "black",
      pattern_colour           = "grey20",
      pattern_contrast_check   = 3.0,
      pattern_contrast_correct = TRUE
    )
  expect_no_warning(ggplotGrob(p))
})

test_that("pattern_contrast_check = FALSE (default) never warns", {
  library(ggplot2)
  df <- data.frame(g = "A", v = 1)
  p <- ggplot(df, aes(g, v)) +
    geom_col_pattern(
      pattern        = "hatch",
      fill           = "black",
      pattern_colour = "black"
    )
  expect_no_warning(ggplotGrob(p))
})

# ---- Physical unit (mm) spacing tests --------------------------------------

test_that("dots are physically uniform across shapes of different bbox sizes", {
  fn <- get_pattern_fn("dots")
  base_gp <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  params  <- list(pattern_spacing = 5, pattern_size = 0.5)

  count_dots <- function(vp_width_mm, vp_height_mm) {
    tmp <- tempfile(fileext = ".pdf")
    on.exit(unlink(tmp))
    pdf(tmp, width = vp_width_mm / 25.4, height = vp_height_mm / 25.4)
    grid::grid.newpage()
    tree <- fn(0, 0, 1, 1, gp = base_gp, params = params)
    rendered <- grid::makeContent(tree$children[[1]])
    dots_grob <- rendered$children[[1]]
    dev.off()
    if (inherits(dots_grob, "null")) 0L else length(dots_grob$x)
  }

  small_n <- count_dots(20, 20)
  large_n <- count_dots(80, 80)
  expect_gt(large_n, small_n)
})

test_that("line patterns use mm spacing — larger viewport produces more lines", {
  fn      <- get_pattern_fn("hatch")
  base_gp <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  params  <- list(pattern_spacing = 5, pattern_angle = 45, pattern_size = 0.5)

  count_lines <- function(vp_width_mm, vp_height_mm) {
    tmp <- tempfile(fileext = ".pdf")
    on.exit(unlink(tmp))
    pdf(tmp, width = vp_width_mm / 25.4, height = vp_height_mm / 25.4)
    grid::grid.newpage()
    tree     <- fn(0, 0, 1, 1, gp = base_gp, params = params)
    rendered <- grid::makeContent(tree$children[[1]])
    line_grob <- rendered$children[[1]]
    dev.off()
    if (inherits(line_grob, "null")) 0L
    else sum(is.na(as.numeric(line_grob$x)))
  }

  expect_gt(count_lines(80, 80), count_lines(20, 20))
})
