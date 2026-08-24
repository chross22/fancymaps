## One internal representation, several ways in.
##
## The requirement this file exists for is that the same map has to be drawn
## from data in whatever shape the modelling left it in. In the two pipelines
## this package was written against, that means:
##
##   sf POLYGON     a prediction grid, one row per cell, values already on it
##                  (dsmfit: 1,167 square 5 km cells in UTM 19N)
##   sf POLYGON     a hex grid with an id column, values arriving SEPARATELY as
##                  a vector indexed by that id
##                  (dynocc: 53 hexagons in lon/lat, occupancy from a posterior)
##   sf POINT       segment midpoints, sightings, raster cell centres
##   sf LINESTRING  tracklines
##   SpatRaster     covariate layers as they arrive from a matching step
##   data.frame     coordinates in columns, which is what is left after geometry
##                  has been dropped for `mgcv` and a prediction rejoined
##
## The separately-supplied case is the one worth being deliberate about. A
## posterior summary comes out of an MCMC fit as a bare vector indexed by cell,
## and a covariate comes out of an averaging step as a [cells x windows] matrix.
## Neither carries geometry. The alternative to accepting them is making every
## caller bind the column on first, which is making every caller assert that
## the row order matches -- an assertion that is silent when it is wrong, and
## which produces a map that is perfectly plausible and completely permuted.
## So: hand over the values and say what they are keyed by, and the join is
## checked here, once.

#' Put spatial model output into the form the maps draw from
#'
#' Called for you by [map_surface()] and friends. Call it directly when you
#' want to inspect what they will draw, or to normalise something once and draw
#' it several times.
#'
#' @param x The geometry: an `sf` object of polygons, points or lines, a
#'   \pkg{terra} `SpatRaster`, or a data frame with coordinate columns.
#' @param value What to colour by. One of:
#'   * a string naming a column of `x`;
#'   * an unnamed numeric vector, one element per feature of `x`, in the same
#'     order;
#'   * a **named** numeric vector, matched against `x[[by]]` by name -- the
#'     form a posterior summary or a lookup table arrives in;
#'   * `NULL`, for geometry drawn without a colour, such as tracklines.
#' @param by The column of `x` holding the identifier that a named `value` is
#'   keyed by. Guessed from `grid_id`, `id` or `cell` when not given.
#' @param coords For a data frame, the two coordinate columns, as
#'   `c("x", "y")`. Guessed from the usual spellings when not given.
#' @param crs The coordinate reference system the coordinates are in. Required
#'   for a data frame, since nothing about two numeric columns says whether
#'   they are degrees or metres. Ignored when `x` already carries one.
#' @param label What to call the value in a legend. Defaults to the column
#'   name, or to the name of the expression passed as `value`.
#'
#' @details
#' # Checking the join
#'
#' When `value` is named, every name must be found in `x[[by]]`, and the
#' function stops if any is not, naming the first few missing keys. It does not
#' quietly drop them: a partial join produces a map with holes in it that looks
#' exactly like a region where the model had nothing to say.
#'
#' Keys are compared as character. An integer `grid_id` and a vector named
#' `"1"`, `"2"`, `"3"` are the common case and they match.
#'
#' # Rasters
#'
#' A `SpatRaster` is read into cell centres and drawn through a raster path.
#' It is deliberately not polygonised: `terra::as.polygons()` on a grid of any
#' size is slow enough to be the dominant cost of drawing the figure, and the
#' result is a polygon per cell that is then drawn as a rectangle anyway.
#'
#' @return An object of class `map_data`: a list with `geometry` (an `sfc`),
#'   `value` (numeric or `NULL`), `kind` (`"polygon"`, `"point"`, `"line"` or
#'   `"raster"`), `label`, and `data`, a data frame of the non-geometry columns.
#'
#' @examples
#' grid <- sf::st_sf(
#'   grid_id = 1:2,
#'   geometry = sf::st_sfc(
#'     sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
#'     sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
#'     crs = 4326))
#'
#' # a column that is already there
#' grid$depth <- c(40, 120)
#' as_map_data(grid, "depth")
#'
#' # values that arrived separately, keyed by id
#' occupancy <- c("2" = 0.8, "1" = 0.3)
#' as_map_data(grid, occupancy, by = "grid_id")
#'
#' @export
as_map_data <- function(x, value = NULL, by = NULL, coords = NULL,
                        crs = NULL, label = NULL) {
  label <- label %||% value_label(rlang::enquo(value), value)

  if (inherits(x, "map_data")) return(x)
  if (inherits(x, "SpatRaster")) return(raster_map_data(x, value, label))

  x <- as_sf(x, coords = coords, crs = crs)
  values <- resolve_values(x, value, by)

  new_map_data(
    geometry = sf::st_geometry(x),
    value = values,
    kind = geometry_kind(x),
    label = label,
    data = sf::st_drop_geometry(x)
  )
}

new_map_data <- function(geometry, value, kind, label, data) {
  structure(
    list(geometry = geometry, value = value, kind = kind, label = label,
         data = data),
    class = "map_data"
  )
}

#' @export
print.map_data <- function(x, ...) {
  cat("<map_data>", x$kind, "|", length(x$geometry), "features\n")
  cat("  crs:  ", sf::st_crs(x$geometry)$input %||% "none", "\n")
  if (is.null(x$value)) {
    cat("  value: none (geometry only)\n")
  } else {
    finite <- x$value[is.finite(x$value)]
    cat("  value:", x$label,
        if (length(finite)) {
          sprintf("[%s, %s]%s", signif(min(finite), 3), signif(max(finite), 3),
                  if (anyNA(x$value)) sprintf(", %d NA", sum(is.na(x$value))) else "")
        } else "all missing", "\n")
  }
  invisible(x)
}

# Whatever we were handed, as sf.
as_sf <- function(x, coords = NULL, crs = NULL) {
  if (inherits(x, "sf")) return(x)
  if (inherits(x, "sfc")) return(sf::st_sf(geometry = x))
  if (!is.data.frame(x)) {
    stop("cannot draw a ", class(x)[1], ".\nas_map_data() takes an sf object, ",
         "a terra SpatRaster, or a data frame with coordinate columns.",
         call. = FALSE)
  }

  coords <- coords %||% guess_coords(x)
  if (is.null(crs)) {
    stop("a data frame carries no coordinate reference system, and `",
         coords[1], "`/`", coords[2], "` could be degrees or metres.\n",
         "Pass `crs =` to say which: crs = 4326 for lon/lat, or the EPSG code ",
         "the model was fitted in.", call. = FALSE)
  }
  check_crs_plausible(x[[coords[1]]], x[[coords[2]]], crs, coords)

  # na.fail = FALSE: a prediction frame routinely carries rows whose covariates
  # were missing, and dropping them is the caller's decision to make, not a
  # reason to refuse to build the object.
  sf::st_as_sf(x, coords = coords, crs = crs, remove = FALSE, na.fail = FALSE)
}

# Does the CRS the caller named match the numbers they handed over?
#
# `crs =` on a data frame is the one place in this package where a coordinate
# system is ASSERTED rather than read, and a wrong assertion is not caught
# anywhere downstream: `sf` attaches whatever it is told, every transform after
# that is arithmetically valid, and the map draws. It is just a map of
# somewhere else -- or, for degrees labelled as metres, a map of a study area
# 140 metres across sitting off the coast of Africa.
#
# Only the certainly-wrong cases are errors. Nothing here can tell UTM 19N from
# UTM 20N, and it does not try; what it catches is degrees and metres swapped,
# which is the mistake that actually gets made.
check_crs_plausible <- function(x, y, crs, coords) {
  x <- x[is.finite(x)]
  y <- y[is.finite(y)]
  if (!length(x) || !length(y)) {
    # Caught here rather than left to sf, which builds a geometry of empty
    # points and then emits "no non-missing arguments to min; returning Inf"
    # three times from inside st_bbox -- which says nothing about the data and
    # names neither the column nor the fix.
    stop("every row is missing a coordinate: `", coords[1], "` and `",
         coords[2], "` are entirely NA, so there is nothing to draw.\n",
         "  Check that `coords =` names the right columns.", call. = FALSE)
  }

  longlat <- isTRUE(sf::st_is_longlat(crs))
  in_degrees <- max(abs(x)) <= 180 && max(abs(y)) <= 90

  if (longlat && !in_degrees) {
    stop("`crs` says these coordinates are longitude and latitude, but `",
         coords[1], "` reaches ", signif(max(abs(x)), 6), " and `", coords[2],
         "` reaches ", signif(max(abs(y)), 6),
         ".
  Longitude cannot pass 180 and latitude cannot pass 90, so ",
         "these are projected coordinates -- probably metres.
  Pass the ",
         "EPSG code the model was fitted in instead, such as crs = 32619.",
         call. = FALSE)
  }

  if (!longlat && in_degrees) {
    # A warning rather than an error: a projected CRS in degree-sized units is
    # not impossible, only very unlikely, and a study area 140 metres across is
    # visible the moment anyone looks at the figure.
    warning("`crs` says these coordinates are projected, but they all fall ",
            "within +/-180 and +/-90, which is what longitude and latitude ",
            "look like.
  If they are lon/lat, pass crs = 4326: read as ",
            "metres they describe an area a few hundred metres across, in ",
            "the wrong place.", call. = FALSE)
  }

  invisible(NULL)
}

# The spellings coordinate columns actually turn up in, most specific first.
# `mid_lon`/`mid_lat` before `lon`/`lat` because a segment table often has both,
# and the midpoint is the one that is one row per segment.
COORD_SPELLINGS <- list(
  c("mid_lon", "mid_lat"), c("mid_x", "mid_y"),
  c("lon", "lat"), c("long", "lat"), c("longitude", "latitude"),
  c("LON", "LAT"), c("LONGITUDE", "LATITUDE"),
  c("x", "y"), c("X", "Y")
)

guess_coords <- function(x) {
  for (pair in COORD_SPELLINGS) {
    if (all(pair %in% names(x))) return(pair)
  }
  stop("could not find coordinate columns in the data frame.\nLooked for ",
       paste(vapply(COORD_SPELLINGS, function(p) paste(p, collapse = "/"),
                    character(1)), collapse = ", "),
       ".\nPass `coords = c(\"x\", \"y\")` naming them.", call. = FALSE)
}

geometry_kind <- function(x) {
  types <- as.character(unique(sf::st_geometry_type(x)))
  kind <- unique(ifelse(grepl("POLYGON", types), "polygon",
                 ifelse(grepl("LINE", types), "line",
                 ifelse(grepl("POINT", types), "point", NA_character_))))
  kind <- kind[!is.na(kind)]
  if (length(kind) != 1L) {
    stop("this object mixes geometry types (", paste(types, collapse = ", "),
         "), and a map layer draws one.\nSplit it and draw the parts as ",
         "separate layers.", call. = FALSE)
  }
  kind
}

# The value column, however it arrived.
resolve_values <- function(x, value, by) {
  if (is.null(value)) return(NULL)

  if (is.character(value) && length(value) == 1L) {
    if (!value %in% names(x)) {
      stop("there is no column called `", value, "`.\nThe data has: ",
           paste(setdiff(names(x), attr(x, "sf_column")), collapse = ", "),
           call. = FALSE)
    }
    return(check_numeric(x[[value]], value))
  }

  if (is.matrix(value)) {
    stop("`value` is a ", nrow(value), " x ", ncol(value), " matrix, and a ",
         "map draws one column of it.\nPick one -- value = m[, 3] or ",
         "value = m[, \"2019\"] -- or draw them all with map_panels().",
         call. = FALSE)
  }

  value <- check_numeric(value, "value")

  if (is.null(names(value))) {
    if (length(value) != nrow(x)) {
      stop("`value` has ", length(value), " element(s) and the geometry has ",
           nrow(x), " feature(s).\nAn unnamed vector is matched by position, ",
           "so the two have to be the same length. If it is keyed by an id ",
           "instead, give it names and pass `by =`.", call. = FALSE)
    }
    return(unname(value))
  }

  join_by_name(x, value, by)
}

join_by_name <- function(x, value, by) {
  by <- by %||% guess_by(x)
  if (!by %in% names(x)) {
    stop("`by = \"", by, "\"` is not a column of the geometry.\nThe data has: ",
         paste(setdiff(names(x), attr(x, "sf_column")), collapse = ", "),
         call. = FALSE)
  }

  keys <- as.character(x[[by]])
  if (anyDuplicated(keys)) {
    dup <- keys[duplicated(keys)][1]
    stop("`", by, "` is not unique -- '", dup, "' appears ",
         sum(keys == dup), " times -- so it cannot key a join.",
         call. = FALSE)
  }

  # Every supplied name must land. A name that does not is either the wrong
  # key column or the wrong subset, and both produce a map with holes that
  # reads as "the model said nothing here" rather than "the join failed".
  missing <- setdiff(names(value), keys)
  if (length(missing)) {
    stop(length(missing), " of ", length(value), " value(s) have names that ",
         "are not in `", by, "`: ",
         paste(utils::head(missing, 5), collapse = ", "),
         if (length(missing) > 5) ", ..." else "",
         ".\nEither `by` names the wrong column, or the values and the ",
         "geometry are from different runs.", call. = FALSE)
  }

  out <- unname(value[keys])
  # The reverse direction is allowed and only reported: drawing a subset of a
  # grid is a legitimate thing to want, and those cells map to NA.
  blank <- sum(is.na(out)) - sum(is.na(value))
  if (blank > 0) {
    message(blank, " of ", nrow(x), " cells have no value and are drawn blank.")
  }
  out
}

guess_by <- function(x) {
  for (nm in c("grid_id", "cell_id", "id", "cell", "seg_id")) {
    if (nm %in% names(x)) return(nm)
  }
  stop("`value` is a named vector, so it has to be joined to the geometry by ",
       "an id, and none of `grid_id`, `cell_id`, `id`, `cell` or `seg_id` is ",
       "a column here.\nPass `by =` naming the column the names refer to.",
       call. = FALSE)
}

check_numeric <- function(v, what) {
  if (is.logical(v)) v <- as.numeric(v)
  if (!is.numeric(v)) {
    stop("`", what, "` is ", class(v)[1], ", and these maps colour by a ",
         "continuous quantity.\nFor a categorical map, convert to numeric ",
         "codes or draw it with ggplot2 directly.", call. = FALSE)
  }
  v
}

# The legend title, taken from whatever the caller wrote. `value = "density"`
# gives "density"; `value = post$mean` gives "post$mean", which is at least
# traceable; a long expression gives nothing rather than a legend title that is
# a line of code.
value_label <- function(quo, value) {
  if (is.character(value) && length(value) == 1L) return(value)
  if (is.null(value)) return(NULL)
  text <- rlang::as_label(quo)
  if (nchar(text) > 24 || grepl("[()]", text)) NULL else text
}

## Rasters take the raster path.
raster_map_data <- function(x, value, label) {
  check_terra()
  layer <- if (is.null(value)) 1L else value
  if (is.character(layer) && !layer %in% names(x)) {
    stop("this raster has no layer called `", layer, "`.\nIt has: ",
         paste(names(x), collapse = ", "), call. = FALSE)
  }
  r <- x[[layer]]

  cells <- terra_df(r)
  new_map_data(
    geometry = sf::st_geometry(
      sf::st_as_sf(cells, coords = c("x", "y"), crs = sf::st_crs(terra_wkt(x)))
    ),
    value = cells[[3]],
    kind = "raster",
    label = label %||% names(r),
    data = data.frame(resolution = I(list(terra_res(x))))
  )
}

# terra is in Suggests, so every use of it goes through a helper that says so.
check_terra <- function() {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("drawing a SpatRaster needs the terra package.\n",
         'install.packages("terra")', call. = FALSE)
  }
}

terra_wkt <- function(x) { check_terra(); terra::crs(x) }
terra_ext <- function(x) { check_terra(); terra::ext(x) }
terra_res <- function(x) { check_terra(); terra::res(x) }
terra_df <- function(x) {
  check_terra()
  terra::as.data.frame(x, xy = TRUE, na.rm = FALSE)
}
