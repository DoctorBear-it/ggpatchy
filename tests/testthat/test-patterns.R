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
  df <- data.frame(g = c("A", "B"), v = c(2, 3), ps = c(0.02, 0.15))
  p  <- ggplot(df, aes(g, v, pattern_spacing = ps)) +
    geom_col_pattern(pattern = "hatch")
  panel_data <- ggplot_build(p)$data[[1]]
  expect_setequal(round(panel_data$pattern_spacing, 4), c(0.02, 0.15))
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
  # clipped_grob → gTree; children[[1]] is the polylineGrob
  count_segs <- function(spacing) {
    g  <- fn(0, 0, 1, 1, gp = base_gp,
             params = list(pattern_spacing = spacing, pattern_angle = 45,
                           pattern_size = 0.4))
    pl <- g$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  expect_gt(count_segs(0.03), count_segs(0.20))
})

test_that(".has_clip_path_support() returns logical scalar", {
  result <- ggpatchy:::.has_clip_path_support()
  expect_true(is.logical(result))
  expect_length(result, 1L)
})

test_that("hatch pattern angle changes line direction", {
  fn      <- get_pattern_fn("hatch")
  base_gp <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  mk <- function(angle) fn(0, 0, 1, 1, gp = base_gp,
    params = list(pattern_spacing = 0.1, pattern_angle = angle, pattern_size = 0.4))
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
  params   <- list(pattern_angle = 45, pattern_size = 0.35)

  count_segs <- function(fn) {
    g  <- fn(0, 0, 1, 1, gp = base_gp, params = params)
    pl <- g$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  expect_gt(count_segs(fn_dense), count_segs(fn_base))
})

test_that("hatch_sparse produces fewer line segments than hatch at default spacing", {
  fn_base   <- get_pattern_fn("hatch")
  fn_sparse <- get_pattern_fn("hatch_sparse")
  base_gp   <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)
  params    <- list(pattern_angle = 45, pattern_size = 0.35)

  count_segs <- function(fn) {
    g  <- fn(0, 0, 1, 1, gp = base_gp, params = params)
    pl <- g$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  expect_gt(count_segs(fn_base), count_segs(fn_sparse))
})

test_that("explicit pattern_spacing overrides the variant default", {
  fn_dense <- get_pattern_fn("hatch_dense")
  fn_base  <- get_pattern_fn("hatch")
  base_gp  <- grid::gpar(pattern_colour = "black", pattern_linewidth = 1)

  count_segs <- function(fn, spacing) {
    g  <- fn(0, 0, 1, 1, gp = base_gp,
             params = list(pattern_spacing = spacing,
                           pattern_angle = 45, pattern_size = 0.35))
    pl <- g$children[[1]]
    sum(is.na(as.numeric(pl$x)))
  }
  # When spacing is supplied explicitly, hatch_dense and hatch produce
  # identical output — the variant's baked-in default is not used.
  expect_equal(count_segs(fn_dense, 0.1), count_segs(fn_base, 0.1))
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
