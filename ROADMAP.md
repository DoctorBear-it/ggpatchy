# Roadmap

Where ggpatchy is now, what it doesn't do yet, and rough priority for what comes next. This is a planning doc — items here are not promises.

## Current state (v0.3.0)

Nine geoms (`geom_col_pattern`, `geom_bar_pattern`, `geom_rect_pattern`, `geom_tile_pattern`, `geom_polygon_pattern`, `geom_ribbon_pattern`, `geom_area_pattern`, `geom_density_pattern`, `geom_violin_pattern`, `geom_sf_pattern`), seven built-in patterns, three scales (`manual`, `identity`, `discrete`), a registration API for custom patterns, and visual regression tests. `R CMD check` is clean. A vignette covers the user-facing geoms.

`geom_sf_pattern` requires the `sf` package (listed in `Suggests`). It supports POLYGON and MULTIPOLYGON geometries; GEOMETRYCOLLECTION produces a warning; LINESTRING and POINT render via the base geom without pattern overlays.

The package is small enough that one person can hold the whole thing in their head, which is the point.

## Known limitations

These are real, current limitations of the implementation. They aren't bugs — they're places where the code does something simpler than the user might expect.

### Coordinate transforms beyond Cartesian aren't well-tested for polygons

`geom_polygon_pattern` clips patterns to the exact polygon shape using device-independent in-R computation (`clip_segments_to_poly` + `pip`). This works on all devices and R versions, but it only handles simple (non-self-intersecting) polygons. Winding-rule nuance for complex polygons is not addressed.

### Limited geom coverage

Implemented: `geom_col_pattern`, `geom_bar_pattern`, `geom_polygon_pattern`, `geom_ribbon_pattern`, `geom_area_pattern`.

Not implemented: `geom_density_pattern`, `geom_boxplot_pattern`, `geom_tile_pattern`, `geom_rect_pattern`, `geom_sf_pattern`. Each is a small project; most reduce to "wrap an existing geom and add the pattern overlay step." `geom_rect_pattern` and `geom_tile_pattern` are the easiest. `geom_sf_pattern` is the most useful for real work but inherits the bounding-box-clipping limitation above.

`geom_ribbon_pattern()` and `geom_area_pattern()` do not support `orientation = "y"` (horizontal ribbons). The base ribbon renders correctly; the pattern overlay is silently skipped. Document this as a known limitation rather than fixing it — the internal coordinate layout under `flipped_aes = TRUE` makes safe pattern reconstruction non-trivial.

### Coordinate transforms beyond Cartesian aren't tested

The geoms call `coord$transform(data, panel_params)` and then draw patterns in screen npc space. `coord_cartesian` works. `coord_flip` probably works. `coord_polar`, `coord_sf`, `coord_map`, and free coordinate systems will produce surprising output because the pattern is drawn in screen space, not data space — a hatch on a pie slice will be straight diagonal lines in screen pixels, not following the slice's curvature.

Whether "screen-space patterns under polar coords" is a bug or a feature depends on what you want. Some users will want curved hatching; most will want screen-space lines because that's how patterns work in print.

### Per-row pattern parameter mapping is untested

The geom reads `pattern_spacing`, `pattern_angle`, `pattern_size` per data row, which means in principle you can map them like aesthetics:

```r
aes(pattern_spacing = density)  # tighter hatch where density is higher
```

The plumbing supports it. We have not tested it, and no fixture exercises this path. Likely works for simple cases, may break in subtle ways (legend rendering, defaults, NA handling).

### Legends use a fudged spacing factor

`R/aaa_draw_key.R` multiplies `pattern_spacing` by 2.5 in legend keys so the swatch isn't a dense blob. This means the legend swatch doesn't faithfully represent the pattern density used in the data area. A better approach would compute a target swatch-relative spacing instead of a global scale factor, but the current behavior is "good enough that nobody complains."

### NA in the pattern column becomes "none" with a warning

If your pattern variable contains NA, that row gets `"none"` (no overlay) and a warning is emitted once per draw call. This is the current behaviour as of v0.3.0.

### Performance is per-row

For each bar, we build a `rectGrob` plus a `pattern_grob`. A 5,000-row plot creates 10,000 grobs. Renders in a few seconds, which is fine for typical analytical charts but bad for very large data. The fix is grouping bars with identical pattern + style into shared grobs.

## Roadmap

Loose priority order. Items closer to the top will land first.

### Near term (0.2.x — small fixes, no API changes)

- ~~Visual fixtures for `position = "dodge"` and faceted plots~~ — done in v0.2.1.
- ~~NA-in-pattern handling: warn and drop, matching ggplot2 convention~~ — done in v0.2.1.
- ~~CI on GitHub Actions across Linux + macOS + Windows, R-release + R-devel~~ — done in v0.2.1.
- ~~pkgdown site at `https://doctorbear-it.github.io/ggpatchy/`~~ — done in v0.2.1.

### Medium term (0.3.0 — new geoms, no breaking changes)

- ~~`geom_violin_pattern`~~ — shipped in v0.2.0.
- ~~`geom_rect_pattern` and `geom_tile_pattern`~~ — shipped in v0.3.0.
- ~~`geom_density_pattern`~~ — shipped in v0.3.0.
- ~~`geom_sf_pattern`~~ — shipped in v0.3.0.
- ~~Per-row mapping of pattern parameters: tested, with sensible legend defaults.~~ — shipped in v0.3.0.

### Speculative (no commitment)

- `geom_boxplot_pattern`, `geom_density_pattern` — each requires deciding what "pattern" means for a non-rectangular shape with internal structure.
- `coord_polar` support (curved hatch lines in polar plots) — a real research project.
- Performance optimization for large datasets — only worth doing if someone reports it as a real problem.
- A "texture from image" pattern type that loads a small bitmap. Adds dependencies, so probably never.

## Things that probably won't happen

- ImageMagick / magick integration. The whole point of ggpatchy is to avoid that dependency.
- Backwards compatibility shims for ggpattern. Different package, different API.
- Pattern animations (e.g. for gganimate). Out of scope.
- Custom pattern *parameters* beyond the existing fixed set. The escape hatch is `register_pattern()` — define your own pattern function and pull whatever you want from `params`.

## Reporting issues and contributing

Issues at https://github.com/DoctorBear-it/ggpatchy/issues. Bug reports with a reprex are gold. Feature requests are welcome but read this roadmap first — there's a decent chance your request is already on it (or already in "probably won't happen").
