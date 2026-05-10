# Map discrete variable to fill patterns

Maps the levels of a discrete variable to specific pattern names. When
`values` is named, names are matched to the variable's levels (so the
order of `values` does not need to match the level order). When unnamed,
values are matched positionally to levels.

## Usage

``` r
scale_pattern_manual(values, ...)
```

## Arguments

- values:

  Named or unnamed character vector of pattern names. Built-in base
  patterns: `"none"`, `"hatch"`, `"crosshatch"`, `"horizontal"`,
  `"vertical"`, `"dots"`, `"weave"`. Each base pattern (except `"none"`)
  also has `_dense` and `_sparse` variants (e.g. `"hatch_dense"`,
  `"crosshatch_sparse"`) that use a pre-set tighter or looser spacing.
  Custom patterns registered via
  [`register_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/register_pattern.md)
  are also accepted.

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(class, fill = class, pattern = class)) +
  geom_bar_pattern() +
  scale_pattern_manual(values = c(
    "suv"        = "crosshatch",
    "compact"    = "hatch",
    "midsize"    = "dots",
    "minivan"    = "horizontal",
    "pickup"     = "vertical",
    "subcompact" = "weave",
    "2seater"    = "none"
  ))
```
