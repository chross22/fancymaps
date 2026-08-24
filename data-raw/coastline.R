## The coastline fixture that ships with the package.
##
## Tests must not touch the network, and the examples must draw land on a
## machine that has never installed a coastline source. Both are served by one
## small cropped polygon set, built here and written to inst/extdata.
##
## The extent is the Gulf of Maine plus the Bay of Fundy, because those are the
## two areas the first customers work in and between them they exercise the
## thing that matters: a 295 km grid and a 30 km one, drawn from the same
## source, where the coarse source is adequate for the first and visibly wrong
## for the second.
##
## Run with `Rscript data-raw/coastline.R` and commit the result.

box <- sf::st_bbox(c(xmin = -72, ymin = 40.5, xmax = -63.5, ymax = 46),
                   crs = sf::st_crs(4326))

land <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
land <- sf::st_make_valid(land[, c("admin")])
land <- suppressWarnings(sf::st_crop(land, box))
land <- sf::st_make_valid(land)

# Written at reduced precision: the fixture is drawn, never measured, and the
# full coordinate precision of the source triples the file for detail no figure
# resolves. `st_write`'s default is 0, meaning "keep everything".
land <- sf::st_set_precision(land, 1e5)
land <- sf::st_make_valid(land)

saveRDS(land, "inst/extdata/coastline-gom.rds", compress = "xz", version = 3)
cat(nrow(land), "features,",
    round(file.size("inst/extdata/coastline-gom.rds") / 1024), "KB\n")
