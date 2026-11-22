# FIESperu

**`FIESperu`** automates the downloading, household-level harmonization,
weighted Rasch psychometric validation, global equating, and
complex-survey prevalence estimation of food insecurity in Peru from the
**Food Insecurity Module (*Módulo de Inseguridad Alimentaria*, Module
2082)** of the **National Household Survey (ENAHO)** conducted by the
**National Institute of Statistics and Informatics (INEI)** (2025
onwards).

It reproduces the official INEI/FAO methodology for SDG indicator 2.1.2
with exact decimal precision, including population weights, linear
equating to the FAO FIES global reference standard, and combined
sampling (`se_s`) and Rasch measurement (`se_m`) errors.

Beyond official prevalence estimation, **`FIESperu`** also provides a
reproducible, real-world data resource for teaching, training, and
applied research in food insecurity measurement, FIES analysis, Rasch
modeling, psychometric validation, and complex survey methodology.

------------------------------------------------------------------------

## Installation / Instalación

``` r

# From GitHub:
# install.packages("remotes")
remotes::install_github("ahernandezv/FIESperu")

# Or from R-universe (once enabled):
# install.packages("FIESperu", repos = c("https://ahernandezv.r-universe.dev", "https://cloud.r-project.org"))
```

------------------------------------------------------------------------

## The Eight FIES Questions (ENAHO Module 2082)

All eight questions can be queried in R via
[`fies_items()`](https://ahernandezv.github.io/FIESperu/reference/fies_items.md)
(raw coding in ENAHO: `1 = Yes`, `2 = No`, `3 = Don't know`,
`4 = No response`; recoded by
[`prepare_fies()`](https://ahernandezv.github.io/FIESperu/reference/prepare_fies.md)
to `1 = Yes`, `0 = No`, `NA`):

| \# | ENAHO Var | Harmonized Var | FAO Code | Global Std (`fies.global.st`) | Official ENAHO Wording (Spanish, 30-day recall) |
|:--:|:---|:---|:---|:--:|:---|
| 1 | `p130_1` | `fies_worried` | `WORRIED` | `-1.2231` | *Durante el mes anterior, ¿hubo algún momento en el que usted o algún otro miembro del hogar estuvo preocupado de no tener suficiente comida para comer por falta de dinero u otras formas de conseguir los alimentos?* |
| 2 | `p130_2` | `fies_healthy` | `HEALTHY` | `-0.8471` | *Pensando aún en el mes anterior, ¿hubo un momento en el que usted o algún otro miembro del hogar no pudo comer alimentos saludables y nutritivos debido a la falta de dinero u otras formas de conseguir los alimentos?* |
| 3 | `p130_3` | `fies_fewfood` | `FEWFOOD` | `-1.1057` | *Durante el mes anterior, ¿hubo un momento en el que usted o algún otro miembro del hogar no comió alimentos variados debido a la falta de dinero u otras formas de conseguir los alimentos?* |
| 4 | `p130_4` | `fies_skipped` | `SKIPPED` | `+0.3510` | *Durante el mes anterior, ¿hubo un momento en el que usted o algún otro miembro del hogar tuvo que dejar de desayunar, almorzar o cenar porque no había suficiente dinero u otras formas de conseguir los alimentos para obtener comida?* |
| 5 | `p130_5` | `fies_ateless` | **`ATELESS`** | **`-0.3118`** | *Pensando aún en el mes anterior, ¿hubo un momento en el que usted o algún otro miembro del hogar comió menor cantidad de lo normal, debido a la falta de dinero u otras formas de conseguir los alimentos?* *(Global threshold: Moderate or Severe)* |
| 6 | `p130_6` | `fies_runout` | `RUNOUT` | `+0.5065` | *En el mes anterior, ¿hubo un momento en el que su hogar se quedó sin alimentos por la falta de dinero u otras formas de conseguir los alimentos?* |
| 7 | `p130_7` | `fies_hungry` | `HUNGRY` | `+0.7546` | *En el mes anterior, ¿hubo un momento en que usted o algún otro miembro del hogar tuvo hambre, pero no comió porque no había suficiente dinero u otras formas de conseguir los alimentos para obtener comida?* |
| 8 | `p130_8` | `fies_whlday` | **`WHLDAY`** | **`+1.8755`** | *Durante el mes anterior, ¿hubo un momento en que usted o algún otro miembro del hogar estuvo sin comer durante un día entero debido a la falta de dinero u otras formas de conseguir los alimentos?* *(Global threshold: Severe)* |

------------------------------------------------------------------------

## Quick Start / Uso Rápido

### 1. Replicating Official INEI ENAHO 2025 Prevalences

``` r

library(FIESperu)

# Inspect the 8 FIES items and official Spanish/English wording:
fies_items()

# Automatically downloads INEI ENAHO 2025 Stata microdata on first run,
# merges Module 2082 (FIES) + Module 34 (Sumaria) + optional sociodemographic blocks,
# and calibrates the annual weighted Rasch model:
fies_2025 <- prepare_fies(
  years = 2025,
  include = c("core", "demographics", "education_health", "programs")
)

# Estimate official FIES indicators across geographic domains:
# National Mod+Sev: 30.5% | Urban: 29.3% | Rural: 35.4% | National Severe: 3.4%
official_tbl <- estimate_fies(fies_2025, by = "official")
print(official_tbl)

# Vulnerability profiles (e.g., children < 5 years, disability, social programs):
estimate_fies(
  fies_2025,
  by = c("has_child_u5", "has_disability", "any_food_program"),
  indicator = "mod_sev"
)

# Validate the Rasch model and visualize results:
val <- validate_rasch(fies_2025)
plot_fies(val, type = "equating")
plot_fies(official_tbl, type = "prevalence", group = "region_inei")
```

### 2. Offline Demo & Rasch Training (`fies_sample`)

``` r

library(FIESperu)

df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
validate_rasch(df_demo)
estimate_fies(df_demo, by = c("area", "poverty"))
```

------------------------------------------------------------------------

## Citation

If you use `FIESperu` in academic publications, teaching, or technical
reports, please cite:

``` r

citation("FIESperu")
```

- Hernández-Vásquez, A. (2026). *FIESperu: Food Insecurity Experience
  Scale (FIES) Estimation for Peru*. R package version 0.1.0.
  <https://github.com/ahernandezv/FIESperu>
