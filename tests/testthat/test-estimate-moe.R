test_that("estimate_fies computes exact variance decomposition and restores options", {
  df <- prepare_fies(sample_data = fies_sample, quiet = TRUE)

  old_opt <- getOption("survey.lonely.psu")
  options(survey.lonely.psu = "fail")
  on.exit(options(survey.lonely.psu = old_opt), add = TRUE)

  res_nat <- estimate_fies(df, by = NULL, indicator = "both", percent = FALSE)
  expect_identical(getOption("survey.lonely.psu"), "fail")

  expect_equal(nrow(res_nat), 2L)
  expect_equal(res_nat$se_total, sqrt(res_nat$se_s^2 + res_nat$se_m^2), tolerance = 1e-12)
  expect_true(all(res_nat$lower < res_nat$estimate & res_nat$upper > res_nat$estimate))

  res_pct <- estimate_fies(df, by = NULL, indicator = "mod_sev", percent = TRUE)
  expect_equal(res_pct$estimate[1], res_nat$estimate[1] * 100, tolerance = 1e-10)

  res_off <- estimate_fies(df, by = "official", indicator = "mod_sev")
  expect_true(all(c("National", "area", "natural_region", "department", "region_inei") %in% res_off$group))

  res_int <- estimate_fies(df, by = c("area", "poverty"), combine_by = TRUE, indicator = "mod_sev")
  expect_true("area x poverty" %in% res_int$group)
})
