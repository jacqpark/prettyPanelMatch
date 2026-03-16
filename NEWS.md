# prettyPanelMatch 0.2.0

* Added `pretty_placebo_test()` and `gg_placebo_test()` for tidying and plotting
  `placebo_test()` results from the PanelMatch package.
* Added `pretty_covariate_balance()` and `gg_covariate_balance()` for tidying and
  plotting `get_covariate_balance()` matrices as faceted grids
  (models as rows, matching stages as columns).
* Added `autoplot()` methods for `ppm_placebo_tidy` and `ppm_cov_tidy` classes.
* Added roxygen2-generated man pages for all exported functions.
* Updated package-level documentation to describe all three function families.

# prettyPanelMatch 0.1.0

* Initial release.
* `tidy_panel_estimate()` converts `PanelEstimate` summaries into tidy data frames.
* `ggplot_panel_estimate()` creates coefficient plots with significance-coded shapes.
* `autoplot()` method for `ppm_tidy` class.
