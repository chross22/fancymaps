skip_if_not_installed("leaflet")
skip_if_not_installed("htmltools")

# The claim these functions exist to make: the interactive map and the static
# map are the same decisions rendered twice, so a cell is the SAME COLOUR in
# both. Anything less and a reader who has seen both has been told two things.
#
# It is worth testing at this precision -- exact hex equality -- because the way
# it breaks is invisible. The first version used 32 palette stops where the
# ggplot2 scale used 33, and the colours differed in the last hex digit: not
# distinguishable on screen, and still a different colour for the same number.
expect_same_colours <- function(static, values, spec, palette, direction = 1) {
  drawn <- ggplot2::ggplot_build(static)$data[[1]]$fill
  interactive <- value_colours(values, spec, palette, direction)
  expect_equal(toupper(drawn), toupper(interactive))
}

test_that("a surface is the same colour in both renderers", {
  g <- example_grid()
  suppressMessages({
    spec <- surface_scale(g$density)
    p <- map_surface(g, "density")
  })
  expect_same_colours(p, g$density, spec, "sequential")
})

test_that("a probability is the same colour in both renderers", {
  g <- example_grid()
  expect_same_colours(map_probability(g, "occupancy"), g$occupancy,
                      list(limits = c(0, 1), transform = "identity"), "bounded")
})

test_that("a diverging surface is the same colour in both renderers", {
  g <- example_grid()
  for (direction in c(1, -1)) {
    spec <- diverging_scale(g$mess, midpoint = 0)
    spec$rescaler <- diverging_rescaler(0)
    expect_same_colours(map_diverging(g, "mess", midpoint = 0,
                                      direction = direction),
                        g$mess, spec, "diverging", direction)
  }
})

test_that("a midpoint away from zero survives into the interactive map", {
  g <- example_grid()
  mid <- mean(g$residual)
  spec <- diverging_scale(g$residual, midpoint = mid)
  spec$rescaler <- diverging_rescaler(mid)
  expect_same_colours(map_diverging(g, "residual", midpoint = mid),
                      g$residual, spec, "diverging")
})

test_that("values past the cap sit at the cap rather than going grey", {
  # Grey already means "no prediction here", so a censored cell would be
  # reporting the wrong thing.
  spec <- list(limits = c(0, 1), transform = "identity")
  over <- value_colours(5, spec, "sequential", 1)
  at_top <- value_colours(1, spec, "sequential", 1)
  expect_equal(over, at_top)
  expect_equal(value_colours(NA_real_, spec, "sequential", 1), "#EBEBEB")
})

test_that("the widgets build for every geometry type", {
  g <- example_grid()
  suppressMessages(expect_s3_class(leaflet_surface(g, "density"), "leaflet"))
  expect_s3_class(leaflet_probability(g, "occupancy"), "leaflet")
  expect_s3_class(leaflet_diverging(g, "mess", midpoint = 0), "leaflet")

  pts <- sf::st_as_sf(
    data.frame(lon = runif(20, -70, -69), lat = runif(20, 43, 44),
               v = runif(20)), coords = c("lon", "lat"), crs = 4326)
  expect_s3_class(leaflet_surface(pts, "v"), "leaflet")
})

test_that("the interactive map works in the projected CRS the model was fitted in", {
  # leaflet takes WGS84, so this is transformed rather than refused -- the
  # projection question is answered by the tile layer, not by display_crs().
  suppressMessages(m <- leaflet_surface(utm_grid(), "density"))
  expect_s3_class(m, "leaflet")
})

test_that("a raster says which function to use rather than failing obscurely", {
  skip_if_not_installed("terra")
  r <- terra::rast(nrows = 4, ncols = 4, xmin = -70, xmax = -69,
                   ymin = 43, ymax = 44, crs = "EPSG:4326",
                   vals = runif(16))
  expect_error(leaflet_surface(r), "addRasterImage")
})

test_that("popups carry the key and the value, and extra columns on request", {
  g <- example_grid()
  md <- as_map_data(g, "density")
  labels <- popup_labels(md, popup = "cv", by = "grid_id")
  expect_match(labels[1], "grid_id")
  expect_match(labels[1], "density")
  expect_match(labels[1], "cv")

  expect_null(popup_labels(md, popup = FALSE, by = "grid_id"))
})

test_that("the interactive legend says the scale was capped, like the static one", {
  # On a linear scale the breaks are worked out here rather than taken from
  # ggplot2, and pretty() stops below the cap -- so the static legend read
  # ">= 0.879" and this one stopped at 0.8 with no sign anything was capped.
  spec <- surface_scale(c(stats::runif(99, 0, 1), 500), transform = "identity")
  expect_true(spec$squished)

  labels <- leaflet_legend_labels(spec)
  expect_match(labels[length(labels)], "≥")
})

test_that("an uncapped legend has nothing to mark", {
  # Limits given explicitly, because the DEFAULT probs cut the top percentile
  # and so cap almost any continuous data -- which is the intended behaviour
  # and is why the marking has to be reliable rather than rare.
  v <- stats::runif(100)
  spec <- surface_scale(v, transform = "identity", limits = range(v))
  expect_false(spec$squished)
  expect_false(any(grepl("≥", leaflet_legend_labels(spec))))
})
