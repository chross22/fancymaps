# Decisions

Choices made while building `fancymaps`, and the bugs found while making
them. Measurements are from this machine (R 4.6.1, macOS, aarch64)
against the two pipelines the package was written for: `dsmfit`, a
1,167-cell 5 km prediction grid in UTM 19N over the Gulf of Maine, and
`dynoccfit`, a 53-cell hexagonal grid in lon/lat at the mouth of the Bay
of Fundy.

Written alongside `docs/02-mapping-package.md` in `dsmfit`, which is the
requirements note this implements.

------------------------------------------------------------------------

## Two customers, not one, and they disagree about everything

The requirements note was written from `dsmfit` alone. `dynoccfit` was
added as a second customer before any code was written, and it turned
out to differ on every axis that shapes the data contract:

|  | `dsmfit` | `dynoccfit` |
|----|----|----|
| CRS | EPSG:32619, projected | EPSG:4326, geographic |
| cells | 1,167 squares, 5 km | 53 hexagons |
| extent | 295 x 230 km | 32 x 45 km |
| values | a column on the `sf` | a bare vector, or a `[cells x windows]` matrix |
| quantity | skewed density, diverging MESS | bounded probability, counts |

Three requirements came out of the second customer that the note does
not have.

**A bounded scale is its own kind.** Posterior occupancy is not a skewed
positive quantity that happens to stop at 1. Drawing it with the surface
scale stretches whatever range the data reached across the full ramp, so
a map running 0.2 to 0.6 uses the same colours as one running 0 to 1 and
makes a different claim in the same picture.
[`map_probability()`](https://camilleross.org/fancymaps/reference/map_probability.md)
fixes the ends at 0 and 1 and uses a ramp that stays near-blank at the
bottom, so 0.02 looks like 0 and weight arrives only near certainty.

**Values arrive without geometry.** A posterior summary comes out of an
MCMC fit as a vector indexed by cell; a covariate comes out of an
averaging step as a matrix. Neither carries geometry, and the
alternative to accepting them is asking every caller to bind the column
on first – which is asking them to assert the row order matches. That
assertion is silent when it is wrong and produces a perfectly plausible,
completely permuted map. So
[`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md)
takes values separately and checks the join, and every unmatched key is
an error naming the key rather than a hole in the map.

**A series on one scale is a first-class figure.** Six seasons of
occupancy and twelve months of a projected surface are the same shape of
problem, and both pipelines currently solve it by looping and producing
panels that cannot be compared.
[`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
computes one scale over every panel pooled.

------------------------------------------------------------------------

## Projection is two questions, not one

[`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
decides what the map is drawn in;
[`equal_area_crs()`](https://camilleross.org/fancymaps/reference/equal_area_crs.md)
decides what areas are computed in. Conflating them is the ordinary way
to get an area wrong, and the mistake is invisible: `st_area()` on
lon/lat returns a number with units attached and no complaint.

Projected data keeps its own projection – if the model was fitted in UTM
19N then reprojecting for the figure draws a map of something other than
what was fitted. Geographic data goes to a **Lambert azimuthal
equal-area centred on the data**, not to a UTM zone: UTM is only honest
within about three degrees of its central meridian and study areas
straddle zone boundaries often enough that picking one automatically
means sometimes picking a bad one silently. Centring on the data has no
boundary to straddle and is equal-area, so the display and measurement
CRSs coincide rather than merely agreeing.

The projection string is rounded to a tenth of a degree, so that two
datasets covering the same study area resolve to the *same* string. `sf`
skips the transform when a CRS compares equal; near-identical CRSs mean
the grid and the coastline get rounded differently, which is a class of
misalignment that is very hard to see and impossible to explain.

**Measured.** A one-degree box at 43N: 9,100 km2 via
[`area_km2()`](https://camilleross.org/fancymaps/reference/area_km2.md),
and the same number to within 0.1% whether the box arrives in EPSG:4326
or EPSG:32619.

------------------------------------------------------------------------

## Scales

### The transform is chosen by a stated rule and reported

The note asks for a replacement for `trans = "sqrt"` with automatic
breaks. The rule is the ratio of the 99th percentile to the median:
below 10, linear; at or above 10, logarithmic. It is reported with a
message whenever it fires, because a default that varies with the data
has to be visible.

A log scale cannot show a zero and a density surface is full of them, so
the transform is `log(x + offset)` with `offset` the 5th percentile of
the positive values – a number from the data with a stated provenance,
rather than a constant. `log(x + 1)` was rejected: it means something
different depending on whether the units are animals per km2 or per m2.

### Breaks are round in the reader’s units, and the cap is a break

1, 2 and 5 per decade. Four labels is the ceiling, set by the narrowest
legend the package draws – a horizontal bar under one panel of a pair.

When the top of the scale is a cap rather than a maximum, **the cap
itself is forced in as the last break** and labelled with a `>=`.
Without it the top label is whichever round number fell below the cap –
`2`, on a bar that runs to 2.75 – and the marking has nothing to attach
to. The cap is reserved before the thinning rather than appended after,
or a capped scale ends up with five labels.

### `midpoint` has no default

`scale_fill_gradient2()` falls back to the middle of the range, which is
almost never the meaning. An extrapolation score diverges around zero;
deviance residuals diverge around their own mean, and centring those on
zero paints every bin the same colour – a bug `dsmfit` hit in exactly
that form. So
[`diverging_scale()`](https://camilleross.org/fancymaps/reference/diverging_scale.md)
and
[`map_diverging()`](https://camilleross.org/fancymaps/reference/map_diverging.md)
require it, with an error that names both cases.

### Ramp direction is a claim, so it is an argument

The diverging ramp runs blue to orange. On an extrapolation surface the
values a reader has to see are the **negative** ones, and they are a
small minority, so leaving them on the cool arm puts the alarm on the
wrong side. `direction = -1` reverses it. This was visible only in a
rendered figure.

### Palettes are checked, not asserted

`tests/testthat/test-palettes.R` simulates protanopia and deuteranopia
(Vienot, Brettel & Mollon 1999, on linear RGB) and asserts:

- the sequential and bounded ramps have **monotone luminance** under
  normal, protan and deutan vision, so the ordering survives when the
  hue does not;
- the two arms of the diverging ramp stay **separated by at least 0.08**
  in linear RGB under both deficiencies – the property that fails for a
  blue-against-red ramp, which is why this one is blue against orange.

The bounded ramp runs light-to-dark and the sequential one
dark-to-light. That is deliberate and the test asserts each direction
explicitly; the first version of the test asserted “increasing” for both
and failed the bounded ramp, which was a bug in the test rather than in
the palette.

------------------------------------------------------------------------

## Land

Drawn by default, and **the figure says so when it is not**. A map of
the ocean with no shoreline looks deliberate, and a reader cannot tell
“this model covers open water” from “the coastline layer failed to
load”.

Those two are different facts and the first implementation returned
`NULL` for both. Drawing the `dynoccfit` grid caught it: the mouth of
the Bay of Fundy genuinely has no land inside a 32 km box, and the
figure was captioned “No coastline was available”, which is false and
alarming.
[`coastline()`](https://camilleross.org/fancymaps/reference/coastline.md)
now returns an empty `sf` for “the source was fine and there is no land
here” and `NULL` for “no source could be found”, and the captions
differ.

**The bundled fixture is only used where its resolution suits.** It is
Natural Earth medium, and the first implementation handed it back for
any extent it covered – which meant a bay-scale map got a 1:50m
shoreline and skipped the warning that the shoreline is coarser than the
map. That warning is the single most useful thing the function says at
that scale, and it is exactly the lesson `dsmfit` records in
`config/analysis.yml`. Below 200 km the fixture is bypassed, the 1:10m
source is asked for, and its absence is warned about by name.

Land is drawn **on top of** the values, not under them: a grid built by
intersecting a bounding box with a study area routinely has cells
overlapping the shore, and a coastline underneath leaves those cells
sitting on land.

------------------------------------------------------------------------

## The seam fix

5 km polygons drawn with `colour = NA` show seams and moire at some
output sizes, because adjacent cells are separate paths and the renderer
antialiases each edge against the background rather than against its
neighbour.

Each cell is stroked at `linewidth = 0.06` **in its own fill colour**.
The stroke is invisible because it matches what it borders, and it is
what the eye would have seen had the two cells abutted. The cost is that
the colour aesthetic is in use, so every scale in this package is built
as a fill/colour pair with identical limits and one guide – which is
what `scale_pair()` is.

------------------------------------------------------------------------

## Bugs found by rendering rather than by reading

The note says three of its defects were invisible in code review and
obvious in a PNG. Four more were, here.

1.  **Two legends where there should have been one.**
    [`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
    passed the shared *limits* and *transform* down, but each panel
    still ran
    [`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md)
    and recomputed `squished` against its own values. The panel holding
    the maximum got a top label reading `>= 4.52` and a quieter one got
    `2`; the scales were no longer identical objects; `patchwork` could
    not collect them. The figure drew one legend per panel – precisely
    what a shared scale exists to prevent, and it read as a layout quirk
    rather than as the scales having silently diverged. Fixed by passing
    the whole spec down. Regression test: `test-maps.R`, “panels share
    one scale”.

2.  **The legend in scientific notation.** `5e-04` where a reader wants
    `0.0005`. Labels are now always supplied rather than left to
    `ggplot2`.

3.  **A colourbar sized for the wrong orientation.** The theme set one
    key size, so a bar sized for a column and laid along a row came out
    about a centimetre long with six labels stacked on each other. A
    colourbar is five keys long, so the numbers in the theme are a fifth
    of what gets drawn.

4.  **The locator inset’s coastline as vertical bands.**
    `assemble_map()` passed the map’s own CRS down to the inset, and an
    inset is by definition much wider than its map: EPSG:32619 is honest
    over the 300 km Gulf of Maine grid and not over the 2,400 km inset
    around it, most of which is many UTM zones from the central
    meridian. It renders as vertical strips of land. The inset now picks
    its own equal-area projection centred on the study area, which has
    no zone to leave – the same fact
    [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
    cites for not choosing a UTM zone automatically, met from the other
    direction.

    Worth recording how long this took to pin down, because the shape of
    the mistake is general. Two plausible fixes were tried and
    *appeared* to work: squaring the inset extent against its rectangle,
    and clearing the grob’s `respect` flag. Both were tested on figures
    that differed in more than one way from the broken one, so each
    looked confirmed and neither was. The thing that settled it was a
    2x2 of projection against `respect` on one otherwise identical
    figure: correct in both LAEA cells, banded in both UTM cells.
    `respect` was irrelevant and is not in the code. Change one thing at
    a time.

5.  **A pair’s capped panel said nothing.** A single map appends the cap
    note to its caption and
    [`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
    to the shared one, but a pair’s panels resolve their scales
    separately, and neither path ran – so the density panel of
    `dsmfit`’s projection pair capped at its 99th percentile in silence,
    which is the exact thing squishing instead of censoring was meant to
    prevent. Each panel of a pair now carries its own note. Found
    drawing the first customer’s actual figure, not by any test; the
    regression test and an updated `pair` snapshot now exist.

6.  **The north arrow’s label clipped.** Drawn above the arrow, the
    reserved height had to cover a glyph in map units plus a text line
    in points, and the `N` pushed past the top of the panel at some
    figure sizes and not others. The label now goes below the arrow.

------------------------------------------------------------------------

## The locator inset

`inset = TRUE` on any of the single-map verbs. Off by default, unlike
the scale bar and the north arrow, because an inset sits over a corner
of the data rather than in a margin – so it is furniture that costs
something.

**How wide is a decision, not a setting.** A fixed multiple does not
work: eight times the Gulf of Maine is most of the northeast seaboard
and orients anyone, while eight times a 32 km hex grid at the mouth of
the Bay of Fundy is 260 km of water and orients nobody. So `zoom` is a
starting point and the extent doubles until land appears, capped at
`max_zoom`. If nothing is found by then the inset is dropped rather than
drawn empty – an empty inset looks like a rendering failure and still
takes the corner.

That rule is what makes the inset earn its place on the `dynoccfit` map,
whose main panel is captioned “No land falls inside this extent” and is
entirely truthful about having nothing a reader can navigate by.

**Its own projection**, not the map’s – see the bug below.

**The marker is not always to scale.** A 32 km box on a 2,400 km inset
is thinner than the line drawing it, so below 6% of the inset’s width it
becomes a fixed-size box on the same centre. That is a marker, not a
measurement, and it is why the inset carries no scale bar: it answers
*where*, and the main panel’s scale bar answers *how big*.

**Still a plain `ggplot`.** Drawn with `annotation_custom()` over a grob
rather than
[`patchwork::inset_element()`](https://patchwork.data-imaginist.com/reference/inset_element.html),
so a verb does not return a `ggplot` most of the time and a `patchwork`
when one argument is set – which would break every downstream `+` a
caller had written.

Costs about 0.15 s: 0.68 s for the Gulf of Maine surface with an inset
against 0.53 s without.

### Placing the furniture

`scalebar_position` and `north_position` on every verb, alongside the
`inset_position` the inset already had. The corner a piece of furniture
should sit in is a property of where the data happens to sit, which no
default can know: on the `dsmfit` effort map the north arrow lands over
Nova Scotia at the default corner, and there is nothing wrong with the
default – it is wrong for that figure. `north_position = "br"` puts it
in open water.

Two pieces asked into the same corner are **warned about, not
rearranged**. Moving one automatically would trade a collision the
caller asked for against one they did not, since the free corner depends
on the data. The warning names both pieces and the argument that moves
one.

------------------------------------------------------------------------

## Performance

The note asks for the Gulf of Maine grid and the segment extract to draw
in under a couple of seconds. Measured, including `ggsave` at 170 dpi:

| figure                                      | time   |
|---------------------------------------------|--------|
| 1,167 cells, single surface                 | 0.53 s |
| 1,167 cells, value + uncertainty pair       | 0.25 s |
| 8,628 segment midpoints, binned             | 0.20 s |
| 8,628 segment midpoints, drawn individually | 0.19 s |
| 53 hexagons x 6 panels, shared scale        | 0.66 s |

**Binning is for legibility, not for speed.** The last two rows are the
same within noise, so the message
[`map_effort()`](https://camilleross.org/fancymaps/reference/map_effort.md)
prints says overplotting hides structure rather than claiming the figure
would be slow. Rasters go through `geom_raster` on cell centres rather
than
[`terra::as.polygons()`](https://rspatial.github.io/terra/reference/as.polygons.html),
which the requirements note asks for and which is about cost.

------------------------------------------------------------------------

## Interactive maps, against the note’s advice

The requirements note lists interactive and web maps as a non-goal,
because `leaflet` and `mapview` exist. That is right about the
**rendering** and wrong about the **decisions**.

Handing a grid straight to `leaflet` means deciding the scale again, by
hand, at the call site – and it gets decided differently, because
[`leaflet::colorNumeric()`](https://rstudio.github.io/leaflet/reference/colorNumeric.html)
defaults to linear over the full data range with no capping. The result
is a static figure and an interactive one, of the same numbers, in
different colours. A reader who has seen both has been told two things.

So
[`leaflet_surface()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md),
[`leaflet_probability()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md)
and
[`leaflet_diverging()`](https://camilleross.org/fancymaps/reference/leaflet-maps.md)
are not a second mapping package. They are the same
[`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md),
the same
[`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md)
/
[`diverging_scale()`](https://camilleross.org/fancymaps/reference/diverging_scale.md),
and the same palettes, rendered by `leaflet` instead of by `ggplot2`.

**Measured.** Colours are compared cell for cell against the static map,
at exact hex equality, in `test-leaflet.R`: 108/108 identical for the
surface, the probability, and the diverging map in both ramp directions.

That test caught the way this breaks. The first version built the
leaflet ramp from 32 palette stops where `scale_fill_gradientn()` used
33, and the colours came out differing in the last hex digit – `#E9DFD3`
against `#E9DED2`. Indistinguishable on screen, and still a different
colour for the same number, which is exactly the claim these functions
exist to make. Both renderers now go through one `ramp_colours()`.

The legend broke the same way and needed the same fix. On a linear scale
the breaks are worked out here rather than taken from `ggplot2`, and
[`pretty()`](https://rdrr.io/r/base/pretty.html) stops below the cap –
so the static legend read `>= 0.879` and the interactive one stopped at
`0.8` with no sign that anything had been capped.

### A pair and a series become a switch, not two maps

[`leaflet_pair()`](https://camilleross.org/fancymaps/reference/leaflet_pair.md)
and
[`leaflet_panels()`](https://camilleross.org/fancymaps/reference/leaflet_panels.md)
put every layer on **one** map behind a radio control rather than
placing widgets side by side.

That is not a shortcut around synchronising two maps. It is the better
interactive form, and it follows from what
[`map_pair()`](https://camilleross.org/fancymaps/reference/map_pair.md)
is doing: shared extent, shared projection, one coastline, aligned
panels – all machinery for approximating, on paper, a comparison the
reader would rather make by looking at one place twice. Switching layers
is a **blink comparison**: same cells, same position, same zoom,
changing only in the quantity drawn. Nothing needs aligning because
nothing moved. Two side-by-side widgets would reintroduce exactly the
alignment problem the static pair exists to solve, and need a
synchronisation dependency to solve it again.

For a series it is stronger still. Small multiples ask a reader to
compare across a page; stepping through them in place compares by
change-blindness, which is far more sensitive to a small shift.

The trade is that two things can no longer be seen at once. When that is
what is wanted – a manuscript figure, a reader who cannot click – the
static verbs are the answer, and they stay.

**One legend for a series, two for a pair**, and the difference is the
point. The series shares one scale, so its legend is drawn once and does
not move while the periods change under it – that stillness is the
visible evidence that the periods are comparable. A pair’s two
quantities are in different units, so each legend follows its own layer.

**Making a legend follow a radio button needed ten lines of
JavaScript.** `addLegend(group =)` binds by listening for `overlayadd`
and `overlayremove`, and a radio control is `baseGroups`, which fires
`baselayerchange` instead – so the binding never fires. Both legends
stayed on screen, one of them describing a layer that was not being
drawn. The alternative was `overlayGroups` so the built-in binding
works, and that is worse: two overlays can both be on, the upper hides
the lower, and the map shows whichever was added last with no way to
tell.

Found by rendering it and looking, not by a test – the widget was
structurally correct and the figure was wrong.

**One scale function, not two.** `pooled_spec()` is shared by
[`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
and
[`leaflet_panels()`](https://camilleross.org/fancymaps/reference/leaflet_panels.md),
extracted rather than duplicated for the reason the palette already
taught: a scale computed in two places is a scale that will eventually
be computed two ways. Asserted period for period at exact hex equality.

### What is deliberately not carried over

- **The projection.** `leaflet` is Web Mercator and takes WGS84 inputs,
  so
  [`display_crs()`](https://camilleross.org/fancymaps/reference/display_crs.md)
  does not apply and everything is transformed to EPSG:4326.
- **The coastline.** Land comes from the tile provider. Which means
  these, alone in the package, **need the network at draw time** – the
  reason the static maps do not use tiles, and the reason this is a
  separate set of functions rather than an argument to the existing
  ones.
- **The north arrow.** Meaningless on a map you can pan but not rotate.

Verified against the real `dsmfit` grid in a browser: 1,167 cells, tiles
loading, legend reading `>= 0.879`, and all 1,167 popups bound with the
value and the requested covariates. The click-to-open interaction could
not be exercised through the sandboxed browser used here, so it is
confirmed at the payload level rather than by a click.

------------------------------------------------------------------------

## CRS agreement: what is checked, and what cannot be

Everything drawn in one figure is transformed to one display CRS before
any of it is drawn, so the layers agree **by construction** rather than
by check. What needed adding was the places where a coordinate system is
*asserted* rather than read.

**`crs =` on a data frame.** The one place a caller states a coordinate
system rather than the data carrying one, and a wrong statement was
caught nowhere: `sf` attaches whatever it is told, every transform
afterwards is arithmetically valid, and the map draws. It is just a map
of somewhere else. Both nonsense directions were accepted silently
before this:

| given           | declared   | now                                           |
|-----------------|------------|-----------------------------------------------|
| 400000, 4800000 | EPSG:4326  | error – longitude cannot pass 180             |
| -70, 43         | EPSG:32619 | warning – read as metres this is 140 m across |

An error for the first because it is certainly wrong; a warning for the
second because a projected CRS in degree-sized units is unlikely rather
than impossible. Neither can tell UTM 19N from UTM 20N, and neither
tries – what they catch is degrees and metres swapped, which is the
mistake that actually gets made.

**`shared_extent()`** now asserts its inputs agree. It should never
fire, since every caller projects first, which is exactly why it is
worth asserting: taking the first layer’s CRS and treating the rest as
if they shared it gives an extent in one system and data in another, and
the symptom is a blank panel rather than an error.

**`map_pair(uncertainty_from = )`.** A pair is read cell by cell, so the
two panels have to be the same cells. Two different grids over the same
water still draw – both get projected, both get the same extent – and
the figure looks entirely normal while inviting a comparison that cannot
be made. Different feature counts are now an error; the same count over
a different extent is a warning.

**An all-missing coordinate frame** now says so, rather than leaking
`no non-missing arguments to min; returning Inf` three times from inside
`st_bbox()`.

------------------------------------------------------------------------

## Visual regression

Every defect this package was written to fix, and four of the five found
while writing it, was a bug in what the figure *looked like*. All of
them passed their unit tests. `test-visual.R` holds 14 `vdiffr`
snapshots so that class of bug has something automatic behind the habit
of looking at a PNG.

**Measured sensitivity.** Perturbing one stop of the diverging palette
by 4/255 – `#E8E8E8` to `#E4E4E4`, invisible on screen – failed exactly
the four snapshots that use that ramp (`diverging`,
`diverging-reversed`, `diverging-off-centre`, `pair`) and none of the
other ten. Reverting the
[`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md)
shared-spec fix failed the `panels` snapshot alongside the unit test
that already covered it.

**The coastline is pinned to the bundled fixture in every snapshot**,
and that is not a detail.
[`example_grid()`](https://camilleross.org/fancymaps/reference/example_grid.md)
is 194 km across, just under the 200 km where
[`coastline()`](https://camilleross.org/fancymaps/reference/coastline.md)
starts asking for a 1:10m shoreline – so left to resolve itself it draws
Natural Earth large where `rnaturalearthhires` is installed and medium
where it is not. The snapshots would then encode which optional packages
the machine happened to have rather than what this package does.

**They are platform-specific, and that is a real limitation.** svglite
writes each text element with a `textLength` measured from system font
metrics, so a first run on a machine with different fonts reports diffs
that are typography rather than regressions. The baselines here are
macOS, R 4.6.1, vdiffr 1.0.9, svglite 2.2.2. CI should pin one image and
regenerate on it once.

**What they are not** is a check that a figure is correct. A snapshot of
a broken map is a stable snapshot of a broken map – as the `panels`
baseline would have been, had it been taken before the two-legend bug
was found. They tell the difference between a change and an accident;
the properties that have to hold are still asserted against numbers, in
`test-maps.R` and its neighbours.

------------------------------------------------------------------------

## Standing caveats

Every requirement in `dsmfit`’s `docs/02-mapping-package.md` is
implemented, including the three it lists as non-goals and which were
later asked for – interactive maps, a locator inset, and furniture
placement. What is left is not missing work but a condition of the
build:

- **`rnaturalearthhires` is declared in `Suggests`** and is not on CRAN,
  so `R CMD check` needs `_R_CHECK_FORCE_SUGGESTS_=false` on a machine
  without it. Status with that set, vignette rebuilt: **0 errors, 0
  warnings, 0 notes.**
- **Snapshot baselines are platform-specific**, so `test-visual.R` skips
  on CI (`skip_on_ci()`) and the snapshots run wherever a human is –
  which is where the “render it and look” convention lives anyway.
  Regenerating the baselines on one pinned CI image and dropping the
  skip is the upgrade path. See “Visual regression” above.
