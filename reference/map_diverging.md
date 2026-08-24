# Map a quantity with a meaningful centre

For anything that diverges: an extrapolation score around zero, model
residuals around their own mean, a difference between two periods around
no change.

## Usage

``` r
map_diverging(
  x,
  value = NULL,
  midpoint,
  by = NULL,
  coords = NULL,
  crs = NULL,
  label = NULL,
  coastline = TRUE,
  region = NULL,
  limits = NULL,
  probs = c(0.01, 0.99),
  direction = 1,
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

- midpoint:

  The value the neutral colour sits at. **Required.**

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

- limits, probs:

  Passed to
  [`diverging_scale()`](https://camilleross.org/fancymaps/reference/diverging_scale.md).
  Limits are made symmetric about `midpoint`.

- direction:

  Which way round the ramp runs. `1` puts the warm arm at the high end;
  `-1` reverses it, which is what an extrapolation surface wants – its
  alarming values are the negative ones.

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

## Details

`midpoint` has no default on purpose.
[`ggplot2::scale_fill_gradient2()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)
falls back to the middle of the range, which is almost never the
meaning:

- an **extrapolation score** diverges around **zero**, because zero is
  where inside the training range becomes outside it;

- **deviance residuals** diverge around **their own mean**, because they
  do not average zero, and centring them on zero paints every bin the
  same colour – a bug the first customer of this package hit in exactly
  that form.

## See also

[`diverging_scale()`](https://camilleross.org/fancymaps/reference/diverging_scale.md)
for the limits,
[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
to draw this beside the surface it qualifies.

## Examples

``` r
grid <- example_grid()

# zero is the meaning, and the alarming side is the negative one
map_diverging(grid, "mess", midpoint = 0, direction = -1, label = "MESS")


# residuals diverge around their own mean
map_diverging(grid, "residual", midpoint = mean(grid$residual),
              label = "deviance residual")

```
