# Fit official INEI weighted Rasch model and equate to FAO global standard
.fit_rasch_inei <- function(fies_raw_df, wt_hh, year, quiet = FALSE) {
  item_cols <- paste0("p130_", 1:8)
  fies_codes <- c("WORRIED", "HEALTHY", "FEWFOOD", "SKIPPED",
                  "ATELESS", "RUNOUT", "HUNGRY", "WHLDAY")

  fies_mat <- as.matrix(vapply(item_cols, function(col) {
    v <- as.numeric(.strip_haven(fies_raw_df[[col]]))
    v[v == 2] <- 0
    v[v > 1 | v < 0] <- NA_real_
    v
  }, numeric(nrow(fies_raw_df))))
  colnames(fies_mat) <- fies_codes

  na_counts <- rowSums(is.na(fies_mat))
  n_complete <- sum(na_counts == 0L)
  n_all_na   <- sum(na_counts == 8L)
  n_partial  <- sum(na_counts > 0L & na_counts < 8L)

  wt_num <- as.numeric(.strip_haven(wt_hh))

  # Fit CML weighted Rasch model via RM.weights::RM.w without writing files to disk
  if (quiet) {
    tmp_out <- utils::capture.output(
      res <- suppressWarnings(
        RM.weights::RM.w(
          .data = fies_mat,
          .w = wt_num,
          write.file = FALSE,
          country = paste0("Peru ENAHO ", year, " - Enero - Diciembre")
        )
      )
    )
    rm(tmp_out)
  } else {
    utils::capture.output(
      res <- suppressWarnings(
        RM.weights::RM.w(
          .data = fies_mat,
          .w = wt_num,
          write.file = FALSE,
          country = paste0("Peru ENAHO ", year, " - Enero - Diciembre")
        )
      )
    )
  }

  # Official INEI linear rescaling of FAO FIES global reference scale onto Peru's SD
  adj_fies <- .fies_global_st / stats::sd(.fies_global_st) * stats::sd(res$b)
  thresh_mod_sev <- unname(adj_fies[5L]) # ATELESS
  thresh_sev     <- unname(adj_fies[8L]) # WHLDAY

  pr_rs_mod_sev <- 1 - stats::pnorm(thresh_mod_sev, mean = res$a, sd = res$se.a)
  pr_rs_sev     <- 1 - stats::pnorm(thresh_sev,     mean = res$a, sd = res$se.a)

  # Official INEI raw score assignment (complete 8-item responses receive RS in 0..8)
  rs <- rowSums(fies_mat, na.rm = FALSE)
  pr_mod_sev <- ifelse(is.na(rs), NA_real_, pr_rs_mod_sev[rs + 1L])
  pr_sev     <- ifelse(is.na(rs), NA_real_, pr_rs_sev[rs + 1L])

  # Residual PCA eigenvalues for unidimensionality scree diagnostic
  eig_vals <- tryCatch({
    if (!is.null(res$mat.res) && nrow(res$mat.res) > 8L) {
      pca <- stats::prcomp(res$mat.res)
      pca$sdev^2
    } else {
      rep(NA_real_, 8L)
    }
  }, error = function(e) rep(NA_real_, 8L))

  diag_info <- list(
    year = as.integer(year),
    item_codes = fies_codes,
    b = as.numeric(res$b),
    se_b = as.numeric(res$se.b),
    infit = as.numeric(res$infit),
    se_infit = if (!is.null(res$se.infit)) as.numeric(res$se.infit) else rep(NA_real_, 8L),
    outfit = as.numeric(res$outfit),
    global_st = as.numeric(.fies_global_st),
    adj_global_st = as.numeric(adj_fies),
    a = as.numeric(res$a),
    se_a = as.numeric(res$se.a),
    pr_rs_mod_sev = as.numeric(pr_rs_mod_sev),
    pr_rs_sev = as.numeric(pr_rs_sev),
    thresh_mod_sev = thresh_mod_sev,
    thresh_sev = thresh_sev,
    reliab = if (!is.null(res$reliab)) as.numeric(res$reliab) else NA_real_,
    reliab_fl = if (!is.null(res$reliab.fl)) as.numeric(res$reliab.fl) else NA_real_,
    cor_global = stats::cor(adj_fies, res$b),
    eigenvalues = eig_vals,
    q_infit = res$q.infit,
    q_infit_theor = res$q.infit.theor,
    n_total = nrow(fies_mat),
    n_complete = n_complete,
    n_partial_na = n_partial,
    n_all_na = n_all_na
  )

  list(
    fies_mat = fies_mat,
    rs = as.integer(rs),
    pr_mod_sev = pr_mod_sev,
    pr_sev = pr_sev,
    diagnostics = diag_info
  )
}
