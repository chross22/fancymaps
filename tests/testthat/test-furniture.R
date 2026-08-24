test_that("a scale bar is a round number of kilometres", {
  # "43 km" is a scale bar nobody can measure anything with.
  expect_equal(round_125(43), 50)
  expect_equal(round_125(1.3), 1)
  expect_equal(round_125(180), 200)
  expect_true(is.na(round_125(0)))
})

test_that("the bar is about a fifth of the panel, whatever the extent", {
  for (width_deg in c(0.4, 2.5, 12)) {
    box <- sf::st_bbox(c(xmin = -70, ymin = 43, xmax = -70 + width_deg,
                         ymax = 44), crs = sf::st_crs(4326))
    layers <- scale_bar(box)
    expect_length(layers, 3)
    label <- layers[[3]]$aes_params$label %||% layers[[3]]$data$label
    km <- as.numeric(gsub("[^0-9]", "", label))
    expect_true(km / extent_width_km(box) > 0.05)
    expect_true(km / extent_width_km(box) < 0.5)
  }
})

test_that("furniture sits inside the panel it is drawn in", {
  box <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 100, ymax = 100),
                     crs = sf::st_crs(32619))
  for (pos in c("bl", "br", "tl", "tr")) {
    at <- corner(box, pos, width = 10, height = 10)
    expect_gte(at$x, 0)
    expect_lte(at$x + 10, 100)
    expect_gte(at$y, 0)
    expect_lte(at$y + 10, 100)
  }
})

test_that("the north arrow keeps its label inside its own reserved height", {
  # Drawn above the arrow, the "N" pushed past the top of the panel and was
  # clipped at some figure sizes and not others.
  box <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 100, ymax = 100),
                     crs = sf::st_crs(32619))
  layers <- north_arrow(box)
  triangle <- layers[[1]]$data
  label <- layers[[2]]$data
  expect_lt(label$y, min(triangle$y))
  expect_lt(max(triangle$y), 100)
})
