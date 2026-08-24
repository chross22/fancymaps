test_that("projected data keeps its own projection", {
  g <- utm_grid()
  expect_equal(display_crs(g), sf::st_crs(32619))
})

test_that("geographic data is projected, and centred on itself", {
  crs <- display_crs(lonlat_points())
  expect_false(sf::st_is_longlat(crs))
  # centred on the data, not on a continent
  expect_match(crs$proj4string, "laea")
  expect_match(crs$proj4string, "lat_0=43.5")
})

test_that("a CRS that is given always wins", {
  expect_equal(display_crs(lonlat_points(), crs = 4326), sf::st_crs(4326))
  expect_equal(display_crs(utm_grid(), crs = 4326), sf::st_crs(4326))
})

test_that("data with no CRS is refused rather than guessed at", {
  # Guessing here means guessing between degrees and metres, and being wrong
  # is not a small error.
  bare <- sf::st_sf(geometry = sf::st_sfc(sf::st_point(c(1, 2))))
  expect_error(display_crs(bare), "no coordinate reference system")
  expect_error(equal_area_crs(bare), "cannot be computed")
})

test_that("the same study area resolves to the same projection string", {
  # Two datasets that differ slightly must not end up in two projections that
  # differ in the ninth decimal: sf skips a transform when the CRS compares
  # equal, so near-identical CRSs mean the layers are rounded differently.
  a <- lonlat_points(20)
  b <- lonlat_points(50)
  expect_equal(display_crs(a), display_crs(b))
})

test_that("area is computed equal-area, not on lon/lat", {
  # A degree box at 43N: about 82 km by 111 km, so roughly 9,100 km2. Getting
  # this from the display CRS or from the raw degrees is the bug the split
  # between display_crs() and equal_area_crs() exists to prevent.
  box <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(cbind(c(-70, -69, -69, -70, -70),
                              c(43, 43, 44, 44, 43)))), crs = 4326))
  expect_equal(area_km2(box), 9100, tolerance = 0.02)
})

test_that("area does not depend on the CRS the data arrived in", {
  box <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(cbind(c(-70, -69, -69, -70, -70),
                              c(43, 43, 44, 44, 43)))), crs = 4326))
  expect_equal(area_km2(box),
               area_km2(sf::st_transform(box, 32619)),
               tolerance = 0.001)
})
