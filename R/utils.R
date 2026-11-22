#' Convert Numeric Vector to Stata 32-bit Float Precision
#'
#' Replicates Stata's default 32-bit single-precision (`float`) rounding on
#' numeric vectors while preserving `NA_real_` values cleanly. Official INEI
#' routines generate the population expansion weight (`facpob = factor07 * mieperho`)
#' using 32-bit float precision; applying `as_stata_float()` ensures exact
#' decimal-level reproducibility of official INEI tabulations in R.
#'
#' @param x A numeric vector.
#'
#' @returns A double-precision numeric vector rounded to IEEE-754 32-bit single
#'   precision, with `NA` positions preserved as `NA_real_`.
#' @export
#'
#' @examples
#' x <- c(123.456789123, NA_real_, 0)
#' as_stata_float(x)
as_stata_float <- function(x) {
  x <- as.numeric(x)
  n <- length(x)
  if (n == 0L) return(numeric(0L))

  na_idx <- is.na(x) & !is.nan(x)
  nan_idx <- is.nan(x)
  out <- x
  ok <- !(na_idx | nan_idx | is.infinite(x))

  if (any(ok)) {
    buf <- writeBin(x[ok], raw(), size = 4L, endian = .Platform$endian)
    out[ok] <- readBin(buf, what = double(), n = sum(ok), size = 4L, endian = .Platform$endian)
  }
  out[na_idx] <- NA_real_
  out[nan_idx] <- NaN
  out
}

# Normalize ENAHO column names across Stata (.dta) and SPSS (.sav) encodings
.clean_enaho_names <- function(nms) {
  nms_utf8 <- iconv(nms, from = "", to = "UTF-8", sub = "")
  low <- tolower(nms_utf8)
  # Replace variations of aNo / ano -> anio internal key
  low <- gsub("^a(\u00f1|\u00d1|n|~)o$", "anio", low)
  # Catch broken latin1 encodings of ano (length 3-4 starting with a and ending with o)
  low <- ifelse(grepl("^a[^a-z0-9]{1,2}o$", low), "anio", low)
  low
}

.strip_haven <- function(x) {
  as.vector(x)
}

# Build standardized INEI geographic variables from ubigeo, dominio, estrato
.derive_geography <- function(ubigeo, dominio, estrato) {
  ub <- sprintf("%06s", trimws(as.character(.strip_haven(ubigeo))))
  ub <- gsub(" ", "0", ub)
  dep_code <- substr(ub, 1L, 2L)
  prov_code <- substr(ub, 1L, 4L)
  dom <- suppressWarnings(as.integer(.strip_haven(dominio)))
  est <- suppressWarnings(as.integer(.strip_haven(estrato)))

  area <- ifelse(is.na(est), NA_character_,
                 ifelse(est < 6L, "Urban", "Rural"))

  dept_map <- c(
    "01" = "Amazonas", "02" = "Ancash", "03" = "Apurimac",
    "04" = "Arequipa", "05" = "Ayacucho", "06" = "Cajamarca",
    "07" = "Callao", "08" = "Cusco", "09" = "Huancavelica",
    "10" = "Huanuco", "11" = "Ica", "12" = "Junin",
    "13" = "La Libertad", "14" = "Lambayeque", "15" = "Lima",
    "16" = "Loreto", "17" = "Madre de Dios", "18" = "Moquegua",
    "19" = "Pasco", "20" = "Piura", "21" = "Puno",
    "22" = "San Martin", "23" = "Tacna", "24" = "Tumbes",
    "25" = "Ucayali"
  )
  department <- unname(dept_map[dep_code])

  # Official 26-domain INEI regional breakdown separating Metropolitan Lima vs Lima Region
  # Note: Provincial Callao is dep_code == "07"; Lima province is prov_code == "1501" (or dep=="15" & dom==8)
  region_inei <- department
  is_lima_metro <- !is.na(dep_code) & dep_code == "15" & (prov_code == "1501" | (!is.na(dom) & dom == 8L))
  is_lima_reg   <- !is.na(dep_code) & dep_code == "15" & !is_lima_metro
  region_inei[is_lima_metro] <- "Lima Metropolitana"
  region_inei[is_lima_reg]   <- "Lima Region"

  natural_region <- ifelse(
    is.na(dom), NA_character_,
    ifelse(dom %in% c(1L, 2L, 3L, 8L), "Coast",
           ifelse(dom %in% c(4L, 5L, 6L), "Highlands",
                  ifelse(dom == 7L, "Jungle", NA_character_)))
  )

  domain_label <- c(
    "1" = "North Coast", "2" = "Central Coast", "3" = "South Coast",
    "4" = "North Highlands", "5" = "Central Highlands", "6" = "South Highlands",
    "7" = "Jungle", "8" = "Metropolitan Lima"
  )[as.character(dom)]

  list(
    area = factor(area, levels = c("Urban", "Rural")),
    department = department,
    region_inei = region_inei,
    natural_region = factor(natural_region, levels = c("Coast", "Highlands", "Jungle")),
    domain_name = unname(domain_label)
  )
}
