# ARD dispatch — routes template to correct builder

fct_ard_dispatch <- function(template, datasets, grouping, var_configs,
                             added_levels = NULL, combined_groups = NULL,
                             var_labels = NULL) {
  adsl <- datasets[["adsl"]] %||% datasets[[names(datasets)[1]]]
  cgs <- combined_groups %||% grouping$combined_groups %||% list()

  switch(template,
    demog = fct_ard_demog_cards(adsl, grouping, var_configs,
              added_levels = added_levels, combined_groups = cgs,
              var_labels = var_labels),
    ae_overall = {
      adae <- datasets[["adae"]]
      if (is.null(adae)) cli::cli_abort("ADAE dataset required for AE Overall template", call = NULL)
      fct_ard_ae_overall(adae, adsl, grouping, var_configs)
    },
    ae_socpt = {
      adae <- datasets[["adae"]]
      if (is.null(adae)) cli::cli_abort("ADAE dataset required for AE SOC/PT template", call = NULL)
      fct_ard_ae_socpt(adae, adsl, grouping, var_configs)
    },
    cli::cli_abort("Template {.val {template}} not yet implemented", call = NULL)
  )
}

# Output type
fct_template_output_type <- function(template) "table"

# Required datasets
fct_template_required_datasets <- function(template) {
  switch(template,
    demog = "adsl",
    ae_overall = c("adsl", "adae"),
    ae_socpt = c("adsl", "adae"),
    "adsl"
  )
}
