#' Tidy placebo_test Results into a Data Frame
#'
#' Converts one or more \code{placebo_test()} results from the PanelMatch
#' package into a single tidy data frame suitable for ggplot2 plotting.
#'
#' @param ... One or more \code{placebo_test()} result objects. Can also be
#'   a single named list of results. Named arguments become model labels
#'   automatically.
#' @param labels A character vector of labels, one per result. If \code{NULL}
#'   and inputs are named, the names are used. Otherwise defaults to
#'   \code{"Model"} (single) or \code{"Model 1"}, \code{"Model 2"}, etc.
#' @param confidence_level Confidence level for constructing intervals.
#'   Default 0.95.
#'
#' @return A data frame (with class \code{"ppm_placebo_tidy"}) containing:
#'   \describe{
#'     \item{term}{Lag period label (e.g., "t-3", "t-2")}
#'     \item{estimate}{Point estimate}
#'     \item{std.error}{Standard error}
#'     \item{conf.low}{Lower confidence bound}
#'     \item{conf.high}{Upper confidence bound}
#'     \item{label}{Model label (ordered factor preserving input order)}
#'     \item{signif}{Whether the CI excludes zero ("Signif" or "Non-signif")}
#'   }
#'
#' @examples
#' \dontrun{
#' pt <- placebo_test(pm.sets, data = mydata, placebo.lead = 0,
#'                    number.iterations = 1000)
#' pretty_placebo_test(pt, labels = "My Model")
#'
#' # Multiple models (names become labels)
#' pretty_placebo_test(
#'   "Energy Dept." = pt_energy,
#'   "State Dept."  = pt_state
#' )
#'
#' # Custom confidence level
#' pretty_placebo_test(pt, confidence_level = 0.90)
#' }
#'
#' @seealso \code{\link{gg_placebo_test}} to plot the result,
#'   \code{\link{tidy_panel_estimate}} for treatment effect estimates,
#'   \code{\link{pretty_covariate_balance}} for covariate balance.
#'
#' @importFrom dplyr bind_rows
#' @export
pretty_placebo_test <- function(..., labels = NULL, confidence_level = 0.95) {

  args <- list(...)

  # If a single unnamed list was passed, decide: single result or list-of-results

  if (length(args) == 1 && is.list(args[[1]])) {
    inner <- args[[1]]
    if (!is.null(inner$estimates)) {
      # Single placebo_test result passed directly — keep as-is
    } else {
      # Named list of results — unpack
      args <- inner
    }
  }

  n <- length(args)

  # Resolve labels: explicit > names(...) > default
  if (is.null(labels)) {
    nms <- names(args)
    if (!is.null(nms) && all(nzchar(nms))) {
      labels <- nms
    } else if (n == 1) {
      labels <- "Model"
    } else {
      labels <- paste("Model", seq_len(n))
    }
  }

  if (length(labels) != n) {
    stop("`labels` must have the same length as the number of placebo_test results provided.",
         call. = FALSE)
  }

  z <- stats::qnorm(1 - (1 - confidence_level) / 2)

  frames <- lapply(seq_len(n), function(i) {
    .tidy_one_placebo(args[[i]], label = labels[i], z = z)
  })

  out <- dplyr::bind_rows(frames)
  out$label <- factor(out$label, levels = labels, ordered = TRUE)

  class(out) <- c("ppm_placebo_tidy", "data.frame")
  out
}


# Internal: tidy a single placebo_test result
.tidy_one_placebo <- function(pt, label, z) {

  est <- pt$estimates
  se  <- pt$standard.errors

  terms <- names(est)
  if (is.null(terms)) {
    n_periods <- length(est)
    terms <- paste0("t-", seq(n_periods + 1, 2))
  }

  out <- data.frame(
    term      = factor(terms, levels = terms, ordered = TRUE),
    estimate  = as.numeric(est),
    std.error = as.numeric(se),
    conf.low  = as.numeric(est - z * se),
    conf.high = as.numeric(est + z * se),
    label     = label,
    stringsAsFactors = FALSE
  )

  out$signif <- ifelse(out$conf.low > 0 | out$conf.high < 0,
                       "Signif", "Non-signif")
  out
}
