library(McMasterPandemic)
library(tidyverse)
library(knitr)

base <- readRDS("cachestuff/ont_calib_comb_mobbreaks.rds")
testify <- readRDS("cachestuff/ont_calib_testify.rds")

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

base_table <- get_params_table(base$fit)
testify_table <- get_params_table(testify$fit)
base_table
testify_table
