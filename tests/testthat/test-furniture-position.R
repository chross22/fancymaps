# The corner each piece of furniture sits in is a property of where the DATA
# happens to sit, which no default can know. On the dsmfit effort map the north
# arrow lands over Nova Scotia at the default corner and there is nothing wrong
# with the default -- it is just wrong for that figure.

corner_of <- function(p, geom) {
  layers <- Filter(function(l) inherits(l$geom, geom), p$layers)
  expect_gt(length(layers), 0)
  layers[[1]]$data
}

test_that("the scale bar goes where it is asked", {
  g <- example_grid()
  suppressMessages({
    left <- map_surface(g, "density", scalebar_position = "bl", north = FALSE)
    right <- map_surface(g, "density", scalebar_position = "br", north = FALSE)
  })
  expect_lt(min(corner_of(left, "GeomRect")$xmin),
            min(corner_of(right, "GeomRect")$xmin))
})

test_that("the north arrow goes where it is asked", {
  g <- example_grid()
  suppressMessages({
    top <- map_surface(g, "density", north_position = "tr", scalebar = FALSE)
    bottom <- map_surface(g, "density", north_position = "br",
                          scalebar = FALSE)
  })
  expect_gt(min(corner_of(top, "GeomPolygon")$y),
            min(corner_of(bottom, "GeomPolygon")$y))
})

test_that("two pieces of furniture in one corner are warned about", {
  # Warned, not rearranged: moving one automatically trades a collision the
  # caller asked for against one they did not.
  g <- example_grid()
  expect_warning(
    suppressMessages(map_surface(g, "density", scalebar_position = "tr",
                                 north_position = "tr")),
    "top-right")
})

test_that("the warning names both pieces and a way out", {
  g <- example_grid()
  w <- tryCatch(
    suppressMessages(map_surface(g, "density", scalebar_position = "br",
                                 north_position = "br")),
    warning = conditionMessage)
  expect_match(w, "scalebar")
  expect_match(w, "north")
  expect_match(w, "north_position")
})

test_that("furniture in different corners is silent", {
  g <- example_grid()
  expect_no_warning(
    suppressMessages(map_surface(g, "density", scalebar_position = "bl",
                                 north_position = "tr")))
})

test_that("an inset counts as furniture for the collision check", {
  g <- example_grid()
  expect_warning(
    suppressMessages(map_surface(g, "density", inset = TRUE,
                                 inset_position = "bl")),
    "bottom-left")
})

test_that("furniture that is turned off cannot collide", {
  g <- example_grid()
  expect_no_warning(
    suppressMessages(map_surface(g, "density", scalebar_position = "tr",
                                 north = FALSE)))
})

test_that("every verb takes the positions", {
  g <- example_grid()
  suppressMessages({
    expect_s3_class(
      map_probability(g, "occupancy", scalebar_position = "tl",
                      north_position = "br"), "ggplot")
    expect_s3_class(
      map_diverging(g, "mess", midpoint = 0, scalebar_position = "tl",
                    north_position = "br"), "ggplot")
    expect_s3_class(
      map_pair(g, "density", "cv", scalebar_position = "tl",
               north_position = "br"), "patchwork")
    expect_s3_class(
      map_panels(g, c("density", "cv"), scalebar_position = "tl",
                 north_position = "br"), "patchwork")
  })

  pts <- sf::st_as_sf(
    data.frame(lon = runif(30, -70.4, -68.1), lat = runif(30, 42.6, 44.3)),
    coords = c("lon", "lat"), crs = 4326)
  suppressWarnings(expect_s3_class(
    map_effort(points = pts, scalebar_position = "tl", north_position = "br"),
    "ggplot"))
})
