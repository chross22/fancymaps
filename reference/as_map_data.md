# Put spatial model output into the form the maps draw from

Called for you by
[`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md)
and friends. Call it directly when you want to inspect what they will
draw, or to normalise something once and draw it several times.

## Usage

``` r
as_map_data(
  x,
  value = NULL,
  by = NULL,
  coords = NULL,
  crs = NULL,
  label = NULL
)
```

## Arguments

- x:

  The geometry: an `sf` object of polygons, points or lines, a terra
  `SpatRaster`, or a data frame with coordinate columns.

- value:

  What to colour by. One of:

  - a string naming a column of `x`;

  - an unnamed numeric vector, one element per feature of `x`, in the
    same order;

  - a **named** numeric vector, matched against `x[[by]]` by name – the
    form a posterior summary or a lookup table arrives in;

  - `NULL`, for geometry drawn without a colour, such as tracklines.

- by:

  The column of `x` holding the identifier that a named `value` is keyed
  by. Guessed from `grid_id`, `id` or `cell` when not given.

- coords:

  For a data frame, the two coordinate columns, as `c("x", "y")`.
  Guessed from the usual spellings when not given.

- crs:

  The coordinate reference system the coordinates are in. Required for a
  data frame, since nothing about two numeric columns says whether they
  are degrees or metres. Ignored when `x` already carries one.

- label:

  What to call the value in a legend. Defaults to the column name, or to
  the name of the expression passed as `value`.

## Value

An object of class `map_data`: a list with `geometry` (an `sfc`),
`value` (numeric or `NULL`), `kind` (`"polygon"`, `"point"`, `"line"` or
`"raster"`), `label`, and `data`, a data frame of the non-geometry
columns.

## Checking the join

When `value` is named, every name must be found in `x[[by]]`, and the
function stops if any is not, naming the first few missing keys. It does
not quietly drop them: a partial join produces a map with holes in it
that looks exactly like a region where the model had nothing to say.

Keys are compared as character. An integer `grid_id` and a vector named
`"1"`, `"2"`, `"3"` are the common case and they match.

## Rasters

A `SpatRaster` is read into cell centres and drawn through a raster
path. It is deliberately not polygonised:
[`terra::as.polygons()`](https://rspatial.github.io/terra/reference/as.polygons.html)
on a grid of any size is slow enough to be the dominant cost of drawing
the figure, and the result is a polygon per cell that is then drawn as a
rectangle anyway.

## Examples

``` r
grid <- sf::st_sf(
  grid_id = 1:2,
  geometry = sf::st_sfc(
    sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
    sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
    crs = 4326))

# a column that is already there
grid$depth <- c(40, 120)
as_map_data(grid, "depth")
#> <map_data> polygon | 2 features
#>   crs:   EPSG:4326 
#>   value: depth [40, 120] 

# values that arrived separately, keyed by id
occupancy <- c("2" = 0.8, "1" = 0.3)
as_map_data(grid, occupancy, by = "grid_id")
#> <map_data> polygon | 2 features
#>   crs:   EPSG:4326 
#>   value: <dbl> [0.3, 0.8] 
```
