suppressMessages({
    library(McMasterPandemic)
    library(tidyverse)
    library(parallel)
})

# load('end_date.RData')
nsims <- 500

flist <- list.files(path="cachestuff/",pattern="RDS")

flist <- flist[grepl("breaks",flist)]

for(i in flist){
 	tempmod <- readRDS(paste0("cachestuff/",i))
 	dd <- data.frame(parameters = names(coef(tempmod$fit,"all"))
 		, value=c(coef(tempmod$fit,"all"))
 	, row.names = NULL)
 	cc <- coef(tempmod$fit,"fitted")
 	bddat <- data.frame(parameters = sapply(1:length(cc$rel_beta0),function(x){paste0("rel_beta_",x)})
 		, value = cc$rel_beta0
 	)
 	datedat <- data.frame(parameters = "date", value = as.character(end_date))
 	paramdat <- rbind(datedat,dd,bddat)
 	# write.csv(paramdat,paste0("outputs/",tempmod$inputs$province,".params.csv"))
 	
 	maxdate <- max(tempmod$trimdat$date)
	print(plot(tempmod$fit, data=tempmod$trimdat))
}

forecast_dat <- function(x,raw_ensembles=FALSE){
	modlist <- readRDS(paste0("cachestuff/",x))
	print(x)
	start_date_offset <- 60
		mle2Sigma <- bbmle::vcov(modlist$fit$mle2)
		# mle2Sigma <- Matrix::nearPD(mle2Sigma)$mat
		fit_de <- attributes(modlist$fit)
		deSigma <- fit_de$de$member$Sigma
		ensembles <- predict(modlist$fit
								, ensemble = TRUE
								, start_date = min(modlist$trimdat$date)- start_date_offset
								, end_date = max(modlist$trimdat$date)+ 365
								, stoch = c(proc =FALSE, obs = TRUE)
								, Sigma = mle2Sigma
								# , scale_Sigma = .001
								, nsim = nsims
								, new_params = c(obs_disp=1000)
								, stoch_start = c(proc=max(modlist$trimdat$date)+1, obs=min(modlist$trimdat$date)-start_date_offset)
								, keep_vars = c("report","ICU","H","death")
								, raw_ensembles=raw_ensembles
		)

	if(raw_ensembles){
		combodat <- (ensembles
			%>% mutate(trim = ifelse(grepl("short",x),"short","full")
				, convergence_code = modlist$fit$mle2@details$convergence
				, province_name = modlist$inputs$province_name
			)
			%>% left_join(.,modlist$fulldat)
			%>% filter(date >= min(modlist$trimdat$date))
			%>% mutate(type = ifelse(date <= max(modlist$trimdat$date),"fit","new")
				, reporting_fraction = coef(modlist$fit,"all")[["c_prop"]]
				)
		)
	return(combodat)
	}
	
	combodat <- (ensembles
		%>% transmute(date = date
			, var
			, lwr
			, med = value
			, upr
			, trim = ifelse(grepl("short",x),"short","full")
			, convergence_code = modlist$fit$mle2@details$convergence
			, province_name = modlist$inputs$province_name
			)
		%>% left_join(.,modlist$fulldat)
		%>% filter(date >= min(modlist$trimdat$date))
		%>% mutate(type = ifelse(date <= max(modlist$trimdat$date),"fit","new")
		)
	)
	return(combodat)
}

ensembles_list <- mclapply(X=flist,FUN=function(x){forecast_dat(x,raw_ensembles = FALSE)},mc.cores = 3)
ensembles_dat <- bind_rows(ensembles_list)
write.csv(ensembles_dat,paste0("cachestuff/breaks.forecast.csv"))

table(ensembles_dat$province)




