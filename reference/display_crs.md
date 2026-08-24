# The coordinate system a map is drawn in

Resolved once per figure and applied to every layer, so that the grid,
the coastline, the tracklines and the region outline are all in the same
system before any of them is drawn. Layers reprojected independently by
their own `geom_sf` is how panels stop lining up.

## Usage

``` r
display_crs(x, crs = NULL)
```

## Arguments

- x:

  Anything with a CRS: an `sf` object, an `sfc`, a `bbox`, a
  `SpatRaster`, a `map_data` from
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md),
  or a CRS itself.

- crs:

  A CRS to force, in any form
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html)
  accepts. Supplying one is always allowed and always wins – this
  function chooses only when it is not told.

## Value

An
[`sf::crs`](https://r-spatial.github.io/sf/reference/coerce-methods.html)
object.

## Details

When `crs` is not given:

- **Projected data keeps its own projection.** If the analysis was done
  in UTM 19N then the model, the grid and the areas are all in UTM 19N,
  and reprojecting for the figure alone would draw a map of something
  slightly other than what was fitted.

- **Geographic data is projected** to a Lambert azimuthal equal-area
  centred on the data. Drawing lon/lat directly is the thing that makes
  a northern study area look stretched, and it puts the display CRS and
  the measurement CRS at odds.

Lambert azimuthal rather than a UTM zone, which would be the other
obvious choice: UTM is only honest within about three degrees of its
central meridian, and study areas straddle zone boundaries often enough
that picking a zone automatically means sometimes picking a bad one
silently. Centring on the data has no boundary to straddle, and it is
equal-area, so the display and the measurement CRS coincide rather than
merely agreeing. Pass `crs = 32619` or any other value if a particular
projection is wanted.

## See also

[`equal_area_crs()`](https://camilleross.org/fancymaps/reference/equal_area_crs.md),
which answers the other question.

## Examples

``` r
pts <- sf::st_as_sf(data.frame(lon = c(-70, -68), lat = c(42, 44)),
                    coords = c("lon", "lat"), crs = 4326)

# lon/lat data gets projected
display_crs(pts)
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

# unless told otherwise
display_crs(pts, crs = 4326)
#> Coordinate Reference System:
#>   User input: EPSG:4326 
#>   wkt:
#> GEOGCRS["WGS 84",
#>     ENSEMBLE["World Geodetic System 1984 ensemble",
#>         MEMBER["World Geodetic System 1984 (Transit)"],
#>         MEMBER["World Geodetic System 1984 (G730)"],
#>         MEMBER["World Geodetic System 1984 (G873)"],
#>         MEMBER["World Geodetic System 1984 (G1150)"],
#>         MEMBER["World Geodetic System 1984 (G1674)"],
#>         MEMBER["World Geodetic System 1984 (G1762)"],
#>         MEMBER["World Geodetic System 1984 (G2139)"],
#>         ELLIPSOID["WGS 84",6378137,298.257223563,
#>             LENGTHUNIT["metre",1]],
#>         ENSEMBLEACCURACY[2.0]],
#>     PRIMEM["Greenwich",0,
#>         ANGLEUNIT["degree",0.0174532925199433]],
#>     CS[ellipsoidal,2],
#>         AXIS["geodetic latitude (Lat)",north,
#>             ORDER[1],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>         AXIS["geodetic longitude (Lon)",east,
#>             ORDER[2],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>     USAGE[
#>         SCOPE["Horizontal component of 3D system."],
#>         AREA["World."],
#>         BBOX[-90,-180,90,180]],
#>     ID["EPSG",4326]]
```
