# Changelog

## ggpatchy 0.6.0

### Breaking changes

- `pattern_spacing` now specifies spacing in **millimetres** (previously
  a dimensionless fraction of each shape’s bounding box). The default
  changes from `0.08` to `5` mm. Update existing code that sets
  `pattern_spacing` explicitly: `0.08` → `5`, `0.04` (dense) → `2.5`,
  `0.16` (sparse) → `10`, or similar.
- `pattern_size` for the `"dots"` pattern is now the dot **radius** in
  millimetres (previously dimensionless). Default changes from `0.4` to
  `0.5` mm.
- Legend key pattern density is no longer overridden to a fixed
  `TARGET_REPS`-based value. The legend now shows the same physical
  spacing as the data, which means legend swatches for dense patterns
  will look denser than for sparse patterns. This is correct behaviour.

### Why this change

The previous bounding-box-relative model produced different visual
densities across shapes of different physical sizes in the same plot —
most visibly on choropleth maps where small and large regions received
wildly different dot counts. Millimetre units resolve against device
physical dimensions at draw time, independently of viewport size, giving
uniform density across all shapes. See
[`vignette("design-philosophy")`](https://doctorbear-it.github.io/ggpatchy/articles/design-philosophy.md)
for full details.

### Interactive resizing

When resizing a plot window interactively, pattern density will appear
to change as the physical dimensions change. This is correct —
`pattern_spacing = 5` always means 5mm regardless of window size. For
consistent results, set chunk `fig.width`/`fig.height` to match your
intended
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
dimensions.

### Internal changes

- `makeContent.DotPatternTree` and `makeContent.LinePatternTree` now
  convert mm → npc via
  [`grid::convertWidth`](https://rdrr.io/r/grid/grid.convert.html) /
  [`grid::convertHeight`](https://rdrr.io/r/grid/grid.convert.html) at
  draw time inside the active shape viewport (infrastructure introduced
  in v0.5.x).

------------------------------------------------------------------------

## ggpatchy 0.5.1

### New features

- New exported function `pattern_contrast(colour1, colour2)` returns the
  WCAG 2.1 contrast ratio between two colours. Useful for pre-validating
  colour choices programmatically.
- New geom aesthetic `pattern_contrast_check`: set to a numeric
  threshold (e.g. `3.0` for WCAG AA non-text) to receive a warning when
  any shape’s `pattern_colour` / `fill` contrast falls below it. `TRUE`
  is an alias for `3.0`. Default `0` (disabled, no behaviour change).
- New geom aesthetic `pattern_contrast_correct`: set to `TRUE` to
  automatically adjust `pattern_colour` luminance to just meet the
  contrast threshold before drawing. Correction is silent; the adjusted
  colour is used for rendering only and does not modify your data.
  Default `FALSE`. When `pattern_contrast_correct = TRUE` without an
  explicit `pattern_contrast_check`, the correction threshold defaults
  to `3.0`.

------------------------------------------------------------------------

## ggpatchy 0.5.0

### New features

- Named density variants for all six base patterns: `hatch_dense`,
  `hatch_sparse`, `crosshatch_dense`, `crosshatch_sparse`,
  `horizontal_dense`, `horizontal_sparse`, `vertical_dense`,
  `vertical_sparse`, `dots_dense`, `dots_sparse`, `weave_dense`,
  `weave_sparse`. Use these in place of any base pattern name to get a
  predictably tighter or looser spacing without setting
  `pattern_spacing` manually. Explicit `pattern_spacing` values still
  override the variant default.

### Internal changes

- All built-in pattern functions now share a single
  `.PATTERN_SPACING_DEFAULT` constant (`0.08`). `dots` (previously
  `0.1`) and `weave` (previously `0.07`) have been harmonised to this
  value (shipped in v0.4.2).

------------------------------------------------------------------------

## ggpatchy 0.4.1

### Improvements

- Pattern spacing is now relative to each shape’s bounding box rather
  than the full panel. `pattern_spacing = 0.08` now means “8% of the
  shape’s bounding box” consistently across shapes of any size.
  Previously, small shapes received sparse patterns and large shapes
  received dense ones with the same spacing value.

------------------------------------------------------------------------

## ggpatchy 0.4.0

### Breaking changes

- Minimum R version is now 4.1.0.

### Bug fixes and improvements

- [`geom_polygon_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_polygon_pattern.md)
  and
  [`geom_sf_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_sf_pattern.md)
  now clip patterns to the exact polygon boundary using the R 4.1
  graphics engine clip path API. On R ≥ 4.1 with a supporting device
  (ragg, Cairo PDF, SVG), hatch lines and dots are correctly contained
  within the polygon shape. The previous bounding-box-only clipping is
  retained as a fallback for older R.

------------------------------------------------------------------------

## ggpatchy 0.2.0

### New geoms

- [`geom_ribbon_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_ribbon_pattern.md)
  and
  [`geom_area_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_ribbon_pattern.md)
  — ribbon and area charts with pattern overlays clipped to the ribbon
  polygon. `GeomRibbonPattern` overrides `draw_group` to reconstruct the
  ribbon polygon from the `coord$transform` output and feed it through
  the existing `clip_segments_to_poly` / `pip` pattern clipper.
  [`geom_area_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_ribbon_pattern.md)
  is a thin `GeomAreaPattern` subclass that mirrors `GeomArea` by
  setting `ymin = 0`, `ymax = y` in `setup_data`; `position = "stack"`
  works correctly.

### Known limitations added

- `orientation = "y"` (horizontal ribbons) is not supported for the
  pattern overlay. The base ribbon renders correctly; the pattern is
  silently skipped.

------------------------------------------------------------------------

## ggpatchy 0.1.0

Initial CRAN release.

### Geoms

- [`geom_col_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_col_pattern.md)
  — column charts with pattern overlays (extends `GeomRect`).
- [`geom_bar_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_col_pattern.md)
  — bar charts using `stat = "count"` (same underlying geom).
- [`geom_polygon_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_polygon_pattern.md)
  — arbitrary polygons with patterns clipped to the exact polygon
  boundary using in-R segment-polygon intersection and ray-casting
  point-in-polygon tests.

### Patterns

Seven built-in patterns: `none`, `hatch`, `crosshatch`, `horizontal`,
`vertical`, `dots`, `weave`. Custom patterns can be registered at
runtime with
[`register_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/register_pattern.md).

### Scales

- [`scale_pattern_manual()`](https://doctorbear-it.github.io/ggpatchy/reference/scale_pattern_manual.md)
  — explicit name-to-pattern mapping.
- [`scale_pattern_discrete()`](https://doctorbear-it.github.io/ggpatchy/reference/scale_pattern_discrete.md)
  — cycles through built-in patterns automatically.
- [`scale_pattern_identity()`](https://doctorbear-it.github.io/ggpatchy/reference/scale_pattern_identity.md)
  — uses the column value directly as a pattern name.

### Other

- [`draw_key_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/draw_key_pattern.md)
  — legend key renderer for pattern aesthetics.
- [`list_patterns()`](https://doctorbear-it.github.io/ggpatchy/reference/list_patterns.md)
  — list all registered pattern names.
