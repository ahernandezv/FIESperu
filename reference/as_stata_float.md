# Convert Numeric Vector to Stata 32-bit Float Precision

Replicates Stata's default 32-bit single-precision (\`float\`) rounding
on numeric vectors while preserving \`NA_real\_\` values cleanly.
Official INEI routines generate the population expansion weight
(\`facpob = factor07 \* mieperho\`) using 32-bit float precision;
applying \`as_stata_float()\` ensures exact decimal-level
reproducibility of official INEI tabulations in R.

## Usage

``` r
as_stata_float(x)
```

## Arguments

- x:

  A numeric vector.

## Value

A double-precision numeric vector rounded to IEEE-754 32-bit single
precision, with \`NA\` positions preserved as \`NA_real\_\`.

## Examples

``` r
x <- c(123.456789123, NA_real_, 0)
as_stata_float(x)
#> [1] 123.4568       NA   0.0000
```
