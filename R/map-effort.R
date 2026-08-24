#' Map survey effort and detections
#'
#' Tracklines, segment midpoints and sightings: where the survey went and what
#' it saw. The map that says what the model was fitted from, and the one a
#' reader checks a prediction against.
#'
#' @param coords,crs Passed to [as_map_data()]. `crs` is also the CRS the map
#'   is drawn in -- see [display_crs()].
#' @param tracks An `sf` object of lines -- the tracklines -- or `NULL`.
#' @param points An `sf` object of points: segment midpoints, or sightings.
#' @param value A column of `points` to colour by, such as group size. `NULL`
#'   draws them in one colour.
#' @param size A column of `points` to size by. Group size is the usual one,
#'   and sizing by it rather than colouring by it leaves colour free for
#'   something else.
#' @param bin Whether to aggregate the points into hexagonal bins instead of
#'   drawing them. `NA` (the default) decides from how many there are; `TRUE`
#'   and `FALSE` force it. See below.
#' @param bins How many bins across the extent, when binning.
#' @param fun How to summarise `value` within a bin. `"count"` when no `value`
#'   is given, which is what an effort map wants.
#' @param bin_threshold How many points before binning becomes the default.
#'   2,000, which is roughly where overlap starts hiding structure at ordinary
#'   figure sizes.
#' @param expand How much margin to leave around the data, as a fraction of its
#'   own extent. Widen it when the data does not reach anything a reader can
#'   orient by -- a small grid in open water shows no coastline at all until the
#'   panel is wide enough to include one.
#' @inheritParams map_surface
#'
#' @details
#' # Binning
#'
#' Eight thousand segment midpoints on one map is a black smear, and it is a
#' smear that looks like data. Past `bin_threshold` points the default is to
#' bin them with [fancyfx::hex_bin()] and say so, rather than to draw a figure
#' whose density is set by the plotting order.
#'
#' The threshold is 2,000, which is roughly where overlap starts to hide
#' structure at ordinary figure sizes. Force it either way when you know
#' better: `bin = FALSE` on a sparse map, `bin = TRUE` on a dense one that
#' happens to fall under the line.
#'
#' @return A \pkg{ggplot2} object.
#'
#' @examples
#' pts <- sf::st_as_sf(
#'   data.frame(lon = runif(300, -70.4, -68.1), lat = runif(300, 42.6, 44.3),
#'              group = rpois(300, 3)),
#'   coords = c("lon", "lat"), crs = 4326)
#'
#' map_effort(points = pts, size = "group", title = "Sightings")
#'
#' @export
map_effort <- function(tracks = NULL, points = NULL, value = NULL,
                       size = NULL, bin = NA, bins = 40, fun = NULL,
                       coords = NULL, crs = NULL, label = NULL,
                       coastline = TRUE, region = NULL,
                       title = NULL, subtitle = NULL, caption = NULL,
                       scalebar = TRUE, north = TRUE, graticule = FALSE,
                       base_size = 12, theme = NULL, bin_threshold = 2000,
                       expand = 0.02) {
  if (is.null(tracks) && is.null(points)) {
    stop("map_effort() needs `tracks`, `points`, or both.", call. = FALSE)
  }
  label <- label %||% value_label(rlang::enquo(value), value)

  md_tracks <- if (!is.null(tracks)) {
    as_map_data(tracks, coords = coords, crs = crs)
  }
  md_points <- if (!is.null(points)) {
    as_map_data(points, value = value, coords = coords, crs = crs,
                label = label)
  }

  crs <- display_crs(md_tracks %||% md_points, crs)
  if (!is.null(md_tracks)) md_tracks <- project_md(md_tracks, crs)
  if (!is.null(md_points)) md_points <- project_md(md_points, crs)

  binned <- NULL
  if (!is.null(md_points)) {
    n <- length(md_points$geometry)
    do_bin <- if (is.na(bin)) n > bin_threshold else isTRUE(bin)
    if (do_bin) {
      binned <- bin_points(md_points, bins = bins,
                           fun = fun %||% if (is.null(value)) "count" else "mean")
      if (is.na(bin)) {
        message(format(n, big.mark = ","), " points is past the ",
                format(bin_threshold, big.mark = ","), " where overplotting ",
                "starts hiding structure, so they are drawn as ", bins,
                " hexagonal bins.\n  Pass `bin = FALSE` to draw them ",
                "individually anyway.")
      }
    }
  }

  extent <- shared_extent(Filter(Negate(is.null),
                                 list(md_tracks, binned %||% md_points)),
                          expand)
  land <- coastline(extent, source = coastline, crs = crs)

  p <- ggplot2::ggplot()

  if (!is.null(binned)) {
    spec <- surface_scale(binned$value)
    p <- p + value_layer(binned) +
      scale_pair(spec, scale_name(binned$label, spec$note), binned$kind)
  }

  # Tracks under points, because a trackline is context and a sighting is the
  # thing being looked at. Drawn in a mid grey rather than in a palette colour:
  # effort is not a quantity here, it is where the aircraft was.
  if (!is.null(md_tracks)) {
    p <- p + ggplot2::geom_sf(
      data = sf::st_sf(geometry = md_tracks$geometry), inherit.aes = FALSE,
      colour = "grey45", linewidth = 0.25, alpha = 0.8)
  }

  if (is.null(binned) && !is.null(md_points)) {
    p <- p + point_layer(md_points, points, size, base_size)
    if (!is.null(md_points$value)) {
      spec <- surface_scale(md_points$value)
      p <- p + scale_pair(spec, scale_name(md_points$label, spec$note), "point")
    }
  }

  p <- p + land_layer(land) + region_layer(region, crs) +
    coord_for(extent, graticule)

  if (isTRUE(scalebar)) p <- p + scale_bar(extent, base_size = base_size)
  if (isTRUE(north)) p <- p + north_arrow(extent, base_size = base_size)

  p +
    ggplot2::labs(title = title, subtitle = subtitle,
                  caption = build_caption(caption,
                                          list(no_land_note(land, coastline)))) +
    (theme %||% theme_fancymap(base_size = base_size, graticule = graticule))
}

point_layer <- function(md, original, size, base_size) {
  data <- sf::st_sf(.value = md$value %||% NA_real_, geometry = md$geometry)
  if (!is.null(size)) {
    data$.size <- if (is.character(size)) {
      sf::st_drop_geometry(original)[[size]]
    } else {
      size
    }
  }

  mapping <- if (is.null(md$value) && is.null(size)) {
    NULL
  } else {
    ggplot2::aes(
      colour = if (is.null(md$value)) NULL else .data$.value,
      size = if (is.null(size)) NULL else .data$.size
    )
  }

  list(
    ggplot2::geom_sf(
      data = data, inherit.aes = FALSE, mapping = mapping,
      # Points on an effort map overlap by nature -- a survey flies the same
      # water repeatedly -- so they are drawn part-transparent, and where they
      # stack the darkening is itself information.
      alpha = 0.55,
      colour = if (is.null(md$value)) "#215689" else NULL,
      size = if (is.null(size)) 0.8 else NULL
    ),
    if (!is.null(size)) {
      ggplot2::scale_size_area(name = if (is.character(size)) size else NULL,
                               max_size = base_size * 0.35)
    }
  )
}

bin_points <- function(md, bins, fun) {
  # `fancyfx::hex_bin()` reads coordinates from named columns rather than from
  # a geometry, and returns bin CENTRES rather than polygons. So the points go
  # over as a plain frame and the hexagons are rebuilt here from the centres
  # and the `cellsize` attribute it reports.
  #
  # They are already in the display CRS by this point, which is what makes the
  # bins regular hexagons on the map. Binned in lon/lat they would come out
  # squashed once projected, by the same factor that makes a degree of
  # longitude 74 km here and 111 at the equator.
  xy <- sf::st_coordinates(md$geometry)
  frame <- data.frame(x = xy[, 1], y = xy[, 2],
                      .value = md$value %||% rep(1, nrow(xy)))

  hb <- fancyfx::hex_bin(frame, value = ".value", coords = c("x", "y"),
                         bins = bins, fun = fun)
  cellsize <- attr(hb, "cellsize")

  new_map_data(
    geometry = hex_polygons(hb$.x, hb$.y, cellsize, sf::st_crs(md$geometry)),
    value = hb$.value,
    kind = "polygon",
    label = if (identical(fun, "count")) "points per bin" else md$label,
    data = hb
  )
}

# Hexagons from centres. Pointy-top, matching what `hexbin` lays out, with
# `cellsize` measured centre to vertex -- so the vertices sit at 90, 150, 210,
# 270, 330 and 30 degrees and the first is repeated to close the ring.
hex_polygons <- function(x, y, cellsize, crs) {
  angle <- (c(90, 150, 210, 270, 330, 30, 90)) * pi / 180
  dx <- cos(angle) * cellsize
  dy <- sin(angle) * cellsize
  sf::st_sfc(
    lapply(seq_along(x), function(i) {
      sf::st_polygon(list(cbind(x[i] + dx, y[i] + dy)))
    }),
    crs = crs
  )
}
