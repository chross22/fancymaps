## Land.
##
## The defect this file exists for: a map of the ocean with no shoreline is a
## heatmap with coordinates. A reader cannot tell Penobscot Bay from Georges
## Basin, cannot see that the bright cells hug the coast, and has no way to
## check that the study area is the water they think it is.
##
## Two rules follow from that, and they are the whole design.
##
## 1. Land is drawn by DEFAULT. Not an argument someone remembers to set.
## 2. If land cannot be drawn, the figure SAYS SO -- in a warning and in a
##    caption on the plot itself. A map with no coastline looks deliberate,
##    and a reader has no way to distinguish "this model covers open water"
##    from "the coastline layer failed to load".
##
## The third thing is resolution, which is not a detail. Natural Earth medium
## is about 1:50,000,000. Over a 300 km grid it is fine. Over the 30 km hex
## grid at the mouth of the Bay of Fundy it renders the Nova Scotia shore as a
## few straight segments, and a cell that is genuinely coastal appears to be
## a long way offshore. So the resolution is chosen from the extent, and when
## the right one is not installed that is said out loud rather than absorbed.

#' A coastline for a map
#'
#' Resolves a land layer for a given extent, choosing a resolution to suit it.
#' Called for you by every map in this package; call it directly to inspect
#' what will be drawn, or to fetch once and reuse across many figures.
#'
#' @param extent Anything with a bounding box -- an `sf` object, a `bbox`, a
#'   `map_data` -- naming the area to be covered. `NULL` returns the whole
#'   source, uncropped.
#' @param source Where land comes from:
#'   * `TRUE` (default) -- choose automatically: the bundled fixture if it
#'     covers the extent, otherwise \pkg{rnaturalearth} at a resolution picked
#'     from the extent;
#'   * `FALSE` -- no land, deliberately. The only way to get a map with no
#'     shoreline and no complaint about it;
#'   * a path to a shapefile or any other format [sf::st_read()] reads. The
#'     better option at bay scale;
#'   * an `sf` object already in memory.
#' @param crs The CRS to return the land in. Defaults to the extent's.
#' @param pad How far past the extent to keep land, as a fraction of the
#'   extent's width. A little overhang stops the shoreline stopping dead at the
#'   panel edge.
#'
#' @details
#' # Which resolution
#'
#' Chosen from the width of the extent, because that is what decides whether
#' the generalisation in a coastline is visible:
#'
#' | extent width | resolution | Natural Earth scale |
#' |---|---|---|
#' | over 1,500 km | `"small"` | 1:110m |
#' | 200 to 1,500 km | `"medium"` | 1:50m |
#' | under 200 km | `"large"` | 1:10m |
#'
#' `"large"` needs the `rnaturalearthhires` package, which is not on CRAN. If
#' it is not installed, `"medium"` is used and a warning says the coastline is
#' coarser than the map, since that is a defect a reader will otherwise
#' attribute to the data.
#'
#' # The bundled fixture
#'
#' A cropped copy of Natural Earth medium covering the Gulf of Maine and the
#' Bay of Fundy ships with the package, so that examples draw land and tests
#' never touch the network. It is used automatically when it covers the
#' requested extent, and it is the same data \pkg{rnaturalearth} would return
#' at that scale -- just already here.
#'
#' @return An `sf` object of land polygons, or `NULL` if `source = FALSE` or
#'   nothing could be resolved.
#'
#' @examples
#' box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
#'                    crs = sf::st_crs(4326))
#' land <- coastline(box)
#' nrow(land)
#'
#' # deliberately none
#' coastline(box, source = FALSE)
#'
#' @export
coastline <- function(extent = NULL, source = TRUE, crs = NULL, pad = 0.05) {
  if (isFALSE(source) || is.null(source)) return(NULL)

  crs <- crs %||% (if (!is.null(extent)) extract_crs(extent) else sf::st_crs(4326))
  box <- if (is.null(extent)) NULL else padded_box(as_bbox(extent), pad)

  land <- if (isTRUE(source)) {
    resolve_land(box)
  } else if (inherits(source, c("sf", "sfc"))) {
    sf::st_sf(geometry = sf::st_geometry(source))
  } else if (is.character(source) && length(source) == 1L) {
    read_land_file(source, box)
  } else {
    stop("`source` should be TRUE, FALSE, a file path, or an sf object -- ",
         "not a ", class(source)[1], ".", call. = FALSE)
  }

  if (is.null(land)) return(NULL)
  # An empty result is returned as an EMPTY sf rather than as NULL, because the
  # two mean different things and the caption has to be able to tell them
  # apart: NULL is "no source could be found", zero rows is "the source was
  # fine and there is no land in this extent". A map of open water is not a
  # broken map, and captioning it as one is its own kind of wrong.
  crop_land(land, box, crs) %||% empty_land(crs)
}

# A file the user named. A named file that is missing is an error, not a
# fallback: the caller said which coastline they wanted, and quietly drawing a
# different one is worse than stopping.
read_land_file <- function(path, box) {
  if (!file.exists(path)) {
    stop("no coastline file at: ", path,
         "\nCheck the path, or pass `coastline = TRUE` to use a bundled or ",
         "downloaded source instead.", call. = FALSE)
  }
  if (grepl("\\.rds$", path, ignore.case = TRUE)) return(readRDS(path))
  sf::st_read(path, quiet = TRUE)
}

resolve_land <- function(box) {
  scale <- natural_earth_scale(box)
  fixture <- coastline_fixture()

  # The fixture is Natural Earth MEDIUM, so it is only an acceptable automatic
  # answer where medium is. Handing it back for a bay-scale extent because it
  # happens to cover the box would skip the resolution check entirely -- and
  # skip the warning that the shoreline is coarser than the map, which is the
  # single most useful thing this function says at that scale.
  if (!is.null(box) && !identical(scale, "large") && covers(fixture, box)) {
    return(fixture)
  }

  land <- natural_earth(scale)
  if (!is.null(land)) return(land)

  # Nothing downloadable. The fixture is worse than what was asked for, but it
  # is land, and land at the wrong resolution beats a blank panel -- the
  # warning above has already said which one this is.
  if (!is.null(box) && covers(fixture, box)) return(fixture)

  warning(
    "no coastline source available, so this map is drawn without land.\n",
    "  A map of the ocean with no shoreline is hard to read and easy to ",
    "misread, so the figure is captioned to say so.\n",
    "  Install rnaturalearth, or pass `coastline = \"path/to/coast.shp\"`.",
    call. = FALSE
  )
  NULL
}

#' @rdname coastline
#' @export
coastline_fixture <- function() {
  readRDS(system.file("extdata", "coastline-gom.rds", package = "fancymaps"))
}

# The thresholds are in kilometres of extent width, and they are about what a
# reader can see. Below roughly 200 km a 1:50m shoreline's straight segments
# are longer than the cells drawn on top of it, which is the point at which
# the land stops being a reference and starts being wrong.
natural_earth_scale <- function(box) {
  if (is.null(box)) return("medium")
  km <- extent_width_km(box)
  if (km > 1500) "small" else if (km > 200) "medium" else "large"
}

natural_earth <- function(scale) {
  if (!requireNamespace("rnaturalearth", quietly = TRUE)) return(NULL)

  if (identical(scale, "large") &&
      !requireNamespace("rnaturalearthhires", quietly = TRUE)) {
    warning(
      "this extent is small enough to need a 1:10m coastline, and the ",
      "rnaturalearthhires package is not installed, so a 1:50m one is drawn ",
      "instead.\n  At this scale its shoreline is visibly generalised -- ",
      "straight segments longer than the cells over them -- and a coastal ",
      "cell can appear to sit offshore.\n  Either install it, or supply a ",
      "local shapefile:\n",
      '  install.packages("rnaturalearthhires", repos = "https://ropensci.r-universe.dev")',
      call. = FALSE
    )
    scale <- "medium"
  }

  land <- try(
    sf::st_make_valid(
      rnaturalearth::ne_countries(scale = scale, returnclass = "sf")
    ),
    silent = TRUE
  )
  if (inherits(land, "try-error")) return(NULL)
  land[, character(0)]
}

crop_land <- function(land, box, crs) {
  if (!is.null(box)) {
    # Cropped in the box's own CRS, so the crop rectangle is a rectangle on the
    # map rather than a shape that has been through a projection.
    land <- sf::st_transform(land, sf::st_crs(box))
    land <- suppressWarnings(try(sf::st_crop(sf::st_make_valid(land), box),
                                 silent = TRUE))
    if (inherits(land, "try-error")) return(NULL)
    if (!nrow(land)) return(empty_land(sf::st_crs(box)))
  }
  sf::st_make_valid(sf::st_transform(land, crs))
}

covers <- function(land, box) {
  have <- sf::st_bbox(sf::st_transform(sf::st_as_sfc(sf::st_bbox(land)),
                                       sf::st_crs(box)))
  have[["xmin"]] <= box[["xmin"]] && have[["xmax"]] >= box[["xmax"]] &&
    have[["ymin"]] <= box[["ymin"]] && have[["ymax"]] >= box[["ymax"]]
}

padded_box <- function(box, pad) {
  dx <- (box[["xmax"]] - box[["xmin"]]) * pad
  dy <- (box[["ymax"]] - box[["ymin"]]) * pad
  box[["xmin"]] <- box[["xmin"]] - dx
  box[["xmax"]] <- box[["xmax"]] + dx
  box[["ymin"]] <- box[["ymin"]] - dy
  box[["ymax"]] <- box[["ymax"]] + dy
  box
}

# The width of an extent in kilometres, whatever it is expressed in. Measured
# along the middle of the box rather than at a corner: on lon/lat the top and
# bottom of a box are different real widths, and the middle is the one that
# describes the map.
extent_width_km <- function(box) {
  if (!isTRUE(sf::st_is_longlat(sf::st_crs(box)))) {
    return(unname(box[["xmax"]] - box[["xmin"]]) / 1000)
  }
  mid <- (box[["ymin"]] + box[["ymax"]]) / 2
  ends <- sf::st_sfc(
    sf::st_point(c(box[["xmin"]], mid)), sf::st_point(c(box[["xmax"]], mid)),
    crs = sf::st_crs(box)
  )
  as.numeric(sf::st_distance(ends)[1, 2]) / 1000
}

empty_land <- function(crs) {
  sf::st_sf(geometry = sf::st_sfc(crs = crs))
}
