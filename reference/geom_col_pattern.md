# Bar and column charts with pattern overlays

These are drop-in replacements for
[`ggplot2::geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html)
and
[`ggplot2::geom_bar()`](https://ggplot2.tidyverse.org/reference/geom_bar.html)
that add support for a `pattern` aesthetic. Map `pattern` to a discrete
variable using
[`scale_pattern_manual()`](https://doctorbear-it.github.io/ggpatchy/reference/scale_pattern_manual.md)
or
[`scale_pattern_discrete()`](https://doctorbear-it.github.io/ggpatchy/reference/scale_pattern_discrete.md).

## Usage

``` r
geom_col_pattern(
  mapping = NULL,
  data = NULL,
  position = "stack",
  ...,
  width = NULL,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)

geom_bar_pattern(
  mapping = NULL,
  data = NULL,
  position = "stack",
  ...,
  width = NULL,
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

- position:

  Position adjustment. Default `"stack"`.

- ...:

  Other arguments passed to the layer.

- width:

  Bar width, as a proportion of the bin width.

- na.rm:

  If `FALSE` (default), missing values are removed with a warning.

- show.legend:

  Logical. Should this layer be included in the legend?

- inherit.aes:

  If `FALSE`, overrides the default aesthetics.

## Value

A ggplot2 layer.

## Pattern aesthetics

In addition to all aesthetics accepted by
[`ggplot2::geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html),
these geoms accept:

- `pattern`:

  Character name of the pattern. One of `"none"`, `"hatch"`,
  `"crosshatch"`, `"horizontal"`, `"vertical"`, `"dots"`, `"weave"`, or
  a custom pattern registered with
  [`register_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/register_pattern.md).
  Each base pattern (except `"none"`) also has `_dense` and `_sparse`
  variants (e.g. `"hatch_dense"`, `"dots_sparse"`) for pre-set tighter
  or looser spacing.

- `pattern_colour`:

  Colour of pattern lines/dots. Default `"black"`.

- `pattern_linewidth`:

  Line width for line-based patterns. Default `1`.

- `pattern_spacing`:

  Spacing between pattern elements in millimetres. Default `5`. Smaller
  values produce denser patterns; larger values produce sparser
  patterns. Named density variants (e.g. `"hatch_dense"`) bake in a
  pre-set spacing multiplier but still respect explicit
  `pattern_spacing` values.

- `pattern_angle`:

  Angle in degrees for hatch patterns. Default `45`.

- `pattern_size`:

  Dot radius in millimetres for the `"dots"` pattern. Default `0.5`.

## Examples

``` r
library(ggplot2)

# geom_bar_pattern uses stat="count" automatically
ggplot(mpg, aes(class, fill = class, pattern = class)) +
  geom_bar_pattern() +
  scale_pattern_discrete() +
  theme_minimal()


# geom_col_pattern needs x and y (pre-summarised data)
df <- data.frame(
  group = c("A", "B", "C"),
  value = c(3, 5, 4)
)
ggplot(df, aes(group, value, fill = group, pattern = group)) +
  geom_col_pattern() +
  scale_pattern_manual(values = c(A = "hatch", B = "dots", C = "crosshatch")) +
  scale_fill_brewer(palette = "Pastel1")
```
