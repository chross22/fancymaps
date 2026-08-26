## A value and its uncertainty, and a value across periods.
##
## The defect these exist for: the density map and the extrapolation map are
## the same geography drawn twice with different legends, different colour
## languages and no visual link -- when the entire reason they sit together is
## to be compared cell by cell. Getting two ggplot objects and calling
## `patchwork` is what everyone does, and it is why the pairs never quite line
## up: each panel takes its extent from its own data, resolves its own
## projection, and sizes its own legend.
##
## So the shared things are computed ONCE, up here, and pushed down into both
## panels: one display CRS, one extent covering the union, one coastline, one
## set of furniture decisions. The panels differ only in what they draw and
## what their legend says.

#' A surface and its uncertainty, as one figure
#'
#' @param x The geometry, or a `map_data`. Both panels are drawn from it unless
#'   `uncertainty_from` names a different object.
#' @param value What the left panel colours by.
#' @param uncertainty What the right panel colours by: a CV, a standard error,
#'   a posterior standard deviation, an extrapolation score.
#' @param uncertainty_from A second object to take `uncertainty` from, when it
#'   does not live alongside `value`. Must cover the same cells.
#' @param kind How the left panel is scaled: `"surface"` for a skewed positive
#'   quantity, `"probability"` for one bounded at 0 and 1.
#' @param uncertainty_kind How the right panel is scaled. `"surface"` for a CV
#'   or an SE, which only increase; `"diverging"` for a signed score such as an
#'   extrapolation surface, which needs `uncertainty_midpoint`.
#' @param uncertainty_direction Which way the diverging ramp runs on the right
#'   panel. `-1` puts the warm arm at the low end, which is what an
#'   extrapolation surface wants.
#' @param uncertainty_midpoint The centre for a diverging right panel. Zero is
#'   the usual meaning and it is the default here, unlike in [map_diverging()],
#'   because the caller has already said the panel is diverging.
#' @param labels A length-2 character vector naming the two quantities in their
#'   legends.
#' @param titles A length-2 character vector of panel titles.
#' @param ncol Panels per row. Two side by side by default; `1` stacks them,
#'   which suits a tall study area.
#' @param expand How much margin to leave around the data, as a fraction of its
#'   own extent. Widen it when the data does not reach anything a reader can
#'   orient by -- a small grid in open water shows no coastline at all until the
#'   panel is wide enough to include one.
#' @inheritParams map_surface
#'
#' @details
#' Both panels are drawn on the **same extent** -- the union of the two, so
#' neither is cropped -- in the **same projection**, with the **same coastline
#' object**, and the furniture is drawn on the left panel only, since a scale
#' bar repeated on an identical extent is furniture twice.
#'
#' The two legends stay separate, and deliberately: they are different
#' quantities in different units, and a shared one would be a lie. What they
#' share is position, size and typography, which is what makes the pairing
#' read.
#'
#' @return A \pkg{patchwork} object.
#'
#' @examples
#' grid <- example_grid()
#'
#' map_pair(grid, "density", "cv",
#'          labels = c("animals per km2", "CV"))
#'
#' # the projection-and-extrapolation pair
#' map_pair(grid, "density", "mess",
#'          uncertainty_kind = "diverging", uncertainty_direction = -1,
#'          labels = c("animals per km2", "MESS"),
#'          titles = c("Predicted density",
#'                     "How familiar these conditions are"))
#'
#' @export
map_pair <- function(x, value, uncertainty, uncertainty_from = NULL,
                     by = NULL, coords = NULL, crs = NULL,
                     kind = c("surface", "probability"),
                     uncertainty_kind = c("surface", "diverging"),
                     uncertainty_midpoint = 0,
                     uncertainty_direction = 1,
                     labels = NULL, titles = NULL, ncol = 2,
                     coastline = TRUE, region = NULL,
                     transform = "auto", limits = NULL, probs = c(0, 0.99),
                     title = NULL, subtitle = NULL, caption = NULL,
                     scalebar = TRUE, north = TRUE,
                     scalebar_position = "bl", north_position = "tr",
                     graticule = FALSE,
                     base_size = 12, expand = 0.02) {
  kind <- match.arg(kind)
  uncertainty_kind <- match.arg(uncertainty_kind)

  labels <- labels %||% c(value_label(rlang::enquo(value), value),
                          value_label(rlang::enquo(uncertainty), uncertainty))

  left <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                      label = labels[1])
  right <- as_map_data(uncertainty_from %||% x, value = uncertainty, by = by,
                       coords = coords, crs = crs, label = labels[2])

  check_same_cells(left, right, !is.null(uncertainty_from))

  crs <- display_crs(left, crs)
  left <- project_md(left, crs)
  right <- project_md(right, crs)
  extent <- shared_extent(list(left, right), expand)

  # One coastline object, fetched once and handed to both. Two calls would
  # return the same land and cost twice as much, and if the sources ever
  # disagreed -- a fixture for one extent and a download for the other -- the
  # panels would show different shorelines.
  land <- coastline(extent, source = coastline, crs = crs)

  panel_theme <- theme_fancymap_panel(base_size = base_size,
                                      graticule = graticule)

  # Both scales are settled HERE rather than inside the panels, because the
  # figure has to say what they decided and only this level can see both. A
  # pair's panels resolve their scales separately -- unlike map_panels(), where
  # one shared scale means one note -- so either panel may cap, and each cap is
  # a fact about the figure. Found drawing dsmfit's projection pair: the
  # density panel capped at its 99th percentile and the figure did not mention
  # it. The first fix gave each panel its own caption, which was worse: two
  # notes, each left-aligned under its own panel, each far wider than a panel
  # is, printed on top of each other and neither legible. Two capped panels is
  # the ordinary case, not the corner -- `probs` caps at the 99th percentile by
  # default, so most real pairs cap twice -- and one caption under the whole
  # figure is the only place two full sentences fit.
  spec_left <- panel_spec(left, kind, transform, limits, probs)
  spec_right <- panel_spec(right, uncertainty_kind, transform, NULL, probs,
                           uncertainty_midpoint)

  p_left <- panel_of(left, kind = kind, transform = transform, limits = limits,
                     probs = probs, land = land, region = region,
                     extent = extent, crs = crs, graticule = graticule,
                     title = titles[1] %||% NULL, base_size = base_size,
                     theme = panel_theme, scalebar = scalebar, north = north,
                     scalebar_position = scalebar_position,
                     north_position = north_position, spec = spec_left)

  p_right <- panel_of(right, kind = uncertainty_kind, transform = transform,
                      limits = NULL, probs = probs, land = land,
                      region = region, extent = extent, crs = crs,
                      graticule = graticule, title = titles[2] %||% NULL,
                      midpoint = uncertainty_midpoint,
                      direction = uncertainty_direction,
                      base_size = base_size, theme = panel_theme,
                      # The furniture goes on the left panel only: the extent
                      # is identical, so a second scale bar measures nothing
                      # new and a second north arrow points the same way.
                      scalebar = FALSE, north = FALSE, spec = spec_right)

  # One note per line: joined with a space they run past the figure edge and
  # the second is clipped, which is the same silence in a different place.
  #
  # The land note belongs here too, and was missing entirely -- every other
  # verb carries it and a pair did not, so a pair drawn where no coastline
  # source resolved said nothing about it. That is the one thing the package
  # promises never to leave unsaid: a map with no shoreline looks deliberate,
  # and "there is no land in this extent" and "no source was available" are
  # opposite facts that look identical.
  notes <- c(squish_note(spec_left, left$label),
             squish_note(spec_right, right$label),
             no_land_note(land, coastline))

  patchwork::wrap_plots(list(p_left, p_right), ncol = ncol) +
    patchwork::plot_annotation(
      title = title, subtitle = subtitle,
      caption = build_caption(
        caption,
        list(if (length(notes)) paste(notes, collapse = "\n"))
      ),
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(size = base_size * 1.1,
                                           face = "bold", hjust = 0),
        plot.subtitle = ggplot2::element_text(size = base_size * 0.72,
                                              hjust = 0),
        plot.caption = ggplot2::element_text(size = base_size * 0.65,
                                             hjust = 0, colour = "grey30")
      )
    )
}

# One panel of a multi-panel figure: the same choices the single-map verbs
# make, but taking the extent, the CRS and the land from the caller rather
# than resolving them itself.
panel_of <- function(md, kind, transform, limits, probs, land, region, extent,
                     crs, graticule, title, base_size, theme,
                     midpoint = NULL, direction = 1, scalebar = FALSE,
                     north = FALSE, scalebar_position = "bl",
                     north_position = "tr", name = NULL, spec = NULL) {
  # A caller that has already settled the scale hands the WHOLE spec down,
  # rather than the transform and the limits for this panel to re-derive from.
  #
  # That distinction is the entire correctness of `map_panels()`. Given the
  # same limits, `surface_scale()` still recomputes `squished` against each
  # panel's own values -- so a panel holding the maximum gets a top label
  # reading ">= 4.52" and a quieter one gets "2", the two scales are no longer
  # identical objects, and `patchwork` cannot collect them into a single
  # legend. The figure then draws one legend per panel: exactly the thing a
  # shared scale exists to prevent, and it looks like a layout quirk rather
  # than like the scales having silently diverged.
  spec <- spec %||% panel_spec(md, kind, transform, limits, probs, midpoint)

  palette <- switch(kind, surface = "sequential", probability = "bounded",
                    diverging = "diverging")

  p <- ggplot2::ggplot() +
    value_layer(md) +
    land_layer(land) +
    region_layer(region, crs) +
    scale_pair(spec, name %||% scale_name(md$label, spec$note), md$kind,
               palette = palette, direction = direction,
               midpoint = if (identical(kind, "diverging")) spec$midpoint else NULL) +
    coord_for(extent, graticule)

  check_furniture_corners(
    c(scalebar = if (isTRUE(scalebar)) scalebar_position,
      north = if (isTRUE(north)) north_position))

  if (isTRUE(scalebar)) {
    p <- p + scale_bar(extent, position = scalebar_position,
                       base_size = base_size)
  }
  if (isTRUE(north)) {
    p <- p + north_arrow(extent, position = north_position,
                         base_size = base_size)
  }

  p + ggplot2::labs(title = title) + theme
}

# The scale a panel is drawn on, resolved from the panel's own values. Split
# out of `panel_of()` so that a caller can settle the scale first and still
# read what it decided -- `map_pair()` needs both panels' specs to write one
# caption, and computing them here rather than inside each panel is what keeps
# the caption and the colours describing the same numbers.
panel_spec <- function(md, kind, transform, limits, probs, midpoint = NULL) {
  switch(
    kind,
    surface = surface_scale(md$value, transform = transform, limits = limits,
                            probs = probs),
    probability = list(limits = limits %||% c(0, 1),
                       breaks = seq(0, 1, length.out = 5),
                       transform = "identity", squished = FALSE, note = NULL),
    diverging = {
      s <- diverging_scale(md$value, midpoint = midpoint %||% 0,
                           limits = limits, probs = c(0.01, 0.99))
      s$rescaler <- diverging_rescaler(s$midpoint)
      s$labels <- squish_labels(ggplot2::waiver(), s$limits, s$squished)
      s
    }
  )
}

# The two panels of a pair are read cell by cell, so they have to BE the same
# cells. When both come off one object they are, by construction; when
# `uncertainty_from` names a second one, nothing has checked.
#
# Two different grids over the same water still draw -- both get projected to
# the same CRS and both get the same extent -- and the figure looks entirely
# normal. It just invites a comparison that cannot be made.
check_same_cells <- function(left, right, separate) {
  if (length(left$geometry) == length(right$geometry)) {
    if (!separate) return(invisible(NULL))
    a <- sf::st_bbox(sf::st_transform(left$geometry, 4326))
    b <- sf::st_bbox(sf::st_transform(right$geometry, 4326))
    if (max(abs(as.numeric(a) - as.numeric(b))) < 1e-6) {
      return(invisible(NULL))
    }
    warning("`uncertainty_from` covers a different extent from `x`, though ",
            "both have ", length(left$geometry), " features.\n  The panels ",
            "are drawn to be compared cell by cell, and these may not be the ",
            "same cells.", call. = FALSE)
    return(invisible(NULL))
  }

  stop("the two panels have different numbers of features -- ",
       length(left$geometry), " and ", length(right$geometry),
       ".\n  A pair is read cell by cell, so both panels have to be the same ",
       "cells.", call. = FALSE)
}
