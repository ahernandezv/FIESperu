# Prepare Household-Level ENAHO Microdata and Calibrate Official FIES Scores

Reads ENAHO Module 2082 (\`enaho01-\<year\>-130\`, Food Insecurity
Experience Scale) and Module 34 (\`sumaria-\<year\>-12g\`), merges
optional household and member modules (\`"housing"\`,
\`"demographics"\`, \`"education_health"\`, \`"programs"\`), fits the
official INEI annual weighted Rasch model, equates severities to the FAO
global reference scale, and returns a clean household-level
\[tibble::tibble()\] ready for both \[estimate_fies()\] and regression
modeling (e.g., \[survey::svyglm()\]).

## Usage

``` r
prepare_fies(
  years = 2025,
  include = "core",
  cache_dir = fies_cache_dir(),
  local_dir = NULL,
  sample_data = NULL,
  download = TRUE,
  quiet = FALSE
)
```

## Arguments

- years:

  Integer vector of annual survey years (\`\>= 2025\`). Defaults to
  \`2025\`.

- include:

  Character vector specifying which module blocks to download:
  \`"core"\` (default: Module 2082 FIES + Module 34 Sumaria),
  \`"housing"\` (Module 01), \`"demographics"\` (Module 02),
  \`"education_health"\` (Modules 03 and 04), \`"programs"\` (Module
  37), or \`"all"\`.

- cache_dir:

  Character path to the local cache directory. Defaults to
  \[fies_cache_dir()\].

- local_dir:

  Optional path to a local folder containing manually downloaded
  \`.dta\` or \`.sav\` ENAHO files (either flat, such as
  \`"D:/Inseguridad_Alimentaria_2025"\`, or organized in \`ModuloXX\`
  subfolders). When \`NULL\` (default), reads from \`cache_dir\`.

- sample_data:

  Optional pre-loaded list or data frame (such as \[fies_sample\]) for
  fast offline demonstration and testing without reading external files.

- download:

  Logical; if \`TRUE\` (default) and \`local_dir\` is \`NULL\`,
  automatically calls \[download_fies()\] for any requested module
  missing from \`cache_dir\`.

- quiet:

  Logical; if \`TRUE\`, suppresses progress messages. Defaults to
  \`FALSE\`.

## Value

A \[tibble::tibble()\] of class \`"fies_tbl"\` with one row per surveyed
household, containing survey design keys (\`conglome\`, \`estrato\`,
\`wt_hh\`, \`wt_pop\`), official INEI geographies (\`area\`,
\`department\`, \`region_inei\`, \`natural_region\`), monetary poverty
indicators, binary FIES items (\`fies_worried\`..\`fies_whlday\`), raw
score (\`fies_rs\`), household probabilities of moderate-or-severe
(\`pr_mod_sev\`) and severe (\`pr_sev\`) food insecurity, and any
requested sociodemographic blocks. Annual Rasch model diagnostics are
stored in \`attr(x, "rasch_models")\`.

## Examples

``` r
# Offline demonstration using the bundled synthetic sample
df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
head(df_demo[, c("year", "area", "poverty", "fies_rs", "pr_mod_sev", "pr_sev")])
#> # A tibble: 6 × 6
#>    year area  poverty  fies_rs pr_mod_sev     pr_sev
#>   <int> <fct> <fct>      <int>      <dbl>      <dbl>
#> 1  2025 Rural Non-Poor       1     0.0335 0.00000723
#> 2  2025 Urban Poor           3     0.349  0.0000872 
#> 3  2025 Urban Non-Poor       1     0.0335 0.00000723
#> 4  2025 Rural Poor           7     0.993  0.539     
#> 5  2025 Urban Non-Poor       0     0.0271 0.0000704 
#> 6  2025 Urban Non-Poor       2     0.115  0.00000784
```
