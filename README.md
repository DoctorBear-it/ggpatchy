# ggpatchy

Simple, sane pattern overlays for ggplot2.

Maps discrete variables to hatch, crosshatch, dot, and other overlay patterns
using grid graphics — no ImageMagick, no magick, no PostScript tomfoolery.

```r
library(ggplot2)
library(ggpatchy)

ggplot(mpg, aes(class, fill = class, pattern = class)) +
  geom_col_pattern(stat = "count") +
  scale_pattern_discrete() +
  scale_fill_brewer(palette = "Pastel1") +
  theme_minimal()
```

## Installation

### With pixi (recommended)

```bash
# Clone the repo
git clone https://github.com/yourname/ggpatchy
cd ggpatchy

# Install everything (R, all deps, dev tools) in one shot
pixi install

# Run tests
pixi run test

# Load in an R session
pixi run load
```

### From GitHub (standard R)

```r
# install.packages("pak")
pak::pkg_install("yourname/ggpatchy")
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

| Aesthetic           | Controls                         | Default   |
|---------------------|----------------------------------|-----------|
| `pattern`           | Pattern name                     | `"none"`  |
| `pattern_colour`    | Line/dot colour                  | `"black"` |
| `pattern_linewidth` | Line width (line patterns)       | `1`       |
| `pattern_spacing`   | Spacing (npc fraction)           | `0.08`    |
| `pattern_angle`     | Angle in degrees (hatch)         | `45`      |
| `pattern_size`      | Dot size in mm (dots pattern)    | `0.4`     |

## Custom patterns

```r
register_pattern("zigzag", function(x, y, width, height, gp, params) {
  # x, y, width, height are npc coordinates of the shape's bounding box
  # Return any grid grob; it will be clipped to the shape
  spacing <- params$pattern_spacing %||% 0.1
  line_gp <- grid::gpar(col = gp$pattern_colour %||% "black",
                        lwd = gp$pattern_linewidth %||% 1)
  # ... build your grob ...
  grid::nullGrob()  # replace with real grob
})
```

## Geoms

- `geom_col_pattern()` — columns (stat = "identity")
- `geom_bar_pattern()` — bars (stat = "count")
- `geom_polygon_pattern()` — arbitrary polygons with path-clipped patterns

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
