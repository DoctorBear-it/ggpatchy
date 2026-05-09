# Rectangle and tile charts with pattern overlays

Drop-in replacements for
[`ggplot2::geom_rect()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
and
[`ggplot2::geom_tile()`](https://ggplot2.tidyverse.org/reference/geom_tile.html)
that add a `pattern` aesthetic. Patterns are drawn on top of a filled
rectangle and clipped to its bounding box.

## Usage

``` r
geom_rect_pattern(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  ...,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)

geom_tile_pattern(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  ...,
  width = NULL,
  height = NULL,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)
```

## Arguments

- mapping:

  Aesthetic mappings created by
  [`ggplot2::aes()`](https://ggplot2.tidyverse.org/reference/aes.html).

- data:

  Data frame.

- stat:

  Statistical transformation. Default `"identity"`.

- position:

  Position adjustment. Default `"identity"`.

- ...:

  Other arguments passed to the layer.

- na.rm:

  If `FALSE` (default), missing values are removed with a warning.

- show.legend:

  Logical. Should this layer be included in the legend?

- inherit.aes:

  If `FALSE`, overrides the default aesthetics.

- width, height:

  Tile width and height in data units. If `NULL` (default), computed as
  the resolution of `x`/`y`.

## Value

A ggplot2 layer.

## Details

`geom_rect_pattern()` requires explicit corner aesthetics (`xmin`,
`xmax`, `ymin`, `ymax`). `geom_tile_pattern()` accepts center + size
aesthetics (`x`, `y` plus optional `width` and `height`; widths/heights
default to the resolution of the x/y values so tiles tessellate without
gaps).

## Pattern aesthetics

- `pattern`:

  Character name of the pattern. One of `"none"`, `"hatch"`,
  `"crosshatch"`, `"horizontal"`, `"vertical"`, `"dots"`, `"weave"`, or
  a custom pattern registered with
  [`register_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/register_pattern.md).

- `pattern_colour`:

  Colour of pattern lines/dots. Default `"black"`.

- `pattern_linewidth`:

  Line width for line-based patterns. Default `1`.

- `pattern_spacing`:

  Spacing between pattern elements as a fraction of the rectangle
  width/height (npc units). Default `0.08`.

- `pattern_angle`:

  Angle in degrees for hatch patterns. Default `45`.

- `pattern_size`:

  Dot diameter in mm for the `"dots"` pattern. Default `0.4`.

## Examples

``` r
library(ggplot2)

# Explicit corner coordinates
df <- data.frame(
  xmin = c(0, 1, 2), xmax = c(0.8, 1.8, 2.8),
  ymin = 0, ymax = c(1, 3, 2),
  pattern = c("hatch", "crosshatch", "dots")
)
ggplot(df, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
               fill = pattern, pattern = pattern)) +
  geom_rect_pattern() +
  scale_pattern_identity() +
  scale_fill_brewer(palette = "Pastel1") +
  theme_minimal()


# Heatmap-style tile chart
df2 <- expand.grid(x = 1:4, y = 1:4)
df2$pattern <- rep(c("hatch", "crosshatch", "dots", "none"), 4)
df2$fill_g  <- rep(letters[1:4], each = 4)
ggplot(df2, aes(x, y, fill = fill_g, pattern = pattern)) +
  geom_tile_pattern() +
  scale_pattern_identity() +
  scale_fill_brewer(palette = "Pastel2") +
  theme_minimal()
```
