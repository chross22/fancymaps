## The one function that actually assembles a figure.
##
## Every drawing verb resolves its own scale and then hands the result here, so
## that extent, projection, layer order, furniture and caption are decided once
## for all of them. A verb that assembled its own would be a second place for
## the panels to stop matching.

assemble_map <- function(md, scales, crs, coastline = TRUE, region = NULL,
                         graticule = FALSE, title = NULL, subtitle = NULL,
                         caption = NULL, notes = list(), scalebar = TRUE,
                         north = TRUE, scalebar_position = "bl",
                         north_position = "tr", inset = FALSE,
                         inset_position = "br", inset_size = 0.3,
                         inset_zoom = 8, base_size = 12,
                         theme = NULL, expand = 0.02, extent = NULL) {
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

  check_furniture_corners(
    c(scalebar = if (isTRUE(scalebar)) scalebar_position,
      north = if (isTRUE(north)) north_position,
      inset = if (!isFALSE(inset)) inset_position))

  if (isTRUE(scalebar)) {
    p <- p + scale_bar(box, position = scalebar_position,
                       base_size = base_size)
  }
  if (isTRUE(north)) {
    p <- p + north_arrow(box, position = north_position,
                         base_size = base_size)
  }
  if (!isFALSE(inset)) {
    # The inset resolves its own coastline, at its own width and so at its own
    # resolution -- a 1:10m shoreline is wasted on a map of the Gulf of Maine
    # drawn two centimetres across, and `coastline()` already knows that.
    #
    # `crs` is deliberately NOT passed. The inset picks its own -- an
    # equal-area projection centred on the study area -- because it is many
    # times wider than the map, and the projection that was honest over 300 km
    # need not be over 2,400. Handing it EPSG:32619 draws the northeast
    # seaboard as vertical bands of land, since most of that extent is many UTM
    # zones from the central meridian. Same fact `display_crs()` cites for not
    # choosing a zone automatically, met from the other direction.
    p <- p + inset_layer(
      locator_inset(box, zoom = inset_zoom,
                    coastline = if (isTRUE(inset)) coastline else inset),
      box, position = inset_position, size = inset_size)
  }

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

  # Every caller projects its layers before getting here, so this should never
  # fire -- which is exactly why it is worth asserting. Taking the first box's
  # CRS and silently treating the rest as if they shared it would produce an
  # extent in one coordinate system and data in another, and the symptom is a
  # blank panel rather than an error.
  crs <- sf::st_crs(boxes[[1]])
  disagree <- !vapply(boxes, function(b) sf::st_crs(b) == crs, logical(1))
  if (any(disagree)) {
    stop("these layers are in ", sum(disagree) + 1, " different coordinate ",
         "systems and one extent has to cover them all.
  This is an ",
         "internal error -- every layer should have been projected before ",
         "reaching here.", call. = FALSE)
  }
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

# Two pieces of furniture in one corner.
#
# Warned about rather than rearranged. Which corner is free depends on where
# the data happens to sit, and this has no way to know that -- so moving one
# automatically would trade a collision the caller asked for against one they
# did not. Naming both is enough to fix it in one edit.
check_furniture_corners <- function(positions) {
  positions <- positions[!vapply(positions, is.null, logical(1))]
  if (length(positions) < 2) return(invisible(NULL))

  positions <- unlist(positions)
  clashes <- unique(positions[duplicated(positions)])
  for (corner in clashes) {
    who <- names(positions)[positions == corner]
    warning("the ", paste(who, collapse = " and the "), " are both in the ",
            corner_name(corner), " corner and will overlap.\n  Move one with ",
            paste0("`", who[2], "_position = \"", other_corner(corner), "\"`"),
            ", or turn it off.", call. = FALSE)
  }
  invisible(NULL)
}

corner_name <- function(x) {
  c(bl = "bottom-left", br = "bottom-right",
    tl = "top-left", tr = "top-right")[[x]]
}

other_corner <- function(x) {
  c(bl = "br", br = "bl", tl = "tr", tr = "tl")[[x]]
}
