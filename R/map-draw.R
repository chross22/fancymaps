## The one function that actually assembles a figure.
##
## Every drawing verb resolves its own scale and then hands the result here, so
## that extent, projection, layer order, furniture and caption are decided once
## for all of them. A verb that assembled its own would be a second place for
## the panels to stop matching.

assemble_map <- function(md, scales, crs, coastline = TRUE, region = NULL,
                         graticule = FALSE, title = NULL, subtitle = NULL,
                         caption = NULL, notes = list(), scalebar = TRUE,
                         north = TRUE, base_size = 12, theme = NULL,
                         expand = 0.02, extent = NULL) {
  md <- project_md(md, crs)
  box <- extent %||% map_extent(md, expand)

  # Resolved against the DRAWN extent rather than the data's, so the land
  # reaches the panel edge instead of stopping where the last cell does.
  land <- coastline(box, source = coastline, crs = crs)

  p <- ggplot2::ggplot() +
    value_layer(md) +
    land_layer(land) +
    region_layer(region, crs) +
    scales +
    coord_for(box, graticule)

  if (isTRUE(scalebar)) p <- p + scale_bar(box, base_size = base_size)
  if (isTRUE(north)) p <- p + north_arrow(box, base_size = base_size)

  p +
    ggplot2::labs(
      title = title, subtitle = subtitle,
      caption = build_caption(caption,
                              c(notes, list(no_land_note(land, coastline))))
    ) +
    (theme %||% theme_fancymap(base_size = base_size, graticule = graticule))
}

# The extent a set of maps share.
#
# `map_pair()` and `map_panels()` need every panel drawn on the same box, and
# the box has to be the union: taking one panel's extent would crop another's
# data, and letting each take its own is what stops them lining up.
shared_extent <- function(mds, expand = 0.02) {
  boxes <- lapply(mds, function(md) sf::st_bbox(md$geometry))
  crs <- sf::st_crs(boxes[[1]])
  padded_box(
    sf::st_bbox(
      c(xmin = min(vapply(boxes, function(b) b[["xmin"]], numeric(1))),
        ymin = min(vapply(boxes, function(b) b[["ymin"]], numeric(1))),
        xmax = max(vapply(boxes, function(b) b[["xmax"]], numeric(1))),
        ymax = max(vapply(boxes, function(b) b[["ymax"]], numeric(1)))),
      crs = crs),
    expand
  )
}
