#' fancymaps: Publication-Ready Maps for Spatial Model Output
#'
#' A model that predicts over space produces a map, and a map is not a heatmap
#' with coordinates. It needs land, so a reader can tell one bay from another
#' and check that the study area is the water they think it is. It needs a
#' stated projection, so that area means area. It needs a colour scale chosen
#' for the quantity being drawn rather than whichever default fell out. And
#' when a value is shown beside its uncertainty, the two need to be drawn as
#' one figure rather than assembled from two.
#'
#' `fancymaps` draws those maps. It does not compute what goes on them:
#' density, occupancy, uncertainty and extrapolation are the fitting package's
#' job, and this one draws what it is given.
#'
#' @section The maps:
#' \describe{
#'   \item{[map_surface()]}{A predicted surface -- a skewed positive quantity
#'     such as density, or a bounded one such as occupancy probability.}
#'   \item{[map_diverging()]}{A quantity with a meaningful centre: an
#'     extrapolation score around zero, residuals around their own mean.}
#'   \item{[map_pair()]}{A value and its uncertainty, as one figure with a
#'     shared extent and aligned panels.}
#'   \item{[map_panels()]}{The same geography over several periods, on one
#'     shared scale, so the panels can be compared.}
#'   \item{[map_effort()]}{Survey effort and detections: lines, points, and
#'     binning when there are too many of them to draw.}
#' }
#'
#' @section What it accepts:
#' Not one blessed type. [as_map_data()] takes \pkg{sf} polygons, points and
#' lines, a \pkg{terra} `SpatRaster`, or a plain data frame with coordinate
#' columns -- which is the form model output usually arrives in, since `mgcv`
#' and `dsm` want geometry dropped and a prediction rejoined afterwards.
#'
#' Values may sit on the object as a column, or be supplied separately and
#' joined by an identifier. The second case is not an afterthought: a posterior
#' summary comes out of an MCMC fit as a bare vector indexed by cell, and
#' requiring the caller to bind it on first is requiring them to get the row
#' order right silently.
#'
#' @section Projection:
#' Handled once. [display_crs()] settles what the map is drawn in -- the data's
#' own CRS when it is projected, and an appropriate UTM zone when it is
#' lon/lat -- and everything is reprojected to it before anything is drawn.
#' Area is computed in an equal-area projection from [equal_area_crs()], never
#' in the display one and never on lon/lat, where a degree of longitude is
#' 74 km in the Gulf of Maine and 111 at the equator.
#'
#' @section Land:
#' Drawn by default. [coastline()] resolves a source: a bundled fixture, a
#' user's own shapefile, or \pkg{rnaturalearth} at a resolution chosen for the
#' extent. If no source can be found the map still draws, but it says so --
#' in a warning and on the figure -- because a map with no coastline looks
#' deliberate, and a reader cannot tell an ocean model from a missing layer.
#'
#' @section House style:
#' [theme_fancymap()] is [fancyfx::theme_fancyfx()] with the axis furniture
#' removed, so a figure from this package and a figure from that one read as
#' one system. Colours come from scales that were chosen: see
#' `vignette("scales")` for why a square-root transform with automatic breaks
#' is not a scale, and what replaces it.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data %||%
## usethis namespace: end
NULL
