# Resolve module codes required for requested 'include' blocks
.resolve_include_blocks <- function(include) {
  valid <- c("core", "housing", "demographics", "education_health", "programs", "all")
  if (is.null(include) || length(include) == 0L) {
    include <- "core"
  }
  include <- unique(tolower(trimws(as.character(include))))
  bad <- setdiff(include, valid)
  if (length(bad) > 0L) {
    stop("Invalid 'include' value(s): ", paste(bad, collapse = ", "),
         ". Valid options are: ", paste(valid, collapse = ", "), ".",
         call. = FALSE)
  }
  if ("all" %in% include) {
    include <- c("core", "housing", "demographics", "education_health", "programs")
  } else {
    include <- unique(c("core", include))
  }
  include
}

.modules_for_blocks <- function(blocks) {
  tbl <- fies_modules()
  unique(tbl$inei_module[tbl$block %in% blocks])
}

# Resolve INEI srienaho annual survey code (built-in catalog + dynamic fallback for 2026+)
.resolve_srienaho_code <- function(year) {
  yr_chr <- as.character(as.integer(year))
  if (yr_chr %in% names(.srienaho_annual_codes)) {
    return(unname(.srienaho_annual_codes[[yr_chr]]))
  }

  # Dynamic lookup on INEI Microdatos portal for future annual releases (e.g. 2026+)
  if (requireNamespace("curl", quietly = TRUE)) {
    u <- "https://proyectos.inei.gob.pe/microdatos/cambiaPeriodo.asp"
    body <- paste0(
      "bandera=1&_cmbEncuesta=",
      "Condiciones%20de%20Vida%20y%20Pobreza%20-%20ENAHO",
      "&_cmbAnno=", yr_chr,
      "&_cmbTrimestre=55"
    )
    res_html <- tryCatch({
      h <- curl::new_handle()
      curl::handle_setheaders(h, "Content-Type" = "application/x-www-form-urlencoded")
      curl::handle_setopt(h, postfields = body, ssl_verifypeer = FALSE)
      raw_res <- curl::curl_fetch_memory(u, handle = h)
      iconv(rawToChar(raw_res$content), from = "latin1", to = "UTF-8", sub = "")
    }, error = function(e) "")

    m <- regmatches(res_html, regexpr("srienaho/descarga/STATA/[0-9]+-Modulo2082\\.zip",
                                      res_html, ignore.case = TRUE))
    if (length(m) == 1L && nzchar(m)) {
      code <- sub(".*STATA/([0-9]+)-Modulo.*", "\\1", m)
      return(code)
    }
  }

  stop("Could not resolve an official annual INEI 'srienaho' code for year ", yr_chr,
       ". The annual ENAHO microdata for ", yr_chr, " may not be published yet.",
       call. = FALSE)
}

#' Download and Cache INEI ENAHO Modules for FIES Estimation
#'
#' Downloads the official Stata (`.dta`) microdata archives from the INEI
#' `srienaho` repository for the requested annual survey years (2025 onwards)
#' and module blocks, storing extracted files in a persistent local cache.
#'
#' @param years Integer vector of annual survey years (`>= 2025`). Defaults to `2025`.
#' @param include Character vector specifying which module blocks to download:
#'   `"core"` (default: Module 2082 FIES + Module 34 Sumaria), `"housing"`
#'   (Module 01), `"demographics"` (Module 02), `"education_health"`
#'   (Modules 03 and 04), `"programs"` (Module 37), or `"all"`.
#' @param cache_dir Character path to the local cache directory. Defaults to
#'   [fies_cache_dir()].
#' @param overwrite Logical; if `TRUE`, re-downloads modules even if already
#'   present in `cache_dir`. Defaults to `FALSE`.
#' @param quiet Logical; if `TRUE`, suppresses progress messages. Defaults to `FALSE`.
#'
#' @returns Invisibly returns a [tibble::tibble()] with the year, module code,
#'   cache status, and local directory path of each requested module.
#' @export
#'
#' @examples
#' \donttest{
#' # Download core 2025 FIES + Sumaria modules into a temporary cache
#' download_fies(years = 2025, include = "core", cache_dir = tempdir())
#' }
download_fies <- function(years = 2025,
                          include = "core",
                          cache_dir = fies_cache_dir(),
                          overwrite = FALSE,
                          quiet = FALSE) {
  years <- sort(unique(as.integer(years)))
  if (length(years) == 0L || any(is.na(years)) || any(years < 2025L)) {
    stop("'years' must contain integer survey years >= 2025.", call. = FALSE)
  }

  blocks <- .resolve_include_blocks(include)
  mod_codes <- .modules_for_blocks(blocks)

  old_timeout <- getOption("timeout")
  options(timeout = max(600, old_timeout))
  on.exit(options(timeout = old_timeout), add = TRUE)

  base_url <- "https://proyectos.inei.gob.pe/iinei/srienaho/descarga/STATA/"
  records <- list()
  idx <- 0L

  for (yr in years) {
    sri_code <- .resolve_srienaho_code(yr)
    yr_dir <- file.path(cache_dir, as.character(yr))
    dir.create(yr_dir, recursive = TRUE, showWarnings = FALSE)

    for (mc in mod_codes) {
      idx <- idx + 1L
      mod_dir <- file.path(yr_dir, paste0("Modulo", mc))
      has_files <- dir.exists(mod_dir) &&
        length(list.files(mod_dir, pattern = "\\.(dta|sav)$", ignore.case = TRUE)) > 0L

      if (has_files && !isTRUE(overwrite)) {
        if (!quiet) {
          message(sprintf("[FIESperu] Year %d - Modulo %s: using cached files.", yr, mc))
        }
        records[[idx]] <- tibble::tibble(
          year = yr, inei_module = mc, status = "cached", path = mod_dir
        )
        next
      }

      dir.create(mod_dir, recursive = TRUE, showWarnings = FALSE)
      zip_url <- paste0(base_url, sri_code, "-Modulo", mc, ".zip")
      tmp_zip <- tempfile(pattern = paste0("enaho_", yr, "_", mc, "_"), fileext = ".zip")

      if (!quiet) {
        message(sprintf("[FIESperu] Downloading Year %d - Modulo %s (%s)...",
                        yr, mc, basename(zip_url)))
      }

      dl_res <- tryCatch(
        suppressWarnings(utils::download.file(url = zip_url, destfile = tmp_zip,
                                              mode = "wb", quiet = TRUE)),
        error = function(e) 1L
      )

      if (!identical(dl_res, 0L) || !file.exists(tmp_zip) || file.info(tmp_zip)$size < 100) {
        unlink(tmp_zip)
        stop("Failed to download ", zip_url,
             ". Check your internet connection or INEI server availability.",
             call. = FALSE)
      }

      uz <- suppressWarnings(
        try(utils::unzip(tmp_zip, exdir = mod_dir, junkpaths = TRUE), silent = TRUE)
      )
      if (inherits(uz, "try-error")) {
        li <- utils::unzip(tmp_zip, list = TRUE)
        for (k in seq_len(nrow(li))) {
          if (grepl("\\.(dta|sav)$", li$Name[k], ignore.case = TRUE)) {
            suppressWarnings(
              try(utils::unzip(tmp_zip, files = li$Name[k],
                               exdir = mod_dir, junkpaths = TRUE), silent = TRUE)
            )
          }
        }
      }
      unlink(tmp_zip)

      records[[idx]] <- tibble::tibble(
        year = yr, inei_module = mc, status = "downloaded", path = mod_dir
      )
    }
  }

  invisible(do.call(rbind, records))
}
