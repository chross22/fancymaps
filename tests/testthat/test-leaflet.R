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

## Interactive pairs and series ------------------------------------------------

calls_of <- function(m, method) {
  Filter(function(c) identical(c$method, method), m$x$calls)
}

test_that("a series draws one layer per period and ONE legend", {
  # One legend because the scale is shared. A legend per period would be three
  # copies of the same thing, and it would move as you step through them --
  # which is the visual cue that says the panels are NOT on one scale.
  g <- example_grid()
  vals <- cbind(a = g$density, b = g$density * 2, c = g$density * 0.5)
  suppressMessages(m <- leaflet_panels(g, vals, label = "density"))

  expect_length(calls_of(m, "addPolygons"), 3)
  expect_length(calls_of(m, "addLegend"), 1)
})

test_that("a series is the same colour as the static panels, period for period", {
  # Both go through pooled_spec(), so a cell of a given value is the same
  # colour in the figure and in the widget.
  g <- example_grid()
  vals <- cbind(a = g$density, b = g$density * 2.5, c = g$density * 0.4)
  suppressMessages({
    static <- map_panels(g, vals, label = "density")
    interactive <- leaflet_panels(g, vals, label = "density")
  })

  layers <- calls_of(interactive, "addPolygons")
  for (i in 1:3) {
    drawn <- ggplot2::ggplot_build(static[[i]])$data[[1]]$fill
    expect_equal(toupper(drawn), toupper(layers[[i]]$args[[4]]$fillColor))
  }
})

test_that("a series shares one scale across its periods", {
  g <- example_grid()
  quiet <- g$density * 0.01
  loud <- g$density * 100
  suppressMessages(m <- leaflet_panels(g, cbind(quiet = quiet, loud = loud),
                                       label = "density"))

  layers <- calls_of(m, "addPolygons")
  # On its own scale the quiet panel would span the whole ramp; on the shared
  # one it sits at the bottom of it.
  quiet_cols <- unique(layers[[1]]$args[[4]]$fillColor)
  loud_cols <- unique(layers[[2]]$args[[4]]$fillColor)
  expect_false(any(quiet_cols %in% loud_cols))
})

test_that("a pair draws two layers, two legends, and switches between them", {
  g <- example_grid()
  suppressMessages(m <- leaflet_pair(g, "density", "cv"))

  expect_length(calls_of(m, "addPolygons"), 2)
  expect_length(calls_of(m, "addLegend"), 2)

  # baseGroups, not overlayGroups: two views of the same cells, exactly one
  # showing. Overlaid, the upper would hide the lower silently.
  control <- calls_of(m, "addLayersControl")[[1]]
  expect_equal(unlist(control$args[[1]]), c("density", "cv"))
  expect_length(unlist(control$args[[2]]), 0)
})

test_that("each legend of a pair is tagged so it can follow the control", {
  # leaflet's own addLegend(group=) binding listens for overlay events, which
  # baseGroups never fire -- so without this both legends stay on screen and
  # one describes a layer that is not being drawn.
  g <- example_grid()
  suppressMessages(m <- leaflet_pair(g, "density", "cv"))
  classes <- vapply(calls_of(m, "addLegend"),
                    function(c) c$args[[1]]$className, character(1))
  expect_match(classes[1], "fancymaps-legend-1")
  expect_match(classes[2], "fancymaps-legend-2")
})

test_that("a pair refuses panels that are not the same cells", {
  g <- example_grid()
  expect_error(
    suppressMessages(leaflet_pair(g, "density", g$cv[1:50],
                                  uncertainty_from = g[1:50, ])),
    "different numbers of features")
})

test_that("a pair takes a diverging uncertainty panel", {
  g <- example_grid()
  suppressMessages(
    m <- leaflet_pair(g, "density", "mess", uncertainty_kind = "diverging",
                      uncertainty_direction = -1))
  expect_s3_class(m, "leaflet")
  expect_length(calls_of(m, "addPolygons"), 2)
})

test_that("a series accepts a matrix, a list, or column names", {
  g <- example_grid()
  suppressMessages({
    expect_s3_class(leaflet_panels(g, c("density", "cv")), "leaflet")
    expect_s3_class(leaflet_panels(g, list(one = g$density, two = g$cv)),
                    "leaflet")
  })
})

test_that("group names survive being written into JavaScript", {
  # Group names are whatever labels the caller passed, so they can carry
  # quotes and backslashes.
  expect_equal(js_string("plain"), "'plain'")
  expect_equal(js_string("it's"), "'it\\'s'")
  expect_equal(js_string("a\\b"), "'a\\\\b'")
})
