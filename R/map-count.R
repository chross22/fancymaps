#' Map a count
#'
#' For a quantity that is a non-negative integer per cell: sightings, surveys,
#' visits. A count is not a continuous surface, and drawing it with
#' [map_surface()] gets the legend wrong twice: the ramp invents intermediate
#' values no cell can hold, and the break-picker, handed values like 0 and 1,
#' prints breaks like ">= 0.000000001" - a legend about floating point, not
#' about whales. Here each integer is one discrete viridis key, the levels are
#' the same in every figure drawn from the same data, and a cell that was
#' never surveyed stays unfilled.
#'
#' Counts above `cap` share the top key, labeled with a `+`; the default cap
#' keeps the legend readable when one cell holds an outlier pile.
#'
#' @inheritParams map_surface
#' @param cap Counts at or above this share the top legend key (labeled e.g.
#'   `"7+"`). Defaults to the data's maximum, or 7 when the maximum is larger.
#'
#' @return A \pkg{ggplot2} object.
#'
#' @seealso [map_surface()] for a continuous positive quantity,
#'   [map_probability()] for a bounded one.
#'
#' @examples
#' grid <- example_grid()
#' grid$n <- rpois(nrow(grid), 0.8)
#' map_count(grid, "n", label = "Sightings")
#'
#' @export
map_count <- function(x, value = NULL, by = NULL, coords = NULL, crs = NULL,
                      label = NULL, cap = NULL, coastline = TRUE,
                      region = NULL,
                      title = NULL, subtitle = NULL, caption = NULL,
                      scalebar = TRUE, north = TRUE,
                      scalebar_position = "bl", north_position = "tr",
                      inset = FALSE,
                      inset_position = "br", inset_size = 0.3,
                      inset_zoom = 8, graticule = FALSE,
                      base_size = 12, theme = NULL, expand = 0.02) {
  label <- label %||% value_label(rlang::enquo(value), value)
  md <- as_map_data(x, value = value, by = by, coords = coords, crs = crs,
                    label = label)
  require_value(md, "map_count")

  cl <- count_levels(md$value, cap = cap)
  md$value <- count_factor(md$value, cl)
  crs <- display_crs(md, crs)

  assemble_map(
    md,
    scales = count_scale_pair(scale_name(md$label, NULL), md$kind),
    crs = crs, coastline = coastline, region = region, graticule = graticule,
    title = title, subtitle = subtitle, caption = caption,
    notes = list(cl$note),
    scalebar = scalebar, north = north,
    scalebar_position = scalebar_position,
    north_position = north_position, inset = inset,
    inset_position = inset_position, inset_size = inset_size,
    inset_zoom = inset_zoom, base_size = base_size, theme = theme,
    expand = expand
  )
}

# The discrete levels a set of counts is drawn on. Shared between the single
# map and the panels, because panels drawn from the same data must agree on
# the levels for their legends to collect into one.
count_levels <- function(values, cap = NULL) {
  v <- values[!is.na(values)]
  if (length(v) && (any(v < 0) || any(v != round(v)))) {
    stop("map_count() draws non-negative integers; these values have ",
         if (any(v < 0)) "negatives" else "fractional parts",
         ". For a continuous quantity use map_surface().", call. = FALSE)
  }
  top <- if (length(v)) max(v) else 0
  cap <- cap %||% min(top, 7)
  capped <- top > cap
  labels <- as.character(0:cap)
  if (capped) labels[length(labels)] <- paste0(cap, "+")
  list(cap = cap, labels = labels,
       note = if (capped) paste0("counts of ", cap, " or more share the top key"))
}

count_factor <- function(values, cl) {
  factor(pmin(values, cl$cap), levels = 0:cl$cap, labels = cl$labels)
}

# The discrete sibling of `scale_pair()`: fill and colour mapped to the same
# levels (the seam fix strokes each polygon in its own fill colour), only one
# of them carrying the legend. `drop = FALSE` keeps every level in the key,
# so a season whose counts stop at 2 still shows the same legend as one that
# reaches the cap.
count_scale_pair <- function(name, kind) {
  filled <- kind %in% c("polygon", "raster")
  guide <- ggplot2::guide_legend(title.position = "top")
  list(
    ggplot2::scale_fill_viridis_d(name = name, drop = FALSE,
                                  na.value = "grey92",
                                  guide = if (filled) guide else "none"),
    ggplot2::scale_colour_viridis_d(name = name, drop = FALSE,
                                    na.value = "grey92",
                                    guide = if (filled) "none" else guide)
  )
}
