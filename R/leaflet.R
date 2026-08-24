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
  m <- leaflet_base(tiles)
  m <- add_md_layer(m, md, spec, palette, direction, opacity, popup = popup,
                    by = by)
  if (isTRUE(legend)) {
    m <- add_spec_legend(m, spec, palette, direction,
                         scale_name(md$label, spec$note))
  }
  m
}

leaflet_base <- function(tiles) {
  check_leaflet()
  m <- leaflet::leaflet(options = leaflet::leafletOptions(minZoom = 3))
  if (!is.null(tiles)) m <- leaflet::addProviderTiles(m, tiles)
  m
}

# One set of geometry on a map, optionally as a named group so that a layer
# control can switch it on and off.
add_md_layer <- function(m, md, spec, palette, direction = 1, opacity = 0.8,
                         group = NULL, popup = NULL, by = NULL) {
  if (identical(md$kind, "raster")) {
    stop("leaflet maps here draw vector geometry, and this is a raster.\n",
         "  Use leaflet::addRasterImage() directly, or draw it with ",
         "map_surface(), which has a raster path.", call. = FALSE)
  }

  # EPSG:4326, always. Not display_crs() -- leaflet is Web Mercator and takes
  # WGS84 inputs, so the projection question is answered by the tile layer
  # rather than by us.
  data <- sf::st_sf(geometry = sf::st_transform(md$geometry, 4326))
  colours <- value_colours(md$value, spec, palette, direction)
  labels <- popup_labels(md, popup, by)

  switch(
    md$kind,
    polygon = leaflet::addPolygons(
      m, data = data, group = group, fillColor = colours,
      fillOpacity = opacity,
      # A hairline stroke in the fill colour, for the same reason the static
      # maps carry one: adjacent cells drawn as separate paths leave a seam.
      color = colours, weight = 0.5, opacity = 1,
      highlightOptions = leaflet::highlightOptions(weight = 2,
                                                   color = "#222222",
                                                   bringToFront = TRUE),
      popup = labels),
    point = leaflet::addCircleMarkers(
      m, data = data, group = group, fillColor = colours,
      fillOpacity = opacity, color = colours, weight = 0.5, radius = 5,
      popup = labels),
    line = leaflet::addPolylines(
      m, data = data, group = group, color = colours, opacity = opacity,
      weight = 2, popup = labels)
  )
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

add_spec_legend <- function(m, spec, palette, direction, title,
                            group = NULL, class_index = NULL) {
  breaks <- leaflet_legend_breaks(spec)
  labels <- leaflet_legend_labels(spec)

  leaflet::addLegend(
    m, position = "bottomright",
    colors = value_colours(breaks, spec, palette, direction),
    labels = labels,
    # `group =` ties a legend to a layer group -- but only for OVERLAY groups.
    # For the radio-button `baseGroups` a pair and a series need, leaflet
    # never fires the events its legend binding listens for, so both legends
    # stay on screen and one of them describes a layer that is not being shown.
    # `sync_group_legends()` handles that case with the event leaflet does
    # fire; this is still passed for the overlay case.
    group = group,
    className = paste(c("info legend", legend_class(class_index)),
                      collapse = " "),
    title = htmltools::HTML(gsub("\n", "<br/>", title)),
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

#' A surface and its uncertainty, interactively
#'
#' The interactive counterpart of [map_pair()]: both quantities on one map, with
#' a control to switch between them.
#'
#' @inheritParams leaflet-maps
#' @inheritParams map_pair
#' @param labels A length-2 character vector naming the two quantities. These
#'   are what the switch is labelled with, so they should read as names rather
#'   than as units.
#' @param position Where the layer control sits.
#'
#' @details
#' # Why one map and a switch, rather than two maps side by side
#'
#' [map_pair()] draws two panels because a static figure has no other way to
#' show two things at once, and it goes to some trouble -- shared extent, shared
#' projection, one coastline, aligned panels -- to make them comparable cell by
#' cell. All of that is machinery for approximating, on paper, something an
#' interactive map gets for free.
#'
#' Switching layers on one map is a **blink comparison**: the same cells, at the
#' same position and the same zoom, changing only in the quantity drawn. Nothing
#' has to be aligned because nothing moved. Two side-by-side widgets would
#' reintroduce exactly the alignment problem `map_pair()` exists to solve, and
#' would need a synchronisation dependency to solve it again.
#'
#' The trade is that the two can no longer be seen simultaneously. When that is
#' what you want -- a figure for a manuscript, or a reader who cannot click --
#' [map_pair()] is the one to use.
#'
#' Each layer carries its own legend, shown and hidden with it, because the two
#' are different quantities in different units.
#'
#' @return A \pkg{leaflet} widget.
#'
#' @seealso [map_pair()], the static original.
#'
#' @examples
#' \dontrun{
#' grid <- example_grid()
#'
#' leaflet_pair(grid, "density", "cv")
#'
#' leaflet_pair(grid, "density", "mess", uncertainty_kind = "diverging",
#'              uncertainty_direction = -1,
#'              labels = c("density", "extrapolation"))
#' }
#'
#' @export
leaflet_pair <- function(x, value, uncertainty, uncertainty_from = NULL,
                         by = NULL, coords = NULL, crs = NULL,
                         kind = c("surface", "probability"),
                         uncertainty_kind = c("surface", "diverging"),
                         uncertainty_midpoint = 0, uncertainty_direction = 1,
                         labels = NULL, transform = "auto", limits = NULL,
                         probs = c(0, 0.99), popup = NULL,
                         tiles = "CartoDB.Positron", opacity = 0.8,
                         position = "topright") {
  kind <- match.arg(kind)
  uncertainty_kind <- match.arg(uncertainty_kind)

  labels <- labels %||% c(value_label(rlang::enquo(value), value),
                          value_label(rlang::enquo(uncertainty), uncertainty))

  left <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                      label = labels[1])
  right <- as_map_data(uncertainty_from %||% x, value = uncertainty, by = by,
                       coords = coords, crs = crs, label = labels[2])
  check_same_cells(left, right, !is.null(uncertainty_from))

  specs <- list(
    leaflet_spec(left$value, kind, transform, limits, probs),
    leaflet_spec(right$value, uncertainty_kind, transform, NULL, probs,
                 midpoint = uncertainty_midpoint)
  )
  palettes <- c(leaflet_palette(kind), leaflet_palette(uncertainty_kind))
  directions <- c(1, uncertainty_direction)
  names <- c(scale_name(left$label, specs[[1]]$note),
             scale_name(right$label, specs[[2]]$note))
  groups <- c(labels[1] %||% "value", labels[2] %||% "uncertainty")

  m <- leaflet_base(tiles)
  for (i in 1:2) {
    md <- list(left, right)[[i]]
    m <- add_md_layer(m, md, specs[[i]], palettes[i], directions[i], opacity,
                      group = groups[i], popup = popup, by = by)
    m <- add_spec_legend(m, specs[[i]], palettes[i], directions[i], names[i],
                         group = groups[i], class_index = i)
  }

  # baseGroups, not overlayGroups: these are two views of the same cells and
  # exactly one should be showing. Overlaid, the upper one hides the lower and
  # the map silently shows whichever was added last.
  m <- leaflet::addLayersControl(
    m, baseGroups = groups, position = position,
    options = leaflet::layersControlOptions(collapsed = FALSE))
  sync_group_legends(m, groups)
}

#' A series over several periods, interactively
#'
#' The interactive counterpart of [map_panels()]: every period on one map, one
#' shared scale, and a control to step through them.
#'
#' @inheritParams leaflet-maps
#' @inheritParams map_panels
#' @param position Where the layer control sits.
#'
#' @details
#' # One legend, and it does not move
#'
#' The scale is computed once over every period pooled, exactly as in
#' [map_panels()] -- both call the same `pooled_spec()`, so a cell of a given
#' value is the same colour in the static figure and this one.
#'
#' Because the scale is shared, the legend is drawn **once and left alone**
#' rather than tied to each layer. Stepping through the periods changes the map
#' and not the legend, which is what makes the comparison readable: a colour
#' that means 0.4 in spring still means 0.4 in autumn, and the legend sitting
#' still is the visible evidence of that.
#'
#' It is also the interactive form that suits a series best. Small multiples ask
#' a reader to compare across a page; stepping through them in place compares by
#' change-blindness instead, which is far more sensitive to a small shift and
#' needs no alignment at all.
#'
#' @return A \pkg{leaflet} widget.
#'
#' @seealso [map_panels()], the static original.
#'
#' @examples
#' \dontrun{
#' grid <- example_grid()
#' seasons <- cbind(spring = grid$density,
#'                  summer = grid$density * 2.5,
#'                  autumn = grid$density * 0.4)
#'
#' leaflet_panels(grid, seasons, label = "animals per km2")
#' }
#'
#' @export
leaflet_panels <- function(x, values, by = NULL, coords = NULL, crs = NULL,
                           titles = NULL,
                           kind = c("surface", "probability", "diverging"),
                           midpoint = NULL, direction = 1, label = NULL,
                           transform = "auto", limits = NULL,
                           probs = c(0, 0.99), popup = NULL,
                           tiles = "CartoDB.Positron", opacity = 0.8,
                           legend = TRUE, position = "topright") {
  kind <- match.arg(kind)
  panels <- panel_values(x, values)
  titles <- titles %||% names(panels)

  mds <- lapply(panels, function(v) {
    as_map_data(x, value = v, by = by, coords = coords, crs = crs,
                label = label)
  })

  # The same pooled scale the static version uses, from the same function --
  # so a period drawn here and drawn by map_panels() is the same colour.
  pooled <- unlist(lapply(mds, function(m) m$value), use.names = FALSE)
  shared <- pooled_spec(pooled, kind = kind, transform = transform,
                        limits = limits, probs = probs, midpoint = midpoint)
  palette <- leaflet_palette(kind)

  m <- leaflet_base(tiles)
  for (i in seq_along(mds)) {
    m <- add_md_layer(m, mds[[i]], shared, palette, direction, opacity,
                      group = titles[i], popup = popup, by = by)
  }

  if (isTRUE(legend)) {
    # No `group =` here, deliberately. The scale is shared, so the legend
    # belongs to the figure rather than to any one period -- and a legend that
    # sits still while the map changes under it is the visible evidence that
    # the periods are on one scale.
    m <- add_spec_legend(m, shared, palette, direction,
                         scale_name(label %||% mds[[1]]$label, shared$note))
  }

  m <- leaflet::addLayersControl(
    m, baseGroups = titles, position = position,
    options = leaflet::layersControlOptions(collapsed = FALSE))

  for (g in titles[-1]) m <- leaflet::hideGroup(m, g)
  m
}

# The scale spec for one interactive layer. `pooled_spec()` covers the shared
# case; this is its single-layer sibling and they agree by construction.
leaflet_spec <- function(values, kind, transform, limits, probs,
                         midpoint = NULL) {
  pooled_spec(values, kind = kind, transform = transform, limits = limits,
              probs = probs, midpoint = midpoint)
}

leaflet_palette <- function(kind) {
  switch(kind, surface = "sequential", probability = "bounded",
         diverging = "diverging")
}


## Legends that follow a radio-button layer control.
##
## `addLegend(group =)` binds a legend to a layer group by listening for
## `overlayadd` and `overlayremove`. A pair and a series both want radio
## buttons rather than checkboxes -- exactly one layer showing -- which means
## `baseGroups`, and leaflet fires `baselayerchange` for those instead. So the
## binding never fires: every legend stays on screen, and on a pair one of them
## describes a quantity that is not being drawn.
##
## Ten lines of JavaScript on the event leaflet does fire. The alternative was
## to use `overlayGroups` so the built-in binding works, and that is worse: two
## overlays can both be on at once, the upper hides the lower, and the map shows
## whichever happened to be added last with no way to tell.

legend_class <- function(index) {
  if (is.null(index)) return(NULL)
  paste0("fancymaps-legend-", index)
}

sync_group_legends <- function(m, groups) {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    warning("legends cannot be tied to the layer control without the ",
            "htmlwidgets package, so every legend is shown at once.\n",
            "  One of them describes a layer that is not on the map.",
            call. = FALSE)
    return(m)
  }

  js <- sprintf("
function(el, x) {
  var groups = [%s];
  var show = function(name) {
    groups.forEach(function(g, i) {
      var nodes = el.querySelectorAll('.fancymaps-legend-' + (i + 1));
      for (var j = 0; j < nodes.length; j++) {
        nodes[j].style.display = (g === name) ? '' : 'none';
      }
    });
  };
  this.on('baselayerchange', function(e) { show(e.name); });
  show(groups[0]);
}", paste(vapply(groups, js_string, character(1)), collapse = ", "))

  htmlwidgets::onRender(m, js)
}

# A group name as a JavaScript string literal. Group names are whatever the
# caller passed as labels, so they can contain quotes and backslashes.
js_string <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub("'", "\\\\'", x)
  paste0("'", x, "'")
}
