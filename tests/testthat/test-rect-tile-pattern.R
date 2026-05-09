library(ggplot2)

rect_df <- data.frame(
  xmin    = c(0, 1, 2),
  xmax    = c(0.8, 1.8, 2.8),
  ymin    = 0,
  ymax    = c(1, 3, 2),
  pattern = c("hatch", "crosshatch", "dots"),
  grp     = c("A", "B", "C")
)

tile_df <- data.frame(
  x       = rep(1:3, 3),
  y       = rep(1:3, each = 3),
  pattern = c("hatch", "crosshatch", "dots",
              "none",  "hatch",      "vertical",
              "dots",  "crosshatch", "none"),
  grp     = rep(c("a", "b", "c"), 3)
)

# ---- functional tests -------------------------------------------------------

test_that("geom_rect_pattern builds without error", {
  p <- ggplot(rect_df,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                  fill = grp, pattern = pattern)) +
    geom_rect_pattern() +
    scale_pattern_identity() +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
})

test_that("geom_tile_pattern builds without error", {
  p <- ggplot(tile_df, aes(x, y, fill = grp, pattern = pattern)) +
    geom_tile_pattern() +
    scale_pattern_identity() +
    scale_fill_brewer(palette = "Pastel2") +
    theme_minimal()
  expect_no_error(ggplot_build(p))
})

test_that("GeomColPattern still inherits draw_panel from GeomRectPattern", {
  # Regression: ensure the refactor didn't break existing col pattern geom
  df <- data.frame(g = c("A", "B"), v = c(2, 4),
                   pattern = c("hatch", "dots"))
  p <- ggplot(df, aes(g, v, fill = g, pattern = pattern)) +
    geom_col_pattern() +
    scale_pattern_identity()
  expect_no_error(ggplot_build(p))
})

# ---- visual snapshots -------------------------------------------------------

test_that("geom_rect_pattern renders correctly", {
  p <- ggplot(rect_df,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                  fill = grp, pattern = pattern)) +
    geom_rect_pattern() +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("rect-pattern-three-shapes", p)
})

test_that("geom_tile_pattern renders correctly", {
  p <- ggplot(tile_df, aes(x, y, fill = grp, pattern = pattern)) +
    geom_tile_pattern(colour = "white", linewidth = 0.5) +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel2") +
    theme_minimal()
  vdiffr::expect_doppelganger("tile-pattern-3x3-grid", p)
})
