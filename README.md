# ggpatchy

Simple, sane pattern overlays for ggplot2.

Maps discrete variables to hatch, crosshatch, dot, and other overlay patterns
using grid graphics — no ImageMagick, no magick, no PostScript tomfoolery.

```r
library(ggplot2)
library(ggpatchy)

ggplot(mpg, aes(class, fill = class, pattern = class)) +
  geom_bar_pattern() +
  scale_pattern_discrete() +
  scale_fill_brewer(palette = "Pastel1") +
  theme_minimal()
```

## Installation

### From GitHub (standard R)

```r
# install.packages("pak")
pak::pkg_install("DoctorBear-it/ggpatchy")
```

### With pixi (for development)

```bash
# Clone the repo
git clone https://github.com/DoctorBear-it/ggpatchy
cd ggpatchy

# Install everything (R, all deps, dev tools) in one shot
pixi install

# Run tests
pixi run test

# Load in an R session
pixi run load
```

## Available patterns

| Name          | Description                          |
|---------------|--------------------------------------|
| `"none"`      | No pattern (transparent overlay)     |
| `"hatch"`     | Diagonal lines (default 45°)         |
| `"crosshatch"`| Two sets of diagonal lines           |
| `"horizontal"`| Flat horizontal lines                |
| `"vertical"`  | Straight vertical lines              |
| `"dots"`      | Grid of small dots                   |
| `"weave"`     | Woven diagonal + horizontal lines    |

```r
list_patterns()  # see all registered patterns
```

## Pattern aesthetics

| Aesthetic           | Controls                                    | Default   |
|---------------------|---------------------------------------------|-----------|
| `pattern`           | Pattern name                                | `"none"`  |
| `pattern_colour`    | Line/dot colour                             | `"black"` |
| `pattern_linewidth` | Line width (line patterns)                  | `1`       |
| `pattern_spacing`   | Spacing as fraction of shape's bounding box | `0.08`    |
| `pattern_angle`     | Angle in degrees (`hatch`/`crosshatch`)     | `45`      |
| `pattern_size`      | Dot size relative to spacing (`dots`)       | `0.35`    |

## Scales

- `scale_pattern_manual(values = ...)` — explicit mapping; `values` may be a
  named character vector (matched to factor levels by name) or unnamed
  (matched positionally).
- `scale_pattern_identity()` — use the data column's values directly as
  pattern names. Best when your variable already contains valid pattern
  names like `"hatch"` or `"dots"`.
- `scale_pattern_discrete()` — auto-cycle through the built-in patterns in
  factor-level order. No name lookup; use `scale_pattern_identity()` if you
  want value-as-pattern semantics.

## Custom patterns

Register a function that takes the bounding box of the shape (in npc) plus
graphical parameters, and returns any grid grob:

```r
library(grid)

register_pattern("zigzag", function(x, y, width, height, gp, params) {
  spacing <- params$pattern_spacing %||% 0.1
  line_gp <- gpar(col = gp$pattern_colour %||% "black",
                  lwd = gp$pattern_linewidth %||% 1)
  ys <- seq(0, 1, by = spacing)
  segs <- lapply(ys, function(y0) {
    polylineGrob(
      x  = unit(c(0, 0.5, 1), "npc"),
      y  = unit(c(y0, y0 + spacing / 2, y0), "npc"),
      gp = line_gp
    )
  })
  vp <- viewport(x = x, y = y, width = width, height = height,
                 just = c("left", "bottom"), clip = "on")
  gTree(children = do.call(gList, segs), vp = vp)
})
```

After registering, use it like any built-in pattern:

```r
ggplot(df, aes(group, value, fill = group, pattern = group)) +
  geom_col_pattern() +
  scale_pattern_manual(values = c(A = "zigzag", B = "hatch", C = "dots"))
```

## Geoms

- `geom_col_pattern()` — columns (`stat = "identity"`)
- `geom_bar_pattern()` — bars (`stat = "count"`)
- `geom_polygon_pattern()` — arbitrary polygons with path-clipped patterns
- `geom_ribbon_pattern()` — ribbons and confidence bands
- `geom_area_pattern()` — filled area charts (stacks supported)
- `geom_violin_pattern()` — violin plots
- `geom_density_pattern()` — smooth density estimates
- `geom_rect_pattern()` — rectangles from `xmin/xmax/ymin/ymax`
- `geom_tile_pattern()` — tiles from centre coordinates
- `geom_sf_pattern()` — sf POLYGON / MULTIPOLYGON geometries (requires **sf**)

## Why not ggpattern?

ggpattern renders patterns by generating raster images via external tools
(magick, gridpattern). This means ImageMagick as a runtime dependency, slow
rendering, blurry output at non-native resolutions, and a truly heroic amount
of code for what should be a simple thing.

ggpatchy renders everything as native grid grobs: scalable, fast, zero extra
dependencies beyond what ggplot2 already needs.

## Dev workflow with pixi

```bash
pixi run document   # regenerate roxygen docs
pixi run test       # run testthat
pixi run check      # full R CMD CHECK
pixi run check-fast # skip vignettes/examples
pixi run docs       # build pkgdown site
pixi run rstudio    # open RStudio using pixi's R
```

## RStudio integration

Pixi manages R itself. Point RStudio at pixi's R binary so it uses the locked
environment:

```bash
# Find the R binary pixi installed:
pixi run Rscript --vanilla -e "R.home('bin')"

# In RStudio: Tools → Global Options → R → R version → Browse
# Select that binary.
```

Or use the `pixi run rstudio` task if RStudio is on your PATH.