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
      "enaho01-<year>-130.dta",
      "sumaria-<year>-12g.dta",
      "enaho01-<year>-100.dta",
      "enaho01-<year>-200.dta",
      "enaho01a-<year>-300.dta",
      "enaho01a-<year>-400.dta",
      "enaho01-<year>-700.dta"
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

#' Dictionary of the Eight FIES Items in INEI ENAHO (Chapter 130)
#'
#' Returns a reference table with the exact Spanish wording from INEI ENAHO
#' Chapter 130 (`p130_1`--`p130_8`, 30-day household recall period), the
#' standard English FAO item wording, the harmonized variable names produced by
#' [prepare_fies()], severity domains, and the FAO global reference standard
#' parameters (`fies.global.st`).
#'
#' @returns A [tibble::tibble()] with 8 rows and 8 columns: `item_num`,
#'   `enaho_var`, `harmonized_var`, `item_code`, `severity_domain`,
#'   `global_st`, `question_es`, and `question_en`.
#' @export
#'
#' @examples
#' fies_items()
fies_items <- function() {
  tibble::tibble(
    item_num = 1:8,
    enaho_var = paste0("p130_", 1:8),
    harmonized_var = c(
      "fies_worried", "fies_healthy", "fies_fewfood", "fies_skipped",
      "fies_ateless", "fies_runout", "fies_hungry", "fies_whlday"
    ),
    item_code = c(
      "WORRIED", "HEALTHY", "FEWFOOD", "SKIPPED",
      "ATELESS", "RUNOUT", "HUNGRY", "WHLDAY"
    ),
    severity_domain = c(
      "Mild", "Mild", "Mild", "Moderate",
      "Moderate (Threshold Mod+Sev)", "Moderate", "Severe", "Severe (Threshold Sev)"
    ),
    global_st = as.numeric(.fies_global_st),
    question_es = c(
      paste0("Durante el mes anterior, \u00bfhubo alg\u00fan momento en el que usted o alg\u00fan otro miembro ",
             "del hogar estuvo preocupado de no tener suficiente comida para comer por falta de dinero u otras formas de conseguir los alimentos?"),
      paste0("Pensando a\u00fan en el mes anterior, \u00bfhubo un momento en el que usted o alg\u00fan otro miembro ",
             "del hogar no pudo comer alimentos saludables y nutritivos debido a la falta de dinero u otras formas de conseguir los alimentos?"),
      paste0("Durante el mes anterior, \u00bfhubo un momento en el que usted o alg\u00fan otro miembro ",
             "del hogar no comi\u00f3 alimentos variados debido a la falta de dinero u otras formas de conseguir los alimentos?"),
      paste0("Durante el mes anterior, \u00bfhubo un momento en el que usted o alg\u00fan otro miembro ",
             "del hogar tuvo que dejar de desayunar, almorzar o cenar porque no hab\u00eda suficiente dinero u otras formas de conseguir los alimentos para obtener comida?"),
      paste0("Pensando a\u00fan en el mes anterior, \u00bfhubo un momento en el que usted o alg\u00fan otro miembro ",
             "del hogar comi\u00f3 menor cantidad de lo normal, debido a la falta de dinero u otras formas de conseguir los alimentos?"),
      paste0("En el mes anterior, \u00bfhubo un momento en el que su hogar se qued\u00f3 sin alimentos ",
             "por la falta de dinero u otras formas de conseguir los alimentos?"),
      paste0("En el mes anterior, \u00bfhubo un momento en que usted o alg\u00fan otro miembro ",
             "del hogar tuvo hambre, pero no comi\u00f3 porque no hab\u00eda suficiente dinero u otras formas de conseguir los alimentos para obtener comida?"),
      paste0("Durante el mes anterior, \u00bfhubo un momento en que usted o alg\u00fan otro miembro ",
             "del hogar estuvo sin comer durante un d\u00eda entero debido a la falta de dinero u otras formas de conseguir los alimentos?")
    ),
    question_en = c(
      "During the previous month, was there a time when you or another household member were worried you would not have enough food to eat because of a lack of money or other resources?",
      "During the previous month, was there a time when you or another household member were unable to eat healthy and nutritious food because of a lack of money or other resources?",
      "During the previous month, was there a time when you or another household member ate only a few kinds of foods because of a lack of money or other resources?",
      "During the previous month, was there a time when you or another household member had to skip a meal because there was not enough money or other resources to get food?",
      "During the previous month, was there a time when you or another household member ate less than you thought you should because of a lack of money or other resources?",
      "During the previous month, was there a time when your household ran out of food because of a lack of money or other resources?",
      "During the previous month, was there a time when you or another household member were hungry but did not eat because there was not enough money or other resources for food?",
      "During the previous month, was there a time when you or another household member went without eating for a whole day because of a lack of money or other resources?"
    )
  )
}
