# Download and Cache INEI ENAHO Modules for FIES Estimation

Downloads the official Stata (\`.dta\`) microdata archives from the INEI
\`srienaho\` repository for the requested annual survey years (2025
onwards) and module blocks, storing extracted files in a persistent
local cache.

## Usage

``` r
download_fies(
  years = 2025,
  include = "core",
  cache_dir = fies_cache_dir(),
  overwrite = FALSE,
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

- overwrite:

  Logical; if \`TRUE\`, re-downloads modules even if already present in
  \`cache_dir\`. Defaults to \`FALSE\`.

- quiet:

  Logical; if \`TRUE\`, suppresses progress messages. Defaults to
  \`FALSE\`.

## Value

Invisibly returns a \[tibble::tibble()\] with the year, module code,
cache status, and local directory path of each requested module.

## Examples

``` r
# \donttest{
# Download core 2025 FIES + Sumaria modules into a temporary cache
download_fies(years = 2025, include = "core", cache_dir = tempdir())
#> [FIESperu] Downloading Year 2025 - Modulo 2082 (1031-Modulo2082.zip)...
#> [FIESperu] Downloading Year 2025 - Modulo 34 (1031-Modulo34.zip)...
# }
```
