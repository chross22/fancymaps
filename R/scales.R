## Scales that were chosen.
##
## The defect this file exists for: predicted density is extremely skewed -- a
## handful of cells carry most of the animals -- so a linear ramp is one bright
## dot on a dark field. The usual response is `trans = "sqrt"`, which is not a
## choice so much as the first thing that looked better, with automatic breaks
## nobody picked and a legend that never mentions the axis is not linear.
##
## Three things replace it.
##
## 1. The transform is SELECTED from the data by a stated rule, REPORTED when
##    it is selected, and named in the legend. A reader who sees breaks at
##    0.1  0.5  1  2 spaced evenly can tell the spacing is not linear only if
##    something says so.
## 2. The breaks are in ORIGINAL units and at round numbers -- 1, 2, 5 per
##    decade -- rather than at whatever round numbers exist in transformed
##    space, which are round in a space the reader is not in.
## 3. The limits come from a QUANTILE by default, with out-of-range values
##    squished rather than dropped, and the legend's top label marked so that
##    the squishing is visible. One extreme cell should not be allowed to
##    flatten everything else, and it should not be able to do it silently
##    either.
##
## The diverging case has its own version of the same problem. Its midpoint is
## an argument with a meaning -- zero for an extrapolation score, the survey
## mean for deviance residuals, which do not average zero -- and never the
## middle of the range. Centring residuals on zero paints every bin the same
## colour, which is a bug this design exists to make hard to write.

#' How a surface should be coloured
#'
#' Works out the transform, limits and breaks for a set of values, without
#' drawing anything. [map_surface()] calls it; call it directly to see what a
#' map is going to do before it does it, or to fix a scale across several
#' figures that would otherwise each choose their own.
#'
#' @param values The numbers to be coloured.
#' @param transform `"auto"` to choose by the rule below, or any transform name
#'   [ggplot2::continuous_scale()] accepts -- `"identity"`, `"log"`, `"sqrt"`.
#' @param limits `NULL` to take them from `probs`, or a length-2 vector to fix
#'   them.
#' @param probs The quantiles the limits are taken from. The default keeps the
#'   bottom of the range and cuts the top percentile, because that is the tail
#'   that flattens a skewed surface.
#'
#' @details
#' # Choosing a transform
#'
#' Only when `transform = "auto"`, and by one rule: the ratio of the 99th
#' percentile to the median. Below 10 the values are drawn linearly. At or
#' above 10 the top of the range is more than an order of magnitude above the
#' middle, a linear ramp spends most of its colours on values almost nothing
#' has, and the scale becomes logarithmic.
#'
#' A logarithmic scale cannot show a zero, and a density surface is full of
#' them. Rather than dropping those cells or adding 1 to everything -- which
#' means something different depending on whether the units are animals per
#' km2 or per m2 -- the transform is `log(x + offset)`, with `offset` set to
#' the 5th percentile of the positive values and reported. It is a real number
#' from the data with a stated provenance, not a constant that happens to make
#' the arithmetic work.
#'
#' Any automatic choice is reported with a message, because a default that
#' varies with the data is a default that has to be visible. It also means two
#' figures of different data can end up on different scales: when they must
#' match, fix `transform` and `limits`, or draw them with [map_panels()], which
#' does that for you.
#'
#' @return A list with `transform`, `limits`, `breaks`, `labels`, `squished`
#'   (whether anything falls outside `limits`) and `note` (the legend
#'   annotation, or `NULL`).
#'
#' @examples
#' skewed <- c(rep(0, 40), rexp(200, rate = 20))
#' surface_scale(skewed)
#'
#' # a quantity that does not need it
#' surface_scale(runif(100, 8, 12))
#'
#' @export
surface_scale <- function(values, transform = "auto", limits = NULL,
                          probs = c(0, 0.99)) {
  v <- values[is.finite(values)]
  if (!length(v)) {
    return(list(transform = "identity", limits = c(0, 1), breaks = ggplot2::waiver(),
                labels = ggplot2::waiver(), squished = FALSE, note = NULL))
  }

  offset <- NULL
  if (identical(transform, "auto")) {
    chosen <- choose_transform(v)
    transform <- chosen$transform
    offset <- chosen$offset
    if (!is.null(chosen$why)) message(chosen$why)
  } else if (identical(transform, "log") && any(v <= 0)) {
    # Asked for explicitly, but still impossible on the data as given. Offset
    # rather than refuse: the caller's intent is clear and the alternative is
    # a scale that silently discards every zero cell.
    offset <- log_offset(v)
    message("`transform = \"log\"` on data containing ",
            sum(v <= 0), " non-positive value(s): drawn as log(x + ",
            signif(offset, 2), "), the 5th percentile of the positive values.")
  }

  trans <- build_transform(transform, offset)
  limits <- limits %||% stats::quantile(v, probs, na.rm = TRUE, names = FALSE)
  limits <- sane_limits(limits, v)

  squished <- any(v > limits[2] + 1e-12) || any(v < limits[1] - 1e-12)
  breaks <- breaks_125(limits, transform, squished)

  list(
    transform = trans,
    limits = limits,
    breaks = breaks,
    # The top label carries the squish. A legend that stops at 2 when a cell
    # holds 40 is a lie of omission; ">= 2" is the same legend telling the
    # truth, and it costs two characters.
    labels = squish_labels(breaks, limits, squished),
    squished = squished,
    note = transform_note(transform, offset)
  )
}

# The rule. One number decides it, and the number is reported.
choose_transform <- function(v) {
  mid <- stats::median(v, na.rm = TRUE)
  top <- stats::quantile(v, 0.99, na.rm = TRUE, names = FALSE)

  # A median of zero means most cells hold nothing, which is itself the extreme
  # case of skew; compare against the median of the positive values so the
  # ratio stays finite and still describes the spread of what is there.
  base <- if (mid > 0) mid else stats::median(v[v > 0], na.rm = TRUE)
  if (!is.finite(base) || base <= 0 || !is.finite(top) || top <= 0) {
    return(list(transform = "identity", offset = NULL, why = NULL))
  }

  ratio <- top / base
  if (ratio < 10) {
    return(list(transform = "identity", offset = NULL, why = NULL))
  }

  offset <- if (any(v <= 0)) log_offset(v) else NULL
  list(
    transform = "log",
    offset = offset,
    why = paste0(
      "scale: log, chosen because the 99th percentile is ",
      signif(ratio, 2), " times the median",
      if (!is.null(offset)) {
        paste0(" (drawn as log(x + ", signif(offset, 2),
               "), since ", sum(v <= 0), " value(s) are not positive)")
      } else "",
      ".\n  Pass `transform =` to fix it, if two figures need to match."
    )
  )
}

log_offset <- function(v) {
  pos <- v[v > 0]
  if (!length(pos)) return(1)
  off <- stats::quantile(pos, 0.05, na.rm = TRUE, names = FALSE)
  if (!is.finite(off) || off <= 0) min(pos) else off
}

build_transform <- function(transform, offset) {
  if (is.null(offset)) return(transform)
  scales::new_transform(
    name = paste0("shifted-log-", signif(offset, 3)),
    transform = function(x) log(x + offset),
    inverse = function(x) exp(x) - offset,
    domain = c(-offset, Inf)
  )
}

transform_note <- function(transform, offset) {
  if (!is.character(transform)) return(NULL)
  switch(transform,
    identity = NULL,
    log = if (is.null(offset)) "log scale" else
      paste0("log scale, +", signif(offset, 2)),
    sqrt = "square-root scale",
    paste0(transform, " scale"))
}

# Breaks at 1, 2 and 5 per decade, which is what a reader recognises as round
# in the units they are actually looking at. On a linear scale, ggplot2's own
# breaks are already round in the right space, so they are left alone.
#
# When the top of the scale is a cap rather than a maximum, the cap itself is
# forced in as the last break. Without it the legend's top label is whichever
# round number fell below the cap -- 2, when the bar actually runs to 2.75 --
# and the "at least" marking has nothing to attach to.
breaks_125 <- function(limits, transform, squished = FALSE) {
  if (is.character(transform) && identical(transform, "identity")) {
    return(ggplot2::waiver())
  }
  lo <- max(limits[1], .Machine$double.eps)
  hi <- limits[2]
  if (!is.finite(hi) || hi <= lo) return(ggplot2::waiver())

  decades <- seq(floor(log10(lo)), ceiling(log10(hi)))
  candidates <- sort(as.vector(outer(c(1, 2, 5), 10^decades)))
  inside <- candidates[candidates >= lo & candidates <= hi]

  # Under about three breaks a legend stops being a scale and becomes two
  # labels, so fall back rather than draw a nearly-unlabelled bar.
  if (length(inside) < 3) return(ggplot2::waiver())
  # Four labels is the ceiling, set by the narrowest legend this package ever
  # draws: a horizontal bar under one panel of a pair. A log scale's labels are
  # long -- "0.0005" -- and five of them across two inches overlap.
  #
  # The cap counts as one of the four, and it is reserved BEFORE the thinning
  # rather than appended after, or a capped scale ends up with five.
  room <- if (squished) 3L else 4L

  if (squished) {
    # A round break too close to the cap collides with its label however the
    # bar is sized -- they are a third of a decade apart and the labels are
    # taller than that. The cap wins, because it is the one carrying the
    # "at least".
    inside <- inside[inside < hi / 10^0.3]
  }
  if (length(inside) > room) {
    inside <- unique(inside[round(seq(1, length(inside), length.out = room))])
  }
  if (squished) inside <- c(inside, hi)

  inside
}

# Labels are always supplied, never left to ggplot2.
#
# Two reasons. The default labeller drops into scientific notation on a log
# scale -- "5e-04" where the reader wants "0.0005", which is the same number in
# a form nobody reads off a map -- and the top label has to be able to say the
# scale is capped.
squish_labels <- function(breaks, limits, squished) {
  function(x) {
    # Rounded before formatting. A forced cap break lands on whatever the
    # quantile happened to be -- 2.749269 -- and a legend that reports six
    # significant figures of a number that was chosen as "the 99th percentile"
    # is claiming a precision the choice never had.
    lab <- format(signif(x, 3), scientific = FALSE, trim = TRUE,
                  drop0trailing = TRUE, big.mark = ",")
    if (!squished) return(lab)
    at_top <- !is.na(x) & abs(x - limits[2]) < 1e-9 * max(1, abs(limits[2]))
    lab[at_top] <- paste0("\u2265 ", lab[at_top])
    lab
  }
}

# A degenerate range -- every cell identical, or a quantile pair that collapsed
# -- makes ggplot2 draw a legend with one colour and no ticks. Widen it around
# the value instead, so the map still says what the value is.
sane_limits <- function(limits, v) {
  limits <- range(limits, na.rm = TRUE)
  if (!all(is.finite(limits))) limits <- range(v, na.rm = TRUE)
  if (diff(limits) > 0) return(limits)
  pad <- max(abs(limits[1]) * 0.05, 1e-9)
  limits + c(-pad, pad)
}

#' How a diverging surface should be coloured
#'
#' @param values The numbers to be coloured.
#' @param midpoint The value the ramp's neutral colour sits at. **Required**,
#'   and deliberately so -- see below.
#' @param limits `NULL` for symmetric limits about `midpoint` taken from
#'   `probs`, or a length-2 vector to fix them.
#' @param probs The quantile pair the limits are taken from, before being made
#'   symmetric.
#'
#' @details
#' `midpoint` has no default because there is no correct one. It is not the
#' middle of the range, which is what [ggplot2::scale_fill_gradient2()] falls
#' back to and what makes a diverging map meaningless: an extrapolation score
#' diverges around **zero**, because zero is where inside the training range
#' becomes outside it, and deviance residuals diverge around **their own
#' mean**, because they do not average zero and centring them on zero paints
#' every bin the same colour.
#'
#' Limits are made symmetric about the midpoint, so that equal distances either
#' side get equal colour weight. An asymmetric diverging scale makes a
#' difference of +1 look bigger or smaller than a difference of -1, which is
#' the one thing the ramp is there to prevent.
#'
#' @return A list with `limits`, `midpoint`, `rescaler`, `squished` and `note`.
#'
#' @examples
#' mess <- c(rnorm(200, 5, 3), rnorm(10, -20, 5))
#'
#' # zero is the meaning here
#' diverging_scale(mess, midpoint = 0)
#'
#' # residuals diverge around their own mean
#' diverging_scale(mess, midpoint = mean(mess))
#'
#' @export
diverging_scale <- function(values, midpoint, limits = NULL,
                            probs = c(0.01, 0.99)) {
  if (missing(midpoint) || is.null(midpoint) || !is.finite(midpoint)) {
    stop("`midpoint` is required, and it has no sensible default.\n",
         "  Zero for an extrapolation score, where zero is where the training ",
         "range ends.\n  mean(values) for deviance residuals, which do not ",
         "average zero -- centring those on zero colours every cell the same.",
         call. = FALSE)
  }

  v <- values[is.finite(values)]
  if (!length(v)) {
    return(list(limits = midpoint + c(-1, 1), midpoint = midpoint,
                squished = FALSE, note = NULL))
  }

  if (is.null(limits)) {
    q <- stats::quantile(v, probs, na.rm = TRUE, names = FALSE)
    reach <- max(abs(q - midpoint), na.rm = TRUE)
    if (!is.finite(reach) || reach <= 0) reach <- max(abs(v - midpoint), 1e-9)
    limits <- midpoint + c(-reach, reach)
  } else {
    reach <- max(abs(limits - midpoint))
    limits <- midpoint + c(-reach, reach)
  }

  squished <- any(v > limits[2] + 1e-12) || any(v < limits[1] - 1e-12)
  list(
    limits = limits,
    midpoint = midpoint,
    squished = squished,
    note = if (abs(midpoint) > 1e-12) {
      paste0("centred on ", signif(midpoint, 3))
    } else NULL
  )
}
