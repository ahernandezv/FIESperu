#' Get Default Cache Directory for FIESperu
#'
#' Returns the platform-appropriate persistent user cache directory used by
#' `FIESperu` to store downloaded INEI ENAHO microdata files, following CRAN
#' policies via [tools::R_user_dir()].
#'
#' @returns A character string with the normalized path to the cache directory.
#' @export
#'
#' @examples
#' fies_cache_dir()
fies_cache_dir <- function() {
  normalizePath(tools::R_user_dir("FIESperu", which = "cache"),
                winslash = "/", mustWork = FALSE)
}

#' Clear FIESperu Local Microdata Cache
#'
#' Removes cached ENAHO microdata directories downloaded by [download_fies()].
#'
#' @param years Optional integer vector of survey years to remove (e.g., `2025`).
#'   If `NULL` (the default), removes the entire cache directory.
#' @param cache_dir Character string indicating the cache root directory.
#'   Defaults to [fies_cache_dir()].
#' @param quiet Logical; if `FALSE` (default), prints a confirmation message.
#'
#' @returns Invisibly returns `TRUE` if files were removed or `FALSE` if nothing
#'   existed to remove.
#' @export
#'
#' @examples
#' tmp_cache <- file.path(tempdir(), "fies_cache_demo")
#' clear_fies_cache(cache_dir = tmp_cache, quiet = TRUE)
clear_fies_cache <- function(years = NULL,
                             cache_dir = fies_cache_dir(),
                             quiet = FALSE) {
  if (!dir.exists(cache_dir)) {
    if (!quiet) message("Cache directory does not exist: ", cache_dir)
    return(invisible(FALSE))
  }

  targets <- if (is.null(years)) {
    cache_dir
  } else {
    file.path(cache_dir, as.character(years))
  }

  existing <- targets[dir.exists(targets)]
  if (length(existing) == 0L) {
    if (!quiet) message("No cached files found for the specified selection.")
    return(invisible(FALSE))
  }

  unlink(existing, recursive = TRUE, force = TRUE)
  if (!quiet) {
    message("Cleared FIESperu cache: ", paste(existing, collapse = ", "))
  }
  invisible(TRUE)
}
