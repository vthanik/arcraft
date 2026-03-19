#' Round like SAS
#'
#' The base SAS round function uses different rounding assumption from the
#' base R round function.  The function round_half_up when used in R mimics
#' the base SAS round function.  The SAS function rounde will match round
#' function in R.
#' @param x Vector containing values to round
#' @param digits digits to be rounded to
#' @export
#' @examples
#' round_half_up(12.5)
#' round_half_up(c(12.5,13.5,6.5))
#' round_half_up(2.477, digits = 2)
#' round_half_up(c(9.243, 4.167, 12.476), digits = 2)
round_half_up <- function (x, digits = 0) {
  posneg <- sign(x)
  z <- abs(x) * 10^digits
  z <- z + 0.5 + sqrt(.Machine$double.eps)
  z <- trunc(z)
  z <- z/10^digits
  z * posneg
}

# Summary Frequency (count and percentage) - Categorical
summ_freq <- function(
    data, 
    segment_num = NA_integer_,
    group_var = NA_character_, 
    trt_vars = NA_character_, # code and decode (in that order)
    bign_df = bign,
    bign_var = "N",
    group_label = NA_character_,
    n_row = TRUE,
    complete_types = FALSE,
    spec_object = NULL,
    codelist_name=NULL
) {
  
  summ <- data |>
    dplyr::group_by(across(all_of(c(trt_vars, bign_var, group_var)))) |>
    dplyr::summarize(
      COUNT = dplyr::n()
    ) |>
    dplyr::ungroup() 
  
  if (complete_types) {
    
    if (is.null(spec_object) | is.null(codelist_name)) {
      warning("Complete types has been set to TRUE and spec_object and/or codelist are not provided. Both are required to include zero counts!")
      return(NULL)
    }
    
    var_fmt <- data.frame({{spec_object}}$codelist$codes[{{spec_object}}$codelist$code_id=={{codelist_name}}]) |>
      dplyr::mutate(order = row_number()) |>
      dplyr::cross_join(
        bign_df
      ) |>
      dplyr::mutate(decode = if_else(is.na(decode), code, decode))
    
    summ <- var_fmt |>
      dplyr::left_join(
        summ, 
        by = dplyr::join_by(!!sym(trt_vars[1]), !!sym(trt_vars[2]), !!sym(bign_var), code == !!sym(group_var))
      ) |>
      tidyr::replace_na(list(COUNT = 0)) |>
      dplyr::mutate(!!sym(group_var) := decode) |>
      dplyr::select(-decode) |>
      dplyr::mutate(segment = segment_num)
  } else {
    summ <- summ |>
      dplyr::mutate(segment = segment_num, order = NA_integer_)
  }
  
  summ <- summ |>
    dplyr::mutate(percent = (COUNT/!!sym(bign_var))*100) |>
    dplyr::mutate(GROUP = group_label)
  
  tfrmt_row_cnt <- summ |>
    mutate(stat = "cnt") |>
    dplyr::select(all_of(c(trt_vars, "GROUP", group_var, "stat", "COUNT", "segment", "order"))) |>
    dplyr::rename(VALUE = COUNT)
  
  tfrmt_row_per <- summ |>
    mutate(stat = "pct") |>
    dplyr::select(all_of(c(trt_vars, "GROUP", group_var, "stat", "percent", "segment", "order"))) |>
    dplyr::rename(VALUE = percent)
  
  tfrmt_row_n <- NULL
  
  if (n_row) {
    n <- data |>
      dplyr::filter(!is.na(group_var)) |>
      dplyr::group_by(across(all_of(trt_vars))) |>
      dplyr::summarize(
        n = dplyr::n_distinct(STUDYID, USUBJID, SUBJID)
      ) |>
      dplyr::ungroup() 
    
    tfrmt_row_n <- n |>
      dplyr::mutate(GROUP = group_label, stat = "n", !!sym(group_var) := "n") |>
      dplyr::select(all_of(c(trt_vars, "GROUP", group_var, "stat", "n"))) |>
      dplyr::rename(VALUE = n) |>
      dplyr::mutate(segment = segment_num, order = 0)
  }
  
  tfrmt_rows <- dplyr::bind_rows(tfrmt_row_n, tfrmt_row_cnt, tfrmt_row_per) |>
    dplyr::rename(GROUP_LABEL = all_of(group_var)) 
  
  return(tfrmt_rows)
}

# Summary Stats - Continuous
summ_stats <- function(
    data,
    segment_num = NA_integer_,
    analysis_var = NA, 
    trt_vars = NA_character_, 
    bign_var = "N", 
    stat_vars = c("Mean", "SD", "Median", "Min", "Max"),
    group_label = NA_character_,
    n_row = TRUE
) {
  
  stats <- data |>
    dplyr::group_by(across(all_of(c(trt_vars, bign_var)))) |>
    dplyr::summarize(
      Mean = mean(!!sym(analysis_var), na.rm = TRUE),
      SD = sd(!!sym(analysis_var), na.rm = TRUE),
      Median = median(!!sym(analysis_var), na.rm = TRUE),
      Min = min(!!sym(analysis_var), na.rm = TRUE),
      Max = max(!!sym(analysis_var), na.rm = TRUE),
      Q1 = quantile(!!sym(analysis_var), 0.25, na.rm = TRUE),
      Q3 = quantile(!!sym(analysis_var), 0.75, na.rm = TRUE)
    ) |>
    dplyr::ungroup() 
  
  tfrmt_stats <- stats |>
    dplyr::select(all_of(trt_vars),all_of(stat_vars)) |>
    tidyr::pivot_longer(cols = all_of(stat_vars), names_to = "GROUP_LABEL", values_to = "VALUE") |>
    dplyr::mutate(GROUP = group_label, stat = tolower(GROUP_LABEL)) |>
    dplyr::mutate(order = match(GROUP_LABEL, stat_vars))
  
  tfrmt_row_n <- NULL
  
  if (n_row) {
    n <- data |>
      dplyr::filter(!is.na(analysis_var)) |>
      dplyr::group_by(across(all_of(trt_vars))) |>
      dplyr::summarize(
        n = dplyr::n_distinct(STUDYID, USUBJID, SUBJID)
      ) |>
      dplyr::ungroup() 
    
    tfrmt_row_n <- n |>
      dplyr::mutate(GROUP = group_label, stat = "n", GROUP_LABEL = "n") |>
      dplyr::select(all_of(c(trt_vars, "GROUP", "GROUP_LABEL", "stat", "n"))) |>
      dplyr::rename(VALUE = n) |>
      dplyr::mutate(order = 0)
  }
  
  tfrmt_rows <- dplyr::bind_rows(tfrmt_row_n, tfrmt_stats) |>
    dplyr::mutate(segment = segment_num)
  
  return(tfrmt_rows)
}

# Derive bigN values and add to data
derive_bign <- function(data, trt_vars = c("TRT01AN", "TRT01A"), bign_varname = "N") {
  
  bign <- data |>
    dplyr::group_by(across(all_of(trt_vars))) |>
    dplyr::summarise(!!sym(bign_varname) := n()) |>
    dplyr::ungroup()
  
  return(bign)
}

# Add total rows to data
add_totals <- function(data, trt_vars = c("TRT01AN", "TRT01A"), total_code = 999, total_decode = "Total") {
  
  tot <- data |>
    dplyr::mutate(!!sym(trt_vars[1]) := total_code, !!sym(trt_vars[2]) := total_decode) |>
    dplyr::bind_rows(data)
  
  return(tot)
}

# Extracts titles and footnotes from dummy AOM object
titles_footnotes <- function(aom_obj, text_type) {
  
  text <- sapply(aom_obj, function(x) {
    if (x$type == text_type) {
      return(x$text)
    } else {
      return(NULL)
    }
  })
  
  return(unlist(text))
}

# Create PDF output
create_pdf <- function(gt, pdf_name, analysis_set = NULL, titles = NULL, footnotes = NULL) {
  
  header_includes <- paste0("/mnt/data/", Sys.getenv("DOMINO_PROJECT_NAME"), "/inputdata/preamble.tex")
  
  if (is.null(analysis_set)) {
    warning("Analysis set is missing from create_pdf() call. This will be blank in PDF.")
  }
  
  as_docorator(
    gt,
    display_name = pdf_name,
    display_loc = output,
    object_loc = dddata,
    header = fancyhead(
      fancyrow(
        left = paste0("Protocol: ", Sys.getenv("STUDYID")), 
        right = doc_pagenum()
      ),
      fancyrow(
        left = paste0("Analysis Set: ", analysis_set), 
        right = paste0("Data as of: ", Sys.getenv("DMV_DATADATE"))
      ),
      fancyrow(
        center = titles
      )
    ),
    footer = fancyfoot(
      fancyrow(
        left = footnotes
      ),
      fancyrow(
        left = paste0("Rendered PDF for ", prod_items$pdf_name, ".R on ", doc_datetime())
      )
    ),
    tbl_scale = FALSE
  ) |>
    render_pdf(
      header_latex = header_includes,
      transform = finalize_gt
    )
  
}

# Create dummy AOM to work with mercuryTFL functions
create_aom <- function(gt, proportional_widths, trt_string = NA_character_, total_string = NA_character_) {
  
  # Initialize AOM object
  aom <- list(
    stubType = "Indented",
    columnGroups = list(
      column_list = list(
        columns = list()
      )
    ),
    titleFootnotes = list()
  )
  
  # Extract table from gt object
  if (class(gt) == "gt_group") {
    gt_data <- gt$gt_tbls$gt_tbl[[1]]$`_data` |> 
      select(-contains("tfrmt"))
  } else {
    gt_data <- gt$`_data` |> 
      select(-contains("tfrmt"))
  }
  
  col_names <- names(gt_data)
  
  # Add proportional widths to columns
  for (i in seq_along(col_names)) {
    column_name <- paste("col", i, sep = "")
    
    if (grepl(trt_string, col_names[i]) == FALSE & grepl(total_string, col_names[i]) == FALSE) {
      aom$columnGroups$column_list$columns[[column_name]] <- list(
        ordinal = i,
        type = "Stub",
        proportionalWidth = proportional_widths[1]
      )
    } else if (grepl(total_string, col_names[i])) {
      aom$columnGroups$column_list$columns[[column_name]] <- list(
        ordinal = i,
        type = "Result",
        proportionalWidth = proportional_widths[3]
      )
    } else if (grepl(trt_string, col_names[i])){
      aom$columnGroups$column_list$columns[[column_name]] <- list(
        ordinal = i,
        type = "Result",
        proportionalWidth = proportional_widths[2]
      )
    } 
  }
  
  return(aom)
}

#Create gt for data and no data to report
create_gt <- function(df, tfrmt) {
  
  #number of rows in df is 0
  if (nrow(df) == 0) {
    
    #... create dummy gt object ...
    data_<-data.frame(x=c(rep("",9),"No data to report",rep("",9)))
    gt <- data_ |>
      gt::gt() |>
      cols_width(x ~ pct(100)) |>
      gt::cols_label( x = " ") |>
      cols_align(
        align = "center",
        columns = c(x) 
      ) |>
      gt::tab_options(
        table.font.size = "10pt",
        column_labels.border.bottom.width = "0pt",
        column_labels.border.top.width = "0pt",
        table_body.hlines.width = "0pt"
      )
    
  } else {
    gt <- print_to_gt(tfrmt, df) |>
      gt::tab_options(
        table.font.size = "10pt"
      )
    
  }
  
  return(gt)
}

# Apply column widths to gt object
apply_widths <- function(gt, trt_widths = NA_integer_, total_width = NA_integer_, other_widths = NA_integer_,
                         trt_string = "GSK227", total_string = "Total") {
  
  # Extract table from gt object
  if (class(gt)[1] == "gt_group") {
    
    gt_data <- gt$gt_tbls$gt_tbl[[1]]$`_data` |> 
      select(-contains("tfrmt"))
    
    col_names <- names(gt_data)
    
    # multiple {gt} tables - extract each table and apply widths
    gt_with_widths <- gt::gt_group() # initialize
    
    for (i in gt$gt_tbls$i) {
      
      gt_table <- gt::grp_pull(gt, i)
      
      # Creating a symbolic representation of the column name and column width
      for (j in seq_along(col_names)) {
        
        col <- rlang::sym(col_names[j]) 
        
        if (grepl(trt_string, col_names[j]) == FALSE & grepl(total_string, col_names[j]) == FALSE) {
          width <- other_widths 
          expr <- rlang::expr(!!col ~ gt::pct(!!width))
        } else if (grepl(total_string, col_names[j])) {
          width <- total_width 
          expr <- rlang::expr(!!col ~ gt::pct(!!width))
        } else if (grepl(trt_string, col_names[j])){
          width <- trt_widths 
          expr <- rlang::expr(!!col ~ gt::pct(!!width))
        } 
        
        gt_table <- gt::cols_width(gt_table, expr)
      }
      
      # combine tables back together
      gt_with_widths <- gt::grp_add(gt_with_widths, gt_table)
    }
  } else {
    gt_data <- gt$`_data` |> 
      select(-contains("tfrmt"))
    
    col_names <- names(gt_data)
    
    for (j in seq_along(col_names)) {
      
      col <- rlang::sym(col_names[j]) 
      width <- other_widths 
      
      if (grepl(trt_string, col_names[j]) == FALSE & grepl(total_string, col_names[j]) == FALSE) {
        width <- other_widths 
        expr <- rlang::expr(!!col ~ gt::pct(!!width))
      } else if (grepl(total_string, col_names[j])) {
        width <- total_width 
        expr <- rlang::expr(!!col ~ gt::pct(!!width))
      } else if (grepl(trt_string, col_names[j])){
        width <- trt_widths 
        expr <- rlang::expr(!!col ~ gt::pct(!!width))
      } 
      
      gt <- gt::cols_width(gt, expr)
    }
    
    gt_with_widths <- gt
  }
  
  return(gt_with_widths)
}

# Summary Frequency (count and percentage) - Categorical - multiple by group variables
summ_freq_multiby <- function(
    data, 
    segment_num = NA_integer_,
    group_var = NA_character_, 
    trt_vars = NA_character_, # code and decode (in that order)
    bign_df = bign,
    bign_var = "N",
    group_label = NA_character_,
    n_row = TRUE,
    complete_types = FALSE,
    spec_object = NULL,
    codelist_name=NULL
) {
  
  summ <- data |>
    dplyr::group_by(across(all_of(c(trt_vars, bign_var, group_var)))) |>
    dplyr::summarize(
      COUNT = dplyr::n()
    ) |>
    dplyr::ungroup() 
  
  if (complete_types) {
    
    if (is.null(spec_object) | is.null(codelist_name)) {
      warning("Complete types has been set to TRUE and spec_object and/or codelist are not provided. Both are required to include zero counts!")
      return(NULL)
    }
    
    
    var_fmt <- data.frame({{spec_object}}$codelist$codes[{{spec_object}}$codelist$code_id=={{codelist_name}}]) |>
      dplyr::mutate(order = row_number()) |>
      dplyr::cross_join(
        bign_df
      ) |>
      dplyr::mutate(decode = if_else(is.na(decode), code, decode))
    
    summ <- var_fmt |>
      dplyr::left_join(
        summ, 
        by = dplyr::join_by(!!sym(trt_vars[1]), !!sym(trt_vars[2]), !!sym(bign_var), code == !!sym(group_var))
      ) |>
      tidyr::replace_na(list(COUNT = 0)) |>
      dplyr::mutate(!!sym(group_var) := decode) |>
      dplyr::select(-decode) |>
      dplyr::mutate(segment = segment_num)
  } else {
    summ <- summ |>
      dplyr::mutate(segment = segment_num, order = NA_integer_)
  }
  
  summ <- summ |>
    dplyr::mutate(percent = (COUNT/!!sym(bign_var))*100) |>
    dplyr::mutate(GROUP = group_label)
  
  tfrmt_row_cnt <- summ |>
    mutate(stat = "cnt") |>
    dplyr::select(all_of(c(trt_vars, "GROUP", group_var, "stat", "COUNT", "segment", "order"))) |>
    dplyr::rename(VALUE = COUNT)
  
  tfrmt_row_per <- summ |>
    mutate(stat = "pct") |>
    dplyr::select(all_of(c(trt_vars, "GROUP", group_var, "stat", "percent", "segment", "order"))) |>
    dplyr::rename(VALUE = percent)
  
  tfrmt_row_n <- NULL
  
  if (n_row) {
    n <- data |>
      dplyr::filter(all(!is.na(group_var))) |>
      dplyr::group_by(across(all_of(c(trt_vars, group_var[1])))) |>
      dplyr::summarize(
        n = dplyr::n_distinct(STUDYID, USUBJID, SUBJID)
      ) |>
      dplyr::ungroup() 
    
    tfrmt_row_n <- n |>
      dplyr::mutate(GROUP = group_label, stat = "n", !!sym(group_var[2]) := "n") |>
      dplyr::select(all_of(c(trt_vars, "GROUP", group_var, "stat", "n"))) |>
      dplyr::rename(VALUE = n) |>
      dplyr::mutate(segment = segment_num, order = 0)
  }
  
  tfrmt_rows <- dplyr::bind_rows(tfrmt_row_n, tfrmt_row_cnt, tfrmt_row_per)
  
  return(tfrmt_rows)
}

consectutive_duplicated <- function(x) {
  if (is.data.frame(x)) {
    x <- tidyr::unite(x, col = "..col_unite..", everything())[["..col_unite.."]]
  }
  
  c(FALSE, (x == dplyr::lead(x))[-length(x)])
}

collapse_group_row <- function(.data, fields, reorder_cols = TRUE) {
  stopifnot(is.data.frame(.data))
  
  alt_fields <- setdiff(colnames(.data), fields)
  
  # make sure all column names passed exist
  if (!all(fields %in% names(.data))) {
    fields <- fields[fields %in% names(.data)]
  }
  
  # # sort row order of fields
  # nice_fields <- ifelse(grepl(" ", fields), paste0("`", fields, "`"), fields)
  # .data <- .data[eval(parse(text = paste0("with(.data,order(", paste(nice_fields,
  #                                                                    collapse = ","), "))"))), ]
  
  # create 'new' fields containing the result of collapsing rows
  for (i in 0:(length(fields) - 1)) {
    field_of_interest <- fields[length(fields) - i]
    duplicated_rows <- consectutive_duplicated(.data[, fields[1:(length(fields) - i)]]) & !grepl("^\\s", .data[[field_of_interest]])
    .data[duplicated_rows, field_of_interest] <- NA
  }
  
  if (reorder_cols) {
    .data[, c(paste0(fields), alt_fields)]
  } else {
    .data
  }
  
}

# Apply column widths to gt object when the columns are known (e.g. stats in cols)
apply_widths_fixed <- function(gt, 
                               cols = c("Col1", "n", "Mean", "SD", "Median", "Min.", "Max."),
                               col_widths = c(20, 5, 10, 10, 10, 10, 10),
                               other_widths = NA_integer_
) {
  
  if (is.na(other_widths)) {
    warning("Widths for other columns must be provided in case any are missing from cols argument. Please provide 'other_widths' value.")
    return(NULL)
  }
  
  if (length(cols) != length(col_widths)) {
    warning(paste0("Not all column widths have been provided. Some columns will be set to ", other_widths, "%. Please check total width of table!"))
  }
  
  # Extract table from gt object
  if (class(gt)[1] == "gt_group") {
    
    gt_data <- gt$gt_tbls$gt_tbl[[1]]$`_data` |> 
      select(-contains("tfrmt"))
    
    col_names <- names(gt_data)
    
    # multiple {gt} tables - extract each table and apply widths
    gt_with_widths <- gt::gt_group() # initialize
    
    for (i in gt$gt_tbls$i) {
      
      gt_table <- gt::grp_pull(gt, i)
      
      # Creating a symbolic representation of the column name and column width
      for (j in seq_along(col_names)) {
        
        col <- rlang::sym(col_names[j]) 
        
        if (col_names[j] %in% cols) {
          stat_coln <- which(cols == col_names[j])
          width <- col_widths[stat_coln]
          expr <- rlang::expr(!!col ~ gt::pct(!!width))
        } else {
          width <- other_widths 
          expr <- rlang::expr(!!col ~ gt::pct(!!width))
        } 
        
        gt_table <- gt::cols_width(gt_table, expr)
      }
      
      # combine tables back together
      gt_with_widths <- gt::grp_add(gt_with_widths, gt_table)
    }
  } else {
    gt_data <- gt$`_data` |> 
      select(-contains("tfrmt"))
    
    col_names <- names(gt_data)
    
    for (j in seq_along(col_names)) {
      
      col <- rlang::sym(col_names[j]) 
      
      if (col_names[j] %in% cols) {
        stat_coln <- which(cols == col_names[j])
        width <- col_widths[stat_coln]
        expr <- rlang::expr(!!col ~ gt::pct(!!width))
      } else {
        width <- other_widths 
        expr <- rlang::expr(!!col ~ gt::pct(!!width))
      }
      
      gt <- gt::cols_width(gt, expr)
    }
    
    gt_with_widths <- gt
  }
  
  return(gt_with_widths)
}

# Apply subtitle (above table) 
apply_subtitle <- function(gt, 
                           subtitle_text = "Test: Test A"
) {
  
  # Extract table from gt object
  if (class(gt)[1] == "gt_group") {
    
    # multiple {gt} tables - extract each table and apply subtitle
    gt_subtitle <- gt::gt_group() # initialize
    
    for (i in gt$gt_tbls$i) {
      
      gt_table <- gt::grp_pull(gt, i) |>
        gt::tab_header(
          title = "",
          subtitle = subtitle_text
        ) 
      
      # combine tables back together
      gt_subtitle <- gt::grp_add(gt_subtitle, gt_table)
    }
  } else {
    
    gt_subtitle <- gt |>
      gt::tab_header(
        title = "",
        subtitle = subtitle_text
      ) 
  }
  
  return(gt_subtitle)
}