# Clear FIESperu Local Microdata Cache

Removes cached ENAHO microdata directories downloaded by
\[download_fies()\].

## Usage

``` r
clear_fies_cache(years = NULL, cache_dir = fies_cache_dir(), quiet = FALSE)
```

## Arguments

- years:

  Optional integer vector of survey years to remove (e.g., \`2025\`). If
  \`NULL\` (the default), removes the entire cache directory.

- cache_dir:

  Character string indicating the cache root directory. Defaults to
  \[fies_cache_dir()\].

- quiet:

  Logical; if \`FALSE\` (default), prints a confirmation message.

## Value

Invisibly returns \`TRUE\` if files were removed or \`FALSE\` if nothing
existed to remove.

## Examples

``` r
tmp_cache <- file.path(tempdir(), "fies_cache_demo")
clear_fies_cache(cache_dir = tmp_cache, quiet = TRUE)
```
