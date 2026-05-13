# Package index

## Geoms

Pattern-enabled geom layers, drop-in replacements for their ggplot2
counterparts.

- [`geom_col_pattern()`](https://ggpatchy.org/reference/geom_col_pattern.md)
  [`geom_bar_pattern()`](https://ggpatchy.org/reference/geom_col_pattern.md)
  : Bar and column charts with pattern overlays
- [`geom_rect_pattern()`](https://ggpatchy.org/reference/geom_rect_pattern.md)
  [`geom_tile_pattern()`](https://ggpatchy.org/reference/geom_rect_pattern.md)
  : Rectangle and tile charts with pattern overlays
- [`geom_polygon_pattern()`](https://ggpatchy.org/reference/geom_polygon_pattern.md)
  : Polygons with pattern overlays
- [`geom_ribbon_pattern()`](https://ggpatchy.org/reference/geom_ribbon_pattern.md)
  [`geom_area_pattern()`](https://ggpatchy.org/reference/geom_ribbon_pattern.md)
  : Ribbon and area charts with pattern overlays
- [`geom_density_pattern()`](https://ggpatchy.org/reference/geom_density_pattern.md)
  : Kernel density estimates with pattern overlays
- [`geom_violin_pattern()`](https://ggpatchy.org/reference/geom_violin_pattern.md)
  : Violin plots with pattern overlays
- [`geom_sf_pattern()`](https://ggpatchy.org/reference/geom_sf_pattern.md)
  : SF polygon maps with pattern overlays

## Scales

Map discrete variables to patterns.

- [`scale_pattern_manual()`](https://ggpatchy.org/reference/scale_pattern_manual.md)
  : Map discrete variable to fill patterns
- [`scale_pattern_discrete()`](https://ggpatchy.org/reference/scale_pattern_discrete.md)
  : Automatically assign patterns to a discrete variable
- [`scale_pattern_identity()`](https://ggpatchy.org/reference/scale_pattern_identity.md)
  : Use a variable's values directly as pattern names

## Custom patterns

Register your own pattern functions.

- [`register_pattern()`](https://ggpatchy.org/reference/register_pattern.md)
  : Register a custom pattern function
- [`list_patterns()`](https://ggpatchy.org/reference/list_patterns.md) :
  List available built-in pattern names

## Accessibility

Check and correct pattern-to-fill contrast.

- [`pattern_contrast()`](https://ggpatchy.org/reference/pattern_contrast.md)
  : Compute WCAG 2.1 contrast ratio between two colours
