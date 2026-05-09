# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ggpatchy** is an R package (v0.2.0) that adds pattern fill overlays to ggplot2 geoms using native grid graphics — no ImageMagick or external raster dependencies.

## Design Constraints (read before proposing solutions)

These are deliberate choices, not TODOs:

- **No ImageMagick / magick / raster dependencies.** The whole point of this package is to be a lightweight pure-grid alternative to `ggpattern`. If a problem looks like it'd be easy to solve with ImageMagick, the answer is "we accept the limitation instead."
- **Patterns are grid grobs, not bitmap fills.** They scale with viewports and respect device DPI naturally. Avoid solutions that pre-rasterize.
- **No new hard dependencies in `DESCRIPTION` without discussion.** Soft suggestions in `Suggests:` are fine for tests/vignettes.

## Development Environment

All dev tasks run through **pixi** (a conda-based environment manager). Never invoke R directly — always use pixi commands.

```sh
pixi run bootstrap    # Run once after cloning to lock .libPaths to pixi env
pixi run document     # Regenerate roxygen2 docs (man/, NAMESPACE)
pixi run test         # Run testthat suite
pixi run check        # Full R CMD CHECK (includes vignettes/examples)
pixi run check-fast   # R CMD CHECK skipping vignettes/examples
pixi run build        # Build package tarball
pixi run install      # Install package into pixi env
pixi run rstudio      # Launch RStudio with the pixi R
```

### Windows: Rtools44

Rtools44 is installed at `C:\rtools44`. Prepend its bin directories to PATH when running `pixi run check` or `pixi run check-fast`:

```sh
export PATH="/c/rtools44/usr/bin:/c/rtools44/mingw64/bin:$PATH" && pixi run check
```

### When a check or test fails

Re-read `CLAUDE.md` before trying alternative approaches. Do not bypass the pixi task system to invoke R or other tools directly.

To run a single test file:
```r
# Inside an R session with the package loaded:
testthat::test_file("tests/testthat/test-patterns.R")
```

### Visual regression testing

Visual tests use **vdiffr** and store SVG snapshots in `tests/testthat/_snaps/visual/`.

**Important:** Never regenerate snapshots just to make a failing test pass. A failing visual test means either (a) you intentionally changed the visual output and the snapshot needs updating, or (b) you broke something. Always confirm which one before regenerating.

To update snapshots after intentional visual changes:
```r
vdiffr::manage_cases()  # interactive snapshot manager
```

## Architecture

### Pattern Registry

`R/patterns.R` owns the central pattern registry — a named list of pattern functions stored in the package environment (`.pattern_registry`, an `emptyenv()`-parented env). Each pattern function has the signature:

```r
fn(x, y, width, height, gp, params) → grid grob
```

Where `x/y/width/height` are in **npc** units (0–1 relative to the parent viewport), `gp` is the base `gpar()` from the geom (carries `pattern_colour`, `pattern_linewidth`), and `params` is a named list of extra parameters from the scale (`pattern_angle`, `pattern_spacing`, `pattern_size`).

Patterns render their content inside a clipped viewport via the `clipped_grob()` helper (clips to the bbox rectangle). `hatch_lines()` is a shared helper for line-based patterns (hatch, crosshatch, horizontal, vertical) that computes line positions via perpendicular-offset arithmetic across the unit square; when `poly_x`/`poly_y` are supplied it calls `clip_segments_to_poly()` to restrict lines to the polygon interior. `pip()` is a vectorised ray-casting point-in-polygon test used by `dots`. Custom patterns are registered at runtime with `register_pattern(name, fn)`.

Built-in patterns: `none`, `hatch`, `crosshatch`, `horizontal`, `vertical`, `dots`, `weave`. Of these, only `hatch` and `crosshatch` currently honor `pattern_angle` — the others have fixed orientations by design (or by oversight; see ROADMAP).

### Geom Layer

Five geoms extend existing ggplot2 ggproto classes:

- `GeomColPattern` / `GeomBarPattern` (`R/geom_col_pattern.R`) — extend **`GeomRect`** (not `GeomBar`). This is deliberate: ggplot2 4.0 restructured `GeomBar` to no longer expose a `draw_panel` method we can safely override. `GeomRect` draws filled rectangles from `xmin/xmax/ymin/ymax`, which is what bars become after the stat + position stack runs. `setup_data()` derives `xmin/xmax/ymin/ymax` from `x/y` for the bar case.
- `GeomPolygonPattern` (`R/geom_polygon_pattern.R`) — extends `GeomPolygon`; clips the pattern to the exact polygon shape using device-independent in-R computation. Polygon vertices are normalised to 0–1 bbox-relative coordinates and passed to pattern functions as `params$poly_x` / `params$poly_y`. Line patterns use `clip_segments_to_poly()` (parametric intersection + ray-casting midpoint test, supports concave simple polygons); `dots` uses `pip()` directly to filter grid positions.
- `GeomRibbonPattern` / `GeomAreaPattern` (`R/geom_ribbon_pattern.R`) — extend **`GeomRibbon`** via `draw_group` override. The base ribbon is rendered by the parent; the pattern overlay reconstructs the ribbon polygon (upper ymax edge + reversed lower ymin edge) from `coord$transform` output and feeds it into the existing `clip_segments_to_poly` / `pip` clipper. `GeomAreaPattern` is a thin subclass that sets `ymin = 0`, `ymax = y` in `setup_data`, mirroring `GeomArea`. `orientation = "y"` is not supported for the pattern overlay.
- `GeomViolinPattern` (`R/geom_violin_pattern.R`) — extends **`GeomViolin`** via `draw_group` override. Reconstructs the violin polygon from the `xminv`/`xmaxv` arithmetic that `GeomViolin` uses internally, transforms to npc, then clips the pattern to the violin outline. Requires a `violinwidth` column (computed by `stat_ydensity`); emits a message and returns `nullGrob()` if absent. `orientation = "y"` is not supported for the pattern overlay.

`draw_panel()` / `draw_group()` renders each geometric primitive as a base grob plus a clipped pattern grob stacked in a `grobTree`.

The `draw_key_pattern()` function in `R/aaa_draw_key.R` (prefixed `aaa_` so it loads first alphabetically — geoms reference it at definition time) renders legend swatches. Legend swatches use a 2.5× spacing multiplier so patterns don't appear as a dense blob in the small key area.

### Scale System

`R/scale_pattern.R` provides three discrete scales that map a variable to pattern names:

- `scale_pattern_manual()` — explicit name→pattern mapping
- `scale_pattern_discrete()` — cycles through built-in patterns automatically
- `scale_pattern_identity()` — uses the column value directly as a pattern name

### Known Limitations (see ROADMAP.md)

- `pattern_angle` is **intentionally** ignored by `horizontal`, `vertical`, `dots`, and `weave` — their names or composite structure define a fixed orientation. Only `hatch` and `crosshatch` rotate.
- Legend key spacing uses a hardcoded 2.5× multiplier on `pattern_spacing`.
- Per-row pattern parameter mapping (e.g. mapping `pattern_spacing` to a column) is untested.
- Performance is O(n) grobs — can be slow for large datasets.

