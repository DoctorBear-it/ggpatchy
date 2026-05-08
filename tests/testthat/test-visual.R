# tests/testthat/test-visual.R
library(ggplot2)

bar_df <- data.frame(
  group = c("A", "B", "C", "D"),
  value = c(3, 5, 2, 4)
)

poly_df <- data.frame(
  x     = c(0, 1, 1, 0,   2, 3, 3, 2),
  y     = c(0, 0, 1, 1,   0, 0, 1, 1),
  group = c("p1","p1","p1","p1", "p2","p2","p2","p2"),
  pat   = c(rep("crosshatch", 4), rep("hatch", 4))
)

# ---- geom_col_pattern ------------------------------------------------------

test_that("geom_col_pattern hatch renders correctly", {
  p <- ggplot(bar_df, aes(group, value, fill = group)) +
    geom_col_pattern(pattern = "hatch") +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("col-pattern-hatch", p)
})

test_that("geom_col_pattern all patterns renders correctly", {
  df <- data.frame(
    group = factor(
      c("none","hatch","crosshatch","horizontal","vertical","dots","weave"),
      levels = c("none","hatch","crosshatch","horizontal","vertical","dots","weave")
    ),
    value = rep(1, 7)
  )
  # The data values ARE pattern names — use scale_pattern_identity()
  # so each level renders as itself with no remapping needed.
  p <- ggplot(df, aes(group, value, fill = group, pattern = group)) +
    geom_col_pattern() +
    scale_pattern_identity(guide = "legend") +
    scale_fill_grey() +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  vdiffr::expect_doppelganger("col-pattern-all-patterns", p)
})

test_that("geom_col_pattern pattern_colour renders correctly", {
  p <- ggplot(bar_df, aes(group, value, fill = group, pattern = group)) +
    geom_col_pattern(pattern_colour = "red", pattern_spacing = 0.05) +
    scale_pattern_manual(values = c(A = "hatch", B = "crosshatch",
                                    C = "dots",  D = "weave")) +
    theme_minimal()
  vdiffr::expect_doppelganger("col-pattern-red-overlay", p)
})

test_that("geom_col_pattern stacked renders correctly", {
  df2 <- data.frame(
    x       = c("X", "X", "Y", "Y"),
    fill    = c("a", "b", "a", "b"),
    pattern = c("hatch", "dots", "hatch", "dots"),
    value   = c(2, 3, 4, 1)
  )
  # pattern column already holds pattern names
  p <- ggplot(df2, aes(x, value, fill = fill, pattern = pattern)) +
    geom_col_pattern(position = "stack") +
    scale_pattern_identity(guide = "legend") +
    theme_minimal()
  vdiffr::expect_doppelganger("col-pattern-stacked", p)
})

# ---- geom_bar_pattern ------------------------------------------------------

test_that("geom_bar_pattern count renders correctly", {
  p <- ggplot(mpg, aes(class, fill = class, pattern = class)) +
    geom_bar_pattern() +
    scale_pattern_manual(values = c(
      "2seater"    = "hatch",
      "compact"    = "crosshatch",
      "midsize"    = "dots",
      "minivan"    = "horizontal",
      "pickup"     = "vertical",
      "subcompact" = "weave",
      "suv"        = "none"
    )) +
    scale_fill_brewer(palette = "Pastel2") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  vdiffr::expect_doppelganger("bar-pattern-count", p)
})

# ---- geom_polygon_pattern --------------------------------------------------

test_that("geom_polygon_pattern hatch renders correctly", {
  # pat column holds pattern names directly
  p <- ggplot(poly_df, aes(x, y, group = group, fill = group, pattern = pat)) +
    geom_polygon_pattern() +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("polygon-pattern-hatch", p)
})

test_that("geom_polygon_pattern dots renders correctly", {
  df <- data.frame(
    x     = c(0, 1, 0.5),
    y     = c(0, 0, 1),
    group = "tri",
    pat   = "dots"
  )
  p <- ggplot(df, aes(x, y, group = group, fill = group, pattern = pat)) +
    geom_polygon_pattern() +
    scale_pattern_identity() +
    theme_void()
  vdiffr::expect_doppelganger("polygon-pattern-dots-triangle", p)
})

test_that("geom_polygon_pattern hatch on concave L-shape renders correctly", {
  df <- data.frame(
    x     = c(0, 0, 0.5, 0.5, 1,   1),
    y     = c(0, 1, 1,   0.5, 0.5, 0),
    group = "L",
    pat   = "hatch"
  )
  p <- ggplot(df, aes(x, y, group = group, fill = group, pattern = pat)) +
    geom_polygon_pattern() +
    scale_pattern_identity() +
    scale_fill_brewer(palette = "Pastel1") +
    theme_void()
  vdiffr::expect_doppelganger("polygon-pattern-hatch-concave-L", p)
})

test_that("geom_polygon_pattern crosshatch on concave L-shape renders correctly", {
  df <- data.frame(
    x     = c(0, 0, 0.5, 0.5, 1,   1),
    y     = c(0, 1, 1,   0.5, 0.5, 0),
    group = "L",
    pat   = "crosshatch"
  )
  p <- ggplot(df, aes(x, y, group = group, fill = group, pattern = pat)) +
    geom_polygon_pattern() +
    scale_pattern_identity() +
    scale_fill_brewer(palette = "Pastel1") +
    theme_void()
  vdiffr::expect_doppelganger("polygon-pattern-crosshatch-concave-L", p)
})

# ---- scale functions -------------------------------------------------------

test_that("scale_pattern_discrete cycles correctly", {
  df <- data.frame(
    g = factor(letters[1:6], levels = letters[1:6]),
    v = c(3, 5, 2, 4, 1, 6)
  )
  p <- ggplot(df, aes(g, v, fill = g, pattern = g)) +
    geom_col_pattern() +
    scale_pattern_discrete() +
    theme_minimal()
  vdiffr::expect_doppelganger("scale-discrete-six-levels", p)
})

# ---- regression tests for the level-ordering bug --------------------------

test_that("scale_pattern_identity renders each value as itself", {
  # This is the regression test for the original bug: when factor levels
  # are pattern names, the rendered pattern must equal the level name.
  # Previously the default scale would rotate (level "none" -> "hatch" etc).
  df <- data.frame(
    g = factor(c("hatch", "dots", "crosshatch"),
               levels = c("hatch", "dots", "crosshatch")),
    v = 1
  )
  p <- ggplot(df, aes(g, v, fill = g, pattern = g)) +
    geom_col_pattern() +
    scale_pattern_identity() +
    scale_fill_grey() +
    theme_minimal()
  vdiffr::expect_doppelganger("scale-identity-name-as-pattern", p)
})

test_that("scale_pattern_manual respects names regardless of order", {
  # Pass values in a deliberately wrong order; named lookup should still
  # produce the correct mapping (A=hatch, B=dots, C=weave, D=crosshatch).
  df <- data.frame(
    g = factor(c("A","B","C","D"), levels = c("A","B","C","D")),
    v = c(1, 2, 3, 4)
  )
  p <- ggplot(df, aes(g, v, fill = g, pattern = g)) +
    geom_col_pattern() +
    scale_pattern_manual(values = c(D = "crosshatch", A = "hatch",
                                    C = "weave",      B = "dots")) +
    scale_fill_grey() +
    theme_minimal()
  vdiffr::expect_doppelganger("scale-manual-out-of-order-names", p)
})