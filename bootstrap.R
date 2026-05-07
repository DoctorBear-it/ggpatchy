# bootstrap.R
# Locks .libPaths() to the pixi environment only, preventing the user's
# system R library (e.g. AppData/Local/R/win-library) from bleeding in.
# Run via: pixi run bootstrap
# All other tasks depend_on this one.

conda_prefix <- Sys.getenv("CONDA_PREFIX")

if (nchar(conda_prefix) == 0) {
  stop("CONDA_PREFIX is not set. Are you inside a pixi environment?")
}

pixi_lib <- file.path(conda_prefix, "lib", "R", "library")
rprofile  <- file.path(conda_prefix, "lib", "R", "etc", "Rprofile.site")

if (!dir.exists(pixi_lib)) {
  stop("Pixi R library not found at: ", pixi_lib)
}

# Normalize to forward slashes so the path is safe inside an R string literal
pixi_lib_safe <- gsub("\\\\", "/", pixi_lib)

lock_line <- paste0('.libPaths(c("', pixi_lib_safe, '"))')

# Read existing Rprofile.site if present, strip any previous lock line
existing <- if (file.exists(rprofile)) readLines(rprofile, warn = FALSE) else character(0)
existing <- existing[!grepl("^\\.libPaths\\(", existing)]

writeLines(c(lock_line, existing), rprofile)

message("bootstrap: .libPaths locked to ", pixi_lib)