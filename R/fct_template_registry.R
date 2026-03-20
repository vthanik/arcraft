# Template registry — demographics only (Phase 1)
# Full registry with 30+ templates backed up in _backup_templates/

template_registry <- function() {
  list(
    list(
      id = "demog",
      name = "Demographics",
      category = "Study Information",
      icon = "fa-users",
      description = "Summary of demographics and baseline characteristics",
      adam_required = "adsl",
      spec_fn = "spec_demog",
      phase = 1,
      enabled = TRUE
    )
  )
}

get_template_def <- function(template_id) {
  match <- Filter(function(t) t$id == template_id, template_registry())
  if (length(match) == 0) return(NULL)
  match[[1]]
}

get_template_categories <- function() {
  unique(vapply(template_registry(), function(t) t$category, character(1)))
}
