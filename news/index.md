# Changelog

## FIESperu 0.1.0

- Initial release of `FIESperu`.
- Added
  [`fies_modules()`](https://ahernandezv.github.io/FIESperu/reference/fies_modules.md)
  and
  [`download_fies()`](https://ahernandezv.github.io/FIESperu/reference/download_fies.md)
  with persistent local caching
  ([`fies_cache_dir()`](https://ahernandezv.github.io/FIESperu/reference/fies_cache_dir.md),
  [`clear_fies_cache()`](https://ahernandezv.github.io/FIESperu/reference/clear_fies_cache.md))
  for INEI ENAHO annual microdata (2025 onwards).
- Added
  [`prepare_fies()`](https://ahernandezv.github.io/FIESperu/reference/prepare_fies.md)
  to build regression-ready household datasets integrating Module 130
  (FIES) and Module 34 (Sumaria) with optional household harmonizers for
  Housing/NBI (Module 01), Demographics (Module 02),
  Education/Health/Disability (Modules 03–04), and Social Programs
  (Module 37).
- Implemented the official INEI Rasch model calibration, global standard
  equating,
  [`as_stata_float()`](https://ahernandezv.github.io/FIESperu/reference/as_stata_float.md)
  precision matching, and combined complex-survey sampling + Rasch
  measurement error estimation in
  [`estimate_fies()`](https://ahernandezv.github.io/FIESperu/reference/estimate_fies.md).
- Added
  [`validate_rasch()`](https://ahernandezv.github.io/FIESperu/reference/validate_rasch.md)
  and
  [`plot_fies()`](https://ahernandezv.github.io/FIESperu/reference/plot_fies.md)
  for psychometric item-fit diagnostics and prevalence visualizations,
  plus synthetic dataset `fies_sample` and bilingual vignettes (English
  and Spanish).
