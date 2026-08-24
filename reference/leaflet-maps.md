# Interactive versions of the maps

The same map, rendered by leaflet: pan, zoom, and click a cell for its
value. For looking at a surface while working on it, and for a report
where the reader should be able to find their own bay.

## Usage

``` r
leaflet_surface(
  x,
  value = NULL,
  by = NULL,
  coords = NULL,
  crs = NULL,
  label = NULL,
  transform = "auto",
  limits = NULL,
  probs = c(0, 0.99),
  popup = NULL,
  tiles = "CartoDB.Positron",
  opacity = 0.8,
  legend = TRUE
)

leaflet_probability(
  x,
  value = NULL,
  by = NULL,
  coords = NULL,
  crs = NULL,
  label = NULL,
  limits = c(0, 1),
  popup = NULL,
  tiles = "CartoDB.Positron",
  opacity = 0.8,
  legend = TRUE
)

leaflet_diverging(
  x,
  value = NULL,
  midpoint,
  by = NULL,
  coords = NULL,
  crs = NULL,
  label = NULL,
  limits = NULL,
  probs = c(0.01, 0.99),
  direction = 1,
  popup = NULL,
  tiles = "CartoDB.Positron",
  opacity = 0.8,
  legend = TRUE
)
```

## Arguments

- x, value, by, coords, crs, label:

  Passed to
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md),
  exactly as for
  [`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md).
  `crs` here only says what the incoming coordinates are; it does not
  choose a projection, because leaflet is always Web Mercator.

- transform, limits, probs:

  Passed to
  [`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md),
  so the colours match the static map's exactly.

- popup:

  Extra columns of `x` to show when a cell is clicked, as a character
  vector. The value and the join key are always shown. `FALSE` turns
  popups off.

- tiles:

  A leaflet provider name for the basemap, or `NULL` for no basemap at
  all. The default is a quiet grey one, so the data is the brightest
  thing on the map rather than competing with a road network.

- opacity:

  How opaque the cells are over the basemap.

- legend:

  Whether to draw the legend.

- midpoint, direction:

  For `leaflet_diverging()`, as in
  [`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md).

## Value

A leaflet widget.

## Why these exist rather than a call to leaflet

Not for the rendering – leaflet does that. For the **decisions**.
Handing a grid to
[`leaflet::colorNumeric()`](https://rstudio.github.io/leaflet/reference/colorNumeric.html)
re-decides the scale at the call site, and it decides differently:
linear, over the full data range, with no capping. So the static figure
and the interactive one show the same numbers in different colours, and
a reader who has seen both has been told two things. These reuse the
same scale objects, so a cell is the same colour in both.

## What is not carried over

The projection is leaflet's: Web Mercator, with WGS84 inputs, so
[`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
does not apply and everything is transformed to EPSG:4326. Land comes
from the tile provider rather than from
[`coastline()`](https://camilleross.org/fancymaps/reference/coastline.md)
– which means, unlike every static map here, **these need the network at
draw time**. That is the reason the static ones do not use tiles.

## The legend

Swatches at the same breaks the static legend uses, with the same labels
– including the `>=` on a capped scale. It is a stepped legend for a
continuous ramp, which is what leaflet draws well; the colours between
the swatches are continuous as they are on the static map.

## See also

[`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md),
[`map_probability()`](https://camilleross.org/fancymaps/reference/map_probability.md)
and
[`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md),
the static originals.

## Examples

``` r
if (FALSE) { # \dontrun{
grid <- example_grid()

leaflet_surface(grid, "density", label = "animals per km2")
leaflet_probability(grid, "occupancy", popup = c("density", "cv"))
leaflet_diverging(grid, "mess", midpoint = 0, direction = -1)
} # }
```
