# ARD dispatch — routes template to correct builder
# Central routing function: template string → ARD tibble

fct_ard_dispatch <- function(template, datasets, grouping, var_configs,
                             added_levels = NULL, combined_groups = NULL,
                             var_labels = NULL) {
  # Get primary dataset
  ds_name <- names(datasets)[1]
  adsl <- datasets[["adsl"]] %||% datasets[[ds_name]]
  cgs <- combined_groups %||% grouping$combined_groups %||% list()

  switch(template,
    # Phase 1 — Demographics (existing)
    demog = fct_ard_demog(adsl, grouping, var_configs,
      added_levels = added_levels, combined_groups = cgs,
      var_labels = var_labels),

    # Phase 2 — General Study Info (14.1.x)
    disposition = fct_ard_disposition(adsl, grouping, var_configs),
    populations = fct_ard_populations(adsl, grouping, var_configs),
    enrollment = fct_ard_categorical(adsl, grouping, var_configs),
    site_trt = fct_ard_categorical(adsl, grouping, var_configs),
    protocol_violations = fct_ard_categorical(adsl, grouping, var_configs),
    medical_history = fct_ard_hierarchical(
      datasets[["adcm"]] %||% adsl, adsl, grouping, var_configs,
      parent_var = var_configs$.parent_var %||% "MHBODSYS",
      child_var = var_configs$.child_var %||% "MHDECOD"
    ),
    prior_meds = fct_ard_hierarchical(
      datasets[["adcm"]] %||% adsl, adsl, grouping, var_configs,
      parent_var = "CMCLAS", child_var = "CMDECOD"
    ),
    concomitant_meds = fct_ard_hierarchical(
      datasets[["adcm"]] %||% adsl, adsl, grouping, var_configs,
      parent_var = "CMCLAS", child_var = "CMDECOD"
    ),

    # Phase 3 — AE tables (14.3.1.x, 14.3.2.x)
    ae_summary = fct_ard_ae_summary(datasets[["adae"]], adsl, grouping, var_configs),
    ae_socpt = fct_ard_ae_socpt(datasets[["adae"]], adsl, grouping, var_configs),
    ae_related = fct_ard_ae_filtered(datasets[["adae"]], adsl, grouping, var_configs,
      filter_expr = quote(AEREL %in% c("RELATED", "PROBABLE", "POSSIBLE", "DEFINITELY RELATED", "Y"))),
    ae_grade34 = fct_ard_ae_filtered(datasets[["adae"]], adsl, grouping, var_configs,
      filter_expr = quote(AETOXGR %in% c("3", "4", "5"))),
    ae_serious = fct_ard_ae_filtered(datasets[["adae"]], adsl, grouping, var_configs,
      filter_expr = quote(AESER == "Y")),
    ae_fatal = fct_ard_ae_filtered(datasets[["adae"]], adsl, grouping, var_configs,
      filter_expr = quote(AEOUT == "FATAL" | AESDTH == "Y")),
    ae_dose_reduced = fct_ard_ae_filtered(datasets[["adae"]], adsl, grouping, var_configs,
      filter_expr = quote(AEACN == "DOSE REDUCED")),
    ae_drug_interrupted = fct_ard_ae_filtered(datasets[["adae"]], adsl, grouping, var_configs,
      filter_expr = quote(AEACN == "DRUG INTERRUPTED")),
    ae_drug_withdrawn = fct_ard_ae_filtered(datasets[["adae"]], adsl, grouping, var_configs,
      filter_expr = quote(AEACN == "DRUG WITHDRAWN")),
    ae_by_severity = fct_ard_ae_by_severity(datasets[["adae"]], adsl, grouping, var_configs),
    ae_frequency = fct_ard_ae_socpt(datasets[["adae"]], adsl, grouping, var_configs, sort_by_freq = TRUE),

    # Phase 3 — Exposure (14.3.1.1.x)
    exposure = fct_ard_exposure(datasets[["adex"]] %||% adsl, adsl, grouping, var_configs),

    # Phase 4 — Efficacy (14.2.x)
    tte = fct_ard_tte(datasets[["adtte"]], adsl, grouping, var_configs),
    response = fct_ard_response(datasets[["adrs"]], adsl, grouping, var_configs),
    efficacy_cont = fct_ard_efficacy_cont(
      datasets[["adeff"]] %||% datasets[["adlb"]], adsl, grouping, var_configs),

    # Phase 5 — Lab/Vitals (14.3.4.x, 14.3.5.x)
    lab_results = fct_ard_bds(datasets[["adlb"]], adsl, grouping, var_configs),
    vitals = fct_ard_bds(datasets[["advs"]], adsl, grouping, var_configs),
    ecg = fct_ard_bds(datasets[["adeg"]], adsl, grouping, var_configs),
    lab_shift = fct_ard_shift(datasets[["adlb"]], adsl, grouping, var_configs),
    vitals_shift = fct_ard_shift(datasets[["advs"]], adsl, grouping, var_configs),
    ecg_shift = fct_ard_shift(datasets[["adeg"]], adsl, grouping, var_configs),
    marked_abnorm = fct_ard_marked_abnorm(
      datasets[["adlb"]] %||% datasets[["advs"]], adsl, grouping, var_configs),

    # Fallback
    stop(paste0("Unknown template: ", template), call. = FALSE)
  )
}

# Dispatch for figures — returns ggplot object, not ARD
fct_figure_dispatch <- function(template, datasets, grouping, fig_configs) {
  adsl <- datasets[["adsl"]]


  switch(template,
    km_plot = fct_fig_km(datasets[["adtte"]], adsl, grouping, fig_configs),
    waterfall = fct_fig_waterfall(datasets[["adtr"]] %||% datasets[["adrs"]], adsl, grouping, fig_configs),
    swimmer = fct_fig_swimmer(datasets[["adtte"]], datasets[["adrs"]], adsl, grouping, fig_configs),
    forest = fct_fig_forest(datasets[["adtte"]], adsl, grouping, fig_configs),
    spider = fct_fig_spider(datasets[["adtr"]], adsl, grouping, fig_configs),
    bar_chart = fct_fig_bar(datasets[[names(datasets)[1]]], adsl, grouping, fig_configs),
    stop(paste0("Unknown figure template: ", template), call. = FALSE)
  )
}

# Dispatch for listings — returns formatted tibble
fct_listing_dispatch <- function(template, datasets, listing_config) {
  switch(template,
    listing_discontinued = fct_build_listing(datasets[["adsl"]], listing_config),
    listing_protocol_dev = fct_build_listing(datasets[["adsl"]], listing_config),
    listing_demographics = fct_build_listing(datasets[["adsl"]], listing_config),
    listing_compliance = fct_build_listing(datasets[["adex"]], listing_config),
    listing_ae = fct_build_listing(datasets[["adae"]], listing_config),
    listing_lab = fct_build_listing(datasets[["adlb"]], listing_config),
    listing_custom = fct_build_listing(datasets[[listing_config$dataset %||% names(datasets)[1]]], listing_config),
    stop(paste0("Unknown listing template: ", template), call. = FALSE)
  )
}
