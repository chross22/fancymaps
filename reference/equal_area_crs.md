# The coordinate system areas and distances are computed in

Always equal-area, and always centred on the data rather than on a
continent.

## Usage

``` r
equal_area_crs(x)
```

## Arguments

- x:

  As for
  [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md).

## Value

An
[`sf::crs`](https://r-spatial.github.io/sf/reference/coerce-methods.html)
object.

## Details

A Lambert azimuthal equal-area projection centred on the middle of the
data. Distortion in an azimuthal projection grows with distance from its
centre, so centring it on the thing being measured is what keeps the
error small, and it is why this is computed per dataset rather than
fixed to a national projection such as Albers North America (EPSG:5070).
That one is equal-area too, but its standard parallels are placed for
the conterminous United States; the Bay of Fundy is not in the
conterminous United States.

This is not necessarily the CRS the map is drawn in – see
[`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
for why those are separate questions.

## Examples

``` r
pts <- sf::st_as_sf(data.frame(lon = c(-70, -68), lat = c(42, 44)),
                    coords = c("lon", "lat"), crs = 4326)
equal_area_crs(pts)
#> Coordinate Reference System:
#>   User input: +proj=laea +lat_0=43.0 +lon_0=-69.0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs 
#>   wkt:
#> PROJCRS["unknown",
#>     BASEGEOGCRS["unknown",
#>         DATUM["World Geodetic System 1984",
#>             ELLIPSOID["WGS 84",6378137,298.257223563,
#>                 LENGTHUNIT["metre",1]],
#>             ID["EPSG",6326]],
#>         PRIMEM["Greenwich",0,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8901]]],
#>     CONVERSION["unknown",
#>         METHOD["Lambert Azimuthal Equal Area",
#>             ID["EPSG",9820]],
#>         PARAMETER["Latitude of natural origin",43,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8801]],
#>         PARAMETER["Longitude of natural origin",-69,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8802]],
#>         PARAMETER["False easting",0,
#>             LENGTHUNIT["metre",1],
#>             ID["EPSG",8806]],
#>         PARAMETER["False northing",0,
#>             LENGTHUNIT["metre",1],
#>             ID["EPSG",8807]]],
#>     CS[Cartesian,2],
#>         AXIS["(E)",east,
#>             ORDER[1],
#>             LENGTHUNIT["metre",1,
#>                 ID["EPSG",9001]]],
#>         AXIS["(N)",north,
#>             ORDER[2],
#>             LENGTHUNIT["metre",1,
#>                 ID["EPSG",9001]]]]
```
