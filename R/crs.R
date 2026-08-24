## Projection, decided once.
##
## Every map here has two coordinate systems and they are not the same one.
##
##   the DISPLAY CRS   what the map is drawn in. It decides what the shapes
##                     look like and where the scale bar's kilometre goes.
##   the MEASUREMENT   what areas and distances are computed in. It decides
##   CRS               whether a density per square kilometre is per square
##                     kilometre.
##
## Conflating them is the ordinary way to get an area wrong, because the
## mistake is invisible: `st_area()` on lon/lat returns a number with units
## attached and no complaint, computed on a sphere in a way that is right for
## the globe and wrong for a projected panel. In the Gulf of Maine a degree of
## longitude is 74 km and a degree of latitude is 111, so a cell drawn square
## is not square, and anything that divides by its area inherits the error.
##
## So: `display_crs()` settles the drawing, `equal_area_crs()` settles the
## measuring, and nothing in the package computes an area in whatever CRS the
## data happened to arrive in.

#' The coordinate system a map is drawn in
#'
#' Resolved once per figure and applied to every layer, so that the grid, the
#' coastline, the tracklines and the region outline are all in the same system
#' before any of them is drawn. Layers reprojected independently by their own
#' `geom_sf` is how panels stop lining up.
#'
#' @param x Anything with a CRS: an `sf` object, an `sfc`, a `bbox`, a
#'   `SpatRaster`, a `map_data` from [as_map_data()], or a CRS itself.
#' @param crs A CRS to force, in any form [sf::st_crs()] accepts. Supplying one
#'   is always allowed and always wins -- this function chooses only when it is
#'   not told.
#'
#' @details
#' When `crs` is not given:
#'
#' * **Projected data keeps its own projection.** If the analysis was done in
#'   UTM 19N then the model, the grid and the areas are all in UTM 19N, and
#'   reprojecting for the figure alone would draw a map of something slightly
#'   other than what was fitted.
#' * **Geographic data is projected** to a Lambert azimuthal equal-area
#'   centred on the data. Drawing lon/lat directly is the thing that makes a
#'   northern study area look stretched, and it puts the display CRS and the
#'   measurement CRS at odds.
#'
#' Lambert azimuthal rather than a UTM zone, which would be the other obvious
#' choice: UTM is only honest within about three degrees of its central
#' meridian, and study areas straddle zone boundaries often enough that
#' picking a zone automatically means sometimes picking a bad one silently.
#' Centring on the data has no boundary to straddle, and it is equal-area, so
#' the display and the measurement CRS coincide rather than merely agreeing.
#' Pass `crs = 32619` or any other value if a particular projection is wanted.
#'
#' @return An `sf::crs` object.
#'
#' @seealso [equal_area_crs()], which answers the other question.
#'
#' @examples
#' pts <- sf::st_as_sf(data.frame(lon = c(-70, -68), lat = c(42, 44)),
#'                     coords = c("lon", "lat"), crs = 4326)
#'
#' # lon/lat data gets projected
#' display_crs(pts)
#'
#' # unless told otherwise
#' display_crs(pts, crs = 4326)
#'
#' @export
display_crs <- function(x, crs = NULL) {
  if (!is.null(crs)) return(sf::st_crs(crs))

  from <- extract_crs(x)
  if (is.na(from)) {
    stop("this data carries no coordinate reference system, so there is no ",
         "way to tell metres from degrees.\nSet one on the data with ",
         "sf::st_crs(), or pass `crs =` to say what the coordinates are.",
         call. = FALSE)
  }
  if (!isTRUE(sf::st_is_longlat(from))) return(from)

  centre <- crs_centre(x)
  sf::st_crs(laea_proj(centre[["lon"]], centre[["lat"]]))
}

#' The coordinate system areas and distances are computed in
#'
#' Always equal-area, and always centred on the data rather than on a continent.
#'
#' @param x As for [display_crs()].
#'
#' @details
#' A Lambert azimuthal equal-area projection centred on the middle of the data.
#' Distortion in an azimuthal projection grows with distance from its centre,
#' so centring it on the thing being measured is what keeps the error small,
#' and it is why this is computed per dataset rather than fixed to a national
#' projection such as Albers North America (EPSG:5070). That one is equal-area
#' too, but its standard parallels are placed for the conterminous United
#' States; the Bay of Fundy is not in the conterminous United States.
#'
#' This is not necessarily the CRS the map is drawn in -- see [display_crs()]
#' for why those are separate questions.
#'
#' @return An `sf::crs` object.
#'
#' @examples
#' pts <- sf::st_as_sf(data.frame(lon = c(-70, -68), lat = c(42, 44)),
#'                     coords = c("lon", "lat"), crs = 4326)
#' equal_area_crs(pts)
#'
#' @export
equal_area_crs <- function(x) {
  from <- extract_crs(x)
  if (is.na(from)) {
    stop("this data carries no coordinate reference system, so its area ",
         "cannot be computed.\nSet one with sf::st_crs() first.", call. = FALSE)
  }
  centre <- crs_centre(x)
  sf::st_crs(laea_proj(centre[["lon"]], centre[["lat"]]))
}

#' Areas in square kilometres, computed honestly
#'
#' @param x An `sf` object of polygons.
#'
#' @return A numeric vector of areas in km2, one per feature, with the units
#'   dropped -- these are for arithmetic, and a `units` object propagating into
#'   a `ggplot2` aesthetic is a surprise nobody wants mid-figure.
#'
#' @examples
#' sq <- sf::st_sf(geometry = sf::st_sfc(
#'   sf::st_polygon(list(cbind(c(-70, -69.9, -69.9, -70, -70),
#'                             c(43, 43, 43.1, 43.1, 43)))), crs = 4326))
#' area_km2(sq)
#'
#' @export
area_km2 <- function(x) {
  as.numeric(sf::st_area(sf::st_transform(x, equal_area_crs(x)))) / 1e6
}

# The centre of whatever we were handed, in lon/lat, for centring a projection
# on. Taken from the bounding box rather than from a centroid of the union:
# unioning a thousand-cell grid to find its middle is expensive, and the answer
# is only used to place a projection's origin, where a few kilometres either way
# changes nothing measurable.
crs_centre <- function(x) {
  box <- as_bbox(x)
  if (!isTRUE(sf::st_is_longlat(sf::st_crs(box)))) {
    box <- sf::st_bbox(sf::st_transform(sf::st_as_sfc(box), 4326))
  }
  c(lon = unname((box[["xmin"]] + box[["xmax"]]) / 2),
    lat = unname((box[["ymin"]] + box[["ymax"]]) / 2))
}

laea_proj <- function(lon, lat) {
  # Rounded to a tenth of a degree so that two datasets covering the same study
  # area resolve to the SAME projection string rather than two that differ in
  # the ninth decimal. Identical strings matter: `sf` skips the transform when
  # the CRS compares equal, and a map whose grid and coastline went through
  # different-but-equivalent projections has each of them rounded differently.
  sprintf(
    "+proj=laea +lat_0=%s +lon_0=%s +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
    format(round(lat, 1), nsmall = 1), format(round(lon, 1), nsmall = 1)
  )
}

extract_crs <- function(x) {
  if (inherits(x, "map_data")) return(sf::st_crs(x$geometry))
  if (inherits(x, "crs")) return(x)
  if (inherits(x, "SpatRaster")) {
    return(sf::st_crs(terra_wkt(x)))
  }
  sf::st_crs(x)
}

as_bbox <- function(x) {
  if (inherits(x, "map_data")) return(sf::st_bbox(x$geometry))
  if (inherits(x, "bbox")) return(x)
  if (inherits(x, "SpatRaster")) {
    e <- as.vector(terra_ext(x))
    return(sf::st_bbox(c(xmin = e[1], xmax = e[2], ymin = e[3], ymax = e[4]),
                       crs = extract_crs(x)))
  }
  sf::st_bbox(x)
}
