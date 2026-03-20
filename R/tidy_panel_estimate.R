#' Tidy PanelEstimate Summaries into a Data Frame
#'
#' Converts one or more \code{summary(PanelEstimate(...))} objects into a
#' single tidy data frame suitable for ggplot2 plotting.
#'
#' @param ... One or more PanelEstimate summary objects (or raw PanelEstimate
#'   objects, which will be summarized automatically). Can also be a single
#'   named list of summaries.
#' @param labels A character vector of labels, one per summary. Used to
#'   distinguish models in the plot legend. If \code{NULL} and inputs are
#'   named (either as named arguments or a named list), the names are used.
#'   Otherwise defaults to \code{"Model 1"}, \code{"Model 2"}, etc.
#'
#' @return A data frame (with class \code{"ppm_tidy"}) containing columns:
#'   \describe{
#'     \item{term}{Lead period label (e.g., "t+0", "t+1", ...)}
#'     \item{estimate}{Point estimate (ATT)}
#'     \item{std.error}{Standard error}
#'     \item{conf.low}{Lower confidence bound}
#'     \item{conf.high}{Upper confidence bound}
#'     \item{label}{Model label (ordered factor preserving input order)}
#'     \item{signif}{Whether the CI excludes zero ("Signif" or "Non-signif")}
#'   }
#'
#' @examples
#' # Create a mock PanelEstimate summary (matrix with 4 columns)
#' pe_sum <- matrix(
#'   c(0.5, 0.2, 0.1, 0.9,
#'     0.8, 0.3, 0.2, 1.4,
#'     1.2, 0.25, 0.7, 1.7),
#'   nrow = 3, byrow = TRUE,
#'   dimnames = list(NULL, c("Estimate", "Std.Error", "lower", "upper"))
#' )
#' tidy_panel_estimate(pe_sum, labels = "My Model")
#'
#' # Multiple models with named arguments
#' pe_sum2 <- matrix(
#'   c(0.3, 0.15, 0.0, 0.6,
#'     0.6, 0.20, 0.2, 1.0,
#'     0.9, 0.18, 0.5, 1.3),
#'   nrow = 3, byrow = TRUE,
#'   dimnames = list(NULL, c("Estimate", "Std.Error", "lower", "upper"))
#' )
#' tidy_panel_estimate("Model A" = pe_sum, "Model B" = pe_sum2)
#'
#' @seealso \code{\link{ggplot_panel_estimate}} to plot the result,
#'   \code{\link{pretty_placebo_test}} for placebo test results,
#'   \code{\link{pretty_covariate_balance}} for covariate balance.
#'
#' @importFrom dplyr bind_rows
#' @export
tidy_panel_estimate <- function(..., labels = NULL) {

  args <- list(...)

  # If a single unnamed list was passed, unpack it
  if (length(args) == 1 && is.list(args[[1]]) && !is.data.frame(args[[1]])
      && !inherits(args[[1]], "PanelEstimate")) {
    args <- args[[1]]
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
    stop("`labels` must have the same length as the number of summaries provided.",
         call. = FALSE)
  }

  # Tidy each summary
  frames <- lapply(seq_len(n), function(i) {
    .tidy_one(args[[i]], label = labels[i])
  })

  out <- dplyr::bind_rows(frames)
  out$label <- factor(out$label, levels = labels, ordered = TRUE)

  class(out) <- c("ppm_tidy", "data.frame")
  out
}


# Internal: tidy a single summary object
.tidy_one <- function(pe_summary, label) {

  if (inherits(pe_summary, "PanelEstimate")) {
    pe_summary <- summary(pe_summary)
  }

  mat <- as.matrix(pe_summary)
  n_leads <- nrow(mat)
  terms <- paste0("t+", seq(0, n_leads - 1))

  out <- data.frame(
    term      = factor(terms, levels = terms, ordered = TRUE),
    estimate  = as.numeric(mat[, 1]),
    std.error = as.numeric(mat[, 2]),
    conf.low  = as.numeric(mat[, 3]),
    conf.high = as.numeric(mat[, 4]),
    label     = label,
    stringsAsFactors = FALSE
  )

  out$signif <- ifelse(out$conf.low > 0 | out$conf.high < 0,
                       "Signif", "Non-signif")
  out
}
