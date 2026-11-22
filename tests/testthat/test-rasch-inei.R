test_that("prepare_fies and validate_rasch work offline on fies_sample", {
  df <- prepare_fies(sample_data = fies_sample, quiet = TRUE)

  expect_s3_class(df, "fies_tbl")
  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), nrow(fies_sample))
  expect_true(all(df$fies_rs >= 0L & df$fies_rs <= 8L))
  expect_true(all(df$pr_mod_sev >= df$pr_sev - 1e-12))
  expect_true(all(c("Lima Metropolitana", "Lima Region") %in% df$region_inei))

  val <- validate_rasch(df)
  expect_s3_class(val, "fies_validation")
  expect_equal(nrow(val$summary), 1L)
  expect_equal(nrow(val$items), 8L)
  expect_equal(nrow(val$raw_scores), 9L)
  expect_gt(val$summary$cor_global, 0.90)
  expect_equal(mean(val$items$severity_b), 0, tolerance = 1e-2)
})
