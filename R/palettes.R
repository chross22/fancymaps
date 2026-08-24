## The colour ramps.
##
## Written out as hex rather than pulled from a palette package, for the same
## reason `fancyfx_palette()` is: a palette is a decision, and a decision
## should be visible in a diff and checkable by a test. `tests/testthat/
## test-palettes.R` simulates protanopia and deuteranopia over each ramp and
## asserts the properties below, so these are measured claims rather than
## inherited assurances.
##
## SEQUENTIAL is viridis (Smith & van der Walt, CC0). Chosen because its
## defining property is the one a surface map needs: lightness increases
## monotonically along it, so the ordering of the data survives being read by
## someone with any of the common colour vision deficiencies, and survives
## being printed in greyscale. Eight stops rather than the full 256: enough for
## a smooth ramp, few enough to read.
##
## DIVERGING is a blue-to-orange ramp through a light neutral. Blue against
## orange rather than the more usual blue against red because red-green
## confusion is the common deficiency and a red arm collapses toward the
## neutral middle under deuteranopia -- which is exactly the failure that
## matters here, since the whole job of a diverging ramp is to make "which side
## of the centre" legible. The two arms are matched for lightness so that
## neither reads as more extreme than the other at equal distance from the
## centre, and the middle is light grey rather than white so that a cell at the
## centre is still visibly a cell.

#' The colour ramps these maps use
#'
#' @param type Which ramp: `"sequential"` for a quantity that only increases,
#'   `"diverging"` for one with a meaningful centre, `"bounded"` for a
#'   proportion or probability.
#' @param n How many stops to return. The stops are interpolated, so any `n`
#'   works; the default returns the ramp as it is defined.
#'
#' @details
#' `"bounded"` is a distinct ramp rather than an alias for `"sequential"`
#' because a probability has two meaningful ends rather than one. Viridis puts
#' its most saturated colour at the top, which is right when the top is
#' "highest observed" and misleading when it is "certain": on an occupancy map
#' a cell at 0.02 and a cell at 0.0 should look nearly the same, and the ramp
#' should reach full weight only as it approaches 1.
#'
#' @return A character vector of hex colours.
#'
#' @examples
#' fancymap_palette("sequential")
#' fancymap_palette("diverging", 5)
#'
#' @export
fancymap_palette <- function(type = c("sequential", "diverging", "bounded"),
                             n = NULL) {
  type <- match.arg(type)
  pal <- switch(
    type,
    sequential = c("#440154", "#46337E", "#365C8D", "#277F8E",
                   "#1FA187", "#4AC16D", "#A0DA39", "#FDE725"),
    diverging  = c("#1B4F72", "#2E86AB", "#8CBEDB", "#E8E8E8",
                   "#F2B36B", "#D2761E", "#8A4404"),
    bounded    = c("#F7F7F4", "#CFE3DF", "#94C7C6", "#4FA3AE",
                   "#2A7391", "#1F4468")
  )
  if (is.null(n)) return(pal)
  grDevices::colorRampPalette(pal)(n)
}
