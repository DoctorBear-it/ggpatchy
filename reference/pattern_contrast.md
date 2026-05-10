# Compute WCAG 2.1 contrast ratio between two colours

Returns the contrast ratio as defined by WCAG 2.1. Values range from 1
(no contrast) to 21 (black on white). The minimum for non-text graphical
elements at Level AA is 3.0:1.

## Usage

``` r
pattern_contrast(colour1, colour2)
```

## Arguments

- colour1, colour2:

  Character colour strings (any format accepted by
  [`grDevices::col2rgb()`](https://rdrr.io/r/grDevices/col2rgb.html)).

## Value

A numeric scalar: the contrast ratio (always \>= 1).

## Examples

``` r
pattern_contrast("black", "white")   # 21
#> [1] 21
pattern_contrast("black", "#4472C4") # typically around 5-6
#> [1] 4.449819
pattern_contrast("grey60", "white")  # typically around 3.5
#> [1] 2.849028
```
