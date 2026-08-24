# A coastline for a map

Resolves a land layer for a given extent, choosing a resolution to suit
it. Called for you by every map in this package; call it directly to
inspect what will be drawn, or to fetch once and reuse across many
figures.

## Usage

``` r
coastline(extent = NULL, source = TRUE, crs = NULL, pad = 0.05)

coastline_fixture()
```

## Arguments

- extent:

  Anything with a bounding box – an `sf` object, a `bbox`, a `map_data`
  – naming the area to be covered. `NULL` returns the whole source,
  uncropped.

- source:

  Where land comes from:

  - `TRUE` (default) – choose automatically: the bundled fixture if it
    covers the extent, otherwise rnaturalearth at a resolution picked
    from the extent;

  - `FALSE` – no land, deliberately. The only way to get a map with no
    shoreline and no complaint about it;

  - a path to a shapefile or any other format
    [`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html)
    reads. The better option at bay scale;

  - an `sf` object already in memory.

- crs:

  The CRS to return the land in. Defaults to the extent's.

- pad:

  How far past the extent to keep land, as a fraction of the extent's
  width. A little overhang stops the shoreline stopping dead at the
  panel edge.

## Value

An `sf` object of land polygons, or `NULL` if `source = FALSE` or
nothing could be resolved.

## Which resolution

Chosen from the width of the extent, because that is what decides
whether the generalisation in a coastline is visible:

|                 |            |                     |
|-----------------|------------|---------------------|
| extent width    | resolution | Natural Earth scale |
| over 1,500 km   | `"small"`  | 1:110m              |
| 200 to 1,500 km | `"medium"` | 1:50m               |
| under 200 km    | `"large"`  | 1:10m               |

`"large"` needs the `rnaturalearthhires` package, which is not on CRAN.
If it is not installed, `"medium"` is used and a warning says the
coastline is coarser than the map, since that is a defect a reader will
otherwise attribute to the data.

## The bundled fixture

A cropped copy of Natural Earth medium covering the Gulf of Maine and
the Bay of Fundy ships with the package, so that examples draw land and
tests never touch the network. It is used automatically when it covers
the requested extent, and it is the same data rnaturalearth would return
at that scale – just already here.

## Examples

``` r
box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
                   crs = sf::st_crs(4326))
land <- coastline(box)
nrow(land)
#> [1] 1

# deliberately none
coastline(box, source = FALSE)
#> NULL
```
