# Get Default Cache Directory for FIESperu

Returns the platform-appropriate persistent user cache directory used by
\`FIESperu\` to store downloaded INEI ENAHO microdata files, following
CRAN policies via \[tools::R_user_dir()\].

## Usage

``` r
fies_cache_dir()
```

## Value

A character string with the normalized path to the cache directory.

## Examples

``` r
fies_cache_dir()
#> [1] "/home/runner/.cache/R/FIESperu"
```
