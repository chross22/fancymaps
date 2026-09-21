# fancymaps 0.1.0

First tagged release. Everything below is new, in the sense that nothing was
released before it; it is listed as what the package does rather than as a
diff.

## Maps

* `map_surface()` draws a predicted surface -- the primary deliverable of a
  spatial model -- with land, a stated projection and a scale chosen by a
  reported rule (log when the 99th percentile is at least 10 times the
  median), with the top percentile capped and the cap marked `≥` in the
  legend.
* `map_probability()` draws a bounded quantity on a scale fixed at 0 and 1,
  on a ramp whose weight arrives near certainty, and reports values that
  leave the interval instead of clipping them quietly.
* `map_diverging()` draws a quantity with a meaningful centre. `midpoint` is
  required, on purpose: an extrapolation score diverges around zero, deviance
  residuals around their own mean, and no default knows which.
* `map_pair()` draws a value beside its uncertainty as one figure: shared
  extent, same projection, same coastline, aligned panels, furniture once.
* `map_panels()` draws the same geography over several periods on one shared
  scale, with one collected legend.
* `map_effort()` draws survey effort as points, lines or hex-binned counts;
  `hex_surface()` bins any point value onto a hex grid for the other map
  functions to draw.

## Input, projection, land

* `as_map_data()` accepts the forms model output arrives in -- `sf` polygons,
  points and lines, `terra` rasters, and plain data frames with coordinate
  columns -- and checks a keyed join rather than quietly dropping unmatched
  cells.
* `display_crs()` keeps projected data in its own projection and projects
  geographic data to a Lambert azimuthal equal-area centred on the data;
  `equal_area_crs()` and `area_km2()` answer the measurement question.
* `coastline()` chooses a Natural Earth resolution from the extent, or takes
  a path or `sf` object; `coastline_fixture()` bundles a small Gulf of Maine
  shoreline so examples, tests and vignettes do not depend on optional
  downloads.

## Furniture and identity

* Scale bar, north arrow, optional locator inset (`locator_inset()`) and
  graticule, each placeable by corner.
* `theme_fancymap()` and the palettes share a visual identity with
  `fancyfx`, which plots the same models' effects and evaluation.

## Interactive

* `leaflet_surface()` and friends mirror the static maps as leaflet widgets,
  for the reader who wants to pan.

## Testing

* 249 unit tests assert the properties that must hold everywhere; 14 vdiffr
  snapshots catch what only a drawing shows. Snapshots are kept per platform
  (a local variant and a pinned-image CI variant run by
  `.github/workflows/visual-tests.yaml`), because SVG text is font metrics
  as much as it is figures.
