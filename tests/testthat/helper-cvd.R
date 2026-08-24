# Simulated colour vision deficiency, so that the palettes' claims are measured
# rather than asserted.
#
# Vienot, Brettel & Mollon (1999), "Digital video colourmaps for checking the
# legibility of displays by dichromats", Color Research & Application 24(4),
# 243-252. The matrices act on LINEAR RGB, so the gamma has to come off first
# and go back on afterwards -- skipping that is the usual way these checks come
# out wrong, because sRGB is roughly gamma 2.2 and the error is largest exactly
# where these ramps spend their time, in the mid tones.

srgb_to_linear <- function(u) ifelse(u <= 0.04045, u / 12.92,
                                     ((u + 0.055) / 1.055)^2.4)
linear_to_srgb <- function(u) ifelse(u <= 0.0031308, u * 12.92,
                                     1.055 * u^(1 / 2.4) - 0.055)

CVD_MATRICES <- list(
  protan = matrix(c(0.11238, 0.88762, 0,
                    0.11238, 0.88762, 0,
                    0.00401, -0.00401, 1), 3, 3, byrow = TRUE),
  deutan = matrix(c(0.29275, 0.70725, 0,
                    0.29275, 0.70725, 0,
                    -0.02234, 0.02234, 1), 3, 3, byrow = TRUE)
)

simulate_cvd <- function(hex, type = c("protan", "deutan", "normal")) {
  type <- match.arg(type)
  rgb <- t(grDevices::col2rgb(hex)) / 255
  if (identical(type, "normal")) return(hex)
  lin <- srgb_to_linear(rgb)
  out <- pmin(pmax(lin %*% t(CVD_MATRICES[[type]]), 0), 1)
  grDevices::rgb(linear_to_srgb(out[, 1]), linear_to_srgb(out[, 2]),
                 linear_to_srgb(out[, 3]))
}

# Relative luminance, which is what carries an ordering when hue does not.
luminance <- function(hex) {
  rgb <- srgb_to_linear(t(grDevices::col2rgb(hex)) / 255)
  as.vector(rgb %*% c(0.2126, 0.7152, 0.0722))
}

# Distance in linear RGB. Crude next to CIEDE2000, but monotone in the thing
# being asked about -- can these two be told apart -- and it brings no
# dependency into a test suite.
colour_distance <- function(a, b) {
  ra <- srgb_to_linear(t(grDevices::col2rgb(a)) / 255)
  rb <- srgb_to_linear(t(grDevices::col2rgb(b)) / 255)
  sqrt(rowSums((ra - rb)^2))
}
