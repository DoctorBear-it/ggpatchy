# R/scale_pattern.R
# ------------------------------------------------------------
# Defines the `pattern` aesthetic and its scales.
# ------------------------------------------------------------

#' @importFrom ggplot2 discrete_scale scale_discrete_identity
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
#' Maps the levels of a discrete variable to specific pattern names. When
#' `values` is named, names are matched to the variable's levels (so the
#' order of `values` does not need to match the level order). When unnamed,
#' values are matched positionally to levels.
#'
#' @param values Named or unnamed character vector of pattern names. Built-in
#'   base patterns: `"none"`, `"hatch"`, `"crosshatch"`, `"horizontal"`,
#'   `"vertical"`, `"dots"`, `"weave"`. Each base pattern (except `"none"`)
#'   also has `_dense` and `_sparse` variants (e.g. `"hatch_dense"`,
#'   `"crosshatch_sparse"`) that use a pre-set tighter or looser spacing.
#'   Custom patterns registered via [register_pattern()] are also accepted.
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

#' Use a variable's values directly as pattern names
#'
#' An identity scale for the `pattern` aesthetic: the data column's values
#' are interpreted directly as pattern names with no remapping. Use this
#' when the variable mapped to `pattern` already contains valid pattern
#' names (e.g. `"hatch"`, `"dots"`).
#'
#' @param ... Passed to [ggplot2::scale_discrete_identity()].
#' @param guide Legend guide. Defaults to `"none"` because identity scales
#'   typically don't need a legend; pass `"legend"` to show one.
#' @export
#' @examples
#' library(ggplot2)
#' df <- data.frame(
#'   group = c("hatch", "dots", "crosshatch"),
#'   value = c(3, 5, 4)
#' )
#' ggplot(df, aes(group, value, fill = group, pattern = group)) +
#'   geom_col_pattern() +
#'   scale_pattern_identity()
scale_pattern_identity <- function(..., guide = "legend") {
  ggplot2::scale_discrete_identity(
    aesthetics = "pattern",
    guide      = guide,
    ...
  )
}

#' Automatically assign patterns to a discrete variable
#'
#' Cycles through the built-in pattern set in a fixed order
#' (`hatch`, `crosshatch`, `dots`, `horizontal`, `vertical`, `weave`, `none`),
#' assigning each level the next pattern in the cycle.
#'
#' Note: assignment is **positional against factor levels**, not by name.
#' If your variable's values *are* pattern names (e.g. `"hatch"`, `"dots"`)
#' and you want each level rendered as its own name, use
#' [scale_pattern_identity()] instead.
#'
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @export
#' @examples
#' library(ggplot2)
#' df <- data.frame(g = letters[1:4], v = c(3, 5, 2, 4))
#' ggplot(df, aes(g, v, fill = g, pattern = g)) +
#'   geom_col_pattern() +
#'   scale_pattern_discrete()
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