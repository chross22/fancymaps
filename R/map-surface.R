#' Map a predicted surface
#'
#' The primary deliverable of a spatial model: a predicted quantity per cell,
#' over a grid, with land, a stated projection and a scale that was chosen.
#'
#' @param x The geometry. An `sf` object of polygons, points or lines, a
#'   \pkg{terra} `SpatRaster`, or a data frame with coordinate columns. See
#'   [as_map_data()].
#' @param value What to colour by: a column name, a vector in feature order, or
#'   a named vector joined by `by`. See [as_map_data()].
#' @param by,coords,crs Passed to [as_map_data()]. `crs` is also the CRS the
#'   map is drawn in -- see [display_crs()] for what happens when it is not
#'   given.
#' @param label What to call the value in the legend. Defaults to the column
#'   name.
#' @param coastline Where land comes from. `TRUE` chooses a source for the
#'   extent, `FALSE` draws none, a path or an `sf` object supplies one. See
#'   [coastline()].
#' @param region An `sf` polygon to outline over the map -- the study area, or
#'   whatever the grid was cropped to.
#' @param transform,limits,probs Passed to [surface_scale()], which decides how
#'   the values are ramped and says so.
#' @param title,subtitle,caption Figure text. The caption is where provenance
#'   belongs: which period, which product, which correction was not applied.
#'   Anything this function had to decide -- a capped scale, a missing
#'   coastline -- is appended to it.
#' @param scalebar,north Whether to draw the furniture. See [scale_bar()] and
#'   [north_arrow()].
#' @param inset Whether to draw a locator inset -- a small wider map with this
#'   figure's extent marked on it. `FALSE` by default, unlike the scale bar and
#'   north arrow, because an inset sits over a corner of the data rather than in
#'   a margin. `TRUE` uses the same coastline source as the map; a path or an
#'   `sf` object gives the inset its own.
#' @param inset_position,inset_size,inset_zoom Which corner the inset sits in,
#'   how much of the panel width it takes, and how many times wider than the map
#'   it starts. See [locator_inset()] -- `inset_zoom` is a starting point, not a
#'   setting, because an inset showing nothing but water orients nobody.
#' @param graticule Whether to label coordinates. Off by default; see
#'   [theme_fancymap()].
#' @param base_size Base font size in points.
#' @param theme A theme to use instead of [theme_fancymap()].
#' @param expand How much margin to leave around the data, as a fraction of its
#'   own extent. The default is a thin margin. Widen it when the data does not
#'   reach anything a reader can orient by -- a small grid in open water shows
#'   no coastline at all until the panel is wide enough to include one.
#'
#' @details
#' # What it does not do
#'
#' It does not compute the surface. Density, abundance, occupancy and their
#' uncertainties are the fitting package's job; this draws what it is handed.
#'
#' # Skewed quantities
#'
#' Predicted density is usually extremely skewed, and by default the scale
#' notices: see [surface_scale()] for the rule, which is reported whenever it
#' fires. For a probability, use [map_probability()], whose scale is bounded at
#' 0 and 1 rather than at whatever the data reached.
#'
#' @return A \pkg{ggplot2} object.
#'
#' @seealso [map_probability()] for a bounded quantity, [map_diverging()] for
#'   one with a meaningful centre, [map_pair()] to draw one beside its
#'   uncertainty.
#'
#' @examples
#' grid <- example_grid()
#'
#' map_surface(grid, "density", label = "animals per km2")
#'
#' # a fixed scale, for comparing with another figure
#' map_surface(grid, "density", transform = "log", limits = c(0.001, 1))
#'
#' @export
map_surface <- function(x, value = NULL, by = NULL, coords = NULL, crs = NULL,
                        label = NULL, coastline = TRUE, region = NULL,
                        transform = "auto", limits = NULL, probs = c(0, 0.99),
                        title = NULL, subtitle = NULL, caption = NULL,
                        scalebar = TRUE, north = TRUE, inset = FALSE,
                        inset_position = "br", inset_size = 0.3,
                        inset_zoom = 8, graticule = FALSE,
                        base_size = 12, theme = NULL, expand = 0.02) {
  label <- label %||% value_label(rlang::enquo(value), value)
  md <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                    label = label)
  require_value(md, "map_surface")

  crs <- display_crs(md, crs)
  spec <- surface_scale(md$value, transform = transform, limits = limits,
                        probs = probs)

  assemble_map(
    md,
    scales = scale_pair(spec, scale_name(md$label, spec$note), md$kind,
                        palette = "sequential"),
    crs = crs, coastline = coastline, region = region, graticule = graticule,
    title = title, subtitle = subtitle, caption = caption,
    notes = list(squish_note(spec, md$label)),
    scalebar = scalebar, north = north, inset = inset,
    inset_position = inset_position, inset_size = inset_size,
    inset_zoom = inset_zoom, base_size = base_size, theme = theme,
    expand = expand
  )
}

#' Map a probability
#'
#' For a quantity that lives on \[0, 1\]: posterior occupancy, probability of
#' presence, the proportion of ensemble members that agreed.
#'
#' @inheritParams map_surface
#' @param limits The ends of the scale. `c(0, 1)` by default, and changing it
#'   is usually a mistake -- see below.
#'
#' @details
#' A probability is not a skewed positive quantity with a coincidental upper
#' bound, and drawing it with [map_surface()] gets two things wrong.
#'
#' The scale is **fixed at 0 and 1**, not taken from the data. A map whose
#' occupancy ran from 0.2 to 0.6 and was stretched across the full ramp says
#' "high here, low there" in exactly the colours a map running 0 to 1 would
#' use, and the two are not the same claim. Fixed ends also mean 0.6 is the
#' same colour in every figure, which is what makes a series of years
#' comparable at a glance.
#'
#' The **ramp is different**. A sequential ramp puts its most saturated colour
#' at the top of the data; here the top is certainty, and a cell at 0.02 should
#' look nearly like a cell at 0, with weight arriving only as the value
#' approaches 1.
#'
#' Values outside \[0, 1\] are drawn at the ends and reported. A posterior mean
#' cannot leave the interval, but a rescaled index or a ratio mistaken for a
#' probability can, and that is worth being told about rather than clipping
#' quietly.
#'
#' @return A \pkg{ggplot2} object.
#'
#' @seealso [map_surface()], [map_panels()] for the same grid across seasons.
#'
#' @examples
#' grid <- example_grid()
#' map_probability(grid, "occupancy", label = "occupancy")
#'
#' @export
map_probability <- function(x, value = NULL, by = NULL, coords = NULL,
                            crs = NULL, label = NULL, coastline = TRUE,
                            region = NULL, limits = c(0, 1),
                            title = NULL, subtitle = NULL, caption = NULL,
                            scalebar = TRUE, north = TRUE, inset = FALSE,
                            inset_position = "br", inset_size = 0.3,
                            inset_zoom = 8, graticule = FALSE,
                            base_size = 12, theme = NULL, expand = 0.02) {
  label <- label %||% value_label(rlang::enquo(value), value)
  md <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                    label = label)
  require_value(md, "map_probability")

  outside <- sum(md$value < limits[1] | md$value > limits[2], na.rm = TRUE)
  if (outside > 0) {
    message(outside, " value(s) fall outside [", limits[1], ", ", limits[2],
            "] and are drawn at the ends. If these are not probabilities, ",
            "map_surface() is the one you want.")
  }

  spec <- list(limits = limits, breaks = seq(limits[1], limits[2], length.out = 5),
               labels = ggplot2::waiver(), transform = "identity",
               squished = FALSE, note = NULL)

  assemble_map(
    md,
    scales = scale_pair(spec, md$label %||% "probability", md$kind,
                        palette = "bounded"),
    crs = display_crs(md, crs), coastline = coastline, region = region,
    graticule = graticule, title = title, subtitle = subtitle,
    caption = caption,
    notes = list(if (outside > 0) {
      paste0(outside, " cell(s) fall outside [", limits[1], ", ", limits[2],
             "] and are drawn at the ends.")
    }),
    scalebar = scalebar, north = north, inset = inset,
    inset_position = inset_position, inset_size = inset_size,
    inset_zoom = inset_zoom, base_size = base_size, theme = theme,
    expand = expand
  )
}

#' Map a quantity with a meaningful centre
#'
#' For anything that diverges: an extrapolation score around zero, model
#' residuals around their own mean, a difference between two periods around no
#' change.
#'
#' @inheritParams map_surface
#' @param midpoint The value the neutral colour sits at. **Required.**
#' @param limits,probs Passed to [diverging_scale()]. Limits are made symmetric
#'   about `midpoint`.
#' @param direction Which way round the ramp runs. `1` puts the warm arm at the
#'   high end; `-1` reverses it, which is what an extrapolation surface wants --
#'   its alarming values are the negative ones.
#'
#' @details
#' `midpoint` has no default on purpose. [ggplot2::scale_fill_gradient2()]
#' falls back to the middle of the range, which is almost never the meaning:
#'
#' * an **extrapolation score** diverges around **zero**, because zero is where
#'   inside the training range becomes outside it;
#' * **deviance residuals** diverge around **their own mean**, because they do
#'   not average zero, and centring them on zero paints every bin the same
#'   colour -- a bug the first customer of this package hit in exactly that
#'   form.
#'
#' @return A \pkg{ggplot2} object.
#'
#' @seealso [diverging_scale()] for the limits, [map_pair()] to draw this
#'   beside the surface it qualifies.
#'
#' @examples
#' grid <- example_grid()
#'
#' # zero is the meaning, and the alarming side is the negative one
#' map_diverging(grid, "mess", midpoint = 0, direction = -1, label = "MESS")
#'
#' # residuals diverge around their own mean
#' map_diverging(grid, "residual", midpoint = mean(grid$residual),
#'               label = "deviance residual")
#'
#' @export
map_diverging <- function(x, value = NULL, midpoint, by = NULL, coords = NULL,
                          crs = NULL, label = NULL, coastline = TRUE,
                          region = NULL, limits = NULL, probs = c(0.01, 0.99),
                          direction = 1,
                          title = NULL, subtitle = NULL, caption = NULL,
                          scalebar = TRUE, north = TRUE, inset = FALSE,
                          inset_position = "br", inset_size = 0.3,
                          inset_zoom = 8, graticule = FALSE,
                          base_size = 12, theme = NULL, expand = 0.02) {
  label <- label %||% value_label(rlang::enquo(value), value)
  md <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                    label = label)
  require_value(md, "map_diverging")

  spec <- diverging_scale(md$value, midpoint = midpoint, limits = limits,
                          probs = probs)
  spec$rescaler <- diverging_rescaler(spec$midpoint)
  spec$labels <- squish_labels(ggplot2::waiver(), spec$limits, spec$squished)

  assemble_map(
    md,
    scales = scale_pair(spec, scale_name(md$label, spec$note), md$kind,
                        midpoint = spec$midpoint, direction = direction),
    crs = display_crs(md, crs), coastline = coastline, region = region,
    graticule = graticule, title = title, subtitle = subtitle,
    caption = caption,
    notes = list(squish_note(spec, md$label)),
    scalebar = scalebar, north = north, inset = inset,
    inset_position = inset_position, inset_size = inset_size,
    inset_zoom = inset_zoom, base_size = base_size, theme = theme,
    expand = expand
  )
}

require_value <- function(md, fn) {
  if (is.null(md$value)) {
    stop(fn, "() colours cells by a value, and none was given.\n",
         "Pass `value =` -- a column name, or the numbers themselves.",
         call. = FALSE)
  }
  invisible(md)
}
