## Submission

This is a new submission. ggpatchy provides a `pattern` aesthetic for
ggplot2 geoms, mapping discrete variables to hatch, crosshatch, dot, and
other overlay patterns rendered via grid graphics. Patterns are clipped to
the underlying shape and render cleanly at any resolution without raster
fallback.

## R CMD check results

0 errors | 0 warnings | 2 notes

* Note: "Non-standard file/directory found at top level: 'LICENSE.md'"

  `LICENSE.md` accompanies the standard `LICENSE` file as a courtesy to
  GitHub, which uses it to render the license badge on the repository
  page. It is otherwise inert and not used at install time. This pattern
  is widespread on CRAN.

* Note: "unable to verify current time"

  This note appears when the check host cannot reach the Network Time
  Protocol service used to confirm system clock accuracy. It does not
  reflect any package issue.

## Test environments

* Local: Windows 11 x64 (build 26200), R 4.4.3 ucrt (conda-forge gcc 13.4.0),
  Rtools44, via pixi

## Downstream dependencies

There are no downstream dependencies (this is a new package).
