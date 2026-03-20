#' Create a ggplot2 Coefficient Plot from Placebo Test Results
#'
#' Produces a customizable ggplot2 coefficient plot for placebo test estimates
#' from the PanelMatch package. This is a convenience wrapper around
#' \code{\link{ggplot_panel_estimate}} with defaults tailored for placebo tests
#' (e.g., y-axis label set to \code{"Placebo estimate"}).
#'
#' All arguments are passed through to \code{ggplot_panel_estimate()}, so
#' the full range of customization (shapes, dodging, significance coding,
#' faceting, themes) is available.
#'
#' @param data A \code{ppm_placebo_tidy} data frame from
#'   \code{\link{pretty_placebo_test}}.
#' @param ylab Y-axis label. Default \code{"Placebo estimate"}.
#' @param ... Additional arguments passed to
#'   \code{\link{ggplot_panel_estimate}} (e.g., \code{shapes},
#'   \code{dodge_width}, \code{facet_by}, \code{theme_fn}).
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' # Toy example (runs without PanelMatch)
#' toy <- data.frame(
#'   term      = factor(paste0("t-", 3:1), levels = paste0("t-", 3:1), ordered = TRUE),
#'   estimate  = c(0.1, -0.05, 0.02),
#'   std.error = c(0.15, 0.12, 0.10),
#'   conf.low  = c(-0.19, -0.29, -0.18),
#'   conf.high = c(0.39, 0.19, 0.22),
#'   label     = factor("Model", ordered = TRUE),
#'   signif    = c("Non-signif", "Non-signif", "Non-signif"),
#'   stringsAsFactors = FALSE
#' )
#' class(toy) <- c("ppm_placebo_tidy", "data.frame")
#' gg_placebo_test(toy)
#'
#' @seealso \code{\link{pretty_placebo_test}} to prepare the input data,
#'   \code{\link{ggplot_panel_estimate}} for treatment effect plots.
#'
#' @export
gg_placebo_test <- function(data, ylab = "Placebo estimate", ...) {
  ggplot_panel_estimate(data, ylab = ylab, ...)
}


#' @rdname gg_placebo_test
#' @param object A \code{ppm_placebo_tidy} data frame.
#' @param ... Additional arguments passed to \code{gg_placebo_test}.
#' @export
autoplot.ppm_placebo_tidy <- function(object, ...) {
  gg_placebo_test(object, ...)
}
