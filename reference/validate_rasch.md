# Extract Psychometric Rasch Model Diagnostics and Equating Metrics

Retrieves item-level Rasch parameters (\`severity_b\`, \`se_b\`,
\`infit\`, \`outfit\`), FAO global standard severities (\`global_st\`,
\`adj_global_st\`), raw-score latent parameters, and scale-level
psychometric validity summaries (flat Rasch reliability, correlation
with the global reference standard, and first residual PCA eigenvalue)
from a dataset prepared with \[prepare_fies()\].

## Usage

``` r
validate_rasch(data, year = NULL)
```

## Arguments

- data:

  A \`fies_tbl\` object returned by \[prepare_fies()\].

- year:

  Optional integer vector filtering specific survey year(s).

## Value

An object of class \`"fies_validation"\` (a named list containing three
tibbles: \`summary\`, \`items\`, and \`raw_scores\`, plus \`models\`
metadata for plotting).

## Examples

``` r
df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
val <- validate_rasch(df_demo)
val
#> == FIESperu Psychometric Rasch Validation ==
#> 
#> -- Scale Summary --
#> # A tibble: 1 × 13
#>    year n_total n_complete n_partial_na n_all_na reliab_fl reliab cor_global
#> * <int>   <int>      <int>        <int>    <int>     <dbl>  <dbl>      <dbl>
#> 1  2025     400        400            0        0     0.732  0.686      0.998
#> # ℹ 5 more variables: sd_b <dbl>, thresh_mod_sev <dbl>, thresh_sev <dbl>,
#> #   max_infit <dbl>, eigenvalue_1 <dbl>
#> 
#> -- Item Severity & Fit Statistics --
#> # A tibble: 8 × 11
#>    year item_num enaho_var item_code severity_b  se_b infit outfit global_st
#> * <int>    <int> <chr>     <chr>          <dbl> <dbl> <dbl>  <dbl>     <dbl>
#> 1  2025        1 p130_1    WORRIED       -1.49  0.133 0.883  0.789    -1.22 
#> 2  2025        2 p130_2    HEALTHY       -1.26  0.130 0.985  0.915    -0.847
#> 3  2025        3 p130_3    FEWFOOD       -1.42  0.132 1.07   1.07     -1.11 
#> 4  2025        4 p130_4    SKIPPED        0.548 0.138 1.02   1.06      0.351
#> 5  2025        5 p130_5    ATELESS       -0.324 0.127 0.935  0.844    -0.312
#> 6  2025        6 p130_6    RUNOUT         0.608 0.139 1.09   1.17      0.507
#> 7  2025        7 p130_7    HUNGRY         0.907 0.146 1.10   1.05      0.755
#> 8  2025        8 p130_8    WHLDAY         2.43  0.214 0.949  0.964     1.88 
#> # ℹ 2 more variables: adj_global_st <dbl>, diff_from_global <dbl>
```
