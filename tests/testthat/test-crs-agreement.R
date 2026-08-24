# `crs =` on a data frame is the one place in this package where a coordinate
# system is ASSERTED rather than read, and a wrong assertion is caught nowhere
# downstream: sf attaches whatever it is told, every transform after that is
# arithmetically valid, and the map draws. It is just a map of somewhere else.

test_that("projected coordinates declared as lon/lat are refused", {
  df <- data.frame(x = c(400000, 405000), y = c(4800000, 4805000), v = 1:2)
  expect_error(as_map_data(df, "v", crs = 4326), "cannot pass 180")
})

test_that("lon/lat declared as projected is warned about", {
  # A warning rather than an error: a projected CRS in degree-sized units is
  # unlikely rather than impossible.
  df <- data.frame(x = c(-70, -69), y = c(43, 44), v = 1:2)
  expect_warning(as_map_data(df, "v", crs = 32619), "lon/lat|longitude")
})

test_that("coordinates that match their stated CRS pass", {
  expect_silent(as_map_data(
    data.frame(x = c(-70, -69), y = c(43, 44), v = 1:2), "v", crs = 4326))
  expect_silent(as_map_data(
    data.frame(x = c(400000, 405000), y = c(4800000, 4805000), v = 1:2),
    "v", crs = 32619))
})

test_that("the check cannot be fooled by missing coordinates", {
  df <- data.frame(x = c(NA, 405000), y = c(NA, 4805000), v = 1:2)
  expect_error(as_map_data(df, "v", crs = 4326), "cannot pass 180")
})

test_that("an all-missing frame says so instead of leaking sf's warnings", {
  # Left to sf this emitted "no non-missing arguments to min; returning Inf"
  # three times, which names neither the column nor the fix.
  df <- data.frame(x = c(NA_real_, NA_real_), y = c(NA_real_, NA_real_),
                   v = 1:2)
  expect_error(as_map_data(df, "v", crs = 4326), "entirely NA")
})

test_that("some missing coordinates are kept, because a prediction frame has them", {
  df <- data.frame(x = c(-70, NA, -69), y = c(43, NA, 44), v = 1:3)
  expect_silent(md <- as_map_data(df, "v", crs = 4326))
  expect_length(md$value, 3)
})

test_that("a shared extent refuses layers in different coordinate systems", {
  # Should never fire -- every caller projects first -- which is why it is
  # asserted. The symptom otherwise is a blank panel, not an error.
  a <- as_map_data(lonlat_points(), "n_seen")
  b <- as_map_data(utm_grid(), "density")
  expect_error(shared_extent(list(a, b)), "different coordinate systems")
})

test_that("a pair refuses panels that are not the same cells", {
  # A pair is read cell by cell. Two different grids over the same water still
  # draw, and the figure looks entirely normal.
  g <- example_grid()
  expect_error(
    suppressMessages(map_pair(g, "density", g$cv[1:50],
                              uncertainty_from = g[1:50, ])),
    "different numbers of features")
})

test_that("a pair from one object needs no alignment check", {
  g <- example_grid()
  suppressMessages(expect_s3_class(map_pair(g, "density", "cv"), "patchwork"))
})

test_that("a pair warns when a second object covers a different extent", {
  g <- example_grid()
  moved <- g
  sf::st_geometry(moved) <- sf::st_geometry(moved) + c(2, 0)
  sf::st_crs(moved) <- 4326
  expect_warning(
    suppressMessages(map_pair(g, "density", "cv", uncertainty_from = moved)),
    "different extent")
})

test_that("data with no CRS at all is refused, not defaulted to lon/lat", {
  bare <- sf::st_sf(v = 1, geometry = sf::st_sfc(sf::st_point(c(-70, 43))))
  expect_error(map_surface(bare, "v"), "no coordinate reference system")
})
