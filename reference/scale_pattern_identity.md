# Use a variable's values directly as pattern names

An identity scale for the `pattern` aesthetic: the data column's values
are interpreted directly as pattern names with no remapping. Use this
when the variable mapped to `pattern` already contains valid pattern
names (e.g. `"hatch"`, `"dots"`).

## Usage

``` r
scale_pattern_identity(..., guide = "legend")
```

## Arguments

- ...:

  Passed to
  [`ggplot2::scale_discrete_identity()`](https://ggplot2.tidyverse.org/reference/scale_identity.html).

- guide:

  Legend guide. Defaults to `"none"` because identity scales typically
  don't need a legend; pass `"legend"` to show one.

## Examples

``` r
library(ggplot2)
df <- data.frame(
  group = c("hatch", "dots", "crosshatch"),
  value = c(3, 5, 4)
)
ggplot(df, aes(group, value, fill = group, pattern = group)) +
  geom_col_pattern() +
  scale_pattern_identity()
```
