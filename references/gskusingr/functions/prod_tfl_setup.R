
####----------------------------------------------------------------------####
# Program Name: prod_tfl_setup.R
# Compound/Project ID/Study: GSK5764227/61602/223054
#
# Developer: Harrison James / haj12129
#
# OS / R Version: Linux / Frozen 4.3
#
# Purpose: Create a list to setup R4PROD for TFLs
#
# Input: name of program, main ADaM dataset, title and display number
# Output: list of values/data to be used in prod program ("prod_items")
#
#-----------------------------------------------------------------------------

prod_tfl_setup <- function(pdf_name = NULL, dset = NULL, popdset = "addq", trtvar = "A", 
                           title = NULL, dsplynum = NULL) {
  
  if (is.null(pdf_name)) {
    stop("WARNING: PDF name is required - this is used for the name of PDF file.")
  }
  
  if (is.null(title)) {
    stop("WARNING: Title is required - this is printed in final PDF.")
  }
  
  if (is.null(dsplynum)) {
    stop("WARNING: Display number is required - this is printed in final PDF.")
  }
  
  if (trtvar != "A" & trtvar != "R") {
    stop("WARNING: Trtvar must be 'A' (actual) or 'R' (Randomised).")
  }
  
  writeLines(paste0("Title before updating is: ", title))
  writeLines(paste0("Display number before updating is: ", dsplynum))
  
  if (Sys.getenv("TFL_Delivery") == "Q3W MONO") {
    new_title <- paste0(title, " - Phase 1a Q3W Monotherapy")
    new_dsplynum <- paste0(dsplynum, "01")
    full_trt <- c(1, 2, 3, 4)
    
    if (!is.null(dset)) {
      if (trtvar == "A") {
        adam_in <- haven::read_sas(paste0(adamdata, dset, ".sas7bdat")) |>
          dplyr::filter(TRT01AN %in% full_trt)
      }
      
      if (trtvar == "R") {
        adam_in <- haven::read_sas(paste0(adamdata, dset, ".sas7bdat")) |>
          dplyr::filter(TRT01PN %in% full_trt)
      }
    }
    
    if (!is.null(popdset)) {
      if (trtvar == "A") {
        pop_in <- haven::read_sas(paste0(adamdata, popdset, ".sas7bdat")) |>
          dplyr::filter(TRT01AN %in% full_trt)
      }
      
      if (trtvar == "R") {
        pop_in <- haven::read_sas(paste0(adamdata, popdset, ".sas7bdat")) |>
          dplyr::filter(TRT01PN %in% full_trt)
      }
    }
  } else if (Sys.getenv("TFL_Delivery") == "Q2W MONO") {
    new_title <- paste0(title, " - Phase 1a Q2W Monotherapy")
    new_dsplynum <- paste0(dsplynum, "04")
    full_trt <- c(6, 7, 8, 9)
    
    if (!is.null(dset)) {
      if (trtvar == "A") {
        adam_in <- haven::read_sas(paste0(adamdata, dset, ".sas7bdat")) |>
          dplyr::filter(TRT01AN %in% full_trt)
      }
      
      if (trtvar == "R") {
        adam_in <- haven::read_sas(paste0(adamdata, dset, ".sas7bdat")) |>
          dplyr::filter(TRT0PAN %in% full_trt)
      }
    }
    
    if (!is.null(popdset)) {
      if (trtvar == "A") {
        pop_in <- haven::read_sas(paste0(adamdata, popdset, ".sas7bdat"))|>
          dplyr::filter(TRT01AN %in% full_trt)
      }
      
      if (trtvar == "R") {
        pop_in <- haven::read_sas(paste0(adamdata, popdset, ".sas7bdat")) |>
          dplyr::filter(TRT0PAN %in% full_trt)
      }
    }
  }
  
  writeLines(paste0("Title after updating is: ", new_title))
  writeLines(paste0("Display number after updating is: ", new_dsplynum))
  
  final <- list(
    pdf_name = pdf_name, 
    title = new_title, 
    dsplynum = new_dsplynum, 
    full_trt = full_trt,
    adam = adam_in, 
    adam_pop = pop_in
  )
  
  return(final)
}
