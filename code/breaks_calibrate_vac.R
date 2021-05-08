use_local_data_repo <- FALSE
source("clean.R")
source("batchtools.R")

suppressMessages({
    library(McMasterPandemic)
    library(splines)
    library(dplyr)
    library(parallel)
    library(readr)
    library(gsheet)
    library(tidyr)
    library(zoo)
    library(furrr)
    library(future.batchtools)
    library(ggplot2)
})

trim_date <- as.Date("2020-09-15")

if(!exists("end_date")){
end_date <- as.Date(max(all_sub$date))
}

all_inputs <- read_csv("breaks.csv")

use_reference <- FALSE
if(!exists("use_reference")){
use_reference <- TRUE
}

immunity_lag <- 14
vac_effect <- 0.6
data_scale <- 1

vacdat <- data.frame(gsheet2tbl("https://docs.google.com/spreadsheets/d/1PjkemMdFSZgA-M8Esr6rbNjHiyfcXcBxPeMjselJIso/edit#gid=0"))


   info <- all_inputs %>% filter(province == "ON")
   print(info)
   prov = info[["province"]]
   params <- fix_pars(read_params(paste0(prov,".csv"))
                      , target = c(R0 = 1.3 , Gbar=6)
   )
   params[["obs_disp"]] <- 30
   # params[["obs_disp_report"]] <- 40
   # params[["obs_disp_H"]] <- 20
   # params[["obs_disp_ICU"]] <- 20
   
   
   params[["vacc"]] <- 1e-10
   
   # params[["proc_disp"]] <- 0.01
   
   
   # Retrieve break dates:
   bd <- as.Date(unlist(strsplit(info[["break_dates"]],split = ";")))
   n.bd = length(bd)
   # bd <- bd[as.Date(bd)<(max(as.Date(all_sub$date))-14)]
   
   bd
   clean_vac <- (vacdat
      %>% transmute(date = as.Date(data...date) + immunity_lag
                    , daily_vac = diff(c(0,data...total_vaccinations))
      )
      %>% filter(date %in% bd)
      %>% mutate(daily_vac = daily_vac/info$population/1e-10
                 , daily_vac = ifelse(is.na(daily_vac) | daily_vac==0,1,vac_effect*daily_vac*data_scale)
                 , daily_vac = ifelse(date < as.Date("2021-01-01"), 1, daily_vac)
                 )
   )
   print(clean_vac)
	
   summary(params)
	params[["N"]] <- info[["population"]]
		
	lgf <- function(x){log(x/(1-x))}
	
	opt_pars <- list(params = c(log_beta0= log(params[["beta0"]])
	# ,logit_mu = lgf(params[["mu"]])
	# , logit_phi1 = lgf(params[["phi1"]])
	)
		, rel_beta0 = c(0.8,0.9,0.7,0.6,1,0.7)
	  , rel_vacc = clean_vac$daily_vac
	
	)
	priors= list(  ~dnorm(rel_vacc[1], mean=clean_vac$daily_vac[1],sd=0.001)
	               , ~dnorm(rel_vacc[2], mean=clean_vac$daily_vac[2],sd=0.001)
	               , ~dnorm(rel_vacc[3], mean=clean_vac$daily_vac[3],sd=0.001)
	               , ~dnorm(rel_vacc[4], mean=clean_vac$daily_vac[4],sd=0.001)
	               , ~dnorm(rel_vacc[5], mean=clean_vac$daily_vac[5],sd=0.001)
	               , ~dnorm(rel_vacc[6], mean=clean_vac$daily_vac[6],sd=0.001)
	               # , ~dnorm(rel_vacc[7], mean=clean_vac$daily_vac[7],sd=0.001)
	               # , ~dnorm(rel_vacc[8], mean=clean_vac$daily_vac[8],sd=0.001)
	               # , ~dnorm(rel_mu[1], mean=0.8,sd=0.5)
	               # , ~dnorm(rel_mu[2], mean=0.8,sd=0.5)
	               # , ~dnorm(rel_mu[3], mean=0.8,sd=0.1)
	               # , ~dnorm(rel_mu[4], mean=0.8,sd=0.5)
	               # , ~dnorm(rel_mu[5], mean=0.6,sd=0.5)
	               # , ~dnorm(params[1],    mean=1,sd=0.5)
	)
	

	# Subset the data to the requested 
	# province and variables:
	province_dat <- (all_sub
      %>% group_by(var)
      %>% filter(province == info[["province"]])
      %>% filter(grepl(var, info[["vars"]]))
   )

	# Define time window
	start_date        <- trim_date
	start_date_offset <- 60
	date_vec <- as.Date(start_date:end_date)
	date_df <- data.frame(date = rep(date_vec,length(unique(province_dat[["var"]]))), 
	                      var  = rep(unlist(strsplit(info[["vars"]],"/")),each=length(date_vec))
   )
		
	dat <- (left_join(date_df, province_dat)
		%>% mutate(value = ifelse(value == 0, NA, value))
	)
	
	## ==== Model calibration ====
	
	fitdat <- dat
	
	## beta, gamma are the contraction and expansion
	## for the Nelder-Mead algo (default used here).
	## If reference params are used as starting values, 
	## we don't want the optimizer to wander too far from
	## those cherry picked values. Same if we start from
	## yesterday's values.
	## So, the expansion and contraction parameters should be 
	## reduced from their default values.
	
	limit_explore_optim <- FALSE
	
	NM.beta  = ifelse(limit_explore_optim, 0.8, 0.5)  # default = 0.5
	NM.gamma = ifelse(limit_explore_optim, 1.2, 2)    # default = 2.0
	
	res <- calibrate(
	    base_params  = params
	    , priors = priors
		, debug_plot = FALSE
		, debug      = FALSE
		, data       = fitdat
		, opt_pars   = opt_pars
		, DE_cores   = info$DE_cores
		, sim_args   = list(ndt = 2)
		, time_args  = list(break_dates = bd)
		, mle2_control = list(maxit  = 1e4,   # default = 1e4
		                      reltol = 1e-6,  # default ~ 1e-8
		                      beta   = NM.beta,
		                      gamma  = NM.gamma
		                      )   
		, start_date_offset = start_date_offset
		, use_DEoptim = FALSE
		)
	plot(res,data=fitdat)
	
## parameters getting passed straight through 
## from the data frame to calibrate_comb()
	res_list <- list(fit=res, inputs=info, trimdat = fitdat, fulldat=dat)
	saveRDS(object=res_list, 
	        file=paste0("./cachestuff/",end_date,".",prov,".vac_breaks.RDS"))
	