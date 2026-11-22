#' Extract Psychometric Rasch Model Diagnostics and Equating Metrics
#'
#' Retrieves item-level Rasch parameters (`severity_b`, `se_b`, `infit`, `outfit`),
#' FAO global standard severities (`global_st`, `adj_global_st`), raw-score
#' latent parameters, and scale-level psychometric validity summaries (flat
#' Rasch reliability, correlation with the global reference standard, and first
#' residual PCA eigenvalue) from a dataset prepared with [prepare_fies()].
#'
#' @param data A `fies_tbl` object returned by [prepare_fies()].
#' @param year Optional integer vector filtering specific survey year(s).
#'
#' @returns An object of class `"fies_validation"` (a named list containing three
#'   tibbles: `summary`, `items`, and `raw_scores`, plus `models` metadata for
#'   plotting).
#' @export
#'
#' @examples
#' df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
#' val <- validate_rasch(df_demo)
#' val
validate_rasch <- function(data, year = NULL) {
  models <- attr(data, "rasch_models")
  if (is.null(models) || length(models) == 0L) {
    stop("'data' does not contain 'rasch_models' metadata. Pass an object created by prepare_fies().",
         call. = FALSE)
  }

  if (!is.null(year)) {
    yr_chr <- as.character(as.integer(year))
    models <- models[names(models) %in% yr_chr]
    if (length(models) == 0L) {
      stop("Requested 'year' not found in 'rasch_models'.", call. = FALSE)
    }
  }

  sum_rows <- lapply(models, function(m) {
    tibble::tibble(
      year = m$year,
      n_total = m$n_total,
      n_complete = m$n_complete,
      n_partial_na = m$n_partial_na,
      n_all_na = m$n_all_na,
      reliab_fl = m$reliab_fl,
      reliab = m$reliab,
      cor_global = m$cor_global,
      sd_b = stats::sd(m$b),
      thresh_mod_sev = m$thresh_mod_sev,
      thresh_sev = m$thresh_sev,
      max_infit = max(m$infit, na.rm = TRUE),
      eigenvalue_1 = m$eigenvalues[1L]
    )
  })

  item_rows <- lapply(models, function(m) {
    tibble::tibble(
      year = m$year,
      item_num = 1:8,
      enaho_var = paste0("p130_", 1:8),
      item_code = m$item_codes,
      severity_b = m$b,
      se_b = m$se_b,
      infit = m$infit,
      outfit = m$outfit,
      global_st = m$global_st,
      adj_global_st = m$adj_global_st,
      diff_from_global = m$b - m$adj_global_st
    )
  })

  rs_rows <- lapply(models, function(m) {
    tibble::tibble(
      year = m$year,
      raw_score = 0:8,
      severity_a = m$a,
      se_a = m$se_a,
      pr_mod_sev = m$pr_rs_mod_sev,
      pr_sev = m$pr_rs_sev
    )
  })

  out <- list(
    summary = do.call(rbind, sum_rows),
    items = do.call(rbind, item_rows),
    raw_scores = do.call(rbind, rs_rows),
    models = models
  )
  class(out) <- "fies_validation"
  out
}

#' @export
print.fies_validation <- function(x, ...) {
  cat("== FIESperu Psychometric Rasch Validation ==\n\n")
  cat("-- Scale Summary --\n")
  print(x$summary)
  cat("\n-- Item Severity & Fit Statistics --\n")
  print(x$items)
  invisible(x)
}
