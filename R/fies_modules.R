#' List Available ENAHO Modules and Annual Survey Codes for FIESperu
#'
#' Displays the ENAHO modules supported by `FIESperu` along with the `include`
#' block names used in [download_fies()] and [prepare_fies()], as well as the
#' built-in annual INEI `srienaho` survey codes (from 2025 onwards).
#'
#' @param year Optional integer year to filter survey codes (e.g., `2025`).
#'
#' @returns A [tibble::tibble()] describing the available module blocks, INEI
#'   module codes, file patterns, and analysis levels.
#' @export
#'
#' @examples
#' fies_modules()
fies_modules <- function(year = NULL) {
  mods <- tibble::tibble(
    block = c("core", "core", "housing", "demographics",
              "education_health", "education_health", "programs"),
    inei_module = c("2082", "34", "01", "02", "03", "04", "37"),
    module_name_es = c(
      "Inseguridad Alimentaria (Cap. 130 - FIES)",
      "Sumarias (Variables Calculadas)",
      "Caracteristicas de la Vivienda y del Hogar",
      "Caracteristicas de los Miembros del Hogar",
      "Educacion",
      "Salud y Discapacidad",
      "Programas Sociales Alimentarios y No Alimentarios"
    ),
    dta_pattern = c(
      "enaho01-{year}-130.dta",
      "sumaria-{year}-12g.dta",
      "enaho01-{year}-100.dta",
      "enaho01-{year}-200.dta",
      "enaho01a-{year}-300.dta",
      "enaho01a-{year}-400.dta",
      "enaho01-{year}-700.dta"
    ),
    unit_raw = c("Household", "Household", "Household", "Member -> Household",
                 "Member -> Household", "Member -> Household", "Household"),
    available_from = 2025L
  )

  if (!is.null(year)) {
    year <- as.integer(year)
    if (any(year < 2025L, na.rm = TRUE)) {
      stop("The permanent INEI ENAHO Food Insecurity module (FIES) starts in 2025.",
           call. = FALSE)
    }
  }
  mods
}
