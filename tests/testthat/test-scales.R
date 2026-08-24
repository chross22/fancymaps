test_that("a skewed quantity gets a log scale, and it is reported", {
  set.seed(1)
  skewed <- c(rep(0, 200), stats::rexp(400, rate = 20))
  expect_message(spec <- surface_scale(skewed), "log")
  expect_s3_class(spec$transform, "transform")
})

test_that("a quantity that does not need a transform does not get one", {
  flat <- seq(8, 12, length.out = 100)
  expect_silent(spec <- surface_scale(flat))
  expect_equal(spec$transform, "identity")
})

test_that("the log offset comes from the data and is stated", {
  # log(x + 1) would mean something different depending on whether the units
  # are animals per km2 or per m2, so the offset is a percentile of the
  # positive values rather than a constant.
  v <- c(0, 0, 0.01, 0.02, 5, 100)
  expect_message(spec <- surface_scale(v), "0\\.01")
  expect_match(spec$note, "^log scale, \\+")
})

test_that("limits come from a quantile and the excess is capped, not dropped", {
  set.seed(2)
  v <- c(stats::runif(99, 0, 1), 500)
  spec <- surface_scale(v, transform = "identity")
  expect_lt(spec$limits[2], 500)
  expect_true(spec$squished)
  # capped, because a censored cell goes grey and grey already means "no
  # prediction here"
  expect_match(squish_note(spec, "x"), "drawn at the cap")
})

test_that("the legend says the scale was capped", {
  spec <- surface_scale(c(stats::runif(99, 0, 1), 500), transform = "identity")
  labels <- spec$labels(c(spec$limits[1], spec$limits[2]))
  expect_match(labels[2], "≥")
})

test_that("breaks are round numbers in the original units", {
  # Round in the space the READER is in. Breaks that are round in transformed
  # space are round in a space nobody is looking at.
  spec <- surface_scale(c(0.001, 0.01, 0.1, 1, 10, 100), transform = "log",
                        limits = c(0.001, 100))
  expect_false(spec$squished)
  expect_true(all(spec$breaks %in% as.vector(outer(c(1, 2, 5), 10^(-4:4)))))
})

test_that("the cap is the only break allowed off the 1-2-5 sequence", {
  # It has to be: it is where the scale actually stops, and a round number
  # below it would leave the top of the bar unlabelled.
  spec <- surface_scale(c(0.001, 0.01, 0.1, 1, 10, 100), transform = "log")
  expect_true(spec$squished)
  round_ones <- utils::head(spec$breaks, -1)
  expect_true(all(round_ones %in% as.vector(outer(c(1, 2, 5), 10^(-4:4)))))
  expect_equal(spec$breaks[length(spec$breaks)], spec$limits[2])
})

test_that("labels never come out in scientific notation", {
  # "5e-04" is the same number as "0.0005" in a form nobody reads off a map.
  spec <- surface_scale(c(0.0005, 0.5), transform = "log")
  expect_false(any(grepl("e[-+]", spec$labels(c(0.0005, 0.002, 0.5)))))
})

test_that("a capped scale still fits four labels", {
  spec <- surface_scale(c(stats::rlnorm(500, -4, 2), 1e6), transform = "log")
  expect_lte(length(spec$breaks), 4)
  expect_equal(spec$breaks[length(spec$breaks)], spec$limits[2])
})

test_that("a degenerate range still draws a legend", {
  spec <- surface_scale(rep(3, 10))
  expect_gt(diff(spec$limits), 0)
})

test_that("a diverging scale refuses to invent its own midpoint", {
  # The middle of the range is what ggplot2 falls back to and it is almost
  # never the meaning.
  expect_error(diverging_scale(rnorm(10)), "no sensible default")
})

test_that("diverging limits are symmetric about the midpoint", {
  v <- c(rnorm(200, 5, 3), rnorm(10, -20, 5))
  spec <- diverging_scale(v, midpoint = 0)
  expect_equal(mean(spec$limits), 0)

  off <- diverging_scale(v, midpoint = 5)
  expect_equal(mean(off$limits), 5)
})

test_that("the rescaler puts the neutral colour at the midpoint", {
  # Not at the middle of the limits: those coincide here only because
  # diverging_scale() made them symmetric, and the two facts stay independent.
  r <- diverging_rescaler(4)
  expect_equal(r(4, from = c(0, 10)), 0.5)
  expect_equal(r(4, from = c(-2, 4)), 0.5)
})

test_that("a midpoint away from zero is named in the legend", {
  # Deviance residuals do not average zero, and this is what says so.
  spec <- diverging_scale(rnorm(100, 0.8), midpoint = 0.8)
  expect_match(spec$note, "centred on")
  expect_null(diverging_scale(rnorm(100), midpoint = 0)$note)
})
