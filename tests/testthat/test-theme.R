test_that("the map theme takes the axis furniture off", {
  th <- theme_fancymap()
  expect_s3_class(th$axis.title, "element_blank")
  expect_s3_class(th$axis.text, "element_blank")
  expect_s3_class(th$panel.grid, "element_blank")
})

test_that("a graticule brings back the numbers but not the titles", {
  # "x" and "y" name nothing on a map; the coordinates at least say where.
  th <- theme_fancymap(graticule = TRUE)
  expect_s3_class(th$axis.title, "element_blank")
  expect_false(inherits(th$axis.text, "element_blank"))
})

test_that("the colourbar is sized for the direction it is laid out in", {
  # A bar sized for a column and then laid along a row comes out a centimetre
  # long with its labels stacked on top of each other.
  tall <- theme_fancymap(legend = "right")
  wide <- theme_fancymap(legend = "bottom")
  expect_gt(as.numeric(wide$legend.key.width),
            as.numeric(tall$legend.key.width))
  expect_gt(as.numeric(tall$legend.key.height),
            as.numeric(wide$legend.key.height))
})

test_that("the panel has a background, so a missing cell is visibly missing", {
  expect_false(inherits(theme_fancymap()$panel.background, "element_blank"))
})
