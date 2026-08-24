test_that("the bundled fixture covers the study areas and needs no network", {
  land <- coastline_fixture()
  expect_s3_class(land, "sf")
  expect_gt(nrow(land), 0)
})

test_that("land is resolved for an ordinary extent", {
  box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
                     crs = sf::st_crs(4326))
  land <- coastline(box)
  expect_s3_class(land, "sf")
  expect_gt(nrow(land), 0)
})

test_that("no land is only silent when it was asked for", {
  box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
                     crs = sf::st_crs(4326))
  expect_null(coastline(box, source = FALSE))
})

test_that("an extent with no land in it is distinguished from a missing source", {
  # These look identical on the figure and mean opposite things, so they must
  # not both come back as NULL.
  open_water <- sf::st_bbox(c(xmin = -68.6, ymin = 42.2, xmax = -68.4,
                              ymax = 42.4), crs = sf::st_crs(4326))
  land <- suppressWarnings(coastline(open_water))
  expect_s3_class(land, "sf")
  expect_equal(nrow(land), 0)

  expect_null(no_land_note(NULL, requested = FALSE))
  expect_match(no_land_note(NULL, requested = TRUE), "source was available")
  expect_match(no_land_note(land, requested = TRUE), "No land falls")
})

test_that("a named coastline file that is missing is an error, not a fallback", {
  # The caller said which coastline they wanted; drawing a different one
  # quietly is worse than stopping.
  expect_error(coastline(source = "nope/coast.shp"), "no coastline file")
})

test_that("a user's own sf object is used as given", {
  own <- coastline_fixture()
  box <- sf::st_bbox(own)
  expect_s3_class(coastline(box, source = own), "sf")
})

test_that("resolution is chosen from the width of the extent", {
  wide <- sf::st_bbox(c(xmin = -100, ymin = 20, xmax = -60, ymax = 50),
                      crs = sf::st_crs(4326))
  mid <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
                     crs = sf::st_crs(4326))
  bay <- sf::st_bbox(c(xmin = -66.65, ymin = 44.45, xmax = -66.25,
                       ymax = 44.85), crs = sf::st_crs(4326))

  expect_equal(natural_earth_scale(wide), "small")
  expect_equal(natural_earth_scale(mid), "medium")
  # A 30 km grid needs a 1:10m shoreline; anything coarser is visibly
  # generalised under the cells, which is the defect this threshold exists for.
  expect_equal(natural_earth_scale(bay), "large")
})

test_that("extent width is measured in km whatever the CRS", {
  box <- sf::st_bbox(c(xmin = -70, ymin = 43, xmax = -69, ymax = 44),
                     crs = sf::st_crs(4326))
  # a degree of longitude at 43.5N is about 81 km
  expect_equal(extent_width_km(box), 81, tolerance = 0.05)
  expect_equal(extent_width_km(sf::st_bbox(utm_grid())), 30)
})
