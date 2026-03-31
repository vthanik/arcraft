# Template registry — demographics only (Phase 1)
# Full registry with 30+ templates backed up in _backup_templates/

template_registry <- function() {
  list(
    # ── Study Information ──
    list(
      id = "demog",
      name = "Demographics",
      category = "Study Information",
      icon = "fa-users",
      description = "Summary of demographics and baseline characteristics",
      adam_required = "adsl",
      spec_fn = "spec_demog",
      sidebar_pattern = "variable_stat",
      phase = 1,
      enabled = TRUE
    ),
    list(
      id = "disposition",
      name = "Disposition",
      category = "Study Information",
      icon = "fa-right-from-bracket",
      description = "Subject disposition and completion status",
      adam_required = "adsl",
      spec_fn = NULL,
      sidebar_pattern = "variable_stat",
      phase = 2,
      enabled = TRUE
    ),
    list(
      id = "protocol_dev",
      name = "Protocol Deviations",
      category = "Study Information",
      icon = "fa-triangle-exclamation",
      description = "Summary of important protocol deviations",
      adam_required = "adsl",
      spec_fn = NULL,
      sidebar_pattern = "variable_stat",
      phase = 2,
      enabled = TRUE
    ),
    # ── Safety ──
    list(
      id = "ae_overall",
      name = "AE Overall Summary",
      category = "Safety",
      icon = "fa-shield-halved",
      description = "Overview of adverse events \u2014 flag counts and severity breakdown",
      adam_required = c("adsl", "adae"),
      spec_fn = "spec_ae_overall",
      sidebar_pattern = "flag_summary",
      phase = 1,
      enabled = TRUE
    ),
    list(
      id = "ae_socpt",
      name = "AE by SOC/PT",
      category = "Safety",
      icon = "fa-list-tree",
      description = "TEAEs by System Organ Class and Preferred Term hierarchy",
      adam_required = c("adsl", "adae"),
      spec_fn = "spec_ae_socpt",
      sidebar_pattern = "hierarchical",
      phase = 1,
      enabled = TRUE
    ),
    list(
      id = "ae_severity",
      name = "AE by Severity",
      category = "Safety",
      icon = "fa-gauge-high",
      description = "Adverse events by maximum severity grade",
      adam_required = c("adsl", "adae"),
      spec_fn = NULL,
      sidebar_pattern = "hierarchical",
      phase = 2,
      enabled = TRUE
    ),
    # ── Laboratory ──
    list(
      id = "lab_summary",
      name = "Lab Summary",
      category = "Laboratory",
      icon = "fa-flask",
      description = "Laboratory results summary by visit and treatment",
      adam_required = c("adsl", "adlb"),
      spec_fn = NULL,
      sidebar_pattern = "parameter_visit",
      phase = 2,
      enabled = TRUE
    ),
    list(
      id = "lab_shift",
      name = "Lab Shift Table",
      category = "Laboratory",
      icon = "fa-arrow-right-arrow-left",
      description = "Baseline to post-baseline shift in lab parameters",
      adam_required = c("adsl", "adlb"),
      spec_fn = NULL,
      sidebar_pattern = "parameter_visit",
      phase = 2,
      enabled = TRUE
    ),
    # ── Efficacy ──
    list(
      id = "tte_km",
      name = "Time-to-Event",
      category = "Efficacy",
      icon = "fa-chart-line",
      description = "Kaplan-Meier estimates and log-rank test",
      adam_required = c("adsl", "adtte"),
      spec_fn = NULL,
      sidebar_pattern = "time_to_event",
      phase = 2,
      enabled = TRUE
    ),
    list(
      id = "resp_summary",
      name = "Response Summary",
      category = "Efficacy",
      icon = "fa-chart-pie",
      description = "Best overall response and response rates",
      adam_required = c("adsl", "adrs"),
      spec_fn = NULL,
      sidebar_pattern = "variable_stat",
      phase = 2,
      enabled = TRUE
    ),
    # ── Listings ──
    list(
      id = "listing_ae",
      name = "AE Listing",
      category = "Listings",
      icon = "fa-table-list",
      description = "Patient-level adverse event listing",
      adam_required = c("adsl", "adae"),
      spec_fn = NULL,
      sidebar_pattern = "flat_listing",
      phase = 2,
      enabled = TRUE
    ),
    list(
      id = "listing_conmed",
      name = "Concomitant Meds",
      category = "Listings",
      icon = "fa-pills",
      description = "Concomitant medications listing",
      adam_required = c("adsl", "adcm"),
      spec_fn = NULL,
      sidebar_pattern = "flat_listing",
      phase = 2,
      enabled = TRUE
    )
  )
}

get_template_def <- function(template_id) {
  match <- Filter(function(t) t$id == template_id, template_registry())
  if (length(match) == 0) return(NULL)
  match[[1]]
}

get_sidebar_pattern <- function(template_id) {
  if (is.null(template_id)) return("variable_stat")
  tmpl <- get_template_def(template_id)
  if (is.null(tmpl)) return("variable_stat")
  tmpl$sidebar_pattern %||% "variable_stat"
}

get_template_categories <- function() {
  unique(vapply(template_registry(), function(t) t$category, character(1)))
}
