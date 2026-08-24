# A series over several periods, interactively

The interactive counterpart of
[`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md):
every period on one map, one shared scale, and a control to step through
them.

## Usage

``` r
leaflet_panels(
  x,
  values,
  by = NULL,
  coords = NULL,
  crs = NULL,
  titles = NULL,
  kind = c("surface", "probability", "diverging"),
  midpoint = NULL,
  direction = 1,
  label = NULL,
  transform = "auto",
  limits = NULL,
  probs = c(0, 0.99),
  popup = NULL,
  tiles = "CartoDB.Positron",
  opacity = 0.8,
  legend = TRUE,
  position = "topright"
)
```

## Arguments

- x:

  The geometry – one grid, drawn once per set of values.

- values:

  The panels. One of:

  - a character vector of column names in `x`;

  - a matrix with one row per cell and one column per period, which is
    the form an averaging or posterior step emits – column names become
    panel titles;

  - a named list of vectors, each in feature order or named by `by`.

- by, coords, crs:

  Passed to
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md).
  `crs` is also the CRS the map is drawn in – see
  [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
  for what happens when it is not given.

- titles:

  Panel titles. Taken from the names of `values` when not given.

- kind:

  How the values are scaled: `"surface"`, `"probability"` or
  `"diverging"`.

- midpoint, direction:

  For
  [`leaflet_diverging()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md),
  as in
  [`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md).

- label:

  What to call the quantity in the single shared legend.

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

- position:

  Where the layer control sits.

## Value

A leaflet widget.

## One legend, and it does not move

The scale is computed once over every period pooled, exactly as in
[`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
– both call the same `pooled_spec()`, so a cell of a given value is the
same colour in the static figure and this one.

Because the scale is shared, the legend is drawn **once and left alone**
rather than tied to each layer. Stepping through the periods changes the
map and not the legend, which is what makes the comparison readable: a
colour that means 0.4 in spring still means 0.4 in autumn, and the
legend sitting still is the visible evidence of that.

It is also the interactive form that suits a series best. Small
multiples ask a reader to compare across a page; stepping through them
in place compares by change-blindness instead, which is far more
sensitive to a small shift and needs no alignment at all.

## See also

[`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md),
the static original.

## Examples

``` r
if (FALSE) { # \dontrun{
grid <- example_grid()
seasons <- cbind(spring = grid$density,
                 summer = grid$density * 2.5,
                 autumn = grid$density * 0.4)

leaflet_panels(grid, seasons, label = "animals per km2")
} # }
```
