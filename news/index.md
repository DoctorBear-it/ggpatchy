# Changelog

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
