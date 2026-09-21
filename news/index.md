# Changelog

## fancymaps 0.1.0

First tagged release. Everything below is new, in the sense that nothing
was released before it; it is listed as what the package does rather
than as a diff.

### Maps

- [`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md)
  draws a predicted surface – the primary deliverable of a spatial model
  – with land, a stated projection and a scale chosen by a reported rule
  (log when the 99th percentile is at least 10 times the median), with
  the top percentile capped and the cap marked `≥` in the legend.
- [`map_probability()`](https://camilleross.org/fancymaps/reference/map_probability.md)
  draws a bounded quantity on a scale fixed at 0 and 1, on a ramp whose
  weight arrives near certainty, and reports values that leave the
  interval instead of clipping them quietly.
- [`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md)
  draws a quantity with a meaningful centre. `midpoint` is required, on
  purpose: an extrapolation score diverges around zero, deviance
  residuals around their own mean, and no default knows which.
- [`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
  draws a value beside its uncertainty as one figure: shared extent,
  same projection, same coastline, aligned panels, furniture once.
- [`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
  draws the same geography over several periods on one shared scale,
  with one collected legend.
- [`map_effort()`](https://camilleross.org/fancymaps/reference/map_effort.md)
  draws survey effort as points, lines or hex-binned counts;
  [`hex_surface()`](https://camilleross.org/fancymaps/reference/hex_surface.md)
  bins any point value onto a hex grid for the other map functions to
  draw.

### Input, projection, land

- [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md)
  accepts the forms model output arrives in – `sf` polygons, points and
  lines, `terra` rasters, and plain data frames with coordinate columns
  – and checks a keyed join rather than quietly dropping unmatched
  cells.
- [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
  keeps projected data in its own projection and projects geographic
  data to a Lambert azimuthal equal-area centred on the data;
  [`equal_area_crs()`](https://camilleross.org/fancymaps/reference/equal_area_crs.md)
  and
  [`area_km2()`](https://camilleross.org/fancymaps/reference/area_km2.md)
  answer the measurement question.
- [`coastline()`](https://camilleross.org/fancymaps/reference/coastline.md)
  chooses a Natural Earth resolution from the extent, or takes a path or
  `sf` object;
  [`coastline_fixture()`](https://camilleross.org/fancymaps/reference/coastline.md)
  bundles a small Gulf of Maine shoreline so examples, tests and
  vignettes do not depend on optional downloads.

### Furniture and identity

- Scale bar, north arrow, optional locator inset
  ([`locator_inset()`](https://camilleross.org/fancymaps/reference/locator_inset.md))
  and graticule, each placeable by corner.
- [`theme_fancymap()`](https://camilleross.org/fancymaps/reference/theme_fancymap.md)
  and the palettes share a visual identity with `fancyfx`, which plots
  the same models’ effects and evaluation.

### Interactive

- [`leaflet_surface()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md)
  and friends mirror the static maps as leaflet widgets, for the reader
  who wants to pan.

### Testing

- 249 unit tests assert the properties that must hold everywhere; 14
  vdiffr snapshots catch what only a drawing shows. Snapshots are kept
  per platform (a local variant and a pinned-image CI variant run by
  `.github/workflows/visual-tests.yaml`), because SVG text is font
  metrics as much as it is figures.
