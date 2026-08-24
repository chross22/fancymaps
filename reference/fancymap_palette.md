# The colour ramps these maps use

The colour ramps these maps use

## Usage

``` r
fancymap_palette(type = c("sequential", "diverging", "bounded"), n = NULL)
```

## Arguments

- type:

  Which ramp: `"sequential"` for a quantity that only increases,
  `"diverging"` for one with a meaningful centre, `"bounded"` for a
  proportion or probability.

- n:

  How many stops to return. The stops are interpolated, so any `n`
  works; the default returns the ramp as it is defined.

## Value

A character vector of hex colours.

## Details

`"bounded"` is a distinct ramp rather than an alias for `"sequential"`
because a probability has two meaningful ends rather than one. Viridis
puts its most saturated colour at the top, which is right when the top
is "highest observed" and misleading when it is "certain": on an
occupancy map a cell at 0.02 and a cell at 0.0 should look nearly the
same, and the ramp should reach full weight only as it approaches 1.

## Examples

``` r
fancymap_palette("sequential")
#> [1] "#440154" "#46337E" "#365C8D" "#277F8E" "#1FA187" "#4AC16D" "#A0DA39"
#> [8] "#FDE725"
fancymap_palette("diverging", 5)
#> [1] "#1B4F72" "#5DA2C3" "#E8E8E8" "#E29444" "#8A4404"
```
