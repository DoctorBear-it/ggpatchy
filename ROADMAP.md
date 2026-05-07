# Roadmap

Where ggpatchy is now, what it doesn't do yet, and rough priority for what comes next. This is a planning doc — items here are not promises.

## Current state (v0.1.0)

Three geoms, seven built-in patterns, three scales (`manual`, `identity`, `discrete`), a registration API for custom patterns, and visual regression tests. `R CMD check` is clean.

The package is small enough that one person can hold the whole thing in their head, which is the point.

## Known limitations

These are real, current limitations of the implementation. They aren't bugs — they're places where the code does something simpler than the user might expect.

### `geom_polygon_pattern` only clips to the bounding box

Patterns drawn over a polygon are clipped to the polygon's *axis-aligned bounding box*, not the polygon itself. For rectangular polygons (squares, ggplot2 default rectangles) this is invisible. For triangles, hexagons, country shapes, or anything non-rectangular, you'll see pattern elements (dots, hatch lines) appearing in the corners outside the actual fill. Image-search "ggpatchy polygon-pattern-dots-triangle" in the test snapshots to see what this looks like.

True polygon clipping requires a graphics device that supports alpha masking via `grid::as.path()` — which means R ≥ 4.1.0 plus a backend like ragg, Cairo PDF, or modern SVG. The infrastructure exists; we haven't wired it up because doing it correctly across devices is its own project. See `R/geom_polygon_pattern.R` for where the comment lives in the source.

### Limited geom coverage

Implemented: `geom_col_pattern`, `geom_bar_pattern`, `geom_polygon_pattern`.

Not implemented: `geom_area_pattern`, `geom_ribbon_pattern`, `geom_density_pattern`, `geom_violin_pattern`, `geom_boxplot_pattern`, `geom_tile_pattern`, `geom_rect_pattern`, `geom_sf_pattern`. Each is a small project; most reduce to "wrap an existing geom and add the pattern overlay step." `geom_rect_pattern` and `geom_tile_pattern` are the easiest. `geom_sf_pattern` is the most useful for real work but inherits the bounding-box-clipping limitation above.

### Coordinate transforms beyond Cartesian aren't tested

The geoms call `coord$transform(data, panel_params)` and then draw patterns in screen npc space. `coord_cartesian` works. `coord_flip` probably works. `coord_polar`, `coord_sf`, `coord_map`, and free coordinate systems will produce surprising output because the pattern is drawn in screen space, not data space — a hatch on a pie slice will be straight diagonal lines in screen pixels, not following the slice's curvature.

Whether "screen-space patterns under polar coords" is a bug or a feature depends on what you want. Some users will want curved hatching; most will want screen-space lines because that's how patterns work in print.

### Per-row pattern parameter mapping is untested

The geom reads `pattern_spacing`, `pattern_angle`, `pattern_size` per data row, which means in principle you can map them like aesthetics:

```r
aes(pattern_spacing = density)  # tighter hatch where density is higher
```

The plumbing supports it. We have not tested it, and no fixture exercises this path. Likely works for simple cases, may break in subtle ways (legend rendering, defaults, NA handling).

### Pattern angle is only honored by hatch and crosshatch

`pattern_angle` is consumed by the `hatch` and `crosshatch` patterns. The `horizontal`, `vertical`, `dots`, and `weave` patterns ignore it entirely. The fix is one line per pattern but introduces visual changes to existing fixtures — worth doing in a 0.2.0 with explicit visual review.

### Legends use a fudged spacing factor

`R/aaa_draw_key.R` multiplies `pattern_spacing` by 2.5 in legend keys so the swatch isn't a dense blob. This means the legend swatch doesn't faithfully represent the pattern density used in the data area. A better approach would compute a target swatch-relative spacing instead of a global scale factor, but the current behavior is "good enough that nobody complains."

### NA in the pattern column silently becomes "none"

If your pattern variable contains NA, that row gets `"none"` (no overlay) without warning. ggplot2's convention for unmapped aesthetics is to drop the row with a warning. We should match that. Low priority.

### Performance is per-row

For each bar, we build a `rectGrob` plus a `pattern_grob`. A 5,000-row plot creates 10,000 grobs. Renders in a few seconds, which is fine for typical analytical charts but bad for very large data. The fix is grouping bars with identical pattern + style into shared grobs.

## Roadmap

Loose priority order. Items closer to the top will land first.

### Near term (0.1.x — small fixes, no API changes)

- Visual fixtures for `position = "dodge"` and faceted plots, to expose any bugs in those paths.
- NA-in-pattern handling: warn and drop, matching ggplot2 convention.
- `pattern_angle` honored by the directional patterns where it makes sense (`horizontal` and `vertical` could rotate; `dots` and `weave` don't have a meaningful single angle).
- A vignette walking through the four most common use cases, written from inside RStudio against the installed package.

### Medium term (0.2.0 — new geoms, no breaking changes)

- `geom_rect_pattern` and `geom_tile_pattern` — straightforward extensions, both rectangle-based.
- `geom_area_pattern` and `geom_ribbon_pattern` — wrap the underlying ggplot2 geoms, add overlay.
- CI on GitHub Actions across Linux + macOS + Windows, R-release + R-devel.
- pkgdown site at `https://doctorbear-it.github.io/ggpatchy/`.

### Longer term (0.3.0 — bigger lifts)

- True polygon clipping using `grid::as.path()` on supporting devices, with graceful fallback to bounding-box clipping on devices that can't handle it.
- `geom_sf_pattern` — depends on the polygon clipping fix being solid.
- Per-row mapping of pattern parameters: tested, with sensible legend defaults.

### Speculative (no commitment)

- `geom_violin_pattern`, `geom_boxplot_pattern`, `geom_density_pattern` — each requires deciding what "pattern" means for a non-rectangular shape with internal structure.
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
