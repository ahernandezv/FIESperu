# List Available ENAHO Modules and Annual Survey Codes for FIESperu

Displays the ENAHO modules supported by \`FIESperu\` along with the
\`include\` block names used in \[download_fies()\] and
\[prepare_fies()\], as well as the built-in annual INEI \`srienaho\`
survey codes (from 2025 onwards).

## Usage

``` r
fies_modules(year = NULL)
```

## Arguments

- year:

  Optional integer year to filter survey codes (e.g., \`2025\`).

## Value

A \[tibble::tibble()\] describing the available module blocks, INEI
module codes, file patterns, and analysis levels.

## Examples

``` r
fies_modules()
#> # A tibble: 7 × 6
#>   block           inei_module module_name_es dta_pattern unit_raw available_from
#>   <chr>           <chr>       <chr>          <chr>       <chr>             <int>
#> 1 core            2082        Inseguridad A… enaho01-<y… Househo…           2025
#> 2 core            34          Sumarias (Var… sumaria-<y… Househo…           2025
#> 3 housing         01          Caracteristic… enaho01-<y… Househo…           2025
#> 4 demographics    02          Caracteristic… enaho01-<y… Member …           2025
#> 5 education_heal… 03          Educacion      enaho01a-<… Member …           2025
#> 6 education_heal… 04          Salud y Disca… enaho01a-<… Member …           2025
#> 7 programs        37          Programas Soc… enaho01-<y… Househo…           2025
```
