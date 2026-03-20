# ARD dispatch — routes template to correct builder
# Demographics only (Phase 1). Other templates backed up in _backup_templates/

fct_ard_dispatch <- function(template, datasets, grouping, var_configs,
                             added_levels = NULL, combined_groups = NULL,
                             var_labels = NULL) {
  adsl <- datasets[["adsl"]] %||% datasets[[names(datasets)[1]]]
  cgs <- combined_groups %||% grouping$combined_groups %||% list()

  switch(template,
    demog = fct_ard_demog(adsl, grouping, var_configs,
              added_levels = added_levels, combined_groups = cgs,
              var_labels = var_labels),
    stop("Template '", template, "' not yet implemented", call. = FALSE)
  )
}

# Output type — demographics is always "table"
fct_template_output_type <- function(template) "table"

# Required datasets
fct_template_required_datasets <- function(template) {
  switch(template, demog = "adsl", "adsl")
}
