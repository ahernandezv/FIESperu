# Estimate Official FIES Food Insecurity Prevalences and Combined Margins of Error

Computes population prevalence estimates, confidence intervals,
coefficients of variation, and total standard errors combining
complex-survey Taylor linearization (\`se_s\`, accounting for
stratification and primary sampling units) with Rasch latent measurement
error (\`se_m\`), following the official INEI / FAO methodology.

## Usage

``` r
estimate_fies(
  data,
  by = NULL,
  indicator = c("both", "mod_sev", "sev"),
  conf_level = 0.95,
  combine_by = FALSE,
  percent = TRUE
)
```

## Arguments

- data:

  A household-level data frame or \`fies_tbl\` produced by
  \[prepare_fies()\].

- by:

  Disaggregation specification: \* \`NULL\` (default): National
  prevalence by survey year. \* \`"official"\`: Generates in one call
  National, Area (\`Urban\`/\`Rural\`), Natural Region
  (\`Coast\`/\`Highlands\`/\`Jungle\`), all 24 Departments + Callao, and
  the official 26-domain regional breakdown (\`region_inei\`, separating
  \`Lima Metropolitana\` and \`Lima Region\`). \* A character vector of
  one or more column names in \`data\` (e.g., \`c("area", "poverty")\`
  or \`"has_child_u5"\`).

- indicator:

  Character string indicating which FIES threshold(s) to estimate:
  \`"both"\` (default), \`"mod_sev"\` (Moderate or Severe), or \`"sev"\`
  (Severe).

- conf_level:

  Confidence level for margins of error and intervals. Defaults to
  \`0.95\`.

- combine_by:

  Logical; when \`by\` is a vector of 2 or more column names, if
  \`TRUE\`, also estimates the Cartesian interaction of those variables
  (e.g., \`area x poverty\`). Ignored when \`by\` is \`NULL\` or
  \`"official"\`.

- percent:

  Logical; if \`TRUE\` (default), scales \`estimate\`, \`lower\`,
  \`upper\`, \`moe\`, \`se_total\`, \`se_s\`, \`se_m\`, and \`cv\` to
  percentages (\`0\`–\`100\`). Set to \`FALSE\` for proportions
  (\`0\`–\`1\`).

## Value

A \[tibble::tibble()\] with columns \`year\`, \`group\`, \`category\`,
\`indicator\`, \`estimate\`, \`lower\`, \`upper\`, \`moe\`,
\`se_total\`, \`se_s\`, \`se_m\`, \`cv\`, and \`n_unweighted\`.

## Examples

``` r
df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
estimate_fies(df_demo, by = c("area", "poverty"))
#> # A tibble: 10 × 13
#>     year group    category indicator   estimate lower upper   moe se_total  se_s
#>    <int> <chr>    <chr>    <chr>          <dbl> <dbl> <dbl> <dbl>    <dbl> <dbl>
#>  1  2025 National National Moderate o…    44.9  39.6  50.3   5.35     2.73 2.13 
#>  2  2025 area     Urban    Moderate o…    38.8  32.4  45.3   6.42     3.28 2.65 
#>  3  2025 area     Rural    Moderate o…    55.9  46.3  65.6   9.68     4.94 3.54 
#>  4  2025 poverty  Poor     Moderate o…    49.3  38.4  60.2  10.9      5.55 4.49 
#>  5  2025 poverty  Non-Poor Moderate o…    43.4  37.2  49.7   6.24     3.18 2.47 
#>  6  2025 National National Severe          5.72  3.15  8.28  2.57     1.31 0.980
#>  7  2025 area     Urban    Severe          5.14  2.16  8.11  2.98     1.52 1.11 
#>  8  2025 area     Rural    Severe          6.76  1.98 11.6   4.79     2.44 1.87 
#>  9  2025 poverty  Poor     Severe         10.8   4.14 17.4   6.62     3.38 2.64 
#> 10  2025 poverty  Non-Poor Severe          3.95  1.40  6.50  2.55     1.30 0.918
#> # ℹ 3 more variables: se_m <dbl>, cv <dbl>, n_unweighted <int>
```
