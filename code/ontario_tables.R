library(McMasterPandemic)
library(tidyverse)
library(knitr)
library(shellpipes)

base <- readRDS("code/cachestuff/ont_calib_comb_mobbreaks.rds")
testify <- readRDS("code/cachestuff/ont_calib_testify.rds")

beautify <- function(x) {
    x[,"symbol"] <- texify(as.character(x[,"symbol"]), force=TRUE)
    return(x)
}

get_params_table <- function(x){
    coef_table <- data.frame()
    cc <- coef(x,"fitted")
    for(i in names(cc)){
        tempdat <- data.frame(type = i
                            , pars = names(cc[[i]])
                            , value = cc[[i]]
                              )
        coef_table <- bind_rows(tempdat,coef_table)
        rownames(coef_table) <- NULL
    }
    return(coef_table)
}

breakpoints <- c("Apr 01", "Apr 07")
par_names <- c(
    sprintf("Relative change in transmission after %s", breakpoints)
  , "Mobility power"
  , sprintf("Change in mobility power after %s", breakpoints)
  , sprintf("Negative binomial dispersion parameter (%s)",
            c("case reports", "deaths"))
  , "Initial number exposed"
  , "Transmission rate"
  , "Non-hospitalized mortality probability"
  , "Exponent of phenomenological response  to susceptible depletion"
)

testify_table <- get_params_table(testify$fit)

mk_table <- function(fit, par_names) {
    (fit
    |> get_params_table()
    |> transmute(names = par_names, value)
    |> mutate(across(value, ~pmin(., 1000))) ## truncate NB dispersions - don't mess up formatting for everyone else
    |> mutate(fval = format(round(value, 3)))
    |> mutate(across(fval, ~ ifelse(value == 1000, "$\\gg 1000$", .)))
    |> select(-value)
    |> setNames(c("Parameter", "Estimate"))
    )
}

write_table <- function(table, fn) {
    invisible(Hmisc::latex(table
                         , col.just = c("l", "r")
                         , collabel.just=c("l","r")
                         , rowname = NULL
                         , file = fn
                         , table.env = FALSE
                           ))
}

base_pardf <- mk_table(base$fit, par_names)
write_table(base_pardf, "base_table.tex")

testify_pardf <- mk_table(testify$fit,
                          grep("(death|mortality)", par_names, invert = TRUE, value = TRUE))


write_table(testify_pardf, "testify_table.tex")

pp <- update(read_params("PHAC_testify.csv"), testing_intensity=0) # reads from pkg if not found locally
attr(pp,"description") <- NULL
descr <- suppressWarnings(describe_params(pp))

lit_param_table <- (
    descr
    |> dplyr::filter(!(symbol %in% c("beta0","N","E0","Multiple","mu","iso_m","iso_s")))
    |> dplyr::select(meaning, value)
    |> setNames(c("Parameter", "Value"))
)

write_table(lit_param_table, "litparmtab.tex")


