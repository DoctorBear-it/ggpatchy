# tests/testthat/test-ribbon-pattern.R
library(ggplot2)

# ---- shared test data -------------------------------------------------------

x_wave <- seq(0, 2 * pi, length.out = 60)

ribbon_single <- data.frame(
  x    = x_wave,
  ymin = sin(x_wave) - 0.3,
  ymax = sin(x_wave) + 0.3
)

ribbon_two_groups <- data.frame(
  x       = c(x_wave, x_wave),
  ymin    = c(sin(x_wave) - 0.2, cos(x_wave) + 0.6),
  ymax    = c(sin(x_wave) + 0.2, cos(x_wave) + 1.0),
  group   = rep(c("A", "B"), each = length(x_wave)),
  pattern = rep(c("hatch", "crosshatch"), each = length(x_wave)),
  fill    = rep(c("lightblue", "lightyellow"), each = length(x_wave))
)

# Two ribbon bands with pre-computed absolute coordinates so they sit on top of
# each other without overlap. position = "identity" is correct here — stacking
# by y-offset is geom_area_pattern's job, not geom_ribbon_pattern's.
ribbon_stacked_precomputed <- data.frame(
  x       = c(x_wave, x_wave),
  ymin    = c(sin(x_wave) - 0.2,       sin(x_wave) + 0.2),
  ymax    = c(sin(x_wave) + 0.2,       sin(x_wave) + 0.6),
  group   = rep(c("A", "B"), each = length(x_wave)),
  pattern = rep(c("hatch", "crosshatch"), each = length(x_wave))
)

area_single <- data.frame(
  x = 1:10,
  y = c(1, 3, 2, 4, 3, 5, 4, 6, 5, 7)
)

area_two_groups <- data.frame(
  x       = c(1:5, 1:5),
  y       = c(1, 2, 3, 2, 1,  2, 1, 3, 2, 1),
  group   = rep(c("A", "B"), each = 5),
  pattern = rep(c("hatch", "crosshatch"), each = 5)
)

# ---- functional tests -------------------------------------------------------

test_that("geom_ribbon_pattern single ribbon builds without error", {
  p <- ggplot(ribbon_single, aes(x, ymin = ymin, ymax = ymax)) +
    geom_ribbon_pattern(pattern = "hatch", fill = "lightblue") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  expect_s3_class(p, "ggplot")
})

test_that("geom_ribbon_pattern two groups with different patterns builds without error", {
  p <- ggplot(ribbon_two_groups,
              aes(x, ymin = ymin, ymax = ymax,
                  group = group, fill = fill, pattern = pattern)) +
    geom_ribbon_pattern() +
    scale_pattern_identity(guide = "legend") +
    scale_fill_identity() +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  built <- ggplot_build(p)
  expect_length(built$plot$layers, 1L)
})

test_that("geom_ribbon_pattern two pre-stacked bands build without error", {
  p <- ggplot(ribbon_stacked_precomputed,
              aes(x, ymin = ymin, ymax = ymax,
                  group = group, fill = group, pattern = pattern)) +
    geom_ribbon_pattern() +
    scale_pattern_identity(guide = "legend") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  built <- ggplot_build(p)
  expect_equal(length(unique(built$data[[1]]$group)), 2L)
})

test_that("geom_area_pattern single area builds without error and ymin defaults to 0", {
  p <- ggplot(area_single, aes(x, y)) +
    geom_area_pattern(pattern = "hatch", fill = "lightblue") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  built <- ggplot_build(p)
  expect_true(all(built$data[[1]]$ymin == 0))
})

test_that("geom_area_pattern stacked multiple groups builds without error", {
  p <- ggplot(area_two_groups,
              aes(x, y, fill = group, pattern = pattern)) +
    geom_area_pattern(position = "stack") +
    scale_pattern_identity(guide = "legend") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  built <- ggplot_build(p)
  d <- built$data[[1]]
  # With stacking the combined ymax must exceed the max y of any single group
  expect_gt(max(d$ymax), max(area_two_groups$y))
})

# ---- visual regression tests ------------------------------------------------

test_that("geom_ribbon_pattern single hatch renders correctly", {
  p <- ggplot(ribbon_single, aes(x, ymin = ymin, ymax = ymax)) +
    geom_ribbon_pattern(pattern = "hatch", fill = "lightblue",
                        pattern_colour = "steelblue") +
    theme_minimal()
  vdiffr::expect_doppelganger("ribbon-pattern-single-hatch", p)
})

test_that("geom_ribbon_pattern two groups hatch vs crosshatch renders correctly", {
  p <- ggplot(ribbon_two_groups,
              aes(x, ymin = ymin, ymax = ymax,
                  group = group, fill = fill, pattern = pattern)) +
    geom_ribbon_pattern() +
    scale_pattern_identity(guide = "legend") +
    scale_fill_identity() +
    theme_minimal()
  vdiffr::expect_doppelganger("ribbon-pattern-two-groups", p)
})

test_that("geom_ribbon_pattern two pre-stacked bands render correctly", {
  p <- ggplot(ribbon_stacked_precomputed,
              aes(x, ymin = ymin, ymax = ymax,
                  group = group, fill = group, pattern = pattern)) +
    geom_ribbon_pattern() +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("ribbon-pattern-stacked", p)
})

test_that("geom_area_pattern single renders correctly", {
  p <- ggplot(area_single, aes(x, y)) +
    geom_area_pattern(pattern = "hatch", fill = "lightblue",
                      pattern_colour = "steelblue") +
    theme_minimal()
  vdiffr::expect_doppelganger("area-pattern-single-hatch", p)
})

test_that("geom_area_pattern stacked multiple groups renders correctly", {
  p <- ggplot(area_two_groups,
              aes(x, y, fill = group, pattern = pattern)) +
    geom_area_pattern(position = "stack") +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("area-pattern-stacked-groups", p)
})
