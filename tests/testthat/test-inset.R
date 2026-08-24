test_that("an inset is built for an ordinary extent", {
  ins <- locator_inset(example_grid())
  expect_s3_class(ins, "ggplot")
  expect_silent(ggplot2::ggplot_build(ins))
})

test_that("the inset widens past its starting zoom to find land", {
  # zoom is a starting point, not a setting: an inset showing nothing but water
  # orients nobody, so it doubles until there is something to recognise.
  g <- example_grid()
  expect_s3_class(locator_inset(g, zoom = 1.2), "ggplot")
})

test_that("an inset with no land to find is dropped, not drawn empty", {
  # An empty inset is worse than none: it looks like a rendering failure and it
  # still takes up the corner.
  pacific <- sf::st_sf(v = 1, geometry = sf::st_sfc(
    sf::st_point(c(-140, -20)), crs = 4326))
  expect_null(suppressWarnings(
    locator_inset(pacific, zoom = 2, max_zoom = 4)))
})

test_that("a map still draws when its inset could not be built", {
  pacific <- sf::st_sf(
    v = c(1, 2),
    geometry = sf::st_sfc(sf::st_point(c(-140, -20)),
                          sf::st_point(c(-139.9, -19.9)), crs = 4326))
  p <- suppressWarnings(map_surface(pacific, "v", inset = TRUE,
                                    coastline = FALSE))
  expect_s3_class(p, "ggplot")
})

test_that("the inset extent is squared, and only ever grown", {
  box <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 100, ymax = 20),
                     crs = sf::st_crs(32619))
  sq <- square_off(box)
  expect_equal(sq[["xmax"]] - sq[["xmin"]], sq[["ymax"]] - sq[["ymin"]])
  # nothing that was in view leaves it
  expect_lte(sq[["xmin"]], box[["xmin"]])
  expect_gte(sq[["xmax"]], box[["xmax"]])
  expect_lte(sq[["ymin"]], box[["ymin"]])
  expect_gte(sq[["ymax"]], box[["ymax"]])
})

test_that("a tiny extent gets a visible marker, on the same centre", {
  # A 32 km box on a 2,000 km inset is thinner than the line drawing it.
  small <- sf::st_bbox(c(xmin = 49, ymin = 49, xmax = 51, ymax = 51),
                       crs = sf::st_crs(32619))
  inset <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 100, ymax = 100),
                       crs = sf::st_crs(32619))
  marked <- sf::st_bbox(extent_marker(small, inset))

  expect_gt(marked[["xmax"]] - marked[["xmin"]], 2)
  expect_equal(unname((marked[["xmin"]] + marked[["xmax"]]) / 2), 50)
  expect_equal(unname((marked[["ymin"]] + marked[["ymax"]]) / 2), 50)
})

test_that("an extent already big enough is drawn to scale", {
  big <- sf::st_bbox(c(xmin = 20, ymin = 20, xmax = 80, ymax = 80),
                     crs = sf::st_crs(32619))
  inset <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 100, ymax = 100),
                       crs = sf::st_crs(32619))
  expect_equal(as.numeric(sf::st_bbox(extent_marker(big, inset))),
               as.numeric(big))
})

test_that("the inset rectangle is square in data units", {
  # coord_sf makes a metre on x the same length on the page as a metre on y, so
  # a square in data units is a square on the page whatever shape the panel is.
  # Taking equal FRACTIONS of width and height instead gave a rectangle as
  # elongated as the panel, and the coastline inside came out as vertical bands.
  box <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 1000, ymax = 200),
                     crs = sf::st_crs(32619))
  # geom_params, not the layer itself: annotation_custom() keeps xmin/xmax
  # there, and reading them off the layer gives NULL -- so `NULL - NULL` is
  # numeric(0) and the comparison passes without comparing anything.
  at <- inset_layer(locator_inset(example_grid()), box, "br",
                    size = 0.3)$geom_params
  expect_equal(at$xmax - at$xmin, at$ymax - at$ymin)
})

test_that("the inset picks its own projection, not the map's", {
  # An inset is many times wider than its map, and the projection that was
  # honest over 300 km need not be over 2,400: drawing an inset of the Gulf of
  # Maine in EPSG:32619 renders the northeast seaboard as vertical bands of
  # land, because most of that extent is many UTM zones from the central
  # meridian.
  g <- utm_grid()
  expect_equal(sf::st_crs(g), sf::st_crs(32619))

  ins <- locator_inset(g)
  drawn <- ggplot2::ggplot_build(ins)$layout$panel_params[[1]]$crs
  expect_false(drawn == sf::st_crs(32619))
  expect_match(drawn$proj4string, "laea")
})

test_that("the inset extent and the rectangle it goes in have the same aspect", {
  # This is the whole of why the first version rendered the northeast seaboard
  # as vertical bands. coord_sf() will not distort a map to fill a shape it was
  # given -- so a square extent placed into an elongated rectangle, or the
  # reverse, comes out compressed along one axis. Squaring both is what fixes
  # it, and it only works while they stay squared together.
  box <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 1000, ymax = 200),
                     crs = sf::st_crs(32619))
  at <- inset_layer(locator_inset(example_grid()), box, "br")$geom_params
  rect_aspect <- (at$ymax - at$ymin) / (at$xmax - at$xmin)

  inset_box <- square_off(sf::st_bbox(
    c(xmin = 0, ymin = 0, xmax = 100, ymax = 40), crs = sf::st_crs(32619)))
  extent_aspect <- (inset_box[["ymax"]] - inset_box[["ymin"]]) /
    (inset_box[["xmax"]] - inset_box[["xmin"]])

  expect_equal(rect_aspect, 1)
  expect_equal(unname(extent_aspect), 1)
})

test_that("a map with an inset is still a plain ggplot", {
  # A verb that returned a ggplot most of the time and a patchwork when one
  # argument was set would break every downstream `+` a caller had written.
  suppressMessages(p <- map_surface(example_grid(), "density", inset = TRUE))
  expect_s3_class(p, "ggplot")
  expect_false(inherits(p, "patchwork"))
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("the inset goes in the corner it was asked for", {
  g <- example_grid()
  box <- sf::st_bbox(g)
  ins <- locator_inset(g)
  at <- function(pos) inset_layer(ins, box, pos)$geom_params

  expect_lt(at("bl")$xmin, at("br")$xmin)
  expect_lt(at("bl")$ymin, at("tl")$ymin)
})
