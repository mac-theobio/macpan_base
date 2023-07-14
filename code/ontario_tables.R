library(McMasterPandemic)
library(tidyverse)
library(knitr)
library(shellpipes)

base <- rdsRead("ontario_calibrate")
testify <- rdsRead("ontario_testify")

cap_first <- function(x) gsub("^(.)", "\\U\\1", x, perl = TRUE)

## Existing param descriptions and symbols
base_param_vals <- (describe_params(coef(base$fit))
    |> mutate(across(meaning, cap_first))
    |> select(symbol, meaning)
)

## add descriptions for params not covered in original model
breakpoints <- c("Apr 01", "Aug 07")
rep_type <- c("report", "death", "postest")
new_par_tab <- tibble(
    orig_symbol = c(rep_type   ## these how the nb disp params show up
                  , paste0("mob_logist", 1:2)
                  , paste0("log(rel_activity):mob_logist", 0:2)
                    ),
    symbol = c(sprintf("\\theta_\\textrm{%s}", rep_type)
               ## ugh, texify is badly hard-coded
                 , sprintf("beta_{%d}", 1:2)
                 , sprintf("beta_{\\textrm{mob},%d}", 0:2)
                   ),
    meaning = c(
        sprintf("Negative binomial dispersion parameter (%s)",
                c("case reports", "deaths", "positive tests"))
      , sprintf("Relative change in transmission after %s", breakpoints)
      , "Mobility power"
      , sprintf("Change in mobility power after %s", breakpoints)
    )
)

beautify <- function(x, sname = "symbol") {
    x[[sname]] <- texify(as.character(x[[sname]]), force=TRUE)
    return(x)
}


get_params_table <- function(x) {
    res <- (coef(x, "fitted")
        |> purrr::map_dfr(~tibble(pars = names(.), value = .),
                             .id = "type")
        |> left_join(base_param_vals,  by = c("pars" = "symbol"))
    )
    newpars <- is.na(res$meaning)
    newinds <- na.omit(match(res$pars[newpars], new_par_tab$orig_symbol))
    res$pars[newpars] <- new_par_tab$symbol[newinds]
    res$meaning[newpars] <- new_par_tab$meaning[newinds]
    select(res, -type)
}

mk_table <- function(fit, par_names) {
    (fit
        |> get_params_table()
        |> beautify(sname = "pars")
        |> mutate(across(pars, ~ gsub("nonhosp_mort", "\\eta", .)))     ## no beautiful symbol defined, make one up
        |> mutate(across(value, ~pmin(., 1000))) ## truncate NB dispersions - don't mess up formatting for everyone else
        |> mutate(fval = format(round(value, 3)))
        |> mutate(across(fval, ~ ifelse(value == 1000, "$\\gg 1000$", .)))
        |> transmute(Parameter = pars, Estimate = fval, Meaning = meaning) 
    )
}

write_table <- function(table, fn) {
    invisible(Hmisc::latex(table
                         , col.just = c("c", "r", "l")
                         , collabel.just=c("c", "r", "l")
                         , rowname = NULL
                         , file = fn
                         , table.env = FALSE
                           ))
}

write_table2 <- function(table, fn) {
	invisible(Hmisc::latex(table
												 , col.just = c("c", "r", "r", "l")
												 , collabel.just=c("c", "r", "r", "l")
												 , rowname = NULL
												 , file = fn
												 , table.env = FALSE
	))
}


base_pardf <- mk_table(base$fit, par_names)
write_table(base_pardf, "base_table.tex")

testify_pardf <- mk_table(testify$fit,
                          grep("(death|mortality)",
                               par_names, invert = TRUE, value = TRUE))

write_table(testify_pardf, "testify_table.tex")

## combine base and testify pardf?

combo_pardf <- (data.frame(Parameter = c(base_pardf[["Parameter"]],testify_pardf[["Parameter"]]))
	%>% distinct()
	%>% left_join(.,base_pardf %>% setNames(paste0('Base ', names(.))), by=c("Parameter"="Base Parameter"))
	%>% left_join(.,testify_pardf %>% setNames(paste0('Testify ', names(.))), by=c("Parameter"="Testify Parameter"))
	%>% transmute(Parameter, `Base Estimate`, `Testify Estimate`								
								, Meaning = ifelse(is.na(`Base Meaning`),`Testify Meaning`,`Base Meaning`))
)

print(combo_pardf)

combo_pardf <- combo_pardf[c(1:4,12,5:11),]

write_table2(combo_pardf, "combo_table.tex")


pp <- update(read_params("PHAC_testify.csv"), testing_intensity=0) # reads from pkg if not found locally
attr(pp,"description") <- NULL
descr <- suppressWarnings(describe_params(pp))

lit_param_table <- (
    descr
    |> dplyr::filter(!(symbol %in% c("beta0","N","E0","Multiple","mu","iso_m","iso_s", "zeta")))
    |> mutate(across(meaning, ~ gsub("([LN][A-Z]+)", "\\L\\1", ., perl = TRUE)))  ## hack to lowercase LATENT and NOT in param desc
    |> mutate(across(meaning, cap_first))
    |> beautify()
    |> transmute(Parameter = symbol, Value = value, Meaning = meaning)
)

write_table(lit_param_table, "litparm_table.tex")


