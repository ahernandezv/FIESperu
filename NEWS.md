# FIESperu 0.1.0

* Initial release of `FIESperu`.
* Added `fies_modules()` and `download_fies()` with persistent local caching (`fies_cache_dir()`, `clear_fies_cache()`) for INEI ENAHO annual microdata (2025 onwards).
* Added `prepare_fies()` to build regression-ready household datasets integrating Module 130 (FIES) and Module 34 (Sumaria) with optional household harmonizers for Housing/NBI (Module 01), Demographics (Module 02), Education/Health/Disability (Modules 03--04), and Social Programs (Module 37).
* Implemented the official INEI Rasch model calibration, global standard equating, `as_stata_float()` precision matching, and combined complex-survey sampling + Rasch measurement error estimation in `estimate_fies()`.
* Added `validate_rasch()` and `plot_fies()` for psychometric item-fit diagnostics and prevalence visualizations, plus synthetic dataset `fies_sample` and bilingual vignettes (English and Spanish).
