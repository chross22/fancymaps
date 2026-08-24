# A north arrow

A north arrow

## Usage

``` r
north_arrow(box, position = c("tr", "tl", "br", "bl"), base_size = 12)
```

## Arguments

- box:

  The panel extent, as a `bbox` in the display CRS.

- position:

  One of `"bl"`, `"br"`, `"tl"`, `"tr"` – which corner.

- base_size:

  Font size for the label, in points.

## Value

A list of ggplot2 layers.

## Details

Grid north, not magnetic north, and not exactly true north away from the
centre of the projection – in an azimuthal or transverse projection the
meridians converge, so "up" is true north only along the central one.
Over a regional extent the difference is a degree or two and the arrow
is a reading aid rather than a navigation instrument. Over a continental
extent it stops being either, which is why
[`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md)
draws it by default and lets you turn it off.

## Examples

``` r
box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
                   crs = sf::st_crs(4326))
north_arrow(box)
#> [[1]]
#> mapping: x = ~x, y = ~y 
#> geom_polygon: na.rm = FALSE
#> stat_identity: na.rm = FALSE
#> position_identity 
#> 
#> [[2]]
#> mapping: x = ~x, y = ~y 
#> geom_text: na.rm = FALSE
#> stat_identity: na.rm = FALSE
#> position_identity 
#> 
```
