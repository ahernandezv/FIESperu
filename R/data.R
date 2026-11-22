#' Synthetic ENAHO Household Sample for FIES Demonstration and Testing
#'
#' A lightweight synthetic dataset of 400 stratified households mimicking the
#' structure and item severity ordering of the Peruvian ENAHO Module 2082
#' (`enaho01-2025-130`) and Module 34 (`sumaria-2025-12g`). Provided so examples,
#' vignettes, and unit tests run offline in under a second without contacting
#' INEI servers.
#'
#' @format A data frame with 400 rows and 23 columns:
#' \describe{
#'   \item{year}{Survey year (`2025`).}
#'   \item{conglome}{Primary sampling unit identifier.}
#'   \item{vivienda}{Dwelling identifier.}
#'   \item{hogar}{Household identifier.}
#'   \item{ubigeo}{Six-digit geographic code.}
#'   \item{dominio}{Geographic domain (`1`--`8`).}
#'   \item{estrato}{Sampling stratum (`1`--`8`, where `6`--`8` are rural).}
#'   \item{factor07}{Household annual sampling weight.}
#'   \item{mieperho}{Number of household members.}
#'   \item{pobreza}{Monetary poverty code (`1` = Extreme poor, `2` = Non-extreme poor, `3` = Non-poor).}
#'   \item{pobrezav}{Vulnerability code (`1`--`4`).}
#'   \item{gashog2d}{Annual gross household expenditure (PEN).}
#'   \item{inghog2d}{Annual net household income (PEN).}
#'   \item{p130_1, p130_2, p130_3, p130_4, p130_5, p130_6, p130_7, p130_8}{Eight FIES items coded `1` = Yes, `2` = No.}
#'   \item{has_child_u5}{Indicator (`0`/`1`) for presence of children under 5 years.}
#'   \item{has_disability}{Indicator (`0`/`1`) for presence of a member with permanent disability.}
#' }
#' @source Simulated Rasch item responses calibrated to the FAO FIES global scale.
"fies_sample"
