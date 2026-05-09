# Automatically assign patterns to a discrete variable

Cycles through the built-in pattern set in a fixed order (`hatch`,
`crosshatch`, `dots`, `horizontal`, `vertical`, `weave`, `none`),
assigning each level the next pattern in the cycle.

## Usage

``` r
scale_pattern_discrete(...)
```

## Arguments

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Details

Note: assignment is **positional against factor levels**, not by name.
If your variable's values *are* pattern names (e.g. `"hatch"`, `"dots"`)
and you want each level rendered as its own name, use
[`scale_pattern_identity()`](https://doctorbear-it.github.io/ggpatchy/reference/scale_pattern_identity.md)
instead.

## Examples

``` r
library(ggplot2)
df <- data.frame(g = letters[1:4], v = c(3, 5, 2, 4))
ggplot(df, aes(g, v, fill = g, pattern = g)) +
  geom_col_pattern() +
  scale_pattern_discrete()
```
