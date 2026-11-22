test_that("module listing, cache helpers, and plot_fies execute cleanly", {
  mods <- fies_modules(2025)
  expect_s3_class(mods, "tbl_df")
  expect_true(all(c("2082", "34", "01", "02", "03", "04", "37") %in% mods$inei_module))
  expect_error(fies_modules(2024), "starts in 2025")

  items <- fies_items()
  expect_s3_class(items, "tbl_df")
  expect_equal(nrow(items), 8L)
  expect_equal(items$enaho_var, paste0("p130_", 1:8))

  tmp_c <- file.path(tempdir(), "fiesperu_test_cache")
  dir.create(file.path(tmp_c, "2025"), recursive = TRUE, showWarnings = FALSE)
  expect_true(clear_fies_cache(years = 2025, cache_dir = tmp_c, quiet = TRUE))
  expect_false(dir.exists(file.path(tmp_c, "2025")))

  df <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
  est <- estimate_fies(df, by = "area")

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    expect_s3_class(plot_fies(est, type = "prevalence"), "ggplot")
    expect_s3_class(plot_fies(df, type = "equating"), "ggplot")
    expect_s3_class(plot_fies(df, type = "items"), "ggplot")
    expect_s3_class(plot_fies(df, type = "scree"), "ggplot")
  }
})
