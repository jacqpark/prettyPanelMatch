#' Tidy Covariate Balance Matrices into a Data Frame
#'
#' Converts \code{get_covariate_balance()} matrices from the PanelMatch package
#' into a single tidy data frame suitable for ggplot2 plotting.
#'
#' Each named argument should be a list of 1--3 matrices (one per matching
#' stage, e.g., before matching, after matching pre-refinement,
#' post-refinement). The argument names become model/row facet labels.
#'
#' @param ... Named arguments where each value is a list of matrices from
#'   \code{get_covariate_balance()}, one per matching stage. Names become
#'   model labels (row facet labels). A single matrix can be passed directly
#'   instead of wrapping in a list.
#' @param stage_labels Character vector naming the matching stages, in order.
#'   Must be at least as long as the longest list of matrices provided.
#'   Default: \code{c("Before matching", "Matched, pre-refinement",
#'   "Post-refinement")}.
#' @param dv Character vector of variable names that are dependent variables.
#'   These are styled differently (black solid lines) in the plot. Variables
#'   not listed here are treated as covariates (grey, varied linetypes).
#'
#' @return A data frame (with class \code{"ppm_cov_tidy"}) containing:
#'   \describe{
#'     \item{model}{Model label (ordered factor, row facet)}
#'     \item{stage}{Matching stage label (ordered factor, column facet)}
#'     \item{time}{Pre-treatment period label (ordered factor, e.g., "t-3")}
#'     \item{variable}{Covariate or DV name (ordered factor)}
#'     \item{estimate}{Standardized mean difference}
#'     \item{is_dv}{Logical; \code{TRUE} for dependent variables}
#'   }
#'
#' @examples
#' # Create a mock covariate balance matrix (rows = time, cols = variables)
#' mat <- matrix(
#'   c(0.3, -0.1, 0.5, 0.2, 0.8, 0.1),
#'   nrow = 3,
#'   dimnames = list(NULL, c("outcome", "covar1"))
#' )
#' pretty_covariate_balance(
#'   "My Model" = mat,
#'   stage_labels = "Before matching",
#'   dv = "outcome"
#' )
#'
#' @seealso \code{\link{gg_covariate_balance}} to plot the result,
#'   \code{\link{tidy_panel_estimate}} for treatment effect estimates,
#'   \code{\link{pretty_placebo_test}} for placebo test results.
#'
#' @export
pretty_covariate_balance <- function(...,
                                   stage_labels = c("Before matching",
                                                    "Matched, pre-refinement",
                                                    "Post-refinement"),
                                   dv = NULL) {

  args <- list(...)

  # If a single unnamed list of lists was passed, unpack it
  if (length(args) == 1 && is.list(args[[1]]) && !is.matrix(args[[1]])) {
    inner <- args[[1]]
    if (!is.null(names(inner)) && all(nzchar(names(inner)))) {
      args <- inner
    }
  }

  model_names <- names(args)
  if (is.null(model_names) || any(!nzchar(model_names))) {
    stop("All arguments must be named. Names become model labels (row facets).",
         call. = FALSE)
  }

  frames <- list()

  for (i in seq_along(args)) {
    stages <- args[[i]]
    if (is.matrix(stages)) stages <- list(stages)
    n_stages <- length(stages)

    if (n_stages > length(stage_labels)) {
      stop("Model '", model_names[i], "' has ", n_stages,
           " matrices but only ", length(stage_labels),
           " stage_labels provided.", call. = FALSE)
    }

    for (j in seq_len(n_stages)) {
      mat <- stages[[j]]
      n_periods <- nrow(mat)
      time_labels <- paste0("t-", seq(n_periods, 1))

      long <- .pivot_balance_matrix(mat, time_labels)
      long$model <- model_names[i]
      long$stage <- stage_labels[j]
      frames <- c(frames, list(long))
    }
  }

  out <- do.call(rbind, frames)
  rownames(out) <- NULL

  # Factor ordering
  out$model <- factor(out$model, levels = model_names, ordered = TRUE)
  out$stage <- factor(out$stage, levels = stage_labels[seq_len(
    max(vapply(args, function(x) {
      if (is.matrix(x)) 1L else length(x)
    }, integer(1)))
  )], ordered = TRUE)

  # Time ordering: t-N ... t-1 (increasing toward treatment)
  all_times <- unique(out$time)
  nums <- as.numeric(gsub("t-", "-", all_times))
  time_order <- all_times[order(nums)]
  out$time <- factor(out$time, levels = time_order, ordered = TRUE)

  # Preserve variable order from data (DVs first, then covariates)
  all_vars <- unique(out$variable)
  if (!is.null(dv)) {
    dv_found <- all_vars[all_vars %in% dv]
    cov_found <- all_vars[!all_vars %in% dv]
    var_order <- c(dv_found, cov_found)
  } else {
    var_order <- all_vars
  }
  out$variable <- factor(out$variable, levels = var_order, ordered = TRUE)

  out$is_dv <- if (!is.null(dv)) out$variable %in% dv else FALSE

  class(out) <- c("ppm_cov_tidy", "data.frame")
  out
}


# Internal: pivot a covariate balance matrix to long format (no tidyr needed)
.pivot_balance_matrix <- function(mat, time_labels) {
  vars <- colnames(mat)
  rows <- lapply(seq_along(vars), function(j) {
    data.frame(
      time     = time_labels,
      variable = vars[j],
      estimate = as.numeric(mat[, j]),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
