# Decisions

Choices made while building `fancymaps`, and the bugs found while making them.
Measurements are from this machine (R 4.6.1, macOS, aarch64) against the two
pipelines the package was written for: `dsmfit`, a 1,167-cell 5 km prediction
grid in UTM 19N over the Gulf of Maine, and `dynoccfit`, a 53-cell hexagonal
grid in lon/lat at the mouth of the Bay of Fundy.

Written alongside `docs/02-mapping-package.md` in `dsmfit`, which is the
requirements note this implements.

---

## Two customers, not one, and they disagree about everything

The requirements note was written from `dsmfit` alone. `dynoccfit` was added as
a second customer before any code was written, and it turned out to differ on
every axis that shapes the data contract:

| | `dsmfit` | `dynoccfit` |
|---|---|---|
| CRS | EPSG:32619, projected | EPSG:4326, geographic |
| cells | 1,167 squares, 5 km | 53 hexagons |
| extent | 295 x 230 km | 32 x 45 km |
| values | a column on the `sf` | a bare vector, or a `[cells x windows]` matrix |
| quantity | skewed density, diverging MESS | bounded probability, counts |

Three requirements came out of the second customer that the note does not have.

**A bounded scale is its own kind.** Posterior occupancy is not a skewed
positive quantity that happens to stop at 1. Drawing it with the surface scale
stretches whatever range the data reached across the full ramp, so a map running
0.2 to 0.6 uses the same colours as one running 0 to 1 and makes a different
claim in the same picture. `map_probability()` fixes the ends at 0 and 1 and
uses a ramp that stays near-blank at the bottom, so 0.02 looks like 0 and weight
arrives only near certainty.

**Values arrive without geometry.** A posterior summary comes out of an MCMC fit
as a vector indexed by cell; a covariate comes out of an averaging step as a
matrix. Neither carries geometry, and the alternative to accepting them is
asking every caller to bind the column on first -- which is asking them to
assert the row order matches. That assertion is silent when it is wrong and
produces a perfectly plausible, completely permuted map. So `as_map_data()`
takes values separately and checks the join, and every unmatched key is an error
naming the key rather than a hole in the map.

**A series on one scale is a first-class figure.** Six seasons of occupancy and
twelve months of a projected surface are the same shape of problem, and both
pipelines currently solve it by looping and producing panels that cannot be
compared. `map_panels()` computes one scale over every panel pooled.

---

## Projection is two questions, not one

`display_crs()` decides what the map is drawn in; `equal_area_crs()` decides what
areas are computed in. Conflating them is the ordinary way to get an area wrong,
and the mistake is invisible: `st_area()` on lon/lat returns a number with units
attached and no complaint.

Projected data keeps its own projection -- if the model was fitted in UTM 19N
then reprojecting for the figure draws a map of something other than what was
fitted. Geographic data goes to a **Lambert azimuthal equal-area centred on the
data**, not to a UTM zone: UTM is only honest within about three degrees of its
central meridian and study areas straddle zone boundaries often enough that
picking one automatically means sometimes picking a bad one silently. Centring
on the data has no boundary to straddle and is equal-area, so the display and
measurement CRSs coincide rather than merely agreeing.

The projection string is rounded to a tenth of a degree, so that two datasets
covering the same study area resolve to the *same* string. `sf` skips the
transform when a CRS compares equal; near-identical CRSs mean the grid and the
coastline get rounded differently, which is a class of misalignment that is very
hard to see and impossible to explain.

**Measured.** A one-degree box at 43N: 9,100 km2 via `area_km2()`, and the same
number to within 0.1% whether the box arrives in EPSG:4326 or EPSG:32619.

---

## Scales

### The transform is chosen by a stated rule and reported

The note asks for a replacement for `trans = "sqrt"` with automatic breaks. The
rule is the ratio of the 99th percentile to the median: below 10, linear; at or
above 10, logarithmic. It is reported with a message whenever it fires, because
a default that varies with the data has to be visible.

A log scale cannot show a zero and a density surface is full of them, so the
transform is `log(x + offset)` with `offset` the 5th percentile of the positive
values -- a number from the data with a stated provenance, rather than a
constant. `log(x + 1)` was rejected: it means something different depending on
whether the units are animals per km2 or per m2.

### Breaks are round in the reader's units, and the cap is a break

1, 2 and 5 per decade. Four labels is the ceiling, set by the narrowest legend
the package draws -- a horizontal bar under one panel of a pair.

When the top of the scale is a cap rather than a maximum, **the cap itself is
forced in as the last break** and labelled with a `>=`. Without it the top label
is whichever round number fell below the cap -- `2`, on a bar that runs to 2.75
-- and the marking has nothing to attach to. The cap is reserved before the
thinning rather than appended after, or a capped scale ends up with five labels.

### `midpoint` has no default

`scale_fill_gradient2()` falls back to the middle of the range, which is almost
never the meaning. An extrapolation score diverges around zero; deviance
residuals diverge around their own mean, and centring those on zero paints every
bin the same colour -- a bug `dsmfit` hit in exactly that form. So
`diverging_scale()` and `map_diverging()` require it, with an error that names
both cases.

### Ramp direction is a claim, so it is an argument

The diverging ramp runs blue to orange. On an extrapolation surface the values a
reader has to see are the **negative** ones, and they are a small minority, so
leaving them on the cool arm puts the alarm on the wrong side. `direction = -1`
reverses it. This was visible only in a rendered figure.

### Palettes are checked, not asserted

`tests/testthat/test-palettes.R` simulates protanopia and deuteranopia (Vienot,
Brettel & Mollon 1999, on linear RGB) and asserts:

* the sequential and bounded ramps have **monotone luminance** under normal,
  protan and deutan vision, so the ordering survives when the hue does not;
* the two arms of the diverging ramp stay **separated by at least 0.08** in
  linear RGB under both deficiencies -- the property that fails for a
  blue-against-red ramp, which is why this one is blue against orange.

The bounded ramp runs light-to-dark and the sequential one dark-to-light. That
is deliberate and the test asserts each direction explicitly; the first version
of the test asserted "increasing" for both and failed the bounded ramp, which
was a bug in the test rather than in the palette.

---

## Land

Drawn by default, and **the figure says so when it is not**. A map of the ocean
with no shoreline looks deliberate, and a reader cannot tell "this model covers
open water" from "the coastline layer failed to load".

Those two are different facts and the first implementation returned `NULL` for
both. Drawing the `dynoccfit` grid caught it: the mouth of the Bay of Fundy
genuinely has no land inside a 32 km box, and the figure was captioned "No
coastline was available", which is false and alarming. `coastline()` now returns
an empty `sf` for "the source was fine and there is no land here" and `NULL` for
"no source could be found", and the captions differ.

**The bundled fixture is only used where its resolution suits.** It is Natural
Earth medium, and the first implementation handed it back for any extent it
covered -- which meant a bay-scale map got a 1:50m shoreline and skipped the
warning that the shoreline is coarser than the map. That warning is the single
most useful thing the function says at that scale, and it is exactly the lesson
`dsmfit` records in `config/analysis.yml`. Below 200 km the fixture is bypassed,
the 1:10m source is asked for, and its absence is warned about by name.

Land is drawn **on top of** the values, not under them: a grid built by
intersecting a bounding box with a study area routinely has cells overlapping
the shore, and a coastline underneath leaves those cells sitting on land.

---

## The seam fix

5 km polygons drawn with `colour = NA` show seams and moire at some output
sizes, because adjacent cells are separate paths and the renderer antialiases
each edge against the background rather than against its neighbour.

Each cell is stroked at `linewidth = 0.06` **in its own fill colour**. The stroke
is invisible because it matches what it borders, and it is what the eye would
have seen had the two cells abutted. The cost is that the colour aesthetic is in
use, so every scale in this package is built as a fill/colour pair with identical
limits and one guide -- which is what `scale_pair()` is.

---

## Bugs found by rendering rather than by reading

The note says three of its defects were invisible in code review and obvious in
a PNG. Four more were, here.

1. **Two legends where there should have been one.** `map_panels()` passed the
   shared *limits* and *transform* down, but each panel still ran
   `surface_scale()` and recomputed `squished` against its own values. The panel
   holding the maximum got a top label reading `>= 4.52` and a quieter one got
   `2`; the scales were no longer identical objects; `patchwork` could not
   collect them. The figure drew one legend per panel -- precisely what a shared
   scale exists to prevent, and it read as a layout quirk rather than as the
   scales having silently diverged. Fixed by passing the whole spec down.
   Regression test: `test-maps.R`, "panels share one scale".

2. **The legend in scientific notation.** `5e-04` where a reader wants `0.0005`.
   Labels are now always supplied rather than left to `ggplot2`.

3. **A colourbar sized for the wrong orientation.** The theme set one key size,
   so a bar sized for a column and laid along a row came out about a centimetre
   long with six labels stacked on each other. A colourbar is five keys long, so
   the numbers in the theme are a fifth of what gets drawn.

4. **The north arrow's label clipped.** Drawn above the arrow, the reserved
   height had to cover a glyph in map units plus a text line in points, and the
   `N` pushed past the top of the panel at some figure sizes and not others. The
   label now goes below the arrow.

---

## Performance

The note asks for the Gulf of Maine grid and the segment extract to draw in
under a couple of seconds. Measured, including `ggsave` at 170 dpi:

| figure | time |
|---|---|
| 1,167 cells, single surface | 0.53 s |
| 1,167 cells, value + uncertainty pair | 0.25 s |
| 8,628 segment midpoints, binned | 0.20 s |
| 8,628 segment midpoints, drawn individually | 0.19 s |
| 53 hexagons x 6 panels, shared scale | 0.66 s |

**Binning is for legibility, not for speed.** The last two rows are the same
within noise, so the message `map_effort()` prints says overplotting hides
structure rather than claiming the figure would be slow. Rasters go through
`geom_raster` on cell centres rather than `terra::as.polygons()`, which the
requirements note asks for and which is about cost.

---

## Not done yet

* **A locator inset.** Asked for in the note, not built. It needs a second
  extent and a second coastline resolution, and it is the one piece of furniture
  that changes the figure's layout rather than sitting inside the panel.
* **Furniture placement arguments.** `scale_bar()` and `north_arrow()` take a
  `position`, but the map verbs do not pass one through, so the corner is fixed.
  On the `dsmfit` effort map the arrow lands over Nova Scotia.
* **Visual regression tests.** The convention is that every figure change is
  rendered and looked at. `vdiffr` would make that a test rather than a habit;
  it is not installed here, so it is not in `Suggests` yet.
* **A vignette.** `scales` is referenced from the package documentation and does
  not exist.
* **`rnaturalearthhires` is declared in `Suggests`** and is not on CRAN, so
  `R CMD check` needs `_R_CHECK_FORCE_SUGGESTS_=false` on a machine without it.
  Status with that set: **0 errors, 0 warnings, 0 notes.**
