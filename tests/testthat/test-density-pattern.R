library(ggplot2)

# ---- functional tests -------------------------------------------------------

test_that("geom_density_pattern builds without error", {
  p <- ggplot(faithful, aes(waiting)) +
    geom_density_pattern(pattern = "hatch", fill = "lightblue")
  expect_no_error(ggplot_build(p))
})

test_that("geom_density_pattern multiple groups builds without error", {
  p <- ggplot(mpg, aes(hwy, fill = drv, pattern = drv)) +
    geom_density_pattern(alpha = 0.6) +
    scale_pattern_manual(values = c("4" = "hatch", "f" = "crosshatch",
                                    "r" = "dots")) +
    scale_fill_brewer(palette = "Pastel1")
  expect_no_error(ggplot_build(p))
})

test_that("geom_density_pattern position=stack builds without error", {
  p <- ggplot(mpg, aes(hwy, fill = drv, pattern = drv)) +
    geom_density_pattern(position = "stack", alpha = 0.8) +
    scale_pattern_manual(values = c("4" = "hatch", "f" = "crosshatch",
                                    "r" = "dots"))
  expect_no_error(ggplot_build(p))
})

# ---- visual snapshots -------------------------------------------------------

test_that("geom_density_pattern single density renders correctly", {
  p <- ggplot(faithful, aes(waiting)) +
    geom_density_pattern(pattern = "hatch", fill = "lightblue",
                         pattern_colour = "steelblue") +
    theme_minimal()
  vdiffr::expect_doppelganger("density-pattern-single-hatch", p)
})

test_that("geom_density_pattern multiple groups renders correctly", {
  p <- ggplot(mpg, aes(hwy, fill = drv, pattern = drv)) +
    geom_density_pattern(alpha = 0.7) +
    scale_pattern_manual(values = c("4" = "hatch", "f" = "crosshatch",
                                    "r" = "dots")) +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("density-pattern-three-groups", p)
})

test_that("geom_density_pattern position=stack renders correctly", {
  p <- ggplot(mpg, aes(hwy, fill = drv, pattern = drv)) +
    geom_density_pattern(position = "stack", alpha = 0.8) +
    scale_pattern_manual(values = c("4" = "hatch", "f" = "crosshatch",
                                    "r" = "none")) +
    scale_fill_brewer(palette = "Pastel2") +
    theme_minimal()
  vdiffr::expect_doppelganger("density-pattern-stacked", p)
})
