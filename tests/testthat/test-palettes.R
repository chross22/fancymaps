# The defining property of a sequential map scale: a reader can tell which end
# is which. If lightness is not monotone then two different values share a
# brightness, and under a deficiency that removes the hue difference between
# them they become the same colour.
#
# Which DIRECTION it runs in is a separate claim and is asserted separately.
# The sequential ramp darkens toward zero, so a cell with nothing in it is dark;
# the bounded one lightens toward zero, so a cell at probability 0.02 is nearly
# blank and weight arrives only as the value approaches certainty.
expect_monotone_luminance <- function(ramp, rising) {
  for (vision in c("normal", "protan", "deutan")) {
    lum <- luminance(simulate_cvd(ramp, vision))
    steps <- diff(lum)
    expect_true(all(if (rising) steps > 0 else steps < 0),
                info = paste("luminance is not monotone under", vision))
  }
}

test_that("the sequential ramp keeps its ordering under colour blindness", {
  expect_monotone_luminance(fancymap_palette("sequential", 24), rising = TRUE)
})

test_that("the bounded ramp keeps its ordering under colour blindness", {
  # Light at zero, dark at one -- the opposite direction from the sequential
  # ramp, and on purpose.
  expect_monotone_luminance(fancymap_palette("bounded", 24), rising = FALSE)
})

test_that("the two arms of the diverging ramp stay apart under colour blindness", {
  # The whole job of a diverging ramp is to say which side of the centre a
  # value is on. A red arm collapses toward the neutral middle under
  # deuteranopia, which is why this one is blue against orange -- and this is
  # the test that says so.
  ramp <- fancymap_palette("diverging", 21)
  low <- ramp[1:10]
  high <- rev(ramp[12:21])

  for (vision in c("normal", "protan", "deutan")) {
    d <- colour_distance(simulate_cvd(low, vision), simulate_cvd(high, vision))
    expect_true(all(d > 0.08),
                info = paste("arms collapse under", vision,
                             "- closest pair", signif(min(d), 3)))
  }
})

test_that("the ramps are asked for by name and interpolate to any length", {
  expect_length(fancymap_palette("sequential"), 8)
  expect_length(fancymap_palette("diverging", 3), 3)
  expect_length(fancymap_palette("bounded", 100), 100)
  expect_error(fancymap_palette("rainbow"))
})
