# R/utils.R — internal utility helpers

.has_clip_path_support <- function() {
  getRversion() >= "4.1.0"
}
