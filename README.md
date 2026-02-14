# prettyPanelMatch

ggplot2-based plotting for `PanelMatch` results. Replaces manual data wrangling with a simple 2-function workflow.

## Install

```r
devtools::install_github("jacqpark/prettyPanelMatch")
```

## Usage

### Before (manual)

```r
pe1 <- summary(pe.results_e1[[1]])
pemat1 <- as.data.frame(cbind(terms, pe1))
# ... 80+ lines of repetitive munging and shape mapping ...
```

### After (with prettyPanelMatch)

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
