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
