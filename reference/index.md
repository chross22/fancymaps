# Package index

## The maps

One verb per question a map answers. Each resolves land, projection and
a colour scale chosen for the quantity, and says so in the figure when
it had to decide something.

- [`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md)
  : Map a predicted surface
- [`map_probability()`](https://camilleross.org/fancymaps/reference/map_probability.md)
  : Map a probability
- [`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md)
  : Map a quantity with a meaningful centre
- [`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
  : A surface and its uncertainty, as one figure
- [`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
  : The same geography over several periods, on one scale
- [`map_effort()`](https://camilleross.org/fancymaps/reference/map_effort.md)
  : Map survey effort and detections
- [`hex_surface()`](https://camilleross.org/fancymaps/reference/hex_surface.md)
  : Bin point values into a hexagonal surface

## Interactive

The same maps as leaflet widgets, built from the same scale objects so a
cell is the same colour in both renderers. A pair and a series become a
layer switch on one map rather than two maps.

- [`leaflet_surface()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md)
  [`leaflet_probability()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md)
  [`leaflet_diverging()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md)
  : Interactive versions of the maps
- [`leaflet_pair()`](https://camilleross.org/fancymaps/reference/leaflet_pair.md)
  : A surface and its uncertainty, interactively
- [`leaflet_panels()`](https://camilleross.org/fancymaps/reference/leaflet_panels.md)
  : A series over several periods, interactively

## What the maps are built from

The data contract, the coastline, and the two coordinate-system
questions – what a map is drawn in and what areas are measured in –
answered separately on purpose.

- [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md)
  : Put spatial model output into the form the maps draw from
- [`coastline()`](https://camilleross.org/fancymaps/reference/coastline.md)
  [`coastline_fixture()`](https://camilleross.org/fancymaps/reference/coastline.md)
  : A coastline for a map
- [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
  : The coordinate system a map is drawn in
- [`equal_area_crs()`](https://camilleross.org/fancymaps/reference/equal_area_crs.md)
  : The coordinate system areas and distances are computed in
- [`area_km2()`](https://camilleross.org/fancymaps/reference/area_km2.md)
  : Areas in square kilometres, computed honestly

## Scales

How a surface should be coloured, decided by stated rules and reported
when a rule fires. See vignette(“scales”) for the argument.

- [`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md)
  : How a surface should be coloured
- [`diverging_scale()`](https://camilleross.org/fancymaps/reference/diverging_scale.md)
  : How a diverging surface should be coloured
- [`fancymap_palette()`](https://camilleross.org/fancymaps/reference/fancymap_palette.md)
  : The colour ramps these maps use

## Furniture and style

Scale bar, north arrow, locator inset, and the theme shared with
fancyfx.

- [`scale_bar()`](https://camilleross.org/fancymaps/reference/scale_bar.md)
  : A scale bar, sized for the panel it is drawn in
- [`north_arrow()`](https://camilleross.org/fancymaps/reference/north_arrow.md)
  : A north arrow
- [`locator_inset()`](https://camilleross.org/fancymaps/reference/locator_inset.md)
  : A locator inset
- [`theme_fancymap()`](https://camilleross.org/fancymaps/reference/theme_fancymap.md)
  : A theme for maps
- [`theme_fancymap_panel()`](https://camilleross.org/fancymaps/reference/theme_fancymap_panel.md)
  : The map theme as used inside a multi-panel figure

## Example data

- [`example_grid()`](https://camilleross.org/fancymaps/reference/example_grid.md)
  : A small example grid
