# R/scale_pattern.R
# ------------------------------------------------------------
# Defines the `pattern` aesthetic and its scales.
# ------------------------------------------------------------

#' @importFrom ggplot2 discrete_scale
#' @importFrom scales manual_pal
NULL

# ---- Aesthetic registration ------------------------------------------------

# Tell ggplot2 that "pattern" is a valid aesthetic, default "none"
# This runs when the package loads.
.register_pattern_aesthetic <- function() {
  # ggplot2 doesn't have a formal "register aesthetic" API,
  # but we can add defaults via update_geom_defaults later.
  # The key thing is our Geom subclasses declare it in `aesthetics()`.
}

# ---- Scale constructors ----------------------------------------------------

#' Map discrete variable to fill patterns
#'
#' @param values Named or unnamed character vector of pattern names. Valid
#'   built-in patterns: `"none"`, `"hatch"`, `"crosshatch"`, `"horizontal"`,
#'   `"vertical"`, `"dots"`, `"weave"`. You can also supply names of custom
#'   patterns registered via [register_pattern()].
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(class, fill = class, pattern = class)) +
#'   geom_bar_pattern() +
#'   scale_pattern_manual(values = c(
#'     "suv"        = "crosshatch",
#'     "compact"    = "hatch",
#'     "midsize"    = "dots",
#'     "minivan"    = "horizontal",
#'     "pickup"     = "vertical",
#'     "subcompact" = "weave",
#'     "2seater"    = "none"
#'   ))
scale_pattern_manual <- function(values, ...) {
  ggplot2::discrete_scale(
    aesthetics = "pattern",
    palette    = scales::manual_pal(values),
    ...
  )
}

#' Automatically assign patterns to a discrete variable
#'
#' Cycles through the built-in pattern set.
#'
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @export
scale_pattern_discrete <- function(...) {
  builtin_patterns <- c("hatch", "crosshatch", "dots", "horizontal",
                        "vertical", "weave", "none")
  ggplot2::discrete_scale(
    aesthetics = "pattern",
    palette    = function(n) {
      if (n > length(builtin_patterns)) {
      rlang::warn(
          paste0("More levels than patterns (", n, " levels, ",
                 length(builtin_patterns), " patterns). ",
                 "Patterns will repeat. Consider `scale_pattern_manual()`.")
        )
      }
      builtin_patterns[((seq_len(n) - 1) %% length(builtin_patterns)) + 1]
    },
    ...
  )
}

# draw_key_pattern lives in R/aaa_draw_key.R so it loads before geom files.