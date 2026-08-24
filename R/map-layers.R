## The pieces every map is built from.
##
## One place that decides layer order, the seam fix, the extent, and what the
## caption ends up saying -- so that the five drawing verbs differ only in the
## scale they put on top, and a fix to any of this reaches all of them.
##
## LAYER ORDER, and why land is on top.
##
##   sea      the panel background, from theme_fancymap(). It is there so a
##            cell with no prediction reads as a hole in the surface rather
##            than as the page showing through.
##   values   the data.
##   land     ON TOP of the values, not under them. A prediction grid built by
##            intersecting a bounding box with a study area routinely has cells
##            that overlap the shore, and a coastline drawn underneath leaves
##            those cells sitting on the land. Drawn on top, the shoreline is
##            crisp and the map claims nothing about what is happening ashore.
##   region   the outline of what was cropped to what.
##   furniture scale bar, north arrow, and any note the figure owes the reader.

# The seam fix.
#
# 5 km polygons drawn with `colour = NA` still show seams and moire at some
# output sizes: adjacent cells are drawn as separate paths, and the renderer
# antialiases each edge against the background rather than against its
# neighbour, leaving a sub-pixel line of panel colour between them. Drawing
# each cell with a hairline stroke IN ITS OWN FILL COLOUR closes the gap
# without adding a mesh -- the stroke is invisible because it matches what it
# borders, and it is what the eye would have seen had the two cells abutted.
#
# It costs a second scale, mapped to the same values with the same limits and
# no guide. That is why every scale in this package is built as a pair.
value_layer <- function(md, alpha = 1) {
  if (identical(md$kind, "raster")) return(raster_layer(md))

  data <- sf::st_sf(.value = md$value %||% NA_real_, geometry = md$geometry)

  if (is.null(md$value)) {
    return(ggplot2::geom_sf(data = data, inherit.aes = FALSE,
                            fill = "grey60", colour = NA))
  }

  switch(md$kind,
    polygon = ggplot2::geom_sf(
      data = data, inherit.aes = FALSE, alpha = alpha, linewidth = 0.06,
      mapping = ggplot2::aes(fill = .data$.value, colour = .data$.value)
    ),
    point = ggplot2::geom_sf(
      data = data, inherit.aes = FALSE, alpha = alpha, size = 0.9,
      mapping = ggplot2::aes(colour = .data$.value)
    ),
    line = ggplot2::geom_sf(
      data = data, inherit.aes = FALSE, alpha = alpha, linewidth = 0.4,
      mapping = ggplot2::aes(colour = .data$.value)
    )
  )
}

# Rasters go through geom_raster on cell centres rather than through polygons.
# `terra::as.polygons()` on a grid of any size dominates the cost of drawing
# the figure, and produces a polygon per cell that is then drawn as a rectangle
# anyway.
raster_layer <- function(md) {
  xy <- sf::st_coordinates(md$geometry)
  ggplot2::geom_raster(
    data = data.frame(x = xy[, 1], y = xy[, 2], .value = md$value),
    mapping = ggplot2::aes(x = .data$x, y = .data$y, fill = .data$.value),
    inherit.aes = FALSE
  )
}

land_layer <- function(land) {
  if (is.null(land) || !nrow(land)) return(NULL)
  ggplot2::geom_sf(data = land, inherit.aes = FALSE, fill = "grey86",
                   colour = "grey55", linewidth = 0.25)
}

# The region boundary, as a real sf layer.
#
# `dsmfit::region_outline()` draws this as a `geom_path` over raw ring
# coordinates, because its check maps use `coord_quickmap()` when no coastline
# is drawn and a `geom_sf` layer errors under that coordinate system. Every map
# here uses `coord_sf()` with a resolved CRS, so that workaround has nothing to
# work around and the outline is just the polygon.
region_layer <- function(region, crs) {
  if (is.null(region)) return(NULL)
  region <- sf::st_transform(sf::st_sf(geometry = sf::st_geometry(region)), crs)
  ggplot2::geom_sf(data = region, inherit.aes = FALSE, fill = NA,
                   colour = "grey20", linewidth = 0.4, linetype = "dashed")
}

# Everything reprojected to the display CRS before anything is drawn, so that
# the grid, the land and the outline are one coordinate system rather than
# three that `coord_sf()` reconciles at draw time. Panels that each reprojected
# their own layers are how a pair of maps stops lining up.
project_md <- function(md, crs) {
  md$geometry <- sf::st_transform(md$geometry, crs)
  md
}

map_extent <- function(md, expand = 0.02) {
  padded_box(sf::st_bbox(md$geometry), expand)
}

coord_for <- function(box, graticule) {
  ggplot2::coord_sf(
    xlim = c(box[["xmin"]], box[["xmax"]]),
    ylim = c(box[["ymin"]], box[["ymax"]]),
    crs = sf::st_crs(box),
    # expand = FALSE because the extent has already been padded deliberately;
    # ggplot2's own 5% on top of that is padding nobody asked for and it
    # differs between panels whose data differ in extent.
    expand = FALSE,
    datum = if (graticule) sf::st_crs(4326) else NA
  )
}

# What the figure owes the reader, assembled in one place.
#
# The caption is where provenance lives -- which period, which product, what
# correction was not applied -- and it is also where this package puts the
# things it had to decide. A scale that was squished and a coastline that could
# not be drawn are both facts about the figure that the figure has to carry,
# because neither is visible in the picture.
build_caption <- function(user, notes) {
  notes <- unlist(notes[!vapply(notes, is.null, logical(1))], use.names = FALSE)
  parts <- c(user, if (length(notes)) paste(notes, collapse = " "))
  if (!length(parts)) return(NULL)
  paste(parts, collapse = "\n")
}

# Why there is no land, when there is none. The two reasons are different
# facts about the figure and a reader cannot tell them apart from the picture:
# an open-water extent and a coastline layer that failed to load look identical.
no_land_note <- function(land, requested) {
  if (isFALSE(requested)) return(NULL)
  if (is.null(land)) {
    return("No coastline source was available: this map has no land on it.")
  }
  if (!nrow(land)) {
    return("No land falls inside this extent.")
  }
  NULL
}

squish_note <- function(spec, label) {
  if (!isTRUE(spec$squished)) return(NULL)
  paste0("Colour is capped at ", signif(spec$limits[2], 3),
         if (!is.null(label)) paste0(" ", label) else "",
         "; cells beyond it are drawn at the cap.")
}
