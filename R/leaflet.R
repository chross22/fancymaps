## The interactive twin of the drawing verbs.
##
## The requirements note lists interactive maps as a non-goal, on the grounds
## that `leaflet` and `mapview` exist. That is right about the RENDERING and
## wrong about the DECISIONS. Handing a grid to `leaflet` directly means
## deciding the scale again, by hand, at the call site -- and it will be decided
## differently, because `leaflet::colorNumeric()` has its own defaults and they
## are linear over the data range. The result is a static figure and an
## interactive one, of the same numbers, in different colours. A reader who has
## seen both has been told two things.
##
## So these are not a second mapping package. They are the same data contract
## and the same scale objects -- `as_map_data()`, `surface_scale()`,
## `diverging_scale()`, `fancymap_palette()` -- rendered by `leaflet` instead of
## by `ggplot2`, so a cell is the same colour in both.
##
## WHAT IS DIFFERENT, and it is worth being explicit about.
##
##   projection   Not ours. `leaflet` is Web Mercator and its inputs are
##                WGS84, so `display_crs()` does not apply and everything is
##                transformed to EPSG:4326 instead. Areas are still computed in
##                an equal-area projection when they are computed at all.
##   land         From the tile provider, not from `coastline()`. That is the
##                one thing an interactive map genuinely does better, and it is
##                also why these need the network at draw time and the static
##                ones do not.
##   furniture    A scale bar comes from `leaflet`; a north arrow is
##                meaningless on a map you can pan but not rotate.

#' Interactive versions of the maps
#'
#' The same map, rendered by \pkg{leaflet}: pan, zoom, and click a cell for its
#' value. For looking at a surface while working on it, and for a report where
#' the reader should be able to find their own bay.
#'
#' @param x,value,by,coords,crs,label Passed to [as_map_data()], exactly as for
#'   [map_surface()]. `crs` here only says what the incoming coordinates are;
#'   it does not choose a projection, because \pkg{leaflet} is always Web
#'   Mercator.
#' @param transform,limits,probs Passed to [surface_scale()], so the colours
#'   match the static map's exactly.
#' @param midpoint,direction For `leaflet_diverging()`, as in [map_diverging()].
#' @param popup Extra columns of `x` to show when a cell is clicked, as a
#'   character vector. The value and the join key are always shown. `FALSE`
#'   turns popups off.
#' @param tiles A \pkg{leaflet} provider name for the basemap, or `NULL` for no
#'   basemap at all. The default is a quiet grey one, so the data is the
#'   brightest thing on the map rather than competing with a road network.
#' @param opacity How opaque the cells are over the basemap.
#' @param legend Whether to draw the legend.
#'
#' @details
#' # Why these exist rather than a call to leaflet
#'
#' Not for the rendering -- \pkg{leaflet} does that. For the **decisions**.
#' Handing a grid to `leaflet::colorNumeric()` re-decides the scale at the call
#' site, and it decides differently: linear, over the full data range, with no
#' capping. So the static figure and the interactive one show the same numbers
#' in different colours, and a reader who has seen both has been told two
#' things. These reuse the same scale objects, so a cell is the same colour in
#' both.
#'
#' # What is not carried over
#'
#' The projection is \pkg{leaflet}'s: Web Mercator, with WGS84 inputs, so
#' [display_crs()] does not apply and everything is transformed to EPSG:4326.
#' Land comes from the tile provider rather than from [coastline()] -- which
#' means, unlike every static map here, **these need the network at draw
#' time**. That is the reason the static ones do not use tiles.
#'
#' # The legend
#'
#' Swatches at the same breaks the static legend uses, with the same labels --
#' including the `>=` on a capped scale. It is a stepped legend for a
#' continuous ramp, which is what \pkg{leaflet} draws well; the colours between
#' the swatches are continuous as they are on the static map.
#'
#' @return A \pkg{leaflet} widget.
#'
#' @seealso [map_surface()], [map_probability()] and [map_diverging()], the
#'   static originals.
#'
#' @examples
#' \dontrun{
#' grid <- example_grid()
#'
#' leaflet_surface(grid, "density", label = "animals per km2")
#' leaflet_probability(grid, "occupancy", popup = c("density", "cv"))
#' leaflet_diverging(grid, "mess", midpoint = 0, direction = -1)
#' }
#'
#' @name leaflet-maps
NULL

#' @rdname leaflet-maps
#' @export
leaflet_surface <- function(x, value = NULL, by = NULL, coords = NULL,
                            crs = NULL, label = NULL, transform = "auto",
                            limits = NULL, probs = c(0, 0.99), popup = NULL,
                            tiles = "CartoDB.Positron", opacity = 0.8,
                            legend = TRUE) {
  label <- label %||% value_label(rlang::enquo(value), value)
  md <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                    label = label)
  require_value(md, "leaflet_surface")

  spec <- surface_scale(md$value, transform = transform, limits = limits,
                        probs = probs)
  assemble_leaflet(md, spec, palette = "sequential", popup = popup,
                   tiles = tiles, opacity = opacity, legend = legend, by = by)
}

#' @rdname leaflet-maps
#' @export
leaflet_probability <- function(x, value = NULL, by = NULL, coords = NULL,
                                crs = NULL, label = NULL, limits = c(0, 1),
                                popup = NULL, tiles = "CartoDB.Positron",
                                opacity = 0.8, legend = TRUE) {
  label <- label %||% value_label(rlang::enquo(value), value)
  md <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                    label = label)
  require_value(md, "leaflet_probability")

  spec <- list(limits = limits, transform = "identity",
               breaks = seq(limits[1], limits[2], length.out = 5),
               labels = function(v) format(v), squished = FALSE, note = NULL)
  assemble_leaflet(md, spec, palette = "bounded", popup = popup, tiles = tiles,
                   opacity = opacity, legend = legend, by = by)
}

#' @rdname leaflet-maps
#' @export
leaflet_diverging <- function(x, value = NULL, midpoint, by = NULL,
                              coords = NULL, crs = NULL, label = NULL,
                              limits = NULL, probs = c(0.01, 0.99),
                              direction = 1, popup = NULL,
                              tiles = "CartoDB.Positron", opacity = 0.8,
                              legend = TRUE) {
  label <- label %||% value_label(rlang::enquo(value), value)
  md <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                    label = label)
  require_value(md, "leaflet_diverging")

  spec <- diverging_scale(md$value, midpoint = midpoint, limits = limits,
                          probs = probs)
  spec$rescaler <- diverging_rescaler(spec$midpoint)
  spec$transform <- "identity"
  spec$breaks <- pretty(spec$limits, n = 5)
  spec$breaks <- spec$breaks[spec$breaks >= spec$limits[1] &
                               spec$breaks <= spec$limits[2]]
  spec$labels <- squish_labels(spec$breaks, spec$limits, spec$squished)

  assemble_leaflet(md, spec, palette = "diverging", direction = direction,
                   popup = popup, tiles = tiles, opacity = opacity,
                   legend = legend, by = by)
}

assemble_leaflet <- function(md, spec, palette, direction = 1, popup = NULL,
                             tiles = "CartoDB.Positron", opacity = 0.8,
                             legend = TRUE, by = NULL) {
  check_leaflet()
  if (identical(md$kind, "raster")) {
    stop("leaflet maps here draw vector geometry, and this is a raster.\n",
         "  Use leaflet::addRasterImage() directly, or draw it with ",
         "map_surface(), which has a raster path.", call. = FALSE)
  }

  # EPSG:4326, always. Not display_crs() -- leaflet is Web Mercator and takes
  # WGS84 inputs, so the projection question is answered by the tile layer
  # rather than by us.
  geometry <- sf::st_transform(md$geometry, 4326)
  colours <- value_colours(md$value, spec, palette, direction)

  m <- leaflet::leaflet(options = leaflet::leafletOptions(minZoom = 3))
  if (!is.null(tiles)) m <- leaflet::addProviderTiles(m, tiles)

  labels <- popup_labels(md, popup, by)
  data <- sf::st_sf(geometry = geometry)

  m <- switch(
    md$kind,
    polygon = leaflet::addPolygons(
      m, data = data, fillColor = colours, fillOpacity = opacity,
      # A hairline stroke in the fill colour, for the same reason the static
      # maps carry one: adjacent cells drawn as separate paths leave a seam.
      color = colours, weight = 0.5, opacity = 1,
      highlightOptions = leaflet::highlightOptions(weight = 2,
                                                   color = "#222222",
                                                   bringToFront = TRUE),
      popup = labels),
    point = leaflet::addCircleMarkers(
      m, data = data, fillColor = colours, fillOpacity = opacity,
      color = colours, weight = 0.5, radius = 5, popup = labels),
    line = leaflet::addPolylines(
      m, data = data, color = colours, opacity = opacity, weight = 2,
      popup = labels)
  )

  if (isTRUE(legend)) m <- add_spec_legend(m, spec, palette, direction, md)
  m
}

# The colours, computed through the SAME spec the static map uses -- same
# transform, same limits, same squishing -- so the two agree cell for cell.
# This is the entire reason these functions exist rather than a documented
# call to leaflet::colorNumeric().
value_colours <- function(values, spec, palette, direction) {
  ramp <- ramp_colours(palette, direction)

  pos <- rescale_through_spec(values, spec)
  out <- scales::gradient_n_pal(ramp)(pos)
  # The same grey the static maps use for a cell with no value, so a hole in
  # the surface looks like a hole in both.
  out[is.na(out)] <- "#EBEBEB"
  out
}

# A value's position on the ramp, in [0, 1]. Squished rather than censored, as
# on the static scale: a value past the cap sits AT the cap rather than going
# grey, because grey already means "no prediction here".
rescale_through_spec <- function(values, spec) {
  if (!is.null(spec$rescaler)) {
    return(scales::squish(spec$rescaler(values, from = spec$limits), c(0, 1)))
  }
  trans <- as_transform(spec$transform)
  t <- trans$transform(values)
  lim <- trans$transform(spec$limits)
  scales::squish(scales::rescale(t, from = lim), c(0, 1))
}

as_transform <- function(x) {
  if (inherits(x, "transform")) return(x)
  scales::as.transform(x %||% "identity")
}

add_spec_legend <- function(m, spec, palette, direction, md) {
  breaks <- leaflet_legend_breaks(spec)
  labels <- leaflet_legend_labels(spec)

  leaflet::addLegend(
    m, position = "bottomright",
    colors = value_colours(breaks, spec, palette, direction),
    labels = labels,
    title = htmltools::HTML(gsub("\n", "<br/>",
                                 scale_name(md$label, spec$note))),
    opacity = 1
  )
}

# What a click says. The value and the join key always, because those are the
# two things a reader is clicking to find out; anything else on request.
popup_labels <- function(md, popup, by) {
  if (isFALSE(popup)) return(NULL)

  parts <- list()
  key <- by %||% intersect(c("grid_id", "cell_id", "id"), names(md$data))[1]
  if (!is.na(key) && !is.null(key) && key %in% names(md$data)) {
    parts[[key]] <- md$data[[key]]
  }
  parts[[md$label %||% "value"]] <- signif(md$value, 4)

  for (col in intersect(popup %||% character(0), names(md$data))) {
    v <- md$data[[col]]
    parts[[col]] <- if (is.numeric(v)) signif(v, 4) else as.character(v)
  }

  rows <- do.call(paste0, c(
    lapply(names(parts), function(nm) {
      paste0("<b>", nm, ":</b> ", parts[[nm]], "<br/>")
    })
  ))
  unname(rows)
}

check_leaflet <- function() {
  if (!requireNamespace("leaflet", quietly = TRUE) ||
      !requireNamespace("htmltools", quietly = TRUE)) {
    stop("interactive maps need the leaflet and htmltools packages.\n",
         '  install.packages(c("leaflet", "htmltools"))', call. = FALSE)
  }
}

# The breaks and labels an interactive legend shows, split out from drawing it
# so the "does it say the scale was capped" question can be asked in a test
# without building a widget.
leaflet_legend_breaks <- function(spec) {
  breaks <- spec$breaks
  if (!inherits(breaks, "waiver") && length(breaks)) return(breaks)
  breaks <- pretty(spec$limits, n = 5)
  breaks <- breaks[breaks >= spec$limits[1] & breaks <= spec$limits[2]]
  if (isTRUE(spec$squished) && !any(abs(breaks - spec$limits[2]) < 1e-9)) {
    breaks <- c(breaks[breaks < spec$limits[2]], spec$limits[2])
  }
  breaks
}

leaflet_legend_labels <- function(spec) {
  breaks <- leaflet_legend_breaks(spec)
  if (is.function(spec$labels)) {
    spec$labels(breaks)
  } else {
    squish_labels(breaks, spec$limits, isTRUE(spec$squished))(breaks)
  }
}
