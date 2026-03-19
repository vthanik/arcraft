# Template registry — master list of all available templates
# Each template has: id, name, category, icon, description, adam_required, spec_fn, phase

template_registry <- function() {
  list(
    # ── Phase 1 (Done): Demographics ──
    list(id = "demog", name = "Demographics", category = "Study Information",
         icon = "fa-users", description = "Summary of demographics and baseline characteristics",
         adam_required = "adsl", spec_fn = "spec_demog", phase = 1, enabled = TRUE),

    # ── Phase 2: General Study Information (14.1.x) ──
    list(id = "disposition", name = "Disposition", category = "Study Information",
         icon = "fa-sign-out-alt", description = "Subject disposition by treatment",
         adam_required = "adsl", spec_fn = "spec_disposition", phase = 2, enabled = TRUE),

    list(id = "populations", name = "Analysis Populations", category = "Study Information",
         icon = "fa-layer-group", description = "Analysis population counts by flag",
         adam_required = "adsl", spec_fn = "spec_populations", phase = 2, enabled = TRUE),

    list(id = "enrollment", name = "Enrollment", category = "Study Information",
         icon = "fa-clipboard-list", description = "Subject enrollment by site/region",
         adam_required = "adsl", spec_fn = "spec_enrollment", phase = 2, enabled = TRUE),

    list(id = "protocol_violations", name = "Protocol Violations", category = "Study Information",
         icon = "fa-exclamation-circle", description = "Summary of protocol deviations",
         adam_required = "adsl", spec_fn = "spec_protocol_violations", phase = 2, enabled = TRUE),

    list(id = "medical_history", name = "Medical History", category = "Study Information",
         icon = "fa-notes-medical", description = "Medical history by SOC and preferred term",
         adam_required = c("adsl", "adcm"), spec_fn = "spec_medhist", phase = 2, enabled = TRUE),

    list(id = "concomitant_meds", name = "Concomitant Medications", category = "Study Information",
         icon = "fa-pills", description = "Concomitant medications by class and term",
         adam_required = c("adsl", "adcm"), spec_fn = "spec_conmed", phase = 2, enabled = TRUE),

    # ── Phase 3: Adverse Events (14.3.1.x, 14.3.2.x) ──
    list(id = "ae_summary", name = "AE Summary", category = "Adverse Events",
         icon = "fa-exclamation-triangle", description = "Overall adverse event summary counts",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_summary", phase = 3, enabled = TRUE),

    list(id = "ae_socpt", name = "AE by SOC/PT", category = "Adverse Events",
         icon = "fa-sitemap", description = "TEAEs by System Organ Class and Preferred Term",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_socpt", phase = 3, enabled = TRUE),

    list(id = "ae_related", name = "Related TEAEs", category = "Adverse Events",
         icon = "fa-link", description = "Treatment-related TEAEs by SOC/PT",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_related", phase = 3, enabled = TRUE),

    list(id = "ae_grade34", name = "Grade 3/4 TEAEs", category = "Adverse Events",
         icon = "fa-thermometer-three-quarters", description = "Grade 3 or higher TEAEs",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_grade34", phase = 3, enabled = TRUE),

    list(id = "ae_serious", name = "Serious AEs", category = "Adverse Events",
         icon = "fa-heart-broken", description = "Serious adverse events by SOC/PT",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_serious", phase = 3, enabled = TRUE),

    list(id = "ae_fatal", name = "Fatal AEs", category = "Adverse Events",
         icon = "fa-skull-crossbones", description = "Fatal adverse events",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_fatal", phase = 3, enabled = TRUE),

    list(id = "ae_by_severity", name = "AE by Severity", category = "Adverse Events",
         icon = "fa-sort-amount-up", description = "TEAEs by maximum severity/grade",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_by_severity", phase = 3, enabled = TRUE),

    list(id = "ae_dose_reduced", name = "AE Leading to Dose Reduction", category = "Adverse Events",
         icon = "fa-minus-circle", description = "TEAEs leading to dose reduction",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_dose_reduced", phase = 3, enabled = TRUE),

    list(id = "ae_drug_withdrawn", name = "AE Leading to Discontinuation", category = "Adverse Events",
         icon = "fa-ban", description = "TEAEs leading to treatment discontinuation",
         adam_required = c("adsl", "adae"), spec_fn = "spec_ae_drug_withdrawn", phase = 3, enabled = TRUE),

    # ── Phase 3: Exposure (14.3.1.1.x) ──
    list(id = "exposure", name = "Exposure", category = "Adverse Events",
         icon = "fa-clock", description = "Treatment exposure summary",
         adam_required = c("adsl", "adex"), spec_fn = "spec_exposure", phase = 3, enabled = TRUE),

    # ── Phase 4: Efficacy (14.2.x) ──
    list(id = "tte", name = "Time-to-Event", category = "Efficacy",
         icon = "fa-hourglass-half", description = "KM median, HR, log-rank p-value",
         adam_required = c("adsl", "adtte"), spec_fn = "spec_tte", phase = 4, enabled = TRUE),

    list(id = "response", name = "Best Overall Response", category = "Efficacy",
         icon = "fa-bullseye", description = "BOR distribution, ORR, CBR with CIs",
         adam_required = c("adsl", "adrs"), spec_fn = "spec_response", phase = 4, enabled = TRUE),

    list(id = "efficacy_cont", name = "Continuous Efficacy", category = "Efficacy",
         icon = "fa-chart-line", description = "Continuous endpoint with change from baseline",
         adam_required = c("adsl", "adeff"), spec_fn = "spec_efficacy_cont", phase = 4, enabled = TRUE),

    # ── Phase 5: Lab & Vitals (14.3.4.x, 14.3.5.x) ──
    list(id = "lab_results", name = "Laboratory Results", category = "Lab & Vitals",
         icon = "fa-flask", description = "Lab results by parameter and visit",
         adam_required = c("adsl", "adlb"), spec_fn = "spec_lab", phase = 5, enabled = TRUE),

    list(id = "vitals", name = "Vital Signs", category = "Lab & Vitals",
         icon = "fa-heartbeat", description = "Vital sign results by parameter and visit",
         adam_required = c("adsl", "advs"), spec_fn = "spec_vitals", phase = 5, enabled = TRUE),

    list(id = "lab_shift", name = "Lab Shift Table", category = "Lab & Vitals",
         icon = "fa-exchange-alt", description = "CTCAE grade or normal range shift table",
         adam_required = c("adsl", "adlb"), spec_fn = "spec_shift", phase = 5, enabled = TRUE),

    list(id = "marked_abnorm", name = "Marked Abnormalities", category = "Lab & Vitals",
         icon = "fa-exclamation", description = "Subjects with marked lab/vitals abnormalities",
         adam_required = c("adsl", "adlb"), spec_fn = "spec_marked_abnorm", phase = 5, enabled = TRUE),

    # ── Phase 6: Figures ──
    list(id = "km_plot", name = "Kaplan-Meier Plot", category = "Figures",
         icon = "fa-chart-area", description = "KM survival curves with risk table",
         adam_required = c("adsl", "adtte"), spec_fn = "spec_km_plot", phase = 6, enabled = TRUE),

    list(id = "waterfall", name = "Waterfall Plot", category = "Figures",
         icon = "fa-chart-bar", description = "Best % change from baseline bars",
         adam_required = c("adsl", "adrs"), spec_fn = "spec_waterfall", phase = 6, enabled = TRUE),

    list(id = "forest", name = "Forest Plot", category = "Figures",
         icon = "fa-align-left", description = "Subgroup HR and CI forest plot",
         adam_required = c("adsl", "adtte"), spec_fn = "spec_forest", phase = 6, enabled = TRUE),

    list(id = "swimmer", name = "Swimmer Plot", category = "Figures",
         icon = "fa-swimmer", description = "Subject-level treatment timelines",
         adam_required = c("adsl", "adtte", "adrs"), spec_fn = "spec_swimmer", phase = 6, enabled = TRUE),

    # ── Phase 7: Listings ──
    list(id = "listing_demographics", name = "Demographics Listing", category = "Listings",
         icon = "fa-list", description = "Subject-level demographics data listing",
         adam_required = "adsl", spec_fn = "spec_listing_demographics", phase = 7, enabled = TRUE),

    list(id = "listing_ae", name = "Adverse Events Listing", category = "Listings",
         icon = "fa-list-alt", description = "Subject-level adverse event listing",
         adam_required = c("adsl", "adae"), spec_fn = "spec_listing_ae", phase = 7, enabled = TRUE),

    list(id = "listing_lab", name = "Laboratory Listing", category = "Listings",
         icon = "fa-list-ol", description = "Subject-level laboratory data listing",
         adam_required = c("adsl", "adlb"), spec_fn = "spec_listing_lab", phase = 7, enabled = TRUE),

    list(id = "listing_discontinued", name = "Discontinued Subjects", category = "Listings",
         icon = "fa-user-slash", description = "Listing of discontinued subjects with reasons",
         adam_required = "adsl", spec_fn = "spec_listing_discontinued", phase = 7, enabled = TRUE),

    list(id = "listing_custom", name = "Custom Listing", category = "Listings",
         icon = "fa-table", description = "Custom data listing from any dataset",
         adam_required = "adsl", spec_fn = "spec_listing_custom", phase = 7, enabled = TRUE)
  )
}

# Get a single template definition by ID
get_template_def <- function(template_id) {
  reg <- template_registry()
  idx <- which(vapply(reg, function(t) t$id, character(1)) == template_id)
  if (length(idx) == 0) return(NULL)
  reg[[idx[1]]]
}

# Get all templates in a category
get_templates_by_category <- function(category) {
  reg <- template_registry()
  Filter(function(t) t$category == category, reg)
}

# Get unique categories in order
get_template_categories <- function() {
  reg <- template_registry()
  cats <- vapply(reg, function(t) t$category, character(1))
  unique(cats)
}
