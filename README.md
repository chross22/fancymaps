# fancymaps

Publication-ready maps for spatial model output.

A model that predicts over space produces a map, and a map is not a heatmap with
coordinates. It needs land, so a reader can tell one bay from another and check
that the study area is the water they think it is. It needs a stated projection,
so that area means area. It needs a colour scale chosen for the quantity being
drawn rather than whichever default fell out. And when a value is shown beside
its uncertainty, the two need to be one figure rather than two that happen to be
adjacent.

`fancymaps` draws those maps. It does not compute what goes on them — density,
occupancy, uncertainty and extrapolation are the fitting package's job.

It is the map half of a pair: [`fancyfx`](https://github.com/chross22/fancyfx)
plots the same models' effects and evaluation. See
[Sister package](#sister-package-fancyfx) below.

## Install

```r
# install.packages("remotes")
remotes::install_github("chross22/fancymaps")
```

## The maps

```r
library(fancymaps)
grid <- example_grid()

# a predicted surface
map_surface(grid, "density", label = "animals per km2")

# a probability, on a scale fixed at 0 and 1
map_probability(grid, "occupancy")

# something with a meaningful centre -- the midpoint is required
map_diverging(grid, "mess", midpoint = 0, direction = -1)

# a value beside its uncertainty, as one figure
map_pair(grid, "density", "mess",
         uncertainty_kind = "diverging", uncertainty_direction = -1,
         labels = c("animals per km2", "MESS"))

# a series, on one shared scale
map_panels(grid, cbind(spring = grid$density, summer = grid$density * 2.5))

# survey effort, binned when there is too much of it to draw
map_effort(points = sightings, size = "group_size")
```

## What it accepts

Not one blessed type. `as_map_data()` takes:

- `sf` polygons, points and lines,
- a `terra` `SpatRaster`,
- a plain data frame with coordinate columns — which is the form model output
  usually arrives in, since `mgcv` and `dsm` want geometry dropped and a
  prediction rejoined afterwards.

Values may sit on the object as a column, or arrive separately and be joined by
an identifier:

```r
# a posterior summary, keyed by cell id
occupancy <- setNames(colMeans(posterior_z), grid$grid_id)
map_probability(grid, occupancy, by = "grid_id")
```

That second path is not an afterthought. A posterior summary comes out of an
MCMC fit as a bare vector and a covariate comes out of an averaging step as a
matrix; requiring the caller to bind the column on first is requiring them to
assert the row order matches, and that assertion is silent when it is wrong.
Every unmatched key is an error naming the key, rather than a hole in the map.

## Things it insists on

**Land, or an explanation.** Drawn by default, at a resolution chosen from the
extent. If no source can be found the map still draws, but it is captioned to
say so — a map with no coastline looks deliberate. "There is no land in this
extent" and "no coastline source was available" are captioned differently,
because they mean opposite things and look identical.

**One projection per figure.** Taken from the data when it is projected, and a
Lambert azimuthal equal-area centred on the data when it is lon/lat. Areas are
computed in an equal-area projection regardless, never in the display one.

**A scale that was chosen.** For a skewed quantity, a transform selected by a
stated rule, reported when it fires, and named in the legend, with breaks at
round numbers in the original units. Limits from a quantile, values beyond them
capped rather than dropped, and the top label marked `≥` so the capping is
visible. For a diverging quantity, `midpoint` is required and has no default —
zero for an extrapolation score, the mean for deviance residuals, never the
middle of the range.

**Colours that survive colour blindness.** The ramps are checked by simulation
in the test suite rather than asserted: monotone luminance under protanopia and
deuteranopia for the sequential and bounded ramps, and measured separation
between the two arms of the diverging one.

## Not this package's job

Interactive maps (`leaflet`, `mapview`), basemap tiles, general GIS, and
deciding the analysis.

## Sister package: fancyfx

[`fancyfx`](https://github.com/chross22/fancyfx) plots what a model claims —
effect curves with a rug of the supporting data above them — and whether it has
earned the claim: ROC, thresholds, calibration, permutation importance. This
package draws where it says it.

The two share a visual identity by construction rather than by agreement.
`theme_fancymap()` is `fancyfx::theme_fancyfx()` with the axis furniture
removed, so the fonts, the sizes and the legend styling come from one place and
change in one place.

The dependency runs one way: `fancymaps` imports `fancyfx`, and `fancyfx` knows
nothing about `fancymaps`. That is the right direction — the maps package needs
the effects package's identity, not the other way round — and it means map
rendering's hard dependency on `sf` never reaches someone who installed a
package to plot a partial effect.

Some things stay over there on purpose. `fancyfx::mess()` and
`plotExtrapolation()` are statements about a *model*, not about a map, so they
belong beside the ROC curves — and what they produce is a common thing to hand
to `map_diverging()`. `fancyfx::hex_bin()` is reused directly by `map_effort()`
rather than reimplemented.

## See also

`DECISIONS.md` records the choices, the measurements behind them, and the bugs
found while making them.
