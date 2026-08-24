## Scale bar, north arrow, and the note that says where this is.
##
## The defect these exist for: nothing on the current maps says where they are
## or how big anything is. No scale bar, no north arrow, no locator. The extent
## is legible to someone who works in this gulf and to nobody else.
##
## Drawn here rather than taken from `ggspatial`, for one reason that matters:
## a scale bar has to be computed in a projection where a metre is a metre, and
## these maps already resolve that question once in `equal_area_crs()`. A layer
## that measures the panel independently is a second answer to a question the
## figure has already answered, and the two can disagree.

#' A scale bar, sized for the panel it is drawn in
#'
#' @param box The panel extent, as a `bbox` in the display CRS.
#' @param position One of `"bl"`, `"br"`, `"tl"`, `"tr"` -- which corner.
#' @param base_size Font size for the label, in points.
#'
#' @return A list of \pkg{ggplot2} layers.
#'
#' @details
#' The bar's length is a round number of kilometres -- 1, 2 or 5 times a power
#' of ten -- closest to a fifth of the panel's width, so it stays a comparable
#' fraction of the figure whether the map is a bay or a gulf. It is measured
#' along the middle of the panel: on an unprojected map the top and bottom of a
#' box are different real widths, and the middle is the one that describes the
#' map a reader is looking at.
#'
#' @examples
#' box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
#'                    crs = sf::st_crs(4326))
#' scale_bar(box)
#'
#' @export
scale_bar <- function(box, position = c("bl", "br", "tl", "tr"),
                      base_size = 12) {
  position <- match.arg(position)

  width_km <- extent_width_km(box)
  bar_km <- round_125(width_km / 5)
  if (!is.finite(bar_km) || bar_km <= 0) return(list())

  # How many x units one kilometre is, at this panel's latitude. On a projected
  # CRS in metres this is exactly 1000; on lon/lat it is a fraction of a degree
  # that depends on where you are, which is the whole reason it is measured
  # rather than assumed.
  per_km <- (box[["xmax"]] - box[["xmin"]]) / width_km
  bar_units <- bar_km * per_km

  at <- corner(box, position, bar_units)
  height <- (box[["ymax"]] - box[["ymin"]]) * 0.012

  list(
    ggplot2::annotate("rect",
                      xmin = at$x, xmax = at$x + bar_units / 2,
                      ymin = at$y, ymax = at$y + height,
                      fill = "grey20", colour = "grey20", linewidth = 0.2),
    ggplot2::annotate("rect",
                      xmin = at$x + bar_units / 2, xmax = at$x + bar_units,
                      ymin = at$y, ymax = at$y + height,
                      fill = "white", colour = "grey20", linewidth = 0.2),
    ggplot2::annotate("text",
                      # Clear of the bar by three times its own thickness. At
                      # two the label's descenders sat on the bar's top edge,
                      # which reads as a stray mark rather than as a gap.
                      x = at$x + bar_units / 2, y = at$y + height * 3.4,
                      label = paste0(format(bar_km, big.mark = ","), " km"),
                      size = base_size * 0.24, colour = "grey20", vjust = 0)
  )
}

#' A north arrow
#'
#' @inheritParams scale_bar
#'
#' @details
#' Grid north, not magnetic north, and not exactly true north away from the
#' centre of the projection -- in an azimuthal or transverse projection the
#' meridians converge, so "up" is true north only along the central one. Over a
#' regional extent the difference is a degree or two and the arrow is a
#' reading aid rather than a navigation instrument. Over a continental extent
#' it stops being either, which is why [map_surface()] draws it by default and
#' lets you turn it off.
#'
#' @return A list of \pkg{ggplot2} layers.
#'
#' @examples
#' box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
#'                    crs = sf::st_crs(4326))
#' north_arrow(box)
#'
#' @export
north_arrow <- function(box, position = c("tr", "tl", "br", "bl"),
                        base_size = 12) {
  position <- match.arg(position)

  w <- (box[["xmax"]] - box[["xmin"]]) * 0.028
  h <- (box[["ymax"]] - box[["ymin"]]) * 0.055

  # The label goes BELOW the arrow, not above it. Above, the glyph's reserved
  # height has to cover the arrow plus a text line whose height is in points
  # rather than in map units, so the "N" pushed past the top of the panel and
  # was clipped at some figure sizes and not others.
  at <- corner(box, position, w, h)
  x0 <- at$x + w / 2
  base <- at$y + h * 0.3

  tri <- data.frame(
    x = c(x0, at$x, x0, at$x + w),
    y = c(at$y + h, base, at$y + h * 0.45, base)
  )

  list(
    ggplot2::annotate("polygon", x = tri$x, y = tri$y,
                      fill = "grey20", colour = "grey20", linewidth = 0.2),
    ggplot2::annotate("text", x = x0, y = at$y + h * 0.22, label = "N",
                      size = base_size * 0.26, colour = "grey20",
                      fontface = "bold", vjust = 1)
  )
}

# Where a piece of furniture sits, inset from the named corner by a margin
# proportional to the panel rather than fixed, so it holds its place when the
# figure is saved at a different size.
corner <- function(box, position, width, height = 0) {
  mx <- (box[["xmax"]] - box[["xmin"]]) * 0.04
  my <- (box[["ymax"]] - box[["ymin"]]) * 0.04
  left <- substr(position, 2, 2) == "l"
  bottom <- substr(position, 1, 1) == "b"
  list(
    x = unname(if (left) box[["xmin"]] + mx else box[["xmax"]] - mx - width),
    y = unname(if (bottom) box[["ymin"]] + my else box[["ymax"]] - my - height)
  )
}

# The nearest 1, 2 or 5 times a power of ten. A scale bar reading "43 km" is a
# scale bar nobody can use to measure anything.
round_125 <- function(x) {
  if (!is.finite(x) || x <= 0) return(NA_real_)
  decade <- 10^floor(log10(x))
  candidates <- c(1, 2, 5, 10) * decade
  candidates[which.min(abs(candidates - x))]
}
