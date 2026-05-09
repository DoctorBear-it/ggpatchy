# Register a custom pattern function

Register a custom pattern function

## Usage

``` r
register_pattern(name, fn)
```

## Arguments

- name:

  Character name for the pattern (used in `scale_pattern_*`).

- fn:

  A function with signature `fn(x, y, width, height, gp, params)` that
  returns a grid grob. `x/y/width/height` are in **npc** units (0–1
  relative to the parent viewport). `gp` is the base
  [`gpar()`](https://rdrr.io/r/grid/gpar.html) from the geom. `params`
  is a named list of extra parameters from the scale.
