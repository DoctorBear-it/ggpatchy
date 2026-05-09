# SF polygon maps with pattern overlays

A drop-in replacement for
[`ggplot2::geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
that adds a `pattern` aesthetic. Patterns are clipped to the exact
polygon boundary using the same device-independent in-R geometry as
[`geom_polygon_pattern()`](https://doctorbear-it.github.io/ggpatchy/reference/geom_polygon_pattern.md).
Requires the `sf` package.

## Usage

``` r
geom_sf_pattern(
  mapping = ggplot2::aes(),
  data = NULL,
  stat = "sf",
  position = "identity",
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

  An sf data frame or compatible object.

- stat:

  Statistical transformation. Default `"sf"`.

- position:

  Position adjustment. Default `"identity"`.

- ...:

  Other arguments passed to the layer.

- na.rm:

  If `FALSE` (default), missing values are removed with a warning.

- show.legend:

  Logical or character. Should this layer be included in the legends?

- inherit.aes:

  If `FALSE`, overrides the default aesthetics.

## Value

A ggplot2 layer.

## Note

**GEOMETRYCOLLECTION**: rows with GEOMETRYCOLLECTION geometry produce a
warning and no pattern overlay; the base geometry is still rendered.

**Holes in polygons**: inner rings (holes / donuts) are silently ignored
— the pattern fills the entire outer boundary including hole areas. This
is a limitation of the in-R polygon clipping approach.

## Pattern aesthetics

In addition to all aesthetics accepted by
[`ggplot2::geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html),
this geom accepts:

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

  Spacing relative to the polygon bounding box (npc units). Default
  `0.08`.

- `pattern_angle`:

  Angle in degrees for hatch patterns. Default `45`.

- `pattern_size`:

  Dot size for the `"dots"` pattern. Default `0.35`.

## Geometry type support

POLYGON and MULTIPOLYGON features receive pattern overlays. POINT and
LINESTRING features render correctly via the base
[`ggplot2::geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
but without pattern overlays (silently skipped). Mixed geometry types in
the same layer are supported.

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE)) {
  library(ggplot2)
  library(sf)

  sq1 <- st_polygon(list(cbind(c(0,1,1,0,0), c(0,0,1,1,0))))
  sq2 <- st_polygon(list(cbind(c(1,2,2,1,1), c(0,0,1,1,0))))
  df  <- data.frame(
    region  = c("A", "B"),
    pattern = c("hatch", "dots"),
    geometry = st_sfc(sq1, sq2, crs = 4326)
  )
  sf::st_geometry(df) <- "geometry"

  ggplot(df) +
    geom_sf_pattern(aes(fill = region, pattern = pattern)) +
    scale_pattern_identity(guide = "legend") +
    scale_fill_brewer(palette = "Pastel1") +
    theme_minimal()
}
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
```
