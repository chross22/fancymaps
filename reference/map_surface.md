# Map a predicted surface

The primary deliverable of a spatial model: a predicted quantity per
cell, over a grid, with land, a stated projection and a scale that was
chosen.

## Usage

``` r
map_surface(
  x,
  value = NULL,
  by = NULL,
  coords = NULL,
  crs = NULL,
  label = NULL,
  coastline = TRUE,
  region = NULL,
  transform = "auto",
  limits = NULL,
  probs = c(0, 0.99),
  title = NULL,
  subtitle = NULL,
  caption = NULL,
  scalebar = TRUE,
  north = TRUE,
  scalebar_position = "bl",
  north_position = "tr",
  inset = FALSE,
  inset_position = "br",
  inset_size = 0.3,
  inset_zoom = 8,
  graticule = FALSE,
  base_size = 12,
  theme = NULL,
  expand = 0.02
)
```

## Arguments

- x:

  The geometry. An `sf` object of polygons, points or lines, a terra
  `SpatRaster`, or a data frame with coordinate columns. See
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md).

- value:

  What to colour by: a column name, a vector in feature order, or a
  named vector joined by `by`. See
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md).

- by, coords, crs:

  Passed to
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md).
  `crs` is also the CRS the map is drawn in – see
  [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
  for what happens when it is not given.

- label:

  What to call the value in the legend. Defaults to the column name.

- coastline:

  Where land comes from. `TRUE` chooses a source for the extent, `FALSE`
  draws none, a path or an `sf` object supplies one. See
  [`coastline()`](https://camilleross.org/fancymaps/reference/coastline.md).

- region:

  An `sf` polygon to outline over the map – the study area, or whatever
  the grid was cropped to.

- transform, limits, probs:

  Passed to
  [`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md),
  which decides how the values are ramped and says so.

- title, subtitle, caption:

  Figure text. The caption is where provenance belongs: which period,
  which product, which correction was not applied. Anything this
  function had to decide – a capped scale, a missing coastline – is
  appended to it.

- scalebar, north:

  Whether to draw the furniture. See
  [`scale_bar()`](https://camilleross.org/fancymaps/reference/scale_bar.md)
  and
  [`north_arrow()`](https://camilleross.org/fancymaps/reference/north_arrow.md).

- scalebar_position, north_position:

  Which corner each sits in: `"bl"`, `"br"`, `"tl"` or `"tr"`. Two
  pieces of furniture asked into the same corner are warned about rather
  than moved – which corner is free depends on where the data sits, and
  only the caller can see that.

- inset:

  Whether to draw a locator inset – a small wider map with this figure's
  extent marked on it. `FALSE` by default, unlike the scale bar and
  north arrow, because an inset sits over a corner of the data rather
  than in a margin. `TRUE` uses the same coastline source as the map; a
  path or an `sf` object gives the inset its own.

- inset_position, inset_size, inset_zoom:

  Which corner the inset sits in, how much of the panel width it takes,
  and how many times wider than the map it starts. See
  [`locator_inset()`](https://camilleross.org/fancymaps/reference/locator_inset.md)
  – `inset_zoom` is a starting point, not a setting, because an inset
  showing nothing but water orients nobody.

- graticule:

  Whether to label coordinates. Off by default; see
  [`theme_fancymap()`](https://camilleross.org/fancymaps/reference/theme_fancymap.md).

- base_size:

  Base font size in points.

- theme:

  A theme to use instead of
  [`theme_fancymap()`](https://camilleross.org/fancymaps/reference/theme_fancymap.md).

- expand:

  How much margin to leave around the data, as a fraction of its own
  extent. The default is a thin margin. Widen it when the data does not
  reach anything a reader can orient by – a small grid in open water
  shows no coastline at all until the panel is wide enough to include
  one.

## Value

A ggplot2 object.

## What it does not do

It does not compute the surface. Density, abundance, occupancy and their
uncertainties are the fitting package's job; this draws what it is
handed.

## Skewed quantities

Predicted density is usually extremely skewed, and by default the scale
notices: see
[`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md)
for the rule, which is reported whenever it fires. For a probability,
use
[`map_probability()`](https://camilleross.org/fancymaps/reference/map_probability.md),
whose scale is bounded at 0 and 1 rather than at whatever the data
reached.

## See also

[`map_probability()`](https://camilleross.org/fancymaps/reference/map_probability.md)
for a bounded quantity,
[`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md)
for one with a meaningful centre,
[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
to draw one beside its uncertainty.

## Examples

``` r
grid <- example_grid()

map_surface(grid, "density", label = "animals per km2")
#> scale: log, chosen because the 99th percentile is 170 times the median.
#>   Pass `transform =` to fix it, if two figures need to match.


# a fixed scale, for comparing with another figure
map_surface(grid, "density", transform = "log", limits = c(0.001, 1))

```
