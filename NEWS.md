# ggpatchy 0.5.1

## New features

- New exported function `pattern_contrast(colour1, colour2)` returns the
  WCAG 2.1 contrast ratio between two colours. Useful for pre-validating
  colour choices programmatically.
- New geom aesthetic `pattern_contrast_check`: set to a numeric threshold
  (e.g. `3.0` for WCAG AA non-text) to receive a warning when any shape's
  `pattern_colour` / `fill` contrast falls below it. `TRUE` is an alias for
  `3.0`. Default `0` (disabled, no behaviour change).
- New geom aesthetic `pattern_contrast_correct`: set to `TRUE` to
  automatically adjust `pattern_colour` luminance to just meet the contrast
  threshold before drawing. Correction is silent; the adjusted colour is
  used for rendering only and does not modify your data. Default `FALSE`.
  When `pattern_contrast_correct = TRUE` without an explicit
  `pattern_contrast_check`, the correction threshold defaults to `3.0`.

---

# ggpatchy 0.5.0

## New features

- Named density variants for all six base patterns: `hatch_dense`,
  `hatch_sparse`, `crosshatch_dense`, `crosshatch_sparse`,
  `horizontal_dense`, `horizontal_sparse`, `vertical_dense`,
  `vertical_sparse`, `dots_dense`, `dots_sparse`, `weave_dense`,
  `weave_sparse`. Use these in place of any base pattern name to get a
  predictably tighter or looser spacing without setting `pattern_spacing`
  manually. Explicit `pattern_spacing` values still override the variant
  default.

## Internal changes

- All built-in pattern functions now share a single `.PATTERN_SPACING_DEFAULT`
  constant (`0.08`). `dots` (previously `0.1`) and `weave` (previously
  `0.07`) have been harmonised to this value (shipped in v0.4.2).

---

# ggpatchy 0.4.1

## Improvements

- Pattern spacing is now relative to each shape's bounding box rather than
  the full panel. `pattern_spacing = 0.08` now means "8% of the shape's
  bounding box" consistently across shapes of any size. Previously, small
  shapes received sparse patterns and large shapes received dense ones with
  the same spacing value.

---

# ggpatchy 0.4.0

## Breaking changes

- Minimum R version is now 4.1.0.

## Bug fixes and improvements

- `geom_polygon_pattern()` and `geom_sf_pattern()` now clip patterns to the
  exact polygon boundary using the R 4.1 graphics engine clip path API. On
  R ≥ 4.1 with a supporting device (ragg, Cairo PDF, SVG), hatch lines and
  dots are correctly contained within the polygon shape. The previous
  bounding-box-only clipping is retained as a fallback for older R.

---

# ggpatchy 0.2.0

## New geoms

* `geom_ribbon_pattern()` and `geom_area_pattern()` — ribbon and area charts
  with pattern overlays clipped to the ribbon polygon. `GeomRibbonPattern`
  overrides `draw_group` to reconstruct the ribbon polygon from the
  `coord$transform` output and feed it through the existing
  `clip_segments_to_poly` / `pip` pattern clipper. `geom_area_pattern()` is a
  thin `GeomAreaPattern` subclass that mirrors `GeomArea` by setting
  `ymin = 0`, `ymax = y` in `setup_data`; `position = "stack"` works correctly.

## Known limitations added

* `orientation = "y"` (horizontal ribbons) is not supported for the pattern
  overlay. The base ribbon renders correctly; the pattern is silently skipped.

---

# ggpatchy 0.1.0

Initial CRAN release.

## Geoms

* `geom_col_pattern()` — column charts with pattern overlays (extends `GeomRect`).
* `geom_bar_pattern()` — bar charts using `stat = "count"` (same underlying geom).
* `geom_polygon_pattern()` — arbitrary polygons with patterns clipped to the
  exact polygon boundary using in-R segment-polygon intersection and
  ray-casting point-in-polygon tests.

## Patterns

Seven built-in patterns: `none`, `hatch`, `crosshatch`, `horizontal`,
`vertical`, `dots`, `weave`. Custom patterns can be registered at runtime
with `register_pattern()`.

## Scales

* `scale_pattern_manual()` — explicit name-to-pattern mapping.
* `scale_pattern_discrete()` — cycles through built-in patterns automatically.
* `scale_pattern_identity()` — uses the column value directly as a pattern name.

## Other

* `draw_key_pattern()` — legend key renderer for pattern aesthetics.
* `list_patterns()` — list all registered pattern names.
