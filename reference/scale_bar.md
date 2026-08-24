# A scale bar, sized for the panel it is drawn in

A scale bar, sized for the panel it is drawn in

## Usage

``` r
scale_bar(box, position = c("bl", "br", "tl", "tr"), base_size = 12)
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

The bar's length is a round number of kilometres – 1, 2 or 5 times a
power of ten – closest to a fifth of the panel's width, so it stays a
comparable fraction of the figure whether the map is a bay or a gulf. It
is measured along the middle of the panel: on an unprojected map the top
and bottom of a box are different real widths, and the middle is the one
that describes the map a reader is looking at.

## Examples

``` r
box <- sf::st_bbox(c(xmin = -70.5, ymin = 42.5, xmax = -68, ymax = 44.5),
                   crs = sf::st_crs(4326))
scale_bar(box)
#> [[1]]
#> mapping: xmin = ~xmin, xmax = ~xmax, ymin = ~ymin, ymax = ~ymax 
#> geom_rect: na.rm = FALSE
#> stat_identity: na.rm = FALSE
#> position_identity 
#> 
#> [[2]]
#> mapping: xmin = ~xmin, xmax = ~xmax, ymin = ~ymin, ymax = ~ymax 
#> geom_rect: na.rm = FALSE
#> stat_identity: na.rm = FALSE
#> position_identity 
#> 
#> [[3]]
#> mapping: x = ~x, y = ~y 
#> geom_text: na.rm = FALSE
#> stat_identity: na.rm = FALSE
#> position_identity 
#> 
```
