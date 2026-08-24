# Areas in square kilometres, computed honestly

Areas in square kilometres, computed honestly

## Usage

``` r
area_km2(x)
```

## Arguments

- x:

  An `sf` object of polygons.

## Value

A numeric vector of areas in km2, one per feature, with the units
dropped – these are for arithmetic, and a `units` object propagating
into a `ggplot2` aesthetic is a surprise nobody wants mid-figure.

## Examples

``` r
sq <- sf::st_sf(geometry = sf::st_sfc(
  sf::st_polygon(list(cbind(c(-70, -69.9, -69.9, -70, -70),
                            c(43, 43, 43.1, 43.1, 43)))), crs = 4326))
area_km2(sq)
#> [1] 90.51335
```
