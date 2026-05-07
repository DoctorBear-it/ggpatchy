# bootstrap.R
# Locks .libPaths() to the pixi environment only, preventing the user's
# system R library (e.g. AppData/Local/R/win-library) from bleeding in.
# Run via: pixi run bootstrap
# All other tasks depend_on this one.

conda_prefix <- Sys.getenv("CONDA_PREFIX")

if (nchar(conda_prefix) == 0) {
  stop("CONDA_PREFIX is not set. Are you inside a pixi environment?")
}

# Normalize separators up-front. chartr is more reliable than gsub here
# because we're doing a literal char-for-char swap, no regex involved.
to_forward <- function(p) chartr("\\", "/", p)

conda_prefix <- to_forward(conda_prefix)

pixi_lib <- to_forward(file.path(conda_prefix, "lib", "R", "library"))
rprofile <- to_forward(file.path(conda_prefix, "lib", "R", "etc", "Rprofile.site"))

if (!dir.exists(pixi_lib)) {
  stop("Pixi R library not found at: ", pixi_lib)
}

lock_line <- paste0('.libPaths(c("', pixi_lib, '"))')

# Read existing Rprofile.site if present.
# Strip any prior .libPaths line — we replace it.
# Also normalize any backslashes anywhere in the file: a previous version
# of this script could have written a line containing backslashes, which
# R's parser treats as escape sequences and refuses to load (e.g. \P in
# C:\Projects).
existing <- if (file.exists(rprofile)) readLines(rprofile, warn = FALSE) else character(0)
existing <- existing[!grepl("^\\s*\\.libPaths\\(", existing)]
existing <- vapply(existing, to_forward, character(1), USE.NAMES = FALSE)

writeLines(c(lock_line, existing), rprofile)

message("bootstrap: .libPaths locked to ", pixi_lib)
