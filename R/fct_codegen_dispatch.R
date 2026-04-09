# Code generation dispatch — routes template to correct codegen

fct_codegen_dispatch <- function(template, data_cfg, grouping, var_configs, format_cfg,
                                  combined_groups = NULL) {
  ir <- fct_build_ir(format_cfg, combined_groups)

  switch(template,
    ae_overall = {
      ard_cols <- c("category", "variable", "stat_label")
      sections <- c(
        fct_codegen_header(),
        fct_codegen_data_ae(data_cfg),
        fct_codegen_ard_ae_overall(grouping, var_configs),
        fct_codegen_format(ir, ard_cols = ard_cols),
        fct_codegen_render(ir)
      )
      paste(sections, collapse = "\n")
    },
    ae_socpt = {
      # Dynamic meta columns: soc + l2..l(N-1) + pt + row_type
      n_hier <- length(grouping$analysis_vars)
      if (n_hier <= 2L) {
        ard_cols <- c("soc", "pt", "row_type")
      } else {
        ard_cols <- c("soc", paste0("l", seq(2L, n_hier - 1L)), "pt", "row_type")
      }
      sections <- c(
        fct_codegen_header(),
        fct_codegen_data_ae(data_cfg),
        fct_codegen_ard_ae_hierarchy(grouping, var_configs),
        fct_codegen_format(ir, ard_cols = ard_cols),
        fct_codegen_render(ir)
      )
      paste(sections, collapse = "\n")
    },
    {
      # Default: demographics
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
  )
}
