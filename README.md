# prettyPanelMatch

ggplot2-based plotting for `PanelMatch` (Imai et al. 2023) results. Tidy-and-plot function pairs for treatment effect estimates, placebo tests, and covariate balance diagnostics.

## Install

```r
devtools::install_github("jacqpark/prettyPanelMatch")
```

## Functions

| Tidy | Plot | Input |
|------|------|-------|
| `tidy_panel_estimate()` | `ggplot_panel_estimate()` | `PanelEstimate` summaries |
| `pretty_placebo_test()` | `gg_placebo_test()` | `placebo_test()` results |
| `pretty_covariate_balance()` | `gg_covariate_balance()` | `get_covariate_balance()` matrices |

All plot functions return standard `ggplot` objects.

## Usage

### Treatment Effect Estimates

```r
library(prettyPanelMatch)

# Step 1: Tidy — pass all summaries at once, with labels
combined <- tidy_panel_estimate(
  "Energy Dept." = summary(pe.results_e1[[1]]),
  "State Dept."  = summary(pe.results_e2[[1]]),
  "Congress"     = summary(pe.results_e3[[1]]),
  "EOP"          = summary(pe.results_e4[[1]])
)

# Step 2: Plot
ggplot_panel_estimate(combined)
```

### Shapes

Hollow shapes indicate non-significant estimates; filled counterparts are auto-paired for significant ones. The legend only shows hollow shapes, with a footnote explaining the convention.

Choose shapes by name: `"circle"`, `"square"`, `"triangle"`, `"diamond"`, `"triangle_down"`.

```r
ggplot_panel_estimate(combined, shapes = c("circle", "diamond", "triangle", "square"))
```

### Customization (it's just ggplot2)

```r
# Custom axis labels
ggplot_panel_estimate(combined, xlab = "Time (in years)", ylab = "Estimate")

# Add title, move legend
ggplot_panel_estimate(combined) +
  ggtitle("Effect of ENG Lobbying on Energy Outcomes") +
  theme(legend.position = "bottom")

# Faceted layout
ggplot_panel_estimate(combined, facet_by = "label")

# Custom theme
ggplot_panel_estimate(combined, theme_fn = theme_bw)

# Suppress significance footnote
ggplot_panel_estimate(combined, footnote = NULL)

# Single model (legend hidden by default)
t1 <- tidy_panel_estimate(summary(pe_results), labels = "My Model")
ggplot_panel_estimate(t1)

# autoplot method
autoplot(combined)
```

### Placebo Tests

```r
# Step 1: Tidy — pass placebo_test() results with labels
pt_combined <- pretty_placebo_test(
  "Congress Finance" = placebo_test(pm.sets_cngFINfin, ...),
  "Treasury Finance" = placebo_test(pm.sets_trsFINfin, ...)
)

# Step 2: Plot
gg_placebo_test(pt_combined)

# Custom confidence level (default 95%)
pt_90 <- pretty_placebo_test(pt_result, confidence_level = 0.90)

# All ggplot_panel_estimate options work here too
gg_placebo_test(pt_combined, shapes = c("circle", "diamond"), facet_by = "label")
```

### Covariate Balance

```r
# Step 1: Tidy — each named argument is a model, with a list of matrices
#   (one per matching stage: before matching, matched pre-refinement, post-refinement)
cov_data <- pretty_covariate_balance(
  "Cong-FIN; US finan" = list(cov_nomatch, cov_matched, cov_refined),
  "Cong-FIN; US banks" = list(cov_nomatch2, cov_matched2, cov_refined2),
  "Cong-BAN; US finan" = list(cov_nomatch3, cov_matched3, cov_refined3),
  dv = c("congress_fin", "congress_ban")
)

# Step 2: Plot — facet_grid(model ~ stage), DVs black/solid, covariates grey/dashed
gg_covariate_balance(cov_data)

# Custom stage labels
pretty_covariate_balance(
  "My Model" = list(mat1, mat2),
  stage_labels = c("Unmatched", "Matched"),
  dv = "outcome_var"
)

# Customize appearance
gg_covariate_balance(cov_data,
  dv_color = "darkblue", cov_color = "grey50",
  ylim = c(-3, 3), show_legend = TRUE
)

# Add a vertical line at the last pre-treatment period
gg_covariate_balance(cov_data) +
  geom_vline(xintercept = 3, lty = "dashed")
```
