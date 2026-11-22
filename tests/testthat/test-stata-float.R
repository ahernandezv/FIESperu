test_that("as_stata_float matches 32-bit IEEE-754 float and preserves NA_real_", {
  x <- c(123.456789123456, NA_real_, NaN, 0, Inf, -Inf)
  y <- as_stata_float(x)

  expect_equal(y[1], 123.456787109375, tolerance = 1e-12)
  expect_true(is.na(y[2]) && !is.nan(y[2]))
  expect_true(is.nan(y[3]))
  expect_identical(y[4], 0)
  expect_identical(y[5], Inf)
  expect_identical(y[6], -Inf)
  expect_identical(as_stata_float(numeric(0)), numeric(0))
})
