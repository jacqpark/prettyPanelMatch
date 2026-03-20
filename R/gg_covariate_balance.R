#' Create a ggplot2 Covariate Balance Plot
#'
#' Produces a faceted covariate balance plot showing standardized mean
#' differences across matching stages. Dependent variables are drawn as
#' black solid lines; covariates as grey lines with distinct linetypes.
#'
#' The default layout uses \code{facet_grid(model ~ stage)}, where models
#' (different DVs / subsamples) form the rows and matching stages form the
#' columns, reproducing the standard PanelMatch covariate-balance diagnostic.
#'
#' @param data A \code{ppm_cov_tidy} data frame from
#'   \code{\link{pretty_covariate_balance}}.
#' @param dv_color Color for DV lines. Default \code{"black"}.
#' @param cov_color Color for covariate lines. Default \code{"grey70"}.
#' @param dv_linetype Linetype for DV lines. Default \code{"solid"}.
#' @param cov_linetypes Character vector of linetypes for covariates. If
#'   \code{NULL} (default), cycles through \code{"dashed"}, \code{"twodash"},
#'   \code{"dotted"}, \code{"dotdash"}, \code{"longdash"}.
#' @param hline Y-intercept for reference line. Default 0. Set to \code{NULL}
#'   to remove.
#' @param ylim Y-axis limits as a length-2 numeric vector. Default
#'   \code{c(-2, 2)}. Set to \code{NULL} for automatic limits.
#' @param xlab X-axis label. Default \code{"Time"}.
#' @param ylab Y-axis label. Default \code{"SD"}.
#' @param title Optional plot title.
#' @param subtitle Optional plot subtitle.
#' @param show_legend Logical. Show legend? Default \code{FALSE}.
#' @param strip_text_y_size Font size for row strip labels. Default 8.5.
#'   Set to \code{NULL} to use the theme default.
#' @param theme_fn A ggplot2 theme function. Default \code{theme_bw}.
#'
#' @return A \code{ggplot} object that can be further customized with
#'   standard ggplot2 syntax.
#'
#' @examples
#' # Toy example (runs without PanelMatch)
#' toy <- data.frame(
#'   model    = factor("Model A", ordered = TRUE),
#'   stage    = factor("Before matching", ordered = TRUE),
#'   time     = factor(rep(paste0("t-", 3:1), 2),
#'                     levels = paste0("t-", 3:1), ordered = TRUE),
#'   variable = factor(rep(c("outcome", "covar1"), each = 3), ordered = TRUE),
#'   estimate = c(0.3, 0.5, 0.8, -0.1, 0.2, 0.1),
#'   is_dv    = rep(c(TRUE, FALSE), each = 3),
#'   stringsAsFactors = FALSE
#' )
#' class(toy) <- c("ppm_cov_tidy", "data.frame")
#' gg_covariate_balance(toy)
#'
#' @seealso \code{\link{pretty_covariate_balance}} to prepare the input data,
#'   \code{\link{ggplot_panel_estimate}} for treatment effect plots,
#'   \code{\link{gg_placebo_test}} for placebo test plots.
#'
#' @importFrom ggplot2 geom_line scale_color_manual scale_linetype_manual
#'   facet_grid coord_cartesian vars
#' @importFrom rlang .data
#' @export
gg_covariate_balance <- function(data,
                                     dv_color = "black",
                                     cov_color = "grey70",
                                     dv_linetype = "solid",
                                     cov_linetypes = NULL,
                                     hline = 0,
                                     ylim = c(-2, 2),
                                     xlab = "Time",
                                     ylab = "SD",
                                     title = NULL,
                                     subtitle = NULL,
                                     show_legend = FALSE,
                                     strip_text_y_size = 8.5,
                                     theme_fn = ggplot2::theme_bw) {

  vars_all <- levels(data$variable)
  if (is.null(vars_all)) vars_all <- unique(as.character(data$variable))

  dv_vars  <- vars_all[vars_all %in% unique(as.character(data$variable[data$is_dv]))]
  cov_vars <- vars_all[!vars_all %in% dv_vars]

  # Resolve covariate linetypes
  default_cov_lty <- c("dashed", "twodash", "dotted", "dotdash", "longdash")
  if (is.null(cov_linetypes)) {
    cov_linetypes <- default_cov_lty[
      ((seq_along(cov_vars) - 1) %% length(default_cov_lty)) + 1
    ]
  }
  if (length(cov_linetypes) < length(cov_vars)) {
    cov_linetypes <- rep_len(cov_linetypes, length(cov_vars))
  }

  # Build named color and linetype maps
  color_map <- stats::setNames(
    c(rep(dv_color, length(dv_vars)), rep(cov_color, length(cov_vars))),
    c(dv_vars, cov_vars)
  )
  lty_map <- stats::setNames(
    c(rep(dv_linetype, length(dv_vars)), cov_linetypes),
    c(dv_vars, cov_vars)
  )

  p <- ggplot2::ggplot(data, ggplot2::aes(
    x        = .data$time,
    y        = .data$estimate,
    group    = .data$variable,
    color    = .data$variable,
    linetype = .data$variable
  )) +
    ggplot2::geom_line() +
    ggplot2::scale_color_manual(values = color_map) +
    ggplot2::scale_linetype_manual(values = lty_map)

  # Reference line
  if (!is.null(hline)) {
    p <- p + ggplot2::geom_hline(
      yintercept = hline, lty = "dashed", linewidth = 0.5, color = "grey90"
    )
  }

  # Y-axis limits
  if (!is.null(ylim)) {
    p <- p + ggplot2::coord_cartesian(ylim = ylim)
  }

  # Labels
  p <- p + ggplot2::labs(
    x = xlab, y = ylab, title = title, subtitle = subtitle,
    color = NULL, linetype = NULL
  )

  # Theme
  p <- p + theme_fn() +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )

  # Strip text sizing
  if (!is.null(strip_text_y_size)) {
    p <- p + ggplot2::theme(
      strip.text.y = ggplot2::element_text(size = strip_text_y_size)
    )
  }

  # Legend
  if (!show_legend) {
    p <- p + ggplot2::theme(legend.position = "none")
  }

  # Faceting: models as rows, stages as columns
  p <- p + ggplot2::facet_grid(model ~ stage)

  p
}


#' @rdname gg_covariate_balance
#' @param object A \code{ppm_cov_tidy} data frame.
#' @param ... Additional arguments passed to \code{gg_covariate_balance}.
#' @export
autoplot.ppm_cov_tidy <- function(object, ...) {
  gg_covariate_balance(object, ...)
}
