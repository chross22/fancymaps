#' A small example grid
#'
#' A 12 by 9 grid of square cells in the Gulf of Maine, carrying one column of
#' each kind of quantity this package draws. Used by the examples and the
#' tests, so that neither needs a fitted model, a covariate product or the
#' network.
#'
#' @param seed The random seed. Fixed by default, so the examples draw the same
#'   figure every time and a change to one is a change worth looking at.
#'
#' @details
#' The values are made up, but not arbitrarily: each is shaped like the
#' quantity it stands for, because the point of the fixture is to exercise the
#' scales.
#'
#' \describe{
#'   \item{`density`}{Skewed hard, most cells near zero, a few carrying most of
#'     the total -- which is what makes a linear ramp useless and is the case
#'     [surface_scale()] exists for.}
#'   \item{`cv`}{Rising where density falls, as a coefficient of variation
#'     does: the model is least certain where it saw least.}
#'   \item{`mess`}{Mostly positive with a novel corner, so it diverges around a
#'     zero that means something.}
#'   \item{`occupancy`}{On \[0, 1\], for [map_probability()].}
#'   \item{`residual`}{Centred on a non-zero mean, which is the case that
#'     breaks a diverging scale centred on zero.}
#'   \item{`grid_id`}{A cell identifier, for exercising the join in
#'     [as_map_data()].}
#' }
#'
#' @return An `sf` data frame of polygons in WGS84.
#'
#' @examples
#' grid <- example_grid()
#' head(sf::st_drop_geometry(grid))
#'
#' @export
example_grid <- function(seed = 42) {
  nx <- 12L
  ny <- 9L
  x0 <- -70.4; y0 <- 42.6; step <- 0.2

  cells <- expand.grid(i = seq_len(nx), j = seq_len(ny))
  geometry <- sf::st_sfc(lapply(seq_len(nrow(cells)), function(k) {
    xs <- x0 + (cells$i[k] - c(1, 0, 0, 1, 1)) * step
    ys <- y0 + (cells$j[k] - c(1, 1, 0, 0, 1)) * step
    sf::st_polygon(list(cbind(xs, ys)))
  }), crs = 4326)

  # Distance from a hotspot near the coast, which every field is built from --
  # so the surface, its uncertainty and its residuals are related the way they
  # would be in a real fit rather than being three unrelated random fields.
  cx <- (nx + 1) / 2 - 2
  cy <- (ny + 1) / 2
  d <- sqrt(((cells$i - cx) / nx)^2 + ((cells$j - cy) / ny)^2) * 6

  withr_seed(seed, {
    density <- exp(-d^2) * 3 + stats::rlnorm(nrow(cells), -6, 1)
    cv <- 0.15 + d * 0.12 + stats::runif(nrow(cells), 0, 0.05)
    mess <- 30 - d * 12 + stats::rnorm(nrow(cells), 0, 3)
    occupancy <- stats::plogis(2.5 - d * 1.1 + stats::rnorm(nrow(cells), 0, 0.4))
    residual <- stats::rnorm(nrow(cells), mean = 0.8, sd = 0.6)
  })

  sf::st_sf(
    grid_id = seq_len(nrow(cells)),
    density = density, cv = cv, mess = mess,
    occupancy = occupancy, residual = residual,
    geometry = geometry
  )
}

# A seed set and put back, so that calling the fixture does not reach out and
# change the random stream of whatever called it.
withr_seed <- function(seed, expr) {
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    old <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  } else {
    on.exit(suppressWarnings(rm(".Random.seed", envir = globalenv())),
            add = TRUE)
  }
  set.seed(seed)
  eval.parent(substitute(expr))
}
