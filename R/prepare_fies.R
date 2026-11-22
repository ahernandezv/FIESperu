#' Prepare Household-Level ENAHO Microdata and Calibrate Official FIES Scores
#'
#' Reads ENAHO Module 2082 (`enaho01-<year>-130`, Food Insecurity Experience Scale)
#' and Module 34 (`sumaria-<year>-12g`), merges optional household and member
#' modules (`"housing"`, `"demographics"`, `"education_health"`, `"programs"`),
#' fits the official INEI annual weighted Rasch model, equates severities to the
#' FAO global reference scale, and returns a clean household-level [tibble::tibble()]
#' ready for both [estimate_fies()] and regression modeling (e.g., [survey::svyglm()]).
#'
#' @inheritParams download_fies
#' @param local_dir Optional path to a local folder containing manually downloaded
#'   `.dta` or `.sav` ENAHO files (either flat, such as `"D:/Inseguridad_Alimentaria_2025"`,
#'   or organized in `ModuloXX` subfolders). When `NULL` (default), reads from
#'   `cache_dir`.
#' @param sample_data Optional pre-loaded list or data frame (such as [fies_sample])
#'   for fast offline demonstration and testing without reading external files.
#' @param download Logical; if `TRUE` (default) and `local_dir` is `NULL`,
#'   automatically calls [download_fies()] for any requested module missing from
#'   `cache_dir`.
#'
#' @returns A [tibble::tibble()] of class `"fies_tbl"` with one row per surveyed
#'   household, containing survey design keys (`conglome`, `estrato`, `wt_hh`,
#'   `wt_pop`), official INEI geographies (`area`, `department`, `region_inei`,
#'   `natural_region`), monetary poverty indicators, binary FIES items
#'   (`fies_worried`..`fies_whlday`), raw score (`fies_rs`), household probabilities
#'   of moderate-or-severe (`pr_mod_sev`) and severe (`pr_sev`) food insecurity,
#'   and any requested sociodemographic blocks. Annual Rasch model diagnostics are
#'   stored in `attr(x, "rasch_models")`.
#' @export
#'
#' @examples
#' # Offline demonstration using the bundled synthetic sample
#' df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
#' head(df_demo[, c("year", "area", "poverty", "fies_rs", "pr_mod_sev", "pr_sev")])
prepare_fies <- function(years = 2025,
                         include = "core",
                         cache_dir = fies_cache_dir(),
                         local_dir = NULL,
                         sample_data = NULL,
                         download = TRUE,
                         quiet = FALSE) {
  if (!is.null(sample_data)) {
    return(.prepare_from_sample(sample_data, quiet = quiet))
  }

  years <- sort(unique(as.integer(years)))
  if (length(years) == 0L || any(is.na(years)) || any(years < 2025L)) {
    stop("'years' must contain integer survey years >= 2025.", call. = FALSE)
  }

  blocks <- .resolve_include_blocks(include)

  if (is.null(local_dir)) {
    if (isTRUE(download)) {
      download_fies(years = years, include = blocks, cache_dir = cache_dir,
                    overwrite = FALSE, quiet = quiet)
    }
    root_dir <- cache_dir
  } else {
    root_dir <- local_dir
  }

  yr_tables <- vector("list", length(years))
  rasch_models <- vector("list", length(years))
  names(rasch_models) <- as.character(years)

  for (idx in seq_along(years)) {
    yr <- years[idx]
    if (!quiet) message(sprintf("[FIESperu] Preparing ENAHO %d microdata...", yr))

    f130 <- .find_module_file(root_dir, "2082", yr)
    f34  <- .find_module_file(root_dir, "34",   yr)

    df130 <- .read_enaho_file(f130)
    df34  <- .read_enaho_file(f34)

    hh_tbl <- .build_core_year(df130 = df130, df34 = df34, year = yr, quiet = quiet)
    rasch_models[[idx]] <- attr(hh_tbl, "rasch_diag")
    attr(hh_tbl, "rasch_diag") <- NULL

    if ("housing" %in% blocks) {
      df100 <- .read_enaho_file(.find_module_file(root_dir, "01", yr))
      h_df  <- .harmonize_housing(df100)
      hh_tbl <- .left_join_hh(hh_tbl, h_df)
    }

    if ("demographics" %in% blocks) {
      df200 <- .read_enaho_file(.find_module_file(root_dir, "02", yr))
      d_df  <- .harmonize_demographics(df200)
      hh_tbl <- .left_join_hh(hh_tbl, d_df)
    }

    if ("education_health" %in% blocks) {
      df300 <- .read_enaho_file(.find_module_file(root_dir, "03", yr))
      df400 <- .read_enaho_file(.find_module_file(root_dir, "04", yr))
      eh_df <- .harmonize_education_health(df300, df400)
      hh_tbl <- .left_join_hh(hh_tbl, eh_df)
    }

    if ("programs" %in% blocks) {
      df700 <- .read_enaho_file(.find_module_file(root_dir, "37", yr))
      pr_df <- .harmonize_programs(df700)
      hh_tbl <- .left_join_hh(hh_tbl, pr_df)
    }

    hh_tbl$hh_key <- NULL
    yr_tables[[idx]] <- hh_tbl
  }

  out <- tibble::as_tibble(do.call(rbind, yr_tables))
  attr(out, "rasch_models") <- rasch_models
  class(out) <- unique(c("fies_tbl", class(out)))
  out
}

# Preserve row order of x when left-joining household summaries by hh_key
.left_join_hh <- function(x, y) {
  m <- match(x$hh_key, y$hh_key)
  y_cols <- setdiff(names(y), "hh_key")
  for (cl in y_cols) {
    x[[cl]] <- y[[cl]][m]
  }
  x
}

.build_core_year <- function(df130, df34, year, quiet = FALSE) {
  df130$hh_key <- .hh_key_str(df130)
  df34$hh_key  <- .hh_key_str(df34)
  df34 <- df34[!duplicated(df34$hh_key), , drop = FALSE]

  m <- match(df130$hh_key, df34$hh_key)

  mieperho <- as.numeric(.strip_haven(df34$mieperho))[m]
  gashog2d <- if ("gashog2d" %in% names(df34)) as.numeric(.strip_haven(df34$gashog2d))[m] else rep(NA_real_, nrow(df130))
  inghog2d <- if ("inghog2d" %in% names(df34)) as.numeric(.strip_haven(df34$inghog2d))[m] else rep(NA_real_, nrow(df130))
  pob_raw  <- if ("pobreza"  %in% names(df34)) as.numeric(.strip_haven(df34$pobreza))[m]  else rep(NA_real_, nrow(df130))
  pobv_raw <- if ("pobrezav" %in% names(df34)) as.numeric(.strip_haven(df34$pobrezav))[m] else rep(NA_real_, nrow(df130))

  wt_hh  <- as.numeric(.strip_haven(df130$factor07))
  wt_pop <- as_stata_float(wt_hh * mieperho)

  rasch <- .fit_rasch_inei(df130, wt_hh = wt_hh, year = year, quiet = quiet)

  geo <- .derive_geography(
    ubigeo  = df130$ubigeo,
    dominio = df130$dominio,
    estrato = df130$estrato
  )

  poverty_3cat <- ifelse(
    is.na(pob_raw), NA_character_,
    ifelse(pob_raw == 1, "Extreme Poor",
    ifelse(pob_raw == 2, "Non-Extreme Poor",
    ifelse(pob_raw == 3, "Non-Poor", NA_character_)))
  )
  poverty_status <- ifelse(
    is.na(pob_raw), NA_character_,
    ifelse(pob_raw %in% c(1, 2), "Poor", "Non-Poor")
  )
  vuln_4cat <- ifelse(
    is.na(pobv_raw), NA_character_,
    ifelse(pobv_raw == 1, "Extreme Poor",
    ifelse(pobv_raw == 2, "Non-Extreme Poor",
    ifelse(pobv_raw == 3, "Vulnerable Non-Poor",
    ifelse(pobv_raw == 4, "Non-Vulnerable", NA_character_))))
  )

  exp_pc_month <- ifelse(!is.na(mieperho) & mieperho > 0, gashog2d / (12 * mieperho), NA_real_)
  inc_pc_month <- ifelse(!is.na(mieperho) & mieperho > 0, inghog2d / (12 * mieperho), NA_real_)

  fmat <- rasch$fies_mat

  core <- data.frame(
    hh_key       = df130$hh_key,
    year         = as.integer(year),
    conglome     = as.character(.strip_haven(df130$conglome)),
    vivienda     = as.character(.strip_haven(df130$vivienda)),
    hogar        = as.character(.strip_haven(df130$hogar)),
    ubigeo       = sprintf("%06s", trimws(as.character(.strip_haven(df130$ubigeo)))),
    dominio      = as.integer(.strip_haven(df130$dominio)),
    estrato      = as.integer(.strip_haven(df130$estrato)),
    wt_hh        = wt_hh,
    wt_pop       = wt_pop,
    hh_size      = as.integer(mieperho),
    area         = geo$area,
    natural_region = geo$natural_region,
    domain_name  = geo$domain_name,
    department   = geo$department,
    region_inei  = geo$region_inei,
    poverty      = factor(poverty_status, levels = c("Poor", "Non-Poor")),
    poverty_3cat = factor(poverty_3cat, levels = c("Extreme Poor", "Non-Extreme Poor", "Non-Poor")),
    vulnerability = factor(vuln_4cat, levels = c("Extreme Poor", "Non-Extreme Poor",
                                                 "Vulnerable Non-Poor", "Non-Vulnerable")),
    exp_pc_month = exp_pc_month,
    inc_pc_month = inc_pc_month,
    fies_worried = as.integer(fmat[, 1L]),
    fies_healthy = as.integer(fmat[, 2L]),
    fies_fewfood = as.integer(fmat[, 3L]),
    fies_skipped = as.integer(fmat[, 4L]),
    fies_ateless = as.integer(fmat[, 5L]),
    fies_runout  = as.integer(fmat[, 6L]),
    fies_hungry  = as.integer(fmat[, 7L]),
    fies_whlday  = as.integer(fmat[, 8L]),
    fies_rs      = rasch$rs,
    pr_mod_sev   = rasch$pr_mod_sev,
    pr_sev       = rasch$pr_sev,
    stringsAsFactors = FALSE
  )
  core$ubigeo <- gsub(" ", "0", core$ubigeo)
  attr(core, "rasch_diag") <- rasch$diagnostics
  core
}

.prepare_from_sample <- function(sample_data, quiet = FALSE) {
  df <- as.data.frame(sample_data)
  names(df) <- .clean_enaho_names(names(df))
  yrs <- sort(unique(as.integer(if ("year" %in% names(df)) df$year else if ("anio" %in% names(df)) df$anio else 2025L)))

  yr_tables <- vector("list", length(yrs))
  rasch_models <- vector("list", length(yrs))
  names(rasch_models) <- as.character(yrs)

  yr_col <- if ("year" %in% names(df)) df$year else if ("anio" %in% names(df)) df$anio else rep(2025L, nrow(df))

  for (idx in seq_along(yrs)) {
    yr <- yrs[idx]
    sub <- df[yr_col == yr, , drop = FALSE]
    hh_tbl <- .build_core_year(df130 = sub, df34 = sub, year = yr, quiet = quiet)
    rasch_models[[idx]] <- attr(hh_tbl, "rasch_diag")
    attr(hh_tbl, "rasch_diag") <- NULL

    extra_cols <- setdiff(names(sub), c(names(hh_tbl), "anio", paste0("p130_", 1:8),
                                        "factor07", "mieperho", "pobreza", "pobrezav",
                                        "gashog2d", "inghog2d"))
    for (cl in extra_cols) {
      hh_tbl[[cl]] <- sub[[cl]]
    }
    hh_tbl$hh_key <- NULL
    yr_tables[[idx]] <- hh_tbl
  }

  out <- tibble::as_tibble(do.call(rbind, yr_tables))
  attr(out, "rasch_models") <- rasch_models
  class(out) <- unique(c("fies_tbl", class(out)))
  out
}
