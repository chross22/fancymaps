# How a diverging surface should be coloured

How a diverging surface should be coloured

## Usage

``` r
diverging_scale(values, midpoint, limits = NULL, probs = c(0.01, 0.99))
```

## Arguments

- values:

  The numbers to be coloured.

- midpoint:

  The value the ramp's neutral colour sits at. **Required**, and
  deliberately so – see below.

- limits:

  `NULL` for symmetric limits about `midpoint` taken from `probs`, or a
  length-2 vector to fix them.

- probs:

  The quantile pair the limits are taken from, before being made
  symmetric.

## Value

A list with `limits`, `midpoint`, `rescaler`, `squished` and `note`.

## Details

`midpoint` has no default because there is no correct one. It is not the
middle of the range, which is what
[`ggplot2::scale_fill_gradient2()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)
falls back to and what makes a diverging map meaningless: an
extrapolation score diverges around **zero**, because zero is where
inside the training range becomes outside it, and deviance residuals
diverge around **their own mean**, because they do not average zero and
centring them on zero paints every bin the same colour.

Limits are made symmetric about the midpoint, so that equal distances
either side get equal colour weight. An asymmetric diverging scale makes
a difference of +1 look bigger or smaller than a difference of -1, which
is the one thing the ramp is there to prevent.

## Examples

``` r
mess <- c(rnorm(200, 5, 3), rnorm(10, -20, 5))

# zero is the meaning here
diverging_scale(mess, midpoint = 0)
#> $limits
#> [1] -25.28315  25.28315
#> 
#> $midpoint
#> [1] 0
#> 
#> $squished
#> [1] TRUE
#> 
#> $note
#> NULL
#> 

# residuals diverge around their own mean
diverging_scale(mess, midpoint = mean(mess))
#> $limits
#> [1] -25.28315  33.29263
#> 
#> $midpoint
#> [1] 4.004744
#> 
#> $squished
#> [1] TRUE
#> 
#> $note
#> [1] "centred on 4"
#> 
```
