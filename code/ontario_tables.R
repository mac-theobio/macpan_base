library(McMasterPandemic)
library(tidyverse)
library(knitr)
library(shellpipes)

base <- readRDS("code/cachestuff/ont_calib_comb_mobbreaks.rds")
testify <- readRDS("code/cachestuff/ont_calib_testify.rds")

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

testify_pardf <- data.frame(pars = testify_table$pars
	, names = c("Mobility Intercept Apr 01"
		, "Mobility Intercept Aug 07"
		, "Mobility Slope"
		, "Mobility Slope Apr 01"
		, "Mobility Slope Aug 07"
		, "Observation Error"
		, "E0"
		, "Beta0"
		, "Zeta"
	)
)

base_pardf <- data.frame(pars = base_table$pars
	, names = c("Mobility Intercept Apr 01"
			, "Mobility Intercept Aug 07"
			, "Mobility Slope"
			, "Mobility Slope Apr 01"
			, "Mobility Slope Aug 07"
			, "Observation Error Report"
			, "Observation Error Death"
			, "E0"
			, "Beta0"
			, "Non-hospitalized Mortality"
			, "Zeta"
	)
)

base_table_rename <- (left_join(base_table,base_pardf)
	%>% transmute(NULL
			, Parameter = names
			, Estimate = ifelse(value > 1000,1000,value)
			, Estimate = as.character(format(round(Estimate,3)),nsmall=3)
			, Estimate = ifelse(as.numeric(Estimate) == 1e3, "\\gg 1000",Estimate)
	)
)

print(base_table_rename)

testify_table_rename <- (left_join(testify_table,testify_pardf)
	%>% rowwise()
	%>% transmute(NULL
		, Parameter = names
		, Estimate = as.character(format(round(value,3)),nsmall=3)
		, Estimate = ifelse(as.numeric(Estimate) > 1e3, "\\gg 1000",Estimate)
	)
)

testify_table_rename

cat(kable(base_table_rename,format="latex",align = "c")
		, file = "base_table.tex"		
)
cat(kable(testify_table_rename,format="latex",align = "c")
	, file = "testify_table.tex"		
)


saveVars(testify_table_rename)


