## Turning a scale spec into the ggplot2 scales that draw it.
##
## Always a PAIR of scales -- fill and colour -- mapped to the same values with
## the same limits, because of the seam fix in `value_layer()`: a polygon is
## stroked in its own fill colour to close the sub-pixel gap between adjacent
## cells, which means the colour aesthetic is in use and needs a scale that
## agrees with the fill one exactly. Only one of them carries the legend.

scale_pair <- function(spec, name, kind, palette = "sequential",
                       midpoint = NULL, direction = 1) {
  colours <- ramp_colours(if (is.null(midpoint)) palette else "diverging",
                          direction)

  args <- list(
    colours = colours,
    limits = spec$limits,
    # squish, not censor. A value past the top of the scale is drawn AT the
    # top; censoring would make it grey, which on a map is indistinguishable
    # from a cell the model had nothing to say about. The legend says the cap
    # is there -- see `squish_labels()` and `squish_note()`.
    oob = scales::squish,
    na.value = "grey92"
  )
  if (!is.null(spec$transform)) args$transform <- spec$transform
  if (!is.null(spec$breaks)) args$breaks <- spec$breaks
  if (!is.null(spec$labels)) args$labels <- spec$labels
  if (!is.null(spec$rescaler)) args$rescaler <- spec$rescaler

  guide <- ggplot2::guide_colourbar(
    title.position = "top", ticks.colour = "white", frame.colour = NA
  )

  # Which aesthetic the legend hangs on depends on what is being drawn:
  # polygons and rasters are filled, points and lines are only stroked.
  filled <- kind %in% c("polygon", "raster")
  list(
    do.call(ggplot2::scale_fill_gradientn,
            c(args, list(name = name,
                         guide = if (filled) guide else "none"))),
    do.call(ggplot2::scale_colour_gradientn,
            c(args, list(name = name,
                         guide = if (filled) "none" else guide)))
  )
}

# The legend title. The quantity, then what the colour ramp is doing to it,
# on its own line -- because a reader looking at evenly spaced breaks reading
# 0.1  0.5  1  2 needs to be told the spacing is not linear, and the legend is
# the only place they are looking.
scale_name <- function(label, note) {
  label <- label %||% ""
  if (is.null(note)) return(label)
  if (!nzchar(label)) return(note)
  paste0(label, "\n(", note, ")")
}

# A diverging ramp has to put its neutral colour AT the midpoint, and the
# midpoint is not generally the middle of the limits -- it is only the middle
# here because `diverging_scale()` made the limits symmetric about it. Doing it
# with an explicit rescaler rather than trusting that keeps the two facts
# independent: if a caller fixes asymmetric limits, the neutral stays put.
diverging_rescaler <- function(midpoint) {
  function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
    reach <- max(abs(from - midpoint))
    if (!is.finite(reach) || reach <= 0) reach <- 1
    scales::rescale(x, to = to, from = midpoint + c(-reach, reach))
  }
}

# The interpolation stops for a ramp.
#
# One function, because both renderers have to use the same one. The colours
# come out of `scales::gradient_n_pal()` in either case, and that interpolates
# between whatever stops it is given -- so a ggplot2 scale built on 33 stops and
# a leaflet layer built on 32 produce colours that differ in the last hex digit.
# Invisible on screen and still wrong: the claim these two renderers make
# together is that a cell is the SAME colour in both.
#
# Odd for the diverging ramp, so that one stop lands exactly on the centre and
# the neutral colour is a colour in the palette rather than an interpolation
# between the two nearest.
ramp_colours <- function(palette, direction = 1) {
  colours <- fancymap_palette(palette,
                              if (identical(palette, "diverging")) 33 else 32)
  # Which end of a ramp carries the weight is a claim about which end matters,
  # and it is not derivable from the numbers. On an extrapolation surface the
  # NEGATIVE values are the ones a reader has to see -- they are where the
  # model is guessing -- and they are a small minority, so leaving them on the
  # cool arm of a blue-to-orange ramp puts the alarm on the wrong side.
  if (is.numeric(direction) && direction < 0) colours <- rev(colours)
  colours
}
