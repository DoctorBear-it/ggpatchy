# tests/testthat/test-violin-pattern.R
library(ggplot2)

# ---- shared test data -------------------------------------------------------

# mtcars subset: three cylinder groups, enough points for a KDE
violin_df <- mtcars[, c("cyl", "mpg")]
violin_df$cyl <- factor(violin_df$cyl)

# Two-group data for paired violin tests
violin_two <- data.frame(
  x       = factor(rep(c("A", "B"), each = 40)),
  y       = c(rnorm(40, mean = 5), rnorm(40, mean = 7)),
  pattern = rep(c("hatch", "crosshatch"), each = 40)
)

# ---- functional tests -------------------------------------------------------

test_that("geom_violin_pattern single group builds without error", {
  p <- ggplot(violin_df[violin_df$cyl == "6", ],
              aes(cyl, mpg, fill = cyl, pattern = cyl)) +
    geom_violin_pattern(pattern = "hatch") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  expect_s3_class(p, "ggplot")
})

test_that("geom_violin_pattern three groups with scale_pattern_manual builds without error", {
  p <- ggplot(violin_df, aes(cyl, mpg, fill = cyl, pattern = cyl)) +
    geom_violin_pattern() +
    scale_pattern_manual(values = c("4" = "hatch", "6" = "crosshatch", "8" = "dots")) +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  built <- ggplot_build(p)
  expect_length(built$plot$layers, 1L)
})

test_that("geom_violin_pattern with pattern = 'none' returns base grob only", {
  p <- ggplot(violin_df, aes(cyl, mpg)) +
    geom_violin_pattern(pattern = "none", fill = "lightblue") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
})

test_that("geom_violin_pattern with quantile lines builds without error", {
  # Exercises the path where the parent draw_group returns grobTree(violin, quantiles)
  # and our overlay wraps it in a further grobTree — nested grobTree must work.
  p <- ggplot(violin_df, aes(cyl, mpg, fill = cyl, pattern = cyl)) +
    geom_violin_pattern(
      quantile.linetype  = 1,
      quantile.linewidth = 0.5,
      quantile.colour    = "grey20"
    ) +
    scale_pattern_manual(values = c("4" = "hatch", "6" = "crosshatch", "8" = "dots")) +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  built <- ggplot_build(p)
  # Three cylinder groups → three groups in the built data
  expect_equal(length(unique(built$data[[1]]$group)), 3L)
})

test_that("geom_violin_pattern with scale_pattern_discrete builds without error", {
  p <- ggplot(violin_df, aes(cyl, mpg, fill = cyl, pattern = cyl)) +
    geom_violin_pattern() +
    scale_pattern_discrete() +
    theme_minimal()
  expect_no_error(ggplot_build(p))
})

test_that("geom_violin_pattern two-group mapped pattern builds without error", {
  p <- ggplot(violin_two, aes(x, y, fill = x, pattern = pattern)) +
    geom_violin_pattern() +
    scale_pattern_identity(guide = "legend") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
  built <- ggplot_build(p)
  expect_equal(length(unique(built$data[[1]]$group)), 2L)
})

test_that("geom_violin_pattern missing violinwidth emits message and returns nullGrob", {
  # When stat = "identity" is used with data that lacks a 'violinwidth' column,
  # draw_group (render phase, not build phase) must emit a message rather than
  # crash, and return a nullGrob so the rest of the plot renders cleanly.
  bad_data <- data.frame(
    x = factor("A"), y = 1:10, group = 1L,
    pattern = "hatch", fill = "white",
    colour = "black", alpha = NA,
    linewidth = 0.5, linetype = 1,
    xmin = 0.55, xmax = 1.45,
    width = 0.9, weight = 1,
    pattern_colour = "black", pattern_linewidth = 1,
    pattern_spacing = 5, pattern_angle = 45,
    pattern_size = 0.5
  )
  # suppress "Ignoring unknown parameters: trim, scale, bounds" — ggplot2's layer
  # validator fires this when stat_identity is given violin-specific params.
  # geom_violin itself produces the same warning in this scenario.
  p <- suppressWarnings(
    ggplot(bad_data, aes(x, y, pattern = pattern)) +
      geom_violin_pattern(stat = "identity") +
      theme_minimal()
  )
  # ggplot_build only processes data/stats; draw_group runs during ggplot_gtable.
  built <- ggplot_build(p)
  expect_message(
    ggplot_gtable(built),
    regexp = "violinwidth"
  )
})

# ---- visual regression tests ------------------------------------------------

test_that("geom_violin_pattern hatch pattern renders correctly", {
  p <- ggplot(violin_df, aes(cyl, mpg, fill = cyl, pattern = cyl)) +
    geom_violin_pattern() +
    scale_pattern_manual(values = c("4" = "hatch", "6" = "crosshatch", "8" = "dots")) +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("violin-pattern-three-groups", p)
})

test_that("geom_violin_pattern with quantile lines renders correctly", {
  p <- ggplot(violin_df, aes(cyl, mpg, fill = cyl, pattern = cyl)) +
    geom_violin_pattern(
      quantile.linetype  = 1,
      quantile.linewidth = 0.5,
      quantile.colour    = "grey30"
    ) +
    scale_pattern_manual(values = c("4" = "hatch", "6" = "crosshatch", "8" = "vertical")) +
    scale_fill_brewer(palette = "Pastel2") +
    theme_minimal()
  vdiffr::expect_doppelganger("violin-pattern-with-quantiles", p)
})
