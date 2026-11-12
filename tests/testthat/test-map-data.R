test_that("a column on the object is found by name", {
  md <- as_map_data(utm_grid(), "density")
  expect_s3_class(md, "map_data")
  expect_equal(md$kind, "polygon")
  expect_equal(md$label, "density")
  expect_length(md$value, 36)
})

test_that("an unnamed vector is matched by position", {
  g <- utm_grid()
  md <- as_map_data(g, g$density * 2)
  expect_equal(md$value, g$density * 2)
})

test_that("a length mismatch is refused rather than recycled", {
  # Recycling here would produce a perfectly plausible map of the wrong
  # numbers, which is the failure this check exists to prevent.
  expect_error(as_map_data(utm_grid(), c(1, 2, 3)), "same length")
})

test_that("a named vector is joined by an id column", {
  g <- utm_grid()
  # deliberately out of order: the join has to reorder, not zip
  v <- stats::setNames(c(9, 8, 7), c("3", "1", "2"))
  md <- as_map_data(g[1:3, ], v, by = "grid_id")
  expect_equal(md$value, c(8, 7, 9))
})

test_that("a name that does not match is an error, not a hole in the map", {
  g <- utm_grid()
  v <- stats::setNames(c(1, 2), c("1", "999"))
  expect_error(as_map_data(g, v, by = "grid_id"), "999")
})

test_that("a non-unique key cannot join", {
  g <- utm_grid()
  g$grid_id <- rep(1L, nrow(g))
  expect_error(as_map_data(g, stats::setNames(1, "1"), by = "grid_id"),
               "not unique")
})

test_that("the id column is guessed, and says so when it cannot be", {
  g <- utm_grid()
  expect_no_error(as_map_data(g, stats::setNames(1, "1")))
  names(g)[names(g) == "grid_id"] <- "cell_number"
  expect_error(as_map_data(g, stats::setNames(1, "1")), "`by =`")
})

test_that("a data frame needs its CRS stated", {
  df <- data.frame(lon = c(-70, -69), lat = c(43, 44), v = c(1, 2))
  expect_error(as_map_data(df, "v"), "crs")
  expect_s3_class(as_map_data(df, "v", crs = 4326), "map_data")
})

test_that("coordinate columns are found under their usual spellings", {
  df <- data.frame(mid_lon = c(-70, -69), mid_lat = c(43, 44), v = c(1, 2))
  expect_equal(as_map_data(df, "v", crs = 4326)$kind, "point")

  bad <- data.frame(easting = 1, northing = 2, v = 3)
  expect_error(as_map_data(bad, "v", crs = 32619), "coords =")
})

test_that("a matrix says which column to draw rather than picking one", {
  g <- utm_grid()
  m <- cbind(a = g$density, b = g$density)
  expect_error(as_map_data(g, m), "map_panels")
})

test_that("mixed geometry types are refused", {
  mixed <- rbind(
    sf::st_sf(geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = 4326)),
    sf::st_sf(geometry = sf::st_sfc(
      sf::st_linestring(cbind(c(0, 1), c(0, 1))), crs = 4326)))
  expect_error(as_map_data(mixed), "one")
})

test_that("a non-numeric value is refused", {
  g <- utm_grid()
  g$name <- letters[seq_len(nrow(g))]
  expect_error(as_map_data(g, "name"), "continuous")
})

test_that("the legend label is the expression the caller wrote", {
  # `value_label()` once forced `value` before capturing it, so `enquo()` got
  # the number back and every legend built from an expression read "<dbl>".
  g <- utm_grid()
  expect_equal(as_map_data(g, g$density * 2)$label, "g$density * 2")
  suppressMessages(p <- map_surface(g, g$density, coastline = FALSE))
  expect_match(p$scales$get_scales("fill")$name, "^g\\$density")
})

test_that("a verb that leaves the label empty does not get the word 'value'", {
  # The verbs capture the caller's expression themselves. Going through the
  # exported as_map_data() captured it again one frame down, where all it saw
  # was the symbol `value`.
  g <- utm_grid()
  suppressMessages(
    p <- map_surface(g, sqrt(g$density), coastline = FALSE))
  expect_false(grepl("value", p$scales$get_scales("fill")$name))
})

test_that("a lon/lat raster is reprojected as cells, not as shifted pixels", {
  skip_if_not_installed("terra")
  r <- terra::rast(nrows = 8, ncols = 10, xmin = -70.5, xmax = -68.5,
                   ymin = 42.5, ymax = 44, crs = "EPSG:4326")
  terra::values(r) <- seq_len(80)
  md <- project_md(as_map_data(r), display_crs(as_map_data(r)))
  expect_equal(md$kind, "polygon")
  expect_length(md$geometry, 80)

  # geom_raster on reprojected centres warns at draw time that its pixels
  # were shifted; the polygon path has nothing to warn about.
  suppressMessages(p <- map_surface(r, coastline = FALSE))
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("a raster already in the display CRS keeps the raster path", {
  skip_if_not_installed("terra")
  r <- terra::rast(nrows = 4, ncols = 4, xmin = 400000, xmax = 420000,
                   ymin = 4800000, ymax = 4820000, crs = "EPSG:32619")
  terra::values(r) <- seq_len(16)
  md <- as_map_data(r)
  expect_equal(project_md(md, display_crs(md))$kind, "raster")
})
