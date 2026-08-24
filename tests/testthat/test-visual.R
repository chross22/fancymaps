# Visual regression.
#
# The convention this package inherited is that every figure change is rendered
# and looked at before it is committed, because three of the defects it was
# written to fix were invisible in code review and obvious in a PNG. Four more
# were, during the writing: two legends where there should have been one, a
# colourbar sized for the wrong orientation, a clipped north arrow, and an inset
# coastline drawn as vertical bands.
#
# Every one of those passed its unit tests. They were bugs in what the figure
# LOOKED like, and the only thing that catches those automatically is comparing
# the drawing.
#
# WHAT THESE SNAPSHOTS ARE FOR: telling the difference between a change and an
# accident. When one fails, look at the diff -- `testthat::snapshot_review()` --
# and either fix the figure or accept the new one. A failing snapshot is not by
# itself a bug report.
#
# WHAT THEY ARE NOT: a check that the figure is CORRECT. A snapshot of a broken
# map is a stable snapshot of a broken map. That is what the rest of the suite
# and a human looking at a PNG are for.

# A NOTE ON PLATFORMS. These snapshots are SVG, and svglite writes text with
# positions resolved from the system's font metrics -- so a first run on a
# machine whose fonts differ from the one the baselines were generated on
# reports diffs that are typography, not regressions. The baselines here were
# generated on macOS with R 4.6.1, vdiffr 1.0.9 and svglite 2.2.2. Continuous
# integration should pin one image and regenerate on that image once, rather
# than accepting whichever platform ran last.
#
# That caveat is why these are additional to the rest of the suite and not a
# replacement for any of it: the properties that must hold everywhere are
# asserted directly, in `test-maps.R` and its neighbours, against numbers rather
# than against pixels.

skip_on_cran()
skip_if_not_installed("vdiffr")

# The coastline is pinned to the bundled fixture in every one of these, and it
# is not a detail.
#
# `example_grid()` is 194 km across, which is under the 200 km where
# `coastline()` asks for a 1:10m shoreline -- so left to resolve itself it draws
# Natural Earth large where `rnaturalearthhires` is installed and medium where
# it is not, and the snapshots would differ by which optional package the
# machine happens to have. Pinning makes the figure a function of this
# package's code and nothing else, which is the only thing worth regressing on.
fixture <- coastline_fixture()

grid <- example_grid()

test_that("a predicted surface looks right", {
  # Skewed, so the scale goes log and the legend says so, with the top break
  # marked as a cap.
  suppressMessages(
    p <- map_surface(grid, "density", label = "animals per km2",
                     title = "Predicted density", coastline = fixture))
  vdiffr::expect_doppelganger("surface", p)
})

test_that("a surface on a fixed linear scale looks right", {
  p <- map_surface(grid, "density", transform = "identity",
                   limits = c(0, 3), coastline = fixture)
  vdiffr::expect_doppelganger("surface-linear", p)
})

test_that("a probability looks right", {
  # Fixed at 0 and 1, and near-blank at the bottom, so a cell at 0.02 looks
  # like a cell at 0.
  p <- map_probability(grid, "occupancy", label = "occupancy",
                       coastline = fixture)
  vdiffr::expect_doppelganger("probability", p)
})

test_that("a diverging surface looks right in both directions", {
  vdiffr::expect_doppelganger(
    "diverging", map_diverging(grid, "mess", midpoint = 0, label = "MESS",
                               coastline = fixture))
  vdiffr::expect_doppelganger(
    "diverging-reversed",
    map_diverging(grid, "mess", midpoint = 0, direction = -1, label = "MESS",
                  coastline = fixture))
})

test_that("a diverging surface centred off zero looks right", {
  # The case that paints every cell the same colour when it is centred on zero
  # instead.
  p <- map_diverging(grid, "residual", midpoint = mean(grid$residual),
                     label = "deviance residual", coastline = fixture)
  vdiffr::expect_doppelganger("diverging-off-centre", p)
})

test_that("a pair looks right", {
  # Aligned panels, shared extent, two separate legends, furniture on the left
  # panel only.
  suppressMessages(
    p <- map_pair(grid, "density", "mess", uncertainty_kind = "diverging",
                  uncertainty_direction = -1,
                  labels = c("animals per km2", "MESS"),
                  titles = c("Predicted density", "How familiar"),
                  coastline = fixture))
  vdiffr::expect_doppelganger("pair", p)
})

test_that("panels look right, with one collected legend", {
  # The regression that motivated this file most directly: given only shared
  # limits, each panel recomputed its own capping, the scales stopped being
  # identical, and patchwork drew one legend per panel.
  vals <- cbind(spring = grid$density, summer = grid$density * 2.5,
                autumn = grid$density * 0.4)
  suppressMessages(
    p <- map_panels(grid, vals, label = "animals per km2",
                    coastline = fixture))
  vdiffr::expect_doppelganger("panels", p)
})

test_that("effort looks right, drawn and binned", {
  set.seed(11)
  pts <- sf::st_as_sf(
    data.frame(lon = stats::runif(200, -70.3, -68.2),
               lat = stats::runif(200, 42.7, 44.2)),
    coords = c("lon", "lat"), crs = 4326)

  vdiffr::expect_doppelganger(
    "effort-points", map_effort(points = pts, coastline = fixture))
  suppressMessages(
    binned <- map_effort(points = pts, bin = TRUE, bins = 15,
                         coastline = fixture))
  vdiffr::expect_doppelganger("effort-binned", binned)
})

test_that("the locator inset looks right", {
  # Its own projection, its extent widened until land appeared, and the marker
  # enlarged to something visible.
  suppressMessages(
    p <- map_surface(grid, "density", coastline = fixture, inset = fixture,
                     north = FALSE))
  vdiffr::expect_doppelganger("inset", p)
})

test_that("furniture goes where it is placed", {
  suppressMessages(
    p <- map_surface(grid, "density", coastline = fixture,
                     scalebar_position = "tr", north_position = "bl"))
  vdiffr::expect_doppelganger("furniture-moved", p)
})

test_that("a graticule looks right when it is asked for", {
  suppressMessages(
    p <- map_surface(grid, "density", coastline = fixture, graticule = TRUE))
  vdiffr::expect_doppelganger("graticule", p)
})

test_that("a map with no land looks right", {
  # Captioned, so a reader can tell it from a coastline that failed to load.
  suppressMessages(
    p <- map_surface(grid, "density", coastline = fixture[0, ]))
  vdiffr::expect_doppelganger("no-land", p)
})
