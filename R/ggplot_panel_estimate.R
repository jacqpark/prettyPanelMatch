#' Create a ggplot2 Coefficient Plot from PanelEstimate Results
#'
#' Produces a customizable ggplot2 coefficient plot showing point estimates
#' and confidence intervals across lead periods. Supports multiple models
#' with dodged positions and significance-based shape coding (hollow = not
#' significant, filled = significant). A footnote is added by default.
#'
#' The returned object is a standard \code{ggplot} object, so you can add
#' any ggplot2 layers, scales, or themes on top of it.
#'
#' @param data A \code{ppm_tidy} data frame from \code{\link{tidy_panel_estimate}}.
#' @param dodge_width Width of position dodge for multiple models. Default 0.5.
#' @param point_size Size of point estimates. Default 2.2.
#' @param errorbar_alpha Alpha transparency for error bars. Default 0.5.
#' @param errorbar_width Width of error bar caps. Default 0 (no caps).
#' @param shapes A character vector of hollow shape names, one per model.
#'   Filled counterparts are paired automatically. If \code{NULL} (default),
#'   shapes cycle through: \code{"circle"}, \code{"diamond"}, \code{"triangle"},
#'   \code{"square"}, \code{"triangle_down"}.
#'   Available names: \code{"circle"}, \code{"square"}, \code{"triangle"},
#'   \code{"diamond"}, \code{"triangle_down"}. Numeric codes (0-14) are also
#'   accepted for advanced users.
#' @param show_signif_shapes Logical. If \code{TRUE} (default), uses different
#'   shapes for significant vs. non-significant estimates. If \code{FALSE},
#'   uses uniform shapes per model.
#' @param legend_labels Optional character vector to override legend labels
#'   (one per model, in input order).
#' @param footnote Character string for the significance footnote. Set to
#'   \code{NULL} to suppress. Default explains hollow vs. filled convention.
#' @param footnote_size Font size for the footnote. Default \code{NULL},
#'   which matches the axis title size from the active theme.
#' @param xlab X-axis label. Default \code{"Time"}.
#' @param ylab Y-axis label. Default \code{"ATT"}.
#' @param title Optional plot title.
#' @param subtitle Optional plot subtitle.
#' @param hline Intercept for reference line. Default 0. Set to \code{NULL}
#'   to remove.
#' @param facet_by Optional variable name to facet by (e.g., \code{"label"}).
#'   Default \code{NULL} (no faceting).
#' @param theme_fn A ggplot2 theme function. Default \code{theme_minimal}.
#'
#' @return A \code{ggplot} object that can be further customized with
#'   standard ggplot2 syntax.
#'
#' @examples
#' \dontrun{
#' # Single model
#' tidy_panel_estimate(summary(pe1), labels = "My Model") |>
#'   ggplot_panel_estimate()
#'
#' # Multiple models with custom hollow shapes
#' combined <- tidy_panel_estimate(
#'   "Energy Dept." = summary(pe1[[1]]),
#'   "State Dept."  = summary(pe2[[1]]),
#'   "Congress"     = summary(pe3[[1]]),
#'   "EOP"          = summary(pe4[[1]])
#' )
#' ggplot_panel_estimate(combined, shapes = c("circle", "diamond", "triangle", "square"))
#'
#' # Suppress footnote
#' ggplot_panel_estimate(combined, footnote = NULL)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_point geom_errorbar geom_hline labs
#'   theme_minimal position_dodge scale_shape_manual facet_wrap autoplot
#' @importFrom rlang .data
#' @export
ggplot_panel_estimate <- function(data,
                                  dodge_width = 0.5,
                                  point_size = 2.2,
                                  errorbar_alpha = 0.5,
                                  errorbar_width = 0,
                                  shapes = NULL,
                                  show_signif_shapes = TRUE,
                                  legend_labels = NULL,
                                  footnote = "Filled markers denote statistical significance (CI excludes zero).",
                                  footnote_size = NULL,
                                  xlab = "Time",
                                  ylab = "ATT",
                                  title = NULL,
                                  subtitle = NULL,
                                  hline = 0,
                                  facet_by = NULL,
                                  theme_fn = ggplot2::theme_minimal) {

  labels_in_data <- levels(data$label)
  if (is.null(labels_in_data)) {
    labels_in_data <- unique(data$label)
  }
  n_labels <- length(labels_in_data)

  pos <- ggplot2::position_dodge(width = dodge_width)

  # Resolve hollow shapes (user-supplied names/numbers or default)
  if (is.null(shapes)) {
    default_names <- c("circle", "diamond", "triangle", "square", "triangle_down")
    shapes <- default_names[((seq_len(n_labels) - 1) %% length(default_names)) + 1]
  }
  if (length(shapes) != n_labels) {
    stop("`shapes` must have one value per model (", n_labels, " needed).",
         call. = FALSE)
  }
  # Convert names to numeric codes
  shapes <- vapply(shapes, .resolve_shape, integer(1), USE.NAMES = FALSE)

  if (show_signif_shapes && n_labels > 1) {

    # Build shape mapping: hollow for non-signif, filled pair for signif
    shape_map <- .build_shape_map(labels_in_data, shapes)

    data$shape_var <- interaction(data$signif, data$label, sep = ".")

    # Legend: show only hollow (non-signif) shapes as model labels
    legend_breaks <- paste0("Non-signif.", labels_in_data)
    if (is.null(legend_labels)) {
      legend_labels <- stats::setNames(labels_in_data, legend_breaks)
    } else {
      legend_labels <- stats::setNames(legend_labels, legend_breaks)
    }

    p <- ggplot2::ggplot(data, ggplot2::aes(
      x = .data$term,
      y = .data$estimate,
      group = .data$label,
      shape = .data$shape_var
    )) +
      ggplot2::geom_point(position = pos, size = point_size) +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high),
        width = errorbar_width, position = pos, alpha = errorbar_alpha
      ) +
      ggplot2::scale_shape_manual(
        values = shape_map,
        breaks = legend_breaks,
        labels = legend_labels
      )

  } else if (show_signif_shapes && n_labels == 1) {

    # Single model: use the first hollow shape and its filled pair
    hollow <- shapes[1]
    filled <- .hollow_to_filled(hollow)

    p <- ggplot2::ggplot(data, ggplot2::aes(
      x = .data$term,
      y = .data$estimate,
      group = .data$label,
      shape = .data$signif
    )) +
      ggplot2::geom_point(position = pos, size = point_size) +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high),
        width = errorbar_width, position = pos, alpha = errorbar_alpha
      ) +
      ggplot2::scale_shape_manual(
        values = c("Signif" = filled, "Non-signif" = hollow)
      ) +
      ggplot2::guides(shape = "none")

  } else {

    # No significance distinction
    p <- ggplot2::ggplot(data, ggplot2::aes(
      x = .data$term,
      y = .data$estimate,
      group = .data$label,
      shape = .data$label
    )) +
      ggplot2::geom_point(position = pos, size = point_size) +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high),
        width = errorbar_width, position = pos, alpha = errorbar_alpha
      )
  }

  # Reference line
  if (!is.null(hline)) {
    p <- p + ggplot2::geom_hline(
      yintercept = hline, lty = "dashed", color = "grey"
    )
  }

  # Labels
  p <- p + ggplot2::labs(
    x = xlab, y = ylab, title = title, subtitle = subtitle, shape = NULL
  )

  # Theme
  p <- p + theme_fn()

  # Footnote — defaults to same size as axis title text
  if (!is.null(footnote) && show_signif_shapes) {
    # Resolve footnote size: use explicit value, or inherit from axis.title
    if (is.null(footnote_size)) {
      resolved_theme <- theme_fn()
      axis_title <- resolved_theme$axis.title
      if (is.null(axis_title)) axis_title <- ggplot2::theme_get()$axis.title
      if (inherits(axis_title, "element_text") && !is.null(axis_title$size)) {
        footnote_size <- axis_title$size
      } else {
        footnote_size <- 11  # ggplot2 default axis title size
      }
    }
    p <- p + ggplot2::labs(caption = footnote) +
      ggplot2::theme(plot.caption = ggplot2::element_text(
        size = footnote_size, hjust = 0, color = "grey40"
      ))
  }

  # Faceting
  if (!is.null(facet_by)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", facet_by)))
  }

  p
}


#' @rdname ggplot_panel_estimate
#' @param object A \code{ppm_tidy} data frame.
#' @param ... Additional arguments passed to \code{ggplot_panel_estimate}.
#' @export
autoplot.ppm_tidy <- function(object, ...) {
  ggplot_panel_estimate(object, ...)
}


# --- Internal helpers ---

# Name-to-code lookup: friendly name -> hollow ggplot2 shape code
.SHAPE_NAMES <- c(
  "circle"        = 1L,
  "square"        = 0L,
  "triangle"      = 2L,
  "diamond"       = 5L,
  "triangle_down" = 6L
)

# Hollow-to-filled pairing (ggplot2 shape codes)
.HOLLOW_TO_FILLED <- c(
  "0"  = 15L,  # square
  "1"  = 19L,  # circle
  "2"  = 17L,  # triangle up
  "5"  = 18L,  # diamond
  "6"  = 25L   # triangle down
)

# Resolve a shape input (name or number) to a hollow numeric code
.resolve_shape <- function(s) {
  if (is.character(s)) {
    s_lower <- tolower(trimws(s))
    if (s_lower %in% names(.SHAPE_NAMES)) {
      return(.SHAPE_NAMES[[s_lower]])
    }
    # Try parsing as numeric string
    num <- suppressWarnings(as.integer(s))
    if (!is.na(num)) return(num)
    valid <- paste(names(.SHAPE_NAMES), collapse = ", ")
    stop("Unknown shape name '", s, "'. Available: ", valid, call. = FALSE)
  }
  as.integer(s)
}

# Get the filled counterpart for a hollow shape code
.hollow_to_filled <- function(hollow) {
  key <- as.character(hollow)
  if (key %in% names(.HOLLOW_TO_FILLED)) {
    return(unname(.HOLLOW_TO_FILLED[key]))
  }
  hollow
}

# Build named shape vector from hollow shape codes
.build_shape_map <- function(labels, hollow_shapes) {
  shape_vals <- integer(0)

  for (i in seq_along(labels)) {
    ns_key <- paste0("Non-signif.", labels[i])
    s_key  <- paste0("Signif.", labels[i])
    shape_vals[ns_key] <- hollow_shapes[i]
    shape_vals[s_key]  <- .hollow_to_filled(hollow_shapes[i])
  }

  shape_vals
}
