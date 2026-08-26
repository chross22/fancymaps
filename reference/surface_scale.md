# How a surface should be coloured

Works out the transform, limits and breaks for a set of values, without
drawing anything.
[`map_surface()`](https://camilleross.org/fancymaps/reference/map_surface.md)
calls it; call it directly to see what a map is going to do before it
does it, or to fix a scale across several figures that would otherwise
each choose their own.

## Usage

``` r
surface_scale(values, transform = "auto", limits = NULL, probs = c(0, 0.99))
```

## Arguments

- values:

  The numbers to be coloured.

- transform:

  `"auto"` to choose by the rule below, or any transform name
  [`ggplot2::continuous_scale()`](https://ggplot2.tidyverse.org/reference/continuous_scale.html)
  accepts – `"identity"`, `"log"`, `"sqrt"`.

- limits:

  `NULL` to take them from `probs`, or a length-2 vector to fix them.

- probs:

  The quantiles the limits are taken from. The default keeps the bottom
  of the range and cuts the top percentile, because that is the tail
  that flattens a skewed surface.

## Value

A list with `transform`, `limits`, `breaks`, `labels`, `squished`
(whether anything falls outside `limits`) and `note` (the legend
annotation, or `NULL`).

## Choosing a transform

Only when `transform = "auto"`, and by one rule: the ratio of the 99th
percentile to the median. Below 10 the values are drawn linearly. At or
above 10 the top of the range is more than an order of magnitude above
the middle, a linear ramp spends most of its colours on values almost
nothing has, and the scale becomes logarithmic.

A logarithmic scale cannot show a zero, and a density surface is full of
them. Rather than dropping those cells or adding 1 to everything – which
means something different depending on whether the units are animals per
km2 or per m2 – the transform is `log(x + offset)`, with `offset` set to
the 5th percentile of the positive values and reported. It is a real
number from the data with a stated provenance, not a constant that
happens to make the arithmetic work.

Any automatic choice is reported with a message, because a default that
varies with the data is a default that has to be visible. It also means
two figures of different data can end up on different scales: when they
must match, fix `transform` and `limits`, or draw them with
[`map_panels()`](https://camilleross.org/fancymaps/reference/map_panels.md),
which does that for you.

## Examples

``` r
skewed <- c(rep(0, 40), rexp(200, rate = 20))
surface_scale(skewed)
#> $transform
#> [1] "identity"
#> 
#> $limits
#> [1] 0.0000000 0.2073073
#> 
#> $breaks
#> list()
#> attr(,"class")
#> [1] "waiver"
#> 
#> $labels
#> function (x) 
#> {
#>     lab <- format(signif(x, 3), scientific = FALSE, trim = TRUE, 
#>         drop0trailing = TRUE, big.mark = ",")
#>     if (!squished) 
#>         return(lab)
#>     at_top <- !is.na(x) & abs(x - limits[2]) < 1e-09 * max(1, 
#>         abs(limits[2]))
#>     lab[at_top] <- paste0("≥ ", lab[at_top])
#>     lab
#> }
#> <bytecode: 0x559ebe433778>
#> <environment: 0x559ebbb9ee00>
#> 
#> $squished
#> [1] TRUE
#> 
#> $note
#> NULL
#> 

# a quantity that does not need it
surface_scale(runif(100, 8, 12))
#> $transform
#> [1] "identity"
#> 
#> $limits
#> [1]  8.046092 11.833802
#> 
#> $breaks
#> list()
#> attr(,"class")
#> [1] "waiver"
#> 
#> $labels
#> function (x) 
#> {
#>     lab <- format(signif(x, 3), scientific = FALSE, trim = TRUE, 
#>         drop0trailing = TRUE, big.mark = ",")
#>     if (!squished) 
#>         return(lab)
#>     at_top <- !is.na(x) & abs(x - limits[2]) < 1e-09 * max(1, 
#>         abs(limits[2]))
#>     lab[at_top] <- paste0("≥ ", lab[at_top])
#>     lab
#> }
#> <bytecode: 0x559ebe433778>
#> <environment: 0x559ebbafa320>
#> 
#> $squished
#> [1] TRUE
#> 
#> $note
#> NULL
#> 
```
