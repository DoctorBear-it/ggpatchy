# R/ggpatchy-package.R
# ------------------------------------------------------------
# Package-level docs, onLoad hook, and small utilities.
# ------------------------------------------------------------

#' ggpatchy: Simple pattern overlays for ggplot2
#'
#' Provides `pattern` aesthetic support for ggplot2 geoms. Map discrete
#' variables to hatch, crosshatch, dot, and other overlay patterns rendered
#' cleanly via grid graphics.
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom rlang `%||%`
NULL

.onLoad <- function(libname, pkgname) {
  .register_builtin_patterns()
}

# Re-export %||% for use in user-facing examples and vignettes
# (already imported from rlang internally)

#' List available built-in pattern names
#'
#' @return Character vector of pattern names registered in ggpatchy.
#' @export
#' @examples
#' list_patterns()
list_patterns <- function() {
  ls(.pattern_registry)
}
