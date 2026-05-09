# Polygons with pattern overlays

A drop-in replacement for
[`ggplot2::geom_polygon()`](https://ggplot2.tidyverse.org/reference/geom_polygon.html)
that adds a `pattern` aesthetic. Patterns are correctly clipped to the
polygon boundary using device-independent in-R geometry: line patterns
via parametric segment-polygon intersection, dot patterns via
ray-casting point-in-polygon. No special R version or device support is
required.

## Usage

``` r
geom_polygon_pattern(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  rule = "evenodd",
  ...,
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

- rule:

  Fill rule for polygon winding: `"evenodd"` or `"winding"`.

- ...:

  Other arguments passed to the layer.

- na.rm:

  If `FALSE` (default), missing values are removed with a warning.

- show.legend:

  Logical. Should this layer be included in the legend?

- inherit.aes:

  If `FALSE`, overrides the default aesthetics.
