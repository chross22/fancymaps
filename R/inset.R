## The locator inset.
##
## The defect this exists for: nothing on these maps says where they are. The
## extent is legible to someone who works in this gulf and to nobody else, and
## a scale bar does not help -- it says how big, not where.
##
## An inset answers it by drawing the same study area on a wider map with the
## extent marked. Which raises the only interesting question here: HOW MUCH
## wider?
##
## A fixed multiple does not work. Eight times the Gulf of Maine is most of the
## northeast seaboard, which orients anyone; eight times a 32 km hex grid at the
## mouth of the Bay of Fundy is 260 km of water with a bit of Nova Scotia in the
## corner, which orients nobody. The inset is only doing its job once there is
## something recognisable in it, and what counts as recognisable is land.
##
## So the rule is: start at `zoom`, and widen until land appears. It is
## data-driven, it terminates (there is a cap), and it degrades honestly -- on a
## map with no land within a very long way, the inset is dropped rather than
## drawn empty, because an empty inset is worse than none.

#' A locator inset
#'
#' A small wider map with the figure's extent marked on it, for saying where in
#' the world this is. Drawn by [map_surface()] and friends when `inset = TRUE`;
#' call it directly to build one and place it yourself.
#'
#' @param extent The extent to mark, as a `bbox`, an `sf` object, or a
#'   `map_data`.
#' @param crs The CRS to draw the inset in. Defaults to an equal-area
#'   projection centred on the extent -- **not** the map's own CRS. See Details.
#' @param zoom How many times wider than `extent` to start at. The inset widens
#'   past this if it has to -- see Details.
#' @param max_zoom How far it is allowed to widen before giving up. Past this,
#'   the inset is a map of an ocean and says nothing.
#' @param coastline Where land comes from, as in [coastline()].
#' @param mark_colour Colour of the extent marker.
#'
#' @details
#' # Which projection
#'
#' An equal-area projection centred on the extent, not the CRS the map is drawn
#' in. An inset is much wider than its map, and a projection that is honest over
#' 300 km need not be over 2,400: drawing an inset eight times the Gulf of Maine
#' in UTM 19N renders the coastline as vertical bands, because most of that
#' extent is many zones from the central meridian. Centring on the extent has no
#' zone to leave.
#'
#' # How wide
#'
#' `zoom` is a starting point, not a setting. An inset is only doing its job
#' once there is something recognisable in it, so the extent is widened --
#' doubling each time, up to `max_zoom` -- until land appears. Eight times the
#' Gulf of Maine is most of the northeast seaboard and orients anyone; eight
#' times a 32 km grid at the mouth of the Bay of Fundy is open water and orients
#' nobody.
#'
#' If no land is found by `max_zoom`, this returns `NULL` and the map is drawn
#' without an inset. An empty inset is worse than no inset: it looks like a
#' rendering failure, and it still takes up the corner.
#'
#' # The marker
#'
#' The extent is drawn as a rectangle. On a wide inset that rectangle can be
#' smaller than the line used to draw it, so below a visible size it is replaced
#' by a fixed-size marker centred on the same place. That marker is deliberately
#' *not* to scale, and it is why the inset never carries a scale bar -- it says
#' where, and the main panel says how big.
#'
#' @return A \pkg{ggplot2} object, or `NULL` if no useful inset could be built.
#'
#' @seealso [map_surface()], which draws one on request.
#'
#' @examples
#' locator_inset(example_grid())
#'
#' @export
locator_inset <- function(extent, crs = NULL, zoom = 8, max_zoom = 64,
                          coastline = TRUE, mark_colour = "#B3402A") {
  box <- as_bbox(extent)

  # Not the map's CRS, and this is the one thing about an inset that is easy to
  # get wrong. An inset is by definition much wider than the map it sits on,
  # and the projection that was honest over 300 km is not honest over 2,400:
  # reprojecting a world coastline into UTM 19N to draw an inset eight times
  # the Gulf of Maine produces vertical bands of land, because most of that
  # extent is many zones away from the central meridian. It is the same fact
  # `display_crs()` cites for not picking a UTM zone automatically, met from
  # the other direction.
  #
  # An equal-area projection centred on the extent has no zone to leave, so it
  # stays honest however far the inset has to widen. North is up at the centre,
  # which is where the marker is.
  crs <- crs %||% equal_area_crs(box)
  box <- sf::st_bbox(sf::st_transform(sf::st_as_sfc(box), crs))

  wide <- widen_until_land(box, zoom, max_zoom, coastline, crs)
  if (is.null(wide)) return(NULL)

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = wide$land, inherit.aes = FALSE, fill = "grey80",
                     colour = "grey55", linewidth = 0.15) +
    ggplot2::geom_sf(data = extent_marker(box, wide$box), inherit.aes = FALSE,
                     fill = NA, colour = mark_colour, linewidth = 0.6) +
    coord_for(wide$box, graticule = FALSE) +
    ggplot2::theme_void() +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "#F2F5F7",
                                               colour = "grey30",
                                               linewidth = 0.4),
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    )
}

# Widen until there is something to recognise, or give up.
widen_until_land <- function(box, zoom, max_zoom, source, crs) {
  z <- zoom
  repeat {
    wider <- square_off(padded_box(box, (z - 1) / 2))
    land <- suppressWarnings(coastline(wider, source = source, crs = crs,
                                       pad = 0))
    if (!is.null(land) && nrow(land)) {
      return(list(box = wider, land = land))
    }
    if (z >= max_zoom) return(NULL)
    z <- min(z * 2, max_zoom)
  }
}

# The extent, drawn so it can be seen.
#
# A 32 km box on a 2,000 km inset is a quarter of a millimetre -- thinner than
# the line drawing it, so it renders as a dot or as nothing. Below a visible
# fraction of the inset it is replaced by a fixed-size box on the same centre,
# which is a marker rather than a measurement. That is the honest trade: the
# inset's job is "where", and a marker answers it; "how big" is the main
# panel's scale bar.
extent_marker <- function(box, inset_box, min_fraction = 0.06) {
  inset_w <- inset_box[["xmax"]] - inset_box[["xmin"]]
  inset_h <- inset_box[["ymax"]] - inset_box[["ymin"]]
  w <- box[["xmax"]] - box[["xmin"]]
  h <- box[["ymax"]] - box[["ymin"]]

  if (w < inset_w * min_fraction || h < inset_h * min_fraction) {
    cx <- (box[["xmin"]] + box[["xmax"]]) / 2
    cy <- (box[["ymin"]] + box[["ymax"]]) / 2
    box[["xmin"]] <- cx - inset_w * min_fraction / 2
    box[["xmax"]] <- cx + inset_w * min_fraction / 2
    box[["ymin"]] <- cy - inset_h * min_fraction / 2
    box[["ymax"]] <- cy + inset_h * min_fraction / 2
  }
  sf::st_as_sfc(box)
}

# Placing the inset inside the main panel.
#
# `annotation_custom()` over a grob rather than `patchwork::inset_element()`,
# so that a map with an inset is still a plain ggplot object. A verb that
# returned a ggplot most of the time and a patchwork when one argument was set
# would break every downstream `+` a caller had written.
inset_layer <- function(inset, box, position = "br", size = 0.3) {
  if (is.null(inset)) return(NULL)

  # Square, in DATA units, and that is not the same as picking equal fractions
  # of the panel's width and height.
  #
  # `coord_sf()` makes a metre on the x axis the same length on the page as a
  # metre on the y axis -- that is what stops a map being stretched. So a
  # rectangle that is square in data units is square on the page, whatever
  # shape the panel is. Sizing it as a fraction of each side instead gives a
  # rectangle as elongated as the panel, and the inset drawn into it comes out
  # with its own coastline compressed along one axis -- which is how this first
  # rendered: the northeast seaboard as vertical bands.
  w <- (box[["xmax"]] - box[["xmin"]]) * size
  h <- w

  at <- corner(box, position, w, h)

  ggplot2::annotation_custom(ggplot2::ggplotGrob(inset),
                             xmin = at$x, xmax = at$x + w,
                             ymin = at$y, ymax = at$y + h)
}

# A square extent, grown rather than cropped from the given one.
#
# The inset is drawn into a square, and `coord_sf()` will not distort to fill
# it -- it letterboxes, leaving the marker off-centre in a band of panel
# background. Squaring the extent first means the two agree and the inset fills
# what it was given. Grown, never shrunk, so nothing that was in view leaves it.
square_off <- function(box) {
  w <- box[["xmax"]] - box[["xmin"]]
  h <- box[["ymax"]] - box[["ymin"]]
  side <- max(w, h)
  cx <- (box[["xmin"]] + box[["xmax"]]) / 2
  cy <- (box[["ymin"]] + box[["ymax"]]) / 2
  box[["xmin"]] <- cx - side / 2
  box[["xmax"]] <- cx + side / 2
  box[["ymin"]] <- cy - side / 2
  box[["ymax"]] <- cy + side / 2
  box
}
