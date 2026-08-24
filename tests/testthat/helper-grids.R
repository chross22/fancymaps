# Two grids that disagree about everything that matters, because the two
# pipelines this package was written for disagree about everything that
# matters: one is projected, square-celled and large; the other is lon/lat,
# hexagonal, small, and keeps its values somewhere other than on the geometry.

utm_grid <- function(n = 6) {
  cells <- expand.grid(i = seq_len(n), j = seq_len(n))
  geom <- sf::st_sfc(lapply(seq_len(nrow(cells)), function(k) {
    x <- 400000 + (cells$i[k] - c(1, 0, 0, 1, 1)) * 5000
    y <- 4800000 + (cells$j[k] - c(1, 1, 0, 0, 1)) * 5000
    sf::st_polygon(list(cbind(x, y)))
  }), crs = 32619)
  sf::st_sf(grid_id = seq_len(nrow(cells)),
            density = seq_len(nrow(cells)) / 100,
            geometry = geom)
}

lonlat_points <- function(n = 20) {
  set.seed(3)
  sf::st_as_sf(
    data.frame(lon = runif(n, -70, -69), lat = runif(n, 43, 44),
               n_seen = rpois(n, 2)),
    coords = c("lon", "lat"), crs = 4326)
}
