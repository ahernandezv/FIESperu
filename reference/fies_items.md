# Dictionary of the Eight FIES Items in INEI ENAHO (Chapter 130)

Returns a reference table with the exact Spanish wording from INEI ENAHO
Chapter 130 (\`p130_1\`–\`p130_8\`, 30-day household recall period), the
standard English FAO item wording, the harmonized variable names
produced by \[prepare_fies()\], severity domains, and the FAO global
reference standard parameters (\`fies.global.st\`).

## Usage

``` r
fies_items()
```

## Value

A \[tibble::tibble()\] with 8 rows and 8 columns: \`item_num\`,
\`enaho_var\`, \`harmonized_var\`, \`item_code\`, \`severity_domain\`,
\`global_st\`, \`question_es\`, and \`question_en\`.

## Examples

``` r
fies_items()
#> # A tibble: 8 × 8
#>   item_num enaho_var harmonized_var item_code severity_domain          global_st
#>      <int> <chr>     <chr>          <chr>     <chr>                        <dbl>
#> 1        1 p130_1    fies_worried   WORRIED   Mild                        -1.22 
#> 2        2 p130_2    fies_healthy   HEALTHY   Mild                        -0.847
#> 3        3 p130_3    fies_fewfood   FEWFOOD   Mild                        -1.11 
#> 4        4 p130_4    fies_skipped   SKIPPED   Moderate                     0.351
#> 5        5 p130_5    fies_ateless   ATELESS   Moderate (Threshold Mod…    -0.312
#> 6        6 p130_6    fies_runout    RUNOUT    Moderate                     0.507
#> 7        7 p130_7    fies_hungry    HUNGRY    Severe                       0.755
#> 8        8 p130_8    fies_whlday    WHLDAY    Severe (Threshold Sev)       1.88 
#> # ℹ 2 more variables: question_es <chr>, question_en <chr>
```
