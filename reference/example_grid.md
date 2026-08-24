# A small example grid

A 12 by 9 grid of square cells in the Gulf of Maine, carrying one column
of each kind of quantity this package draws. Used by the examples and
the tests, so that neither needs a fitted model, a covariate product or
the network.

## Usage

``` r
example_grid(seed = 42)
```

## Arguments

- seed:

  The random seed. Fixed by default, so the examples draw the same
  figure every time and a change to one is a change worth looking at.

## Value

An `sf` data frame of polygons in WGS84.

## Details

The values are made up, but not arbitrarily: each is shaped like the
quantity it stands for, because the point of the fixture is to exercise
the scales.

- `density`:

  Skewed hard, most cells near zero, a few carrying most of the total –
  which is what makes a linear ramp useless and is the case
  [`surface_scale()`](https://camilleross.org/fancymaps/reference/surface_scale.md)
  exists for.

- `cv`:

  Rising where density falls, as a coefficient of variation does: the
  model is least certain where it saw least.

- `mess`:

  Mostly positive with a novel corner, so it diverges around a zero that
  means something.

- `occupancy`:

  On \[0, 1\], for
  [`map_probability()`](https://camilleross.org/fancymaps/reference/map_probability.md).

- `residual`:

  Centred on a non-zero mean, which is the case that breaks a diverging
  scale centred on zero.

- `grid_id`:

  A cell identifier, for exercising the join in
  [`as_map_data()`](https://camilleross.org/fancymaps/reference/as_map_data.md).

## Examples

``` r
grid <- example_grid()
head(sf::st_drop_geometry(grid))
#>   grid_id     density        cv      mess occupancy  residual
#> 1       1 0.009878606 0.5614851 -7.785698 0.3145203 0.8803216
#> 2       2 0.001922370 0.5210795 -6.429409 0.3271094 1.8712034
#> 3       3 0.004958808 0.5097867 -1.471500 0.3812665 2.2532980
#> 4       4 0.006967122 0.5160391  2.156948 0.4320310 0.1539027
#> 5       5 0.006013330 0.4959027 -5.118395 0.3532427 1.0915647
#> 6       6 0.003623981 0.4909970 -1.877589 0.4942128 1.6331130
```
