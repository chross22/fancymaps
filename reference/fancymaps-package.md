# fancymaps: Publication-Ready Maps for Spatial Model Output

A model that predicts over space produces a map, and a map is not a
heatmap with coordinates. It needs land, so a reader can tell one bay
from another and check that the study area is the water they think it
is. It needs a stated projection, so that area means area. It needs a
colour scale chosen for the quantity being drawn rather than whichever
default fell out. And when a value is shown beside its uncertainty, the
two need to be drawn as one figure rather than assembled from two.

## Details

`fancymaps` draws those maps. It does not compute what goes on them:
density, occupancy, uncertainty and extrapolation are the fitting
package's job, and this one draws what it is given.

## The maps

- [`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md):

  A predicted surface – a skewed positive quantity such as density, or a
  bounded one such as occupancy probability.

- [`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md):

  A quantity with a meaningful centre: an extrapolation score around
  zero, residuals around their own mean.

- [`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md):

  A value and its uncertainty, as one figure with a shared extent and
  aligned panels.

- [`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md):

  The same geography over several periods, on one shared scale, so the
  panels can be compared.

- [`map_effort()`](https://camilleross.org/fancymaps/reference/map_effort.md):

  Survey effort and detections: lines, points, and binning when there
  are too many of them to draw.

## What it accepts

Not one blessed type.
[`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md)
takes sf polygons, points and lines, a terra `SpatRaster`, or a plain
data frame with coordinate columns – which is the form model output
usually arrives in, since `mgcv` and `dsm` want geometry dropped and a
prediction rejoined afterwards.

Values may sit on the object as a column, or be supplied separately and
joined by an identifier. The second case is not an afterthought: a
posterior summary comes out of an MCMC fit as a bare vector indexed by
cell, and requiring the caller to bind it on first is requiring them to
get the row order right silently.

## Projection

Handled once.
[`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
settles what the map is drawn in – the data's own CRS when it is
projected, and an appropriate UTM zone when it is lon/lat – and
everything is reprojected to it before anything is drawn. Area is
computed in an equal-area projection from
[`equal_area_crs()`](https://camilleross.org/fancymaps/reference/equal_area_crs.md),
never in the display one and never on lon/lat, where a degree of
longitude is 74 km in the Gulf of Maine and 111 at the equator.

## Land

Drawn by default.
[`coastline()`](https://camilleross.org/fancymaps/reference/coastline.md)
resolves a source: a bundled fixture, a user's own shapefile, or
rnaturalearth at a resolution chosen for the extent. If no source can be
found the map still draws, but it says so – in a warning and on the
figure – because a map with no coastline looks deliberate, and a reader
cannot tell an ocean model from a missing layer.

## Sister package – fancyfx

fancyfx is the other half of the pair. It plots what a model claims –
effect curves with a rug of the supporting data above them – and whether
it has earned the claim: ROC, thresholds, calibration, permutation
importance. This package draws where it says it.

The two share a visual identity by construction rather than by
agreement.
[`theme_fancymap()`](https://camilleross.org/fancymaps/reference/theme_fancymap.md)
is
[`fancyfx::theme_fancyfx()`](https://camilleross.org/fancyfx/reference/theme_fancyfx.html)
with the axis furniture removed, so the fonts, the sizes and the legend
styling come from one place and change in one place. An effect figure
and a map figure from the same analysis read as one system.

The dependency runs one way: this package imports fancyfx, and fancyfx
knows nothing about this one. That is the right direction – the maps
package needs the effects package's identity, not the other way round –
and it means map rendering's hard dependency on sf never reaches someone
who installed a package to plot a partial effect.

Some things stay over there on purpose.
[`fancyfx::mess()`](https://camilleross.org/fancyfx/reference/mess.html)
and
[`fancyfx::plotExtrapolation()`](https://camilleross.org/fancyfx/reference/plotExtrapolation.html)
are statements about a *model*, not about a map, so they belong beside
the ROC curves; what they produce is a common thing to hand to
[`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md).
[`fancyfx::hex_bin()`](https://camilleross.org/fancyfx/reference/hex_bin.html)
is reused directly by
[`map_effort()`](https://camilleross.org/fancymaps/reference/map_effort.md)
rather than reimplemented.

## Scales

Colours come from scales that were chosen.
[`vignette("scales")`](https://camilleross.org/fancymaps/articles/scales.md)
is the long version – why a square-root transform with automatic breaks
is not a scale, what replaces it, and why a diverging midpoint has no
default. See
[`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md)
and
[`diverging_scale()`](https://camilleross.org/fancymaps/reference/diverging_scale.md)
for the reference pages.

## See also

fancyfx at <https://github.com/chross22/fancyfx>, which plots the
effects and the evaluation of the same models these maps come from.

## Author

**Maintainer**: Camille Ross <camille.ross@maine.edu>
([ORCID](https://orcid.org/0000-0002-1428-2294))

Authors:

- Camille Ross <camille.ross@maine.edu>
  ([ORCID](https://orcid.org/0000-0002-1428-2294))
