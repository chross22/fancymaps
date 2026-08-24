# Every one of these builds the plot rather than only constructing it.
# ggplot2 defers almost everything to draw time, so a map that is returned
# without error is not a map that draws -- three of the defects this package
# was written to fix were invisible until something was rendered.
build <- function(p) {
  expect_silent(g <- ggplot2::ggplot_build(p))
  invisible(g)
}

test_that("a surface draws from an sf grid", {
  suppressMessages(p <- map_surface(example_grid(), "density"))
  expect_s3_class(p, "ggplot")
  build(p)
})

test_that("a surface draws from a plain data frame with coordinates", {
  # The form model output usually arrives in, once geometry has been dropped
  # for mgcv and a prediction rejoined.
  df <- data.frame(lon = runif(50, -70, -69), lat = runif(50, 43, 44),
                   density = rlnorm(50))
  # suppressWarnings: an 80 km extent asks for a 1:10m coastline, and the
  # warning that it is not installed is the behaviour tested in
  # test-coastline.R rather than a problem here.
  suppressWarnings(suppressMessages(p <- map_surface(df, "density", crs = 4326)))
  build(p)
})

test_that("a surface draws from values joined by id", {
  g <- example_grid()
  v <- stats::setNames(g$density, as.character(g$grid_id))
  suppressMessages(p <- map_surface(g, v, by = "grid_id", label = "density"))
  build(p)
})

test_that("a map without a value says so rather than drawing a blank", {
  expect_error(map_surface(example_grid()), "none was given")
})

test_that("a probability is drawn on a fixed 0-1 scale", {
  g <- example_grid()
  p <- map_probability(g, "occupancy")
  build(p)
  # fixed, not stretched to the data -- so 0.6 is the same colour in every
  # figure and a series of seasons can be compared
  fill <- p$scales$get_scales("fill")
  expect_equal(fill$limits, c(0, 1))
})

test_that("a probability map reports values that are not probabilities", {
  g <- example_grid()
  g$occupancy[1] <- 1.4
  expect_message(map_probability(g, "occupancy"), "outside")
})

test_that("a diverging map needs its midpoint", {
  expect_error(map_diverging(example_grid(), "mess"), "midpoint")
})

test_that("a diverging map draws, and reverses when asked", {
  g <- example_grid()
  build(map_diverging(g, "mess", midpoint = 0))
  build(map_diverging(g, "mess", midpoint = 0, direction = -1))
})

test_that("a pair shares one extent across both panels", {
  g <- example_grid()
  suppressMessages(p <- map_pair(g, "density", "cv"))
  expect_s3_class(p, "patchwork")

  panels <- lapply(list(p[[1]], p[[2]]), function(q) {
    ggplot2::ggplot_build(q)$layout$panel_params[[1]]
  })
  expect_equal(panels[[1]]$x_range, panels[[2]]$x_range)
  expect_equal(panels[[1]]$y_range, panels[[2]]$y_range)
})

test_that("a pair draws its furniture once", {
  # A second scale bar on an identical extent measures nothing new.
  g <- example_grid()
  suppressMessages(p <- map_pair(g, "density", "cv"))
  expect_gt(length(p[[1]]$layers), length(p[[2]]$layers))
})

test_that("panels share one scale, so one legend can be collected", {
  # The regression this exists for: given only shared LIMITS, each panel still
  # recomputed whether it was capped against its own values, the scales stopped
  # being identical, patchwork could not collect them, and the figure drew one
  # legend per panel -- exactly what a shared scale is for.
  g <- example_grid()
  vals <- cbind(a = g$density, b = g$density * 3, c = g$density * 0.2)
  suppressMessages(p <- map_panels(g, vals, label = "density"))

  fills <- lapply(seq_len(3), function(i) p[[i]]$scales$get_scales("fill"))
  expect_equal(fills[[1]]$limits, fills[[2]]$limits)
  expect_equal(fills[[1]]$limits, fills[[3]]$limits)
  expect_equal(fills[[1]]$get_labels(), fills[[2]]$get_labels())
  expect_equal(fills[[1]]$get_labels(), fills[[3]]$get_labels())
})

test_that("panels take their scale from every panel pooled", {
  g <- example_grid()
  vals <- cbind(a = g$density, b = g$density * 50)
  suppressMessages(p <- map_panels(g, vals, label = "density"))
  fill <- p[[1]]$scales$get_scales("fill")
  # the quiet panel's own maximum would be far below this
  expect_gt(fill$limits[2], max(g$density))
})

test_that("panels accept a matrix, a list, or column names", {
  g <- example_grid()
  suppressMessages({
    expect_s3_class(map_panels(g, c("density", "cv")), "patchwork")
    expect_s3_class(map_panels(g, list(one = g$density, two = g$cv)),
                    "patchwork")
  })
  expect_error(map_panels(g, 1:3), "map_surface")
})

test_that("up to three panels go in one row", {
  expect_equal(panel_columns(2), 2)
  expect_equal(panel_columns(3), 3)
  expect_equal(panel_columns(4), 2)
  expect_equal(panel_columns(6), 3)
})

test_that("effort draws points, and bins them when there are too many", {
  pts <- sf::st_as_sf(
    data.frame(lon = runif(100, -70.4, -68.1), lat = runif(100, 42.6, 44.3)),
    coords = c("lon", "lat"), crs = 4326)
  build(map_effort(points = pts))

  many <- sf::st_as_sf(
    data.frame(lon = runif(2500, -70.4, -68.1), lat = runif(2500, 42.6, 44.3)),
    coords = c("lon", "lat"), crs = 4326)
  expect_message(p <- map_effort(points = many), "hexagonal bins")
  build(p)
})

test_that("effort needs something to draw", {
  expect_error(map_effort(), "needs")
})

test_that("a region outline is a real sf layer, under any coordinate system", {
  # dsmfit draws this as a geom_path over raw ring coordinates because its
  # check maps use coord_quickmap(), under which a geom_sf layer errors. Every
  # map here uses coord_sf, so the workaround has nothing to work around.
  g <- example_grid()
  region <- sf::st_as_sfc(sf::st_bbox(g))
  suppressMessages(p <- map_surface(g, "density", region = region))
  build(p)
})

test_that("a map with no land drawn is captioned to say so", {
  g <- example_grid()
  # coastline = FALSE is the one way to get a map with no land and no
  # complaint, because it is the one case where nobody expected any.
  suppressMessages(p <- map_surface(g, "density", coastline = FALSE))
  expect_false(grepl("land|coastline", p$labels$caption %||% ""))

  open_water <- suppressWarnings(
    suppressMessages(map_surface(g, "density", coastline = coastline_fixture()[0, ])))
  expect_match(open_water$labels$caption, "No land")
})

test_that("hex_surface bins point values into polygons", {
  set.seed(4)
  pts <- sf::st_as_sf(
    data.frame(lon = runif(400, -70, -69), lat = runif(400, 43, 44),
               resid = rnorm(400, mean = 0.8)),
    coords = c("lon", "lat"), crs = 4326)

  hex <- hex_surface(pts, "resid", bins = 10, fun = "mean")
  expect_s3_class(hex, "sf")
  expect_true(all(c("value", "n") %in% names(hex)))
  expect_true(all(sf::st_geometry_type(hex) == "POLYGON"))
  expect_equal(sum(hex$n), 400)

  # and the point of it: the binned surface goes straight to a centred scale
  p <- map_diverging(hex, "value", midpoint = mean(hex$value),
                     coastline = FALSE)
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("hex_surface counts when given no value, and refuses polygons", {
  pts <- sf::st_as_sf(
    data.frame(lon = runif(50, -70, -69), lat = runif(50, 43, 44)),
    coords = c("lon", "lat"), crs = 4326)
  hex <- hex_surface(pts, bins = 8)
  expect_equal(sum(hex$value), 50)

  expect_error(hex_surface(example_grid(), "density"), "bins points")
})

test_that("a pair's capped panel says so on the panel", {
  # A single map appends the cap note to its caption and map_panels() to the
  # shared one, but a pair's panels resolve their scales separately -- and
  # without this the capped panel said nothing at all.
  g <- example_grid()
  g$density[1] <- 1e6
  suppressMessages(p <- map_pair(g, "density", "cv",
                                 labels = c("density", "cv")))
  expect_match(p[[1]]$labels$caption, "capped")
})
