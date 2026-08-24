#' The same geography over several periods, on one scale
#'
#' Six seasons of occupancy, twelve months of a projected surface, four
#' candidate models over the same grid. One shared colour scale across every
#' panel, because panels drawn separately cannot be compared and look as though
#' they can.
#'
#' @param x The geometry -- one grid, drawn once per set of values.
#' @param values The panels. One of:
#'   * a character vector of column names in `x`;
#'   * a matrix with one row per cell and one column per period, which is the
#'     form an averaging or posterior step emits -- column names become panel
#'     titles;
#'   * a named list of vectors, each in feature order or named by `by`.
#' @param titles Panel titles. Taken from the names of `values` when not given.
#' @param kind How the values are scaled: `"surface"`, `"probability"` or
#'   `"diverging"`.
#' @param midpoint The centre, for `kind = "diverging"`.
#' @param direction Which way the ramp runs; `-1` reverses it.
#' @param ncol Panels per row. Chosen to keep the figure roughly square when
#'   not given.
#' @param label What to call the quantity in the single shared legend.
#' @param expand How much margin to leave around the data, as a fraction of its
#'   own extent. Widen it when the data does not reach anything a reader can
#'   orient by -- a small grid in open water shows no coastline at all until the
#'   panel is wide enough to include one.
#' @inheritParams map_surface
#'
#' @details
#' # The shared scale is the point
#'
#' Limits and transform are computed once over **every** panel's values pooled
#' together, then applied to all of them. A per-panel scale makes each panel a
#' picture of its own relative pattern, and lays them out in a grid that
#' invites reading across -- so a quiet season and a busy one look identical
#' and the difference between them, the only thing a series is for, is the one
#' thing that has been scaled away.
#'
#' This is also why the transform is fixed once. [surface_scale()]'s automatic
#' choice depends on the data it sees; letting each panel choose would give a
#' log scale to the skewed months and a linear one to the flat ones.
#'
#' # Extent and land
#'
#' One extent, one projection, one coastline object, resolved once and used by
#' every panel. The scale bar and north arrow are drawn on the first panel
#' only.
#'
#' @return A \pkg{patchwork} object.
#'
#' @examples
#' grid <- example_grid()
#'
#' # three periods held on one scale
#' seasons <- cbind(spring = grid$density,
#'                  summer = grid$density * 2.5,
#'                  autumn = grid$density * 0.4)
#' map_panels(grid, seasons, label = "animals per km2")
#'
#' @export
map_panels <- function(x, values, by = NULL, coords = NULL, crs = NULL,
                       titles = NULL, kind = c("surface", "probability",
                                               "diverging"),
                       midpoint = NULL, direction = 1, ncol = NULL,
                       label = NULL,
                       coastline = TRUE, region = NULL,
                       transform = "auto", limits = NULL, probs = c(0, 0.99),
                       title = NULL, subtitle = NULL, caption = NULL,
                       scalebar = TRUE, north = TRUE, graticule = FALSE,
                       base_size = 11, expand = 0.02) {
  kind <- match.arg(kind)
  panels <- panel_values(x, values)
  titles <- titles %||% names(panels)

  mds <- lapply(seq_along(panels), function(i) {
    as_map_data(x, value = panels[[i]], by = by, coords = coords, crs = crs,
                label = label)
  })

  crs <- display_crs(mds[[1]], crs)
  mds <- lapply(mds, project_md, crs = crs)
  extent <- shared_extent(mds, expand)
  land <- coastline(extent, source = coastline, crs = crs)

  # The whole reason this function exists: one scale, computed over everything.
  pooled <- unlist(lapply(mds, function(m) m$value), use.names = FALSE)
  shared <- switch(
    kind,
    surface = surface_scale(pooled, transform = transform, limits = limits,
                            probs = probs),
    probability = list(limits = limits %||% c(0, 1)),
    diverging = {
      d <- diverging_scale(pooled, midpoint = midpoint, limits = limits)
      d$rescaler <- diverging_rescaler(d$midpoint)
      d$labels <- squish_labels(ggplot2::waiver(), d$limits, d$squished)
      d
    }
  )
  if (identical(kind, "probability")) {
    shared$breaks <- seq(shared$limits[1], shared$limits[2], length.out = 5)
    shared$transform <- "identity"
    shared$squished <- FALSE
  }

  panel_theme <- theme_fancymap_panel(base_size = base_size,
                                      graticule = graticule)

  plots <- lapply(seq_along(mds), function(i) {
    panel_of(
      mds[[i]], kind = kind,
      # The pooled spec itself, not the ingredients for each panel to redo the
      # calculation with -- see the note in panel_of().
      spec = shared,
      transform = shared$transform %||% "identity",
      limits = shared$limits, probs = probs, land = land, region = region,
      extent = extent, crs = crs, graticule = graticule,
      title = titles[i], midpoint = shared$midpoint, direction = direction,
      base_size = base_size,
      theme = panel_theme,
      scalebar = isTRUE(scalebar) && i == 1L,
      north = isTRUE(north) && i == 1L,
      name = scale_name(label %||% mds[[i]]$label, shared$note)
    )
  })

  patchwork::wrap_plots(plots, ncol = ncol %||% panel_columns(length(plots))) +
    # collect, so the identical legends on every panel become one. They can be
    # collected precisely because they are identical, which they are because
    # the scale was computed once.
    patchwork::plot_layout(guides = "collect") +
    patchwork::plot_annotation(
      title = title, subtitle = subtitle,
      caption = build_caption(caption, list(
        squish_note(shared, label), no_land_note(land, coastline)
      )),
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(size = base_size * 1.2,
                                           face = "bold", hjust = 0),
        plot.subtitle = ggplot2::element_text(size = base_size * 0.8, hjust = 0),
        plot.caption = ggplot2::element_text(size = base_size * 0.7, hjust = 0,
                                             colour = "grey30")
      )
    ) &
    ggplot2::theme(legend.position = "right")
}

# The panels, however they were handed over.
panel_values <- function(x, values) {
  if (is.matrix(values)) {
    nms <- colnames(values) %||% paste("panel", seq_len(ncol(values)))
    return(stats::setNames(
      lapply(seq_len(ncol(values)), function(j) values[, j]), nms))
  }
  if (is.character(values)) {
    return(stats::setNames(as.list(values), values))
  }
  if (is.list(values)) {
    if (is.null(names(values))) {
      names(values) <- paste("panel", seq_along(values))
    }
    return(values)
  }
  stop("`values` should be a character vector of column names, a matrix with ",
       "one column per panel, or a named list -- not a ", class(values)[1],
       ".\nFor a single map, use map_surface().", call. = FALSE)
}

# How many panels to a row. Up to three go in one row, which is how a short
# series reads -- left to right, in order. Past that a single row makes each
# panel too narrow to see, so it wraps towards square.
panel_columns <- function(n) {
  if (n <= 3) n else ceiling(sqrt(n))
}
