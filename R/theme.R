#' A theme for maps
#'
#' [fancyfx::theme_fancyfx()] with the axis furniture taken off. An effect plot
#' wants axis titles, tick labels and a grid, because the numbers on its axes
#' are the quantities being discussed. A map's axes are its coordinates, which
#' are almost never what a reader is being asked to look at -- and a projected
#' map labelled `x (km)` or a geographic one labelled `45.0degN` every half
#' degree is panel furniture competing with the thing being shown.
#'
#' Sharing a base with `fancyfx` is deliberate: an effect figure and a map
#' figure from the same analysis should read as one system, so the fonts, the
#' sizes and the legend styling come from one place and change in one place.
#'
#' @param base_size Base font size in points. Everything else is a multiple of
#'   it, so raising it scales the figure and stays balanced.
#' @param base_family Base font family. Empty lets the device choose.
#' @param legend Legend position: `"right"`, `"bottom"`, `"top"`, `"left"` or
#'   `"none"`. `"right"` suits a tall panel and `"bottom"` a wide one, which is
#'   why the paired and panelled layouts change it.
#' @param graticule Whether to draw coordinate labels and gridlines. `FALSE` by
#'   default on the reasoning above. Set `TRUE` when the coordinates are the
#'   point -- a locator map, or a figure whose caption cites positions.
#' @param border Whether to draw a thin frame around the panel. `TRUE` by
#'   default here, unlike in `fancyfx`: a map has no axis lines to bound it, so
#'   without a frame the sea and the page are the same white.
#' @param ... Passed to [fancyfx::theme_fancyfx()], so its per-element size
#'   arguments all work.
#'
#' @return A \pkg{ggplot2} theme object.
#'
#' @seealso [theme_fancymap_panel()] for the variant used inside a multi-panel
#'   figure, and [fancyfx::theme_fancyfx()] for the base.
#'
#' @examples
#' library(ggplot2)
#'
#' box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
#'                    crs = sf::st_crs(4326))
#' ggplot(coastline(box)) +
#'   geom_sf() +
#'   theme_fancymap()
#'
#' # with coordinates, when they are the point
#' ggplot(coastline(box)) +
#'   geom_sf() +
#'   theme_fancymap(graticule = TRUE)
#'
#' @export
theme_fancymap <- function(base_size = 12, base_family = "", legend = "right",
                           graticule = FALSE, border = TRUE, ...) {
  horizontal <- legend %in% c("top", "bottom")

  base <- fancyfx::theme_fancyfx(base_size = base_size,
                                 base_family = base_family,
                                 legend = legend, border = border, ...)

  stripped <- if (graticule) {
    ggplot2::theme(
      # Even when the graticule is wanted, the axis TITLES are not: "x" and "y"
      # name nothing, and a reader who needs the coordinates can read the
      # numbers.
      axis.title = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "grey85",
                                               linewidth = 0.2),
      panel.ontop = FALSE
    )
  } else {
    ggplot2::theme(
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.line = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )
  }

  base + stripped + ggplot2::theme(
    # Sea, so that a cell with no prediction is visibly a hole in the surface
    # rather than the page showing through, and so the panel has an edge even
    # where no land reaches it.
    panel.background = ggplot2::element_rect(fill = "#F2F5F7", colour = NA),
    panel.border = if (border) {
      ggplot2::element_rect(fill = NA, colour = "grey30", linewidth = 0.4)
    } else {
      ggplot2::element_blank()
    },
    # A colourbar's proportions follow the legend's orientation, and getting
    # this wrong is not cosmetic: a bar sized for a column and then laid out
    # along a row is a centimetre long with six labels stacked on top of each
    # other, which is what a paired figure produced before this was here.
    # These are the KEY sizes, and a colourbar is five keys long -- so the
    # bar that gets drawn is five times what is written here. Sized so a
    # horizontal bar stays under a single panel of a paired figure rather than
    # running across into its neighbour's.
    legend.key.height = grid::unit(if (horizontal) 9 else base_size * 2.2, "pt"),
    legend.key.width = grid::unit(if (horizontal) base_size * 2.6 else 10, "pt"),
    legend.title = ggplot2::element_text(size = base_size * 0.9, face = "bold",
                                         hjust = if (horizontal) 0.5 else 0),
    # A caption on a map carries the provenance -- which period, which product,
    # what correction was not applied -- so it is left-aligned under the panel
    # where it reads as a sentence rather than centred like a title.
    plot.caption = ggplot2::element_text(hjust = 0, colour = "grey30"),
    plot.margin = ggplot2::margin(4, 6, 4, 6)
  )
}

#' The map theme as used inside a multi-panel figure
#'
#' The same theme with the per-panel title made smaller and the margins tightened,
#' so that two maps sitting side by side read as one figure rather than as two
#' figures that happen to be adjacent.
#'
#' @inheritParams theme_fancymap
#'
#' @return A \pkg{ggplot2} theme object.
#'
#' @examples
#' theme_fancymap_panel()
#'
#' @export
theme_fancymap_panel <- function(base_size = 12, base_family = "",
                                 legend = "bottom", graticule = FALSE, ...) {
  theme_fancymap(base_size = base_size, base_family = base_family,
                 legend = legend, graticule = graticule, ...) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = base_size * 0.95, face = "bold",
                                         hjust = 0),
      plot.subtitle = ggplot2::element_text(size = base_size * 0.75, hjust = 0),
      plot.margin = ggplot2::margin(2, 3, 2, 3),
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      legend.box.spacing = grid::unit(4, "pt")
    )
}
