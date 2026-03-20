# Code generation dispatch — demographics only (Phase 1)
# Other template codegen backed up in _backup_templates/

fct_codegen_dispatch <- function(template, data_cfg, grouping, var_configs, format_cfg,
                                  combined_groups = NULL) {
  ir <- fct_build_ir(format_cfg, combined_groups)
  # Determine which columns will exist in the generated tbl_data
  has_group_value <- !is.null(grouping$by_var) && nzchar(grouping$by_var %||% "")
  ard_cols <- c("variable", "var_label", "var_type", "stat_label")
  if (has_group_value) ard_cols <- c("group_value", ard_cols)
  sections <- c(
    fct_codegen_header(),
    fct_codegen_data(data_cfg),
    fct_codegen_ard(grouping, var_configs),
    fct_codegen_format(ir, ard_cols = ard_cols),
    fct_codegen_render(ir)
  )
  paste(sections, collapse = "\n")
}
