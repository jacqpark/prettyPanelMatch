#' @keywords internal
"_PACKAGE"

#' prettyPanelMatch: ggplot2-Based Visualization for PanelMatch Results
#'
#' Provides tidy-and-plot function pairs for three types of PanelMatch output:
#' treatment effect estimates, placebo test estimates, and covariate balance
#' diagnostics. All plotting functions return standard \code{ggplot} objects
#' that can be extended with additional ggplot2 layers.
#'
#' @section Panel Estimate functions:
#' \describe{
#'   \item{\code{\link{tidy_panel_estimate}}}{Convert one or more
#'     \code{PanelEstimate} summaries to a tidy data frame}
#'   \item{\code{\link{ggplot_panel_estimate}}}{Create a coefficient plot
#'     with significance-coded shapes}
#' }
#'
#' @section Placebo Test functions:
#' \describe{
#'   \item{\code{\link{pretty_placebo_test}}}{Convert one or more
#'     \code{placebo_test()} results to a tidy data frame}
#'   \item{\code{\link{gg_placebo_test}}}{Create a coefficient plot for
#'     placebo test estimates}
#' }
#'
#' @section Covariate Balance functions:
#' \describe{
#'   \item{\code{\link{pretty_covariate_balance}}}{Convert
#'     \code{get_covariate_balance()} matrices to a tidy data frame}
#'   \item{\code{\link{gg_covariate_balance}}}{Create a faceted balance plot
#'     (models as rows, matching stages as columns)}
#' }
#'
#' @name prettyPanelMatch-package
NULL
