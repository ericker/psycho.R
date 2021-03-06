context("analyze.glmerMod")

test_that("If it works.", {
  # Fit
  require(lme4)

  fit <- lme4::glmer(vs ~ mpg + (1 | cyl), data = mtcars, family = "binomial")

  model <- psycho::analyze(fit)
  values <- psycho::values(model)
  testthat::expect_equal(round(values$mpg$Coef, 2), 0.17, tolerance = 0.02)

  # test summary
  summa <- summary(model, round = 2)
  testthat::expect_equal(nrow(summa), 2)
})
