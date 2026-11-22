# Core combined sampling + Rasch measurement error estimator (official INEI moe)
.moe_from_design <- function(diseno, df_valid_wt, prob_vec, rs_vec, domain_vec,
                             conf_level = 0.95, sd_mult = 1) {
  valid_dom <- domain_vec & !is.na(prob_vec) & !is.na(rs_vec)
  n_dom <- sum(valid_dom, na.rm = TRUE)

  if (n_dom == 0L) {
    return(list(
      estimate = NA_real_, lower = NA_real_, upper = NA_real_,
      cv = NA_real_, moe = NA_real_, se_total = NA_real_,
      se_s = NA_real_, se_m = NA_real_, n_unweighted = 0L
    ))
  }

  # Attach working column onto design$variables for domain subset + svymean
  diseno$variables$.prob_tmp <- prob_vec

  diseno_dom <- diseno[valid_dom, ]
  media_svy <- survey::svymean(~.prob_tmp, design = diseno_dom, na.rm = TRUE)

  est  <- as.numeric(stats::coef(media_svy))
  se_s <- as.numeric(survey::SE(media_svy)) * sd_mult

  p_sub <- prob_vec[valid_dom]
  r_sub <- rs_vec[valid_dom]
  w_sub <- df_valid_wt$wt_pop[valid_dom]

  p_rs <- tapply(p_sub, r_sub, mean)
  n_rs <- tapply(p_sub, r_sub, length)
  w_rs <- tapply(w_sub, r_sub, sum)

  w_share <- w_rs / sum(w_rs, na.rm = TRUE)
  var_m <- sum((p_rs * (1 - p_rs) / n_rs) * (w_share^2), na.rm = TRUE)
  se_m <- sqrt(var_m)

  se_total <- sqrt(se_s^2 + se_m^2)
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  moe_val <- se_total * z

  lower <- est - moe_val
  upper <- est + moe_val
  cv <- if (is.na(est) || est == 0) NA_real_ else se_total / est

  list(
    estimate = est,
    lower = lower,
    upper = upper,
    cv = cv,
    moe = moe_val,
    se_total = se_total,
    se_s = se_s,
    se_m = se_m,
    n_unweighted = as.integer(n_dom)
  )
}

#' Estimate Official FIES Food Insecurity Prevalences and Combined Margins of Error
#'
#' Computes population prevalence estimates, confidence intervals, coefficients
#' of variation, and total standard errors combining complex-survey Taylor
#' linearization (`se_s`, accounting for stratification and primary sampling
#' units) with Rasch latent measurement error (`se_m`), following the official
#' INEI / FAO methodology.
#'
#' @param data A household-level data frame or `fies_tbl` produced by
#'   [prepare_fies()].
#' @param by Disaggregation specification:
#'   * `NULL` (default): National prevalence by survey year.
#'   * `"official"`: Generates in one call National, Area (`Urban`/`Rural`),
#'     Natural Region (`Coast`/`Highlands`/`Jungle`), all 24 Departments + Callao,
#'     and the official 26-domain regional breakdown (`region_inei`, separating
#'     `Lima Metropolitana` and `Lima Region`).
#'   * A character vector of one or more column names in `data` (e.g.,
#'     `c("area", "poverty")` or `"has_child_u5"`).
#' @param indicator Character string indicating which FIES threshold(s) to
#'   estimate: `"both"` (default), `"mod_sev"` (Moderate or Severe), or `"sev"`
#'   (Severe).
#' @param conf_level Confidence level for margins of error and intervals.
#'   Defaults to `0.95`.
#' @param combine_by Logical; when `by` is a vector of 2 or more column names,
#'   if `TRUE`, also estimates the Cartesian interaction of those variables
#'   (e.g., `area x poverty`). Ignored when `by` is `NULL` or `"official"`.
#' @param percent Logical; if `TRUE` (default), scales `estimate`, `lower`,
#'   `upper`, `moe`, `se_total`, `se_s`, `se_m`, and `cv` to percentages
#'   (`0`--`100`). Set to `FALSE` for proportions (`0`--`1`).
#'
#' @returns A [tibble::tibble()] with columns `year`, `group`, `category`,
#'   `indicator`, `estimate`, `lower`, `upper`, `moe`, `se_total`, `se_s`,
#'   `se_m`, `cv`, and `n_unweighted`.
#' @export
#'
#' @examples
#' df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
#' estimate_fies(df_demo, by = c("area", "poverty"))
estimate_fies <- function(data,
                          by = NULL,
                          indicator = c("both", "mod_sev", "sev"),
                          conf_level = 0.95,
                          combine_by = FALSE,
                          percent = TRUE) {
  indicator <- match.arg(indicator)
  req_cols <- c("year", "conglome", "estrato", "wt_pop", "fies_rs", "pr_mod_sev", "pr_sev")
  miss <- setdiff(req_cols, names(data))
  if (length(miss) > 0L) {
    stop("'data' is missing required columns from prepare_fies(): ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L || conf_level <= 0 || conf_level >= 1) {
    stop("'conf_level' must be a single number strictly between 0 and 1.", call. = FALSE)
  }

  # Save and restore global survey.lonely.psu option cleanly (CRAN policy)
  old_lonely <- getOption("survey.lonely.psu")
  options(survey.lonely.psu = "adjust")
  on.exit(options(survey.lonely.psu = old_lonely), add = TRUE)

  ind_specs <- list()
  if (indicator %in% c("both", "mod_sev")) {
    ind_specs[["Moderate or Severe"]] <- "pr_mod_sev"
  }
  if (indicator %in% c("both", "sev")) {
    ind_specs[["Severe"]] <- "pr_sev"
  }

  is_official_preset <- identical(by, "official")
  if (!is.null(by) && !is_official_preset) {
    by <- unique(as.character(by))
    miss_by <- setdiff(by, names(data))
    if (length(miss_by) > 0L) {
      stop("Grouping variable(s) not found in 'data': ",
           paste(miss_by, collapse = ", "), call. = FALSE)
    }
  }

  yrs <- sort(unique(data$year))
  all_rows <- list()
  r_idx <- 0L
  scale_k <- if (isTRUE(percent)) 100 else 1

  for (yr in yrs) {
    df_yr <- as.data.frame(data[data$year == yr, , drop = FALSE])
    df_yr <- df_yr[!is.na(df_yr$wt_pop) & df_yr$wt_pop > 0, , drop = FALSE]

    psu_vec <- ifelse(is.na(df_yr$conglome), "1", as.character(df_yr$conglome))
    str_vec <- ifelse(is.na(df_yr$estrato),  1L,  as.integer(df_yr$estrato))
    df_yr$.psu <- psu_vec
    df_yr$.strata <- str_vec
    df_yr$.prob_tmp <- 0
    df_yr$.valid_tmp <- TRUE

    if (length(unique(psu_vec)) <= 1L && length(unique(str_vec)) <= 1L) {
      diseno <- suppressWarnings(
        survey::svydesign(id = ~1, weights = ~wt_pop, data = df_yr)
      )
    } else {
      diseno <- suppressWarnings(
        survey::svydesign(id = ~.psu, strata = ~.strata, weights = ~wt_pop,
                          nest = TRUE, data = df_yr)
      )
    }

    # Build list of (group_name, category_label, logical_domain_vector)
    dom_specs <- list(
      list(group = "National", category = "National", domain = rep(TRUE, nrow(df_yr)))
    )

    if (is_official_preset) {
      preset_vars <- intersect(c("area", "natural_region", "department", "region_inei"), names(df_yr))
      for (gv in preset_vars) {
        dom_specs <- c(dom_specs, .expand_group_domains(df_yr, gv))
      }
    } else if (!is.null(by)) {
      for (gv in by) {
        dom_specs <- c(dom_specs, .expand_group_domains(df_yr, gv))
      }
      if (isTRUE(combine_by) && length(by) >= 2L) {
        dom_specs <- c(dom_specs, .expand_interaction_domains(df_yr, by))
      }
    }

    for (ind_label in names(ind_specs)) {
      p_col <- ind_specs[[ind_label]]
      prob_v <- as.numeric(df_yr[[p_col]])
      rs_v   <- as.numeric(df_yr$fies_rs)

      for (ds in dom_specs) {
        res <- .moe_from_design(
          diseno = diseno,
          df_valid_wt = df_yr,
          prob_vec = prob_v,
          rs_vec = rs_v,
          domain_vec = ds$domain,
          conf_level = conf_level
        )
        r_idx <- r_idx + 1L
        all_rows[[r_idx]] <- tibble::tibble(
          year = as.integer(yr),
          group = ds$group,
          category = ds$category,
          indicator = ind_label,
          estimate = res$estimate * scale_k,
          lower = res$lower * scale_k,
          upper = res$upper * scale_k,
          moe = res$moe * scale_k,
          se_total = res$se_total * scale_k,
          se_s = res$se_s * scale_k,
          se_m = res$se_m * scale_k,
          cv = res$cv * scale_k,
          n_unweighted = res$n_unweighted
        )
      }
    }
  }

  do.call(rbind, all_rows)
}

.expand_group_domains <- function(df, col_name) {
  vals <- df[[col_name]]
  if (is.factor(vals)) {
    levs <- levels(vals)
    levs <- levs[levs %in% as.character(vals[!is.na(vals)])]
  } else if (haven::is.labelled(vals)) {
    vals_chr <- as.character(haven::as_factor(vals))
    vals <- vals_chr
    levs <- sort(unique(vals[!is.na(vals)]))
  } else {
    vals <- as.character(vals)
    levs <- sort(unique(vals[!is.na(vals)]))
  }

  lapply(levs, function(lv) {
    list(
      group = col_name,
      category = as.character(lv),
      domain = !is.na(vals) & as.character(vals) == as.character(lv)
    )
  })
}

.expand_interaction_domains <- function(df, cols) {
  char_list <- lapply(cols, function(cl) {
    v <- df[[cl]]
    if (haven::is.labelled(v)) as.character(haven::as_factor(v)) else as.character(v)
  })
  ok <- Reduce(`&`, lapply(char_list, function(v) !is.na(v)))
  combo_vec <- do.call(paste, c(char_list, sep = " x "))
  combo_vec[!ok] <- NA_character_

  levs <- unique(combo_vec[ok])
  levs <- sort(levs)
  grp_label <- paste(cols, collapse = " x ")

  lapply(levs, function(lv) {
    list(
      group = grp_label,
      category = lv,
      domain = !is.na(combo_vec) & combo_vec == lv
    )
  })
}
