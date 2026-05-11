# Roadmap

Where ggpatchy is now, what it doesn’t do yet, and rough priority for
what comes next. This is a planning doc — items here are not promises.

## Current state (v0.6.0)

Ten geoms (`geom_col_pattern`, `geom_bar_pattern`, `geom_rect_pattern`,
`geom_tile_pattern`, `geom_polygon_pattern`, `geom_ribbon_pattern`,
`geom_area_pattern`, `geom_density_pattern`, `geom_violin_pattern`,
`geom_sf_pattern`), nineteen built-in patterns (seven base patterns plus
`_dense` and `_sparse` variants for each), three scales (`manual`,
`identity`, `discrete`), a registration API for custom patterns, and
visual regression tests. `R CMD check` is clean. Four vignettes cover
the user-facing geoms, choropleth mapping, the built-in pattern
reference, and design philosophy.

`geom_sf_pattern` requires the `sf` package (listed in `Suggests`). It
supports POLYGON and MULTIPOLYGON geometries; GEOMETRYCOLLECTION
produces a warning; LINESTRING and POINT render via the base geom
without pattern overlays.

On R ≥ 4.1 with a supporting device (ragg, Cairo PDF, SVG), polygon and
sf patterns are clipped to the exact polygon boundary via the native
graphics engine clip path API. On older R the fallback is bounding-box
clipping.

Pattern spacing is in **millimetres**: `pattern_spacing = 5` means 5 mm
between pattern elements on every shape at every size. Grid resolves mm
to device pixels inside the active shape viewport at draw time via
`makeContent`-based deferral, giving uniform visual density across all
shapes in the same plot regardless of their physical size.

The package is small enough that one person can hold the whole thing in
their head, which is the point.

## Known limitations

These are real, current limitations of the implementation. They aren’t
bugs — they’re places where the code does something simpler than the
user might expect.

### `orientation = "y"` not supported for ribbon/area/violin

[`geom_ribbon_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_ribbon_pattern.md),
[`geom_area_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_ribbon_pattern.md),
and
[`geom_violin_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_violin_pattern.md)
do not support `orientation = "y"` (horizontal orientation). The base
shape renders correctly; the pattern overlay is silently skipped. The
internal coordinate layout under `flipped_aes = TRUE` makes safe pattern
reconstruction non-trivial. Use `coord_flip()` on a vertical geom as a
workaround.

### Coordinate transforms beyond Cartesian aren’t tested

The geoms call `coord$transform(data, panel_params)` and then draw
patterns in screen npc space. `coord_cartesian` works. `coord_flip`
probably works. `coord_polar`, `coord_sf`, `coord_map`, and free
coordinate systems will produce surprising output because the pattern is
drawn in screen space, not data space — a hatch on a pie slice will be
straight diagonal lines in screen pixels, not following the slice’s
curvature.

Whether “screen-space patterns under polar coords” is a bug or a feature
depends on what you want. Some users will want curved hatching; most
will want screen-space lines because that’s how patterns work in print.

### Legends use geometry-derived spacing, not data spacing

`draw_key_pattern` in `aaa_draw_key.R` overrides `pattern_spacing` with
a geometry-derived value (`0.9 / TARGET_REPS`) so the legend swatch
always shows approximately 3 pattern repetitions regardless of the
user’s chosen density. This is deliberate — the legend communicates
pattern *type*, not density — but it means the legend swatch does not
faithfully represent the visual density in the data area.

### NA in the pattern column becomes “none” with a warning

If your pattern variable contains NA, that row gets `"none"` (no
overlay) and a warning is emitted once per draw call. This is the
current behaviour as of v0.3.0.

### Performance is per-row

For each bar, we build a `rectGrob` plus a `pattern_grob`. A 5,000-row
plot creates 10,000 grobs. Renders in a few seconds, which is fine for
typical analytical charts but bad for very large data. The fix is
grouping bars with identical pattern + style into shared grobs.

## Roadmap

Priority order. Items closer to the top will land first.

### Speculative (no commitment)

- `geom_boxplot_pattern` — requires deciding what “pattern” means for a
  shape with internal structure (whiskers, outlier points).
- `coord_polar` support (curved hatch lines in polar plots) — a real
  research project.
- Performance optimization for large datasets — only worth doing if
  someone reports it as a real problem.
- A “texture from image” pattern type that loads a small bitmap. Adds
  dependencies, so probably never.

## Shipped

### 0.6.0 — physical-unit spacing (breaking change)

- ~~`pattern_spacing` changes from a dimensionless bbox fraction to
  millimetres. Default `5` (mm). `pattern_size` for dots changes from
  dimensionless to mm, default `0.5` (mm).~~ — shipped in v0.6.0.
- ~~`makeContent`-based deferral (`DotPatternTree`, `LinePatternTree`
  grob classes) so mm → npc conversion happens inside the active shape
  viewport at draw time.~~ — shipped in v0.6.0.
- ~~Named density variants (`hatch_dense` etc.) bake in a spacing
  multiplier against the mm default — no changes needed to variant
  registrations.~~ — shipped in v0.6.0.

### 0.5.0 — named density variants

- ~~Named density variants: `hatch_dense`, `hatch_sparse`,
  `crosshatch_dense`, `crosshatch_sparse`, `horizontal_dense`,
  `horizontal_sparse`, `vertical_dense`, `vertical_sparse`,
  `dots_dense`, `dots_sparse`, `weave_dense`, `weave_sparse`. Pre-baked
  spacing multipliers (0.5× dense, 2.0× sparse) against
  `.PATTERN_SPACING_DEFAULT`.~~ — shipped in v0.5.0.
- ~~Pattern reference vignette (`vignettes/pattern-reference.Rmd`) —
  shows all patterns at sparse / default / dense.~~ — shipped in v0.5.0.

### 0.4.x — spacing constant and clip paths

- ~~`.PATTERN_SPACING_DEFAULT` constant; `dots` and `weave` harmonised
  to `0.08`.~~ — shipped in v0.4.2.
- ~~True polygon clip paths via R 4.1 graphics engine
  (`geom_polygon_pattern`, `geom_sf_pattern`); bounding-box fallback on
  older R.~~ — shipped in v0.4.0.
- ~~Bounding-box-relative pattern spacing: `pattern_spacing` is now a
  fraction of each shape’s bbox, not the panel.~~ — shipped in v0.4.1.

### 0.3.0 — new geoms

- ~~`geom_violin_pattern`~~ — shipped in v0.2.0.
- ~~`geom_rect_pattern` and `geom_tile_pattern`~~ — shipped in v0.3.0.
- ~~`geom_density_pattern`~~ — shipped in v0.3.0.
- ~~`geom_sf_pattern`~~ — shipped in v0.3.0.
- ~~Per-row mapping of pattern parameters.~~ — shipped in v0.3.0.

### 0.2.x — small fixes

- ~~Visual fixtures for `position = "dodge"` and faceted plots~~ — done
  in v0.2.1.
- ~~NA-in-pattern handling: warn and drop, matching ggplot2 convention~~
  — done in v0.2.1.
- ~~CI on GitHub Actions across Linux + macOS + Windows, R-release +
  R-devel~~ — done in v0.2.1.
- ~~pkgdown site at `https://doctorbear-it.github.io/ggpatchy/`~~ — done
  in v0.2.1.

## Things that probably won’t happen

- ImageMagick / magick integration. The whole point of ggpatchy is to
  avoid that dependency.
- Backwards compatibility shims for ggpattern. Different package,
  different API.
- Pattern animations (e.g. for gganimate). Out of scope.
- Custom pattern *parameters* beyond the existing fixed set. The escape
  hatch is
  [`register_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/register_pattern.md)
  — define your own pattern function and pull whatever you want from
  `params`.

## Reporting issues and contributing

Issues at <https://github.com/DoctorBear-it/ggpatchy/issues>. Bug
reports with a reprex are gold. Feature requests are welcome but read
this roadmap first — there’s a decent chance your request is already on
it (or already in “probably won’t happen”).
