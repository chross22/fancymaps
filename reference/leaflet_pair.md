# A surface and its uncertainty, interactively

The interactive counterpart of
[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md):
both quantities on one map, with a control to switch between them.

## Usage

``` r
leaflet_pair(
  x,
  value,
  uncertainty,
  uncertainty_from = NULL,
  by = NULL,
  coords = NULL,
  crs = NULL,
  kind = c("surface", "probability"),
  uncertainty_kind = c("surface", "diverging"),
  uncertainty_midpoint = 0,
  uncertainty_direction = 1,
  labels = NULL,
  transform = "auto",
  limits = NULL,
  probs = c(0, 0.99),
  popup = NULL,
  tiles = "CartoDB.Positron",
  opacity = 0.8,
  position = "topright"
)
```

## Arguments

- x:

  The geometry, or a `map_data`. Both panels are drawn from it unless
  `uncertainty_from` names a different object.

- value:

  What the left panel colours by.

- uncertainty:

  What the right panel colours by: a CV, a standard error, a posterior
  standard deviation, an extrapolation score.

- uncertainty_from:

  A second object to take `uncertainty` from, when it does not live
  alongside `value`. Must cover the same cells.

- by, coords, crs:

  Passed to
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md).
  `crs` is also the CRS the map is drawn in – see
  [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
  for what happens when it is not given.

- kind:

  How the left panel is scaled: `"surface"` for a skewed positive
  quantity, `"probability"` for one bounded at 0 and 1.

- uncertainty_kind:

  How the right panel is scaled. `"surface"` for a CV or an SE, which
  only increase; `"diverging"` for a signed score such as an
  extrapolation surface, which needs `uncertainty_midpoint`.

- uncertainty_midpoint:

  The centre for a diverging right panel. Zero is the usual meaning and
  it is the default here, unlike in
  [`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md),
  because the caller has already said the panel is diverging.

- uncertainty_direction:

  Which way the diverging ramp runs on the right panel. `-1` puts the
  warm arm at the low end, which is what an extrapolation surface wants.

- labels:

  A length-2 character vector naming the two quantities. These are what
  the switch is labelled with, so they should read as names rather than
  as units.

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

- position:

  Where the layer control sits.

## Value

A leaflet widget.

## Why one map and a switch, rather than two maps side by side

[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
draws two panels because a static figure has no other way to show two
things at once, and it goes to some trouble – shared extent, shared
projection, one coastline, aligned panels – to make them comparable cell
by cell. All of that is machinery for approximating, on paper, something
an interactive map gets for free.

Switching layers on one map is a **blink comparison**: the same cells,
at the same position and the same zoom, changing only in the quantity
drawn. Nothing has to be aligned because nothing moved. Two side-by-side
widgets would reintroduce exactly the alignment problem
[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
exists to solve, and would need a synchronisation dependency to solve it
again.

The trade is that the two can no longer be seen simultaneously. When
that is what you want – a figure for a manuscript, or a reader who
cannot click –
[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
is the one to use.

Each layer carries its own legend, shown and hidden with it, because the
two are different quantities in different units.

## See also

[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md),
the static original.

## Examples

``` r
if (FALSE) { # \dontrun{
grid <- example_grid()

leaflet_pair(grid, "density", "cv")

leaflet_pair(grid, "density", "mess", uncertainty_kind = "diverging",
             uncertainty_direction = -1,
             labels = c("density", "extrapolation"))
} # }
```
