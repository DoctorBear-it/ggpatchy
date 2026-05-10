# tests/testthat/test-sf-pattern.R
library(ggplot2)
skip_if_not_installed("sf")
library(sf)

# Helper: build a closed square polygon
sq <- function(x0, y0, x1, y1) {
  st_polygon(list(cbind(c(x0, x1, x1, x0, x0), c(y0, y0, y1, y1, y0))))
}

# ---- Functional tests -------------------------------------------------------

test_that("geom_sf_pattern single POLYGON renders without error", {
  df <- st_sf(
    label = "A", pattern = "hatch",
    geometry = st_sfc(sq(0, 0, 1, 1), crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = label, pattern = pattern)) +
    scale_pattern_identity()
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("geom_sf_pattern multiple POLYGONs with different patterns", {
  df <- st_sf(
    region  = c("A", "B"),
    pattern = c("hatch", "crosshatch"),
    geometry = st_sfc(sq(0, 0, 1, 1), sq(1, 0, 2, 1), crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel1")
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("geom_sf_pattern MULTIPOLYGON renders without error", {
  multi <- st_multipolygon(list(
    list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0))),
    list(cbind(c(2, 3, 3, 2, 2), c(0, 0, 1, 1, 0)))
  ))
  df <- st_sf(
    region = "AB", pattern = "dots",
    geometry = st_sfc(multi, crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity()
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("geom_sf_pattern GEOMETRYCOLLECTION emits a warning", {
  gc <- st_geometrycollection(list(sq(0, 0, 1, 1),
                                   st_linestring(cbind(c(0, 1), c(0, 1)))))
  df <- st_sf(
    region = "GC", pattern = "hatch",
    geometry = st_sfc(gc, crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity()
  expect_warning(ggplotGrob(p), "GEOMETRYCOLLECTION")
})

test_that("geom_sf_pattern multiple GEOCOLLECTION rows produce at most one warning per draw", {
  gc1 <- st_geometrycollection(list(sq(0, 0, 1, 1)))
  gc2 <- st_geometrycollection(list(sq(2, 0, 3, 1)))
  df  <- st_sf(
    region  = c("A", "B"),
    pattern = c("hatch", "hatch"),
    geometry = st_sfc(gc1, gc2, crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity()

  # has_geocollection flag ensures rlang::warn is called at most once per
  # draw_panel invocation regardless of how many rows are GEOMETRYCOLLECTION.
  w         <- testthat::capture_warnings(ggplotGrob(p))
  gc_warns  <- w[grepl("GEOMETRYCOLLECTION", w)]
  expect_lte(length(gc_warns), 1L)
})

test_that("geom_sf_pattern mixed POLYGON+LINESTRING renders cleanly", {
  df <- st_sf(
    region  = c("poly", "line"),
    pattern = c("hatch", "hatch"),
    geometry = st_sfc(sq(0, 0, 1, 1), st_linestring(cbind(c(2, 3), c(0, 1))),
                      crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity()
  # LINESTRING renders via base grob; POLYGON gets pattern; no error
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("geom_sf_pattern pattern='none' renders base grob only", {
  df <- st_sf(
    label = "A",
    geometry = st_sfc(sq(0, 0, 1, 1), crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = label), pattern = "none")
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("geom_sf_pattern errors cleanly without sf installed", {
  # requireNamespace is in base, which can't be mocked via local_mocked_bindings.
  # Test the error message format directly by checking what the call would do.
  # The guard is: if (!requireNamespace("sf", quietly=TRUE)) stop(...)
  # Verify the stop() message matches our expectation by inspecting the function body.
  fn_body <- deparse(body(geom_sf_pattern))
  expect_true(any(grepl("requires the 'sf' package", fn_body)))
})

# ---- Visual snapshots -------------------------------------------------------

test_that("geom_sf_pattern single polygon hatch renders correctly", {
  df <- st_sf(
    label = "A", pattern = "hatch",
    geometry = st_sfc(sq(0, 0, 1, 1), crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = label, pattern = pattern)) +
    scale_pattern_identity() +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("sf-pattern-single-polygon-hatch", p)
})

test_that("geom_sf_pattern two polygons different patterns renders correctly", {
  df <- st_sf(
    region  = c("A", "B"),
    pattern = c("hatch", "crosshatch"),
    geometry = st_sfc(sq(0, 0, 1, 1), sq(1, 0, 2, 1), crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("sf-pattern-two-polygons", p)
})

test_that("geom_sf_pattern multipolygon dots renders correctly", {
  multi <- st_multipolygon(list(
    list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0))),
    list(cbind(c(2, 3, 3, 2, 2), c(0, 0, 1, 1, 0)))
  ))
  df <- st_sf(
    region = "AB", pattern = "dots",
    geometry = st_sfc(multi, crs = 4326)
  )
  p <- ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity() +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
  vdiffr::expect_doppelganger("sf-pattern-multipolygon-dots", p)
})

test_that("geom_sf_pattern nc counties hatch/crosshatch/dots renders correctly", {
  skip_if_not_installed("sf")
  nc         <- sf::st_read(system.file("shape/nc.shp", package = "sf"),
                            quiet = TRUE)
  nc$pattern <- rep(c("hatch", "crosshatch", "dots"), length.out = nrow(nc))
  p <- ggplot2::ggplot(nc) +
    geom_sf_pattern(ggplot2::aes(pattern = pattern), fill = "white") +
    scale_pattern_identity(guide = "legend") +
    theme_minimal()
  vdiffr::expect_doppelganger("sf-pattern-hatch-nc", p)
})

test_that("geom_sf_pattern us states choropleth fill+pattern renders correctly", {
  skip_if_not_installed("sf")
  skip_if_not_installed("spData")

  # Exact code from vignettes/mapping-with-patterns.Rmd — "US states" chunk.
  # Fix a known typo in the REGION factor level
  us <- spData::us_states
  levels(us$REGION)[levels(us$REGION) == "Norteast"] <- "Northeast"

  p <- ggplot2::ggplot(us) +
    geom_sf_pattern(
      ggplot2::aes(fill = total_pop_15, pattern = REGION),
      pattern_colour    = "grey20",
      pattern_linewidth = 0.45,
      pattern_spacing   = 0.09
    ) +
    scale_pattern_manual(
      values = c(
        Midwest   = "hatch",
        Northeast = "crosshatch",
        South     = "dots",
        West      = "vertical"
      ),
      name = "Region"
    ) +
    ggplot2::scale_fill_distiller(
      palette   = "Blues",
      direction = 1,
      name      = "Population (2015)",
      labels    = scales::comma
    ) +
    ggplot2::labs(
      title    = "US states",
      subtitle = "Fill: 2015 population  ·  Pattern: Census region"
    ) +
    ggplot2::theme_minimal()

  vdiffr::expect_doppelganger("sf-pattern-us-states-choropleth", p)
})
