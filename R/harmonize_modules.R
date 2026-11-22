# Locate module file (.dta or .sav) in either structured cache or flat local_dir
.find_module_file <- function(base_dir, inei_module, year) {
  yr_chr <- as.character(year)
  search_dirs <- unique(c(
    file.path(base_dir, yr_chr, paste0("Modulo", inei_module)),
    file.path(base_dir, paste0("Modulo", inei_module)),
    base_dir
  ))
  search_dirs <- search_dirs[dir.exists(search_dirs)]
  if (length(search_dirs) == 0L) {
    stop("Directory not found when searching for Modulo ", inei_module,
         " (year ", yr_chr, "): ", base_dir, call. = FALSE)
  }

  pat <- switch(
    as.character(inei_module),
    "2082" = paste0("130\\.(dta|sav)$"),
    "34"   = paste0("sumaria.*", yr_chr, ".*\\.(dta|sav)$"),
    "01"   = paste0("100\\.(dta|sav)$"),
    "02"   = paste0("200\\.(dta|sav)$"),
    "03"   = paste0("300\\.(dta|sav)$"),
    "04"   = paste0("400\\.(dta|sav)$"),
    "37"   = paste0("700\\.(dta|sav)$"),
    "\\.(dta|sav)$"
  )

  candidates <- character(0L)
  for (d in search_dirs) {
    fls <- list.files(d, pattern = pat, ignore.case = TRUE, full.names = TRUE)
    if (length(fls) > 0L) {
      candidates <- c(candidates, fls)
      break
    }
  }

  if (length(candidates) == 0L) {
    stop("Could not find microdata file for Modulo ", inei_module,
         " (year ", yr_chr, ") inside: ", paste(search_dirs, collapse = ", "),
         call. = FALSE)
  }

  # Prefer .dta over .sav, and for Sumaria prefer '-12g' (official INEI FIES routine)
  dta_cand <- candidates[grepl("\\.dta$", candidates, ignore.case = TRUE)]
  if (length(dta_cand) > 0L) candidates <- dta_cand

  if (as.character(inei_module) == "34") {
    g12 <- candidates[grepl("12g", basename(candidates), ignore.case = TRUE)]
    if (length(g12) > 0L) return(g12[1L])
  }

  # Pick largest matching file if multiple remain
  sz <- file.info(candidates)$size
  candidates[which.max(sz)]
}

.read_enaho_file <- function(path) {
  if (grepl("\\.dta$", path, ignore.case = TRUE)) {
    df <- tryCatch(
      haven::read_dta(path),
      error = function(e) haven::read_dta(path, encoding = "latin1")
    )
  } else {
    df <- tryCatch(
      haven::read_spss(path, user_na = TRUE),
      error = function(e) haven::read_sav(path, user_na = TRUE, encoding = "latin1")
    )
  }
  names(df) <- .clean_enaho_names(names(df))
  df
}

.hh_key_str <- function(df) {
  paste(trimws(as.character(.strip_haven(df$conglome))),
        trimws(as.character(.strip_haven(df$vivienda))),
        trimws(as.character(.strip_haven(df$hogar))),
        sep = "_")
}

# Module 01: Housing, basic services, and Unsatisfied Basic Needs (NBI)
.harmonize_housing <- function(df100) {
  get_num <- function(nm) {
    if (nm %in% names(df100)) as.numeric(.strip_haven(df100[[nm]])) else rep(NA_real_, nrow(df100))
  }

  p110  <- get_num("p110")
  p110a <- get_num("p110a")
  p111a <- get_num("p111a")
  p1121 <- get_num("p1121")
  p113a <- get_num("p113a")
  p103  <- get_num("p103")
  nbi1  <- get_num("nbi1")
  nbi2  <- get_num("nbi2")
  nbi3  <- get_num("nbi3")
  nbi4  <- get_num("nbi4")
  nbi5  <- get_num("nbi5")

  nbi_sum <- nbi1 + nbi2 + nbi3 + nbi4 + nbi5

  out <- data.frame(
    hh_key = .hh_key_str(df100),
    water_public_net = ifelse(is.na(p110), NA_integer_, as.integer(p110 %in% c(1, 2))),
    safe_water_chlorine = ifelse(is.na(p110a), NA_integer_, as.integer(p110a == 1)),
    sanitation_sewer = ifelse(is.na(p111a), NA_integer_, as.integer(p111a %in% c(1, 2))),
    electricity = ifelse(is.na(p1121), NA_integer_, as.integer(p1121 == 1)),
    clean_cooking_fuel = ifelse(is.na(p113a), NA_integer_, as.integer(p113a %in% c(1, 2, 3))),
    earth_floor = ifelse(is.na(p103), NA_integer_, as.integer(p103 == 6)),
    nbi_1 = as.integer(nbi1),
    nbi_2 = as.integer(nbi2),
    nbi_3 = as.integer(nbi3),
    nbi_4 = as.integer(nbi4),
    nbi_5 = as.integer(nbi5),
    any_nbi = ifelse(is.na(nbi_sum), NA_integer_, as.integer(nbi_sum >= 1)),
    stringsAsFactors = FALSE
  )
  out[!duplicated(out$hh_key), , drop = FALSE]
}

# Module 02: Household demographic composition and head-of-household traits
.harmonize_demographics <- function(df200) {
  p203  <- as.numeric(.strip_haven(df200$p203))
  p204  <- as.numeric(.strip_haven(df200$p204))
  p207  <- as.numeric(.strip_haven(df200$p207))
  p208a <- as.numeric(.strip_haven(df200$p208a))
  p209  <- if ("p209" %in% names(df200)) as.numeric(.strip_haven(df200$p209)) else rep(NA_real_, nrow(df200))
  keys  <- .hh_key_str(df200)

  # Keep official household members (p204 == 1)
  mem_idx <- !is.na(p204) & p204 == 1
  k_mem   <- keys[mem_idx]
  age_mem <- p208a[mem_idx]

  u5_cnt  <- tapply(!is.na(age_mem) & age_mem < 5,  k_mem, sum)
  u18_cnt <- tapply(!is.na(age_mem) & age_mem < 18, k_mem, sum)
  oa_cnt  <- tapply(!is.na(age_mem) & age_mem >= 60, k_mem, sum)

  comp_df <- data.frame(
    hh_key = names(u5_cnt),
    n_children_u5 = as.integer(u5_cnt),
    has_child_u5 = as.integer(u5_cnt > 0),
    has_child_u18 = as.integer(u18_cnt > 0),
    has_older_adult = as.integer(oa_cnt > 0),
    stringsAsFactors = FALSE
  )

  # Household head (p203 == 1)
  hd_idx <- which(!is.na(p203) & p203 == 1)
  marital_map <- c(
    "1" = "Cohabiting", "2" = "Married", "3" = "Widowed",
    "4" = "Divorced", "5" = "Separated", "6" = "Single"
  )
  head_df <- data.frame(
    hh_key = keys[hd_idx],
    head_sex = factor(ifelse(p207[hd_idx] == 1, "Male",
                             ifelse(p207[hd_idx] == 2, "Female", NA_character_)),
                      levels = c("Male", "Female")),
    head_age = as.numeric(p208a[hd_idx]),
    head_marital = unname(marital_map[as.character(p209[hd_idx])]),
    stringsAsFactors = FALSE
  )
  head_df <- head_df[!duplicated(head_df$hh_key), , drop = FALSE]

  merge(comp_df, head_df, by = "hh_key", all = TRUE, sort = FALSE)
}

# Modules 03 & 04: Head education/mother tongue, household disability & insurance
.harmonize_education_health <- function(df300, df400) {
  # Module 03: Head of household education & mother tongue
  k3 <- .hh_key_str(df300)
  p203_3 <- as.numeric(.strip_haven(df300$p203))
  p300a  <- as.numeric(.strip_haven(df300$p300a))
  p301a  <- as.numeric(.strip_haven(df300$p301a))

  hd3 <- which(!is.na(p203_3) & p203_3 == 1)
  educ_cat <- ifelse(
    is.na(p301a[hd3]), NA_character_,
    ifelse(p301a[hd3] %in% c(1, 2, 12), "None/Initial",
    ifelse(p301a[hd3] %in% c(3, 4), "Primary",
    ifelse(p301a[hd3] %in% c(5, 6), "Secondary",
    ifelse(p301a[hd3] %in% c(7, 8), "Higher Non-Univ",
    ifelse(p301a[hd3] %in% c(9, 10, 11), "University/Postgrad", NA_character_)))))
  )
  lang_cat <- ifelse(
    is.na(p300a[hd3]), NA_character_,
    ifelse(p300a[hd3] %in% c(1, 2, 3, 10:15), "Indigenous",
    ifelse(p300a[hd3] == 4, "Spanish", "Other"))
  )

  ed_df <- data.frame(
    hh_key = k3[hd3],
    head_educ = factor(educ_cat, levels = c("None/Initial", "Primary", "Secondary",
                                            "Higher Non-Univ", "University/Postgrad")),
    head_mother_tongue = factor(lang_cat, levels = c("Spanish", "Indigenous", "Other")),
    stringsAsFactors = FALSE
  )
  ed_df <- ed_df[!duplicated(ed_df$hh_key), , drop = FALSE]

  # Module 04: Any member with permanent disability & health insurance
  k4 <- .hh_key_str(df400)
  p204_4 <- as.numeric(.strip_haven(df400$p204))
  mem4 <- which(!is.na(p204_4) & p204_4 == 1)

  disc_cols <- intersect(paste0("p401h", 1:6), names(df400))
  disc_mat <- vapply(disc_cols, function(cl) as.numeric(.strip_haven(df400[[cl]][mem4])) == 1,
                     logical(length(mem4)))
  person_disc <- rowSums(disc_mat, na.rm = TRUE) > 0

  ins_cols <- intersect(paste0("p419", 1:8), names(df400))
  ins_mat <- vapply(ins_cols, function(cl) as.numeric(.strip_haven(df400[[cl]][mem4])) == 1,
                    logical(length(mem4)))
  person_ins <- rowSums(ins_mat, na.rm = TRUE) > 0
  person_sis <- if ("p4195" %in% names(df400)) as.numeric(.strip_haven(df400$p4195[mem4])) == 1 else rep(FALSE, length(mem4))
  person_ess <- if ("p4191" %in% names(df400)) as.numeric(.strip_haven(df400$p4191[mem4])) == 1 else rep(FALSE, length(mem4))

  k4_mem <- k4[mem4]
  has_disc <- tapply(person_disc, k4_mem, any, na.rm = TRUE)
  any_ins  <- tapply(person_ins,  k4_mem, any, na.rm = TRUE)
  any_sis  <- tapply(person_sis,  k4_mem, any, na.rm = TRUE)
  any_ess  <- tapply(person_ess,  k4_mem, any, na.rm = TRUE)

  hl_df <- data.frame(
    hh_key = names(has_disc),
    has_disability = as.integer(has_disc),
    any_health_insurance = as.integer(any_ins),
    any_sis = as.integer(any_sis),
    any_essalud = as.integer(any_ess),
    stringsAsFactors = FALSE
  )

  merge(ed_df, hl_df, by = "hh_key", all = TRUE, sort = FALSE)
}

# Module 37: Food assistance and social protection programs (700.dta is household-level)
.harmonize_programs <- function(df700) {
  get_bin <- function(nm) {
    if (!nm %in% names(df700)) return(rep(NA_integer_, nrow(df700)))
    v <- as.numeric(.strip_haven(df700[[nm]]))
    ifelse(is.na(v), NA_integer_, as.integer(v == 1))
  }

  p701_01 <- get_bin("p701_01")
  p701_02 <- get_bin("p701_02")
  p701_03 <- get_bin("p701_03")
  p701_04 <- get_bin("p701_04")
  p701_05 <- get_bin("p701_05")
  p701_09 <- get_bin("p701_09")
  p701_10 <- get_bin("p701_10")
  p710_04 <- get_bin("p710_04")
  p710_05 <- get_bin("p710_05")
  p710_14 <- get_bin("p710_14")
  p710_15 <- get_bin("p710_15")
  p710_34 <- get_bin("p710_34")

  school_food <- ifelse(is.na(p701_03) & is.na(p701_04), NA_integer_,
                        as.integer((!is.na(p701_03) & p701_03 == 1L) |
                                     (!is.na(p701_04) & p701_04 == 1L)))

  out <- data.frame(
    hh_key = .hh_key_str(df700),
    prog_vaso_leche = p701_01,
    prog_comedor_popular = p701_02,
    prog_school_food = school_food,
    prog_cunamas_food = p701_05,
    prog_muni_basket = p701_10,
    any_food_program = ifelse(is.na(p701_09), NA_integer_, as.integer(p701_09 == 0L)),
    prog_juntos = p710_04,
    prog_pension65 = p710_05,
    prog_contigo = p710_34,
    prog_bono_gas = p710_15,
    any_social_program = ifelse(is.na(p710_14), NA_integer_, as.integer(p710_14 == 0L)),
    stringsAsFactors = FALSE
  )
  out[!duplicated(out$hh_key), , drop = FALSE]
}
