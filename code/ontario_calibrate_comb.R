library(McMasterPandemic)
library(tidyverse)

run <- FALSE
save <- FALSE

if(run){

# source("calibrate_comb_setup.R")
## This is a very slow step because it is downloading large mobility csvs
# load("calibrate_comb_setup.rda")

stop_date <-  as.Date("2020-08-30")

cachedat <- readRDS("code/cachestuff/calibrate_comb_setup.rds")



calibrate_data <- (cachedat$calibrate_data_fill
	%>% filter(date <= stop_date)
	%>% filter(var %in% c("report","death"))
	%>% filter(date >= as.Date("2020-02-24"))
)


## loading parameters

params <- fix_pars(read_params("code/ON.csv")
	, target=c(R0=3, Gbar=6)	
)


## Clean or relocate this?
params[["E0"]] <- 5
params[["mu"]] <- 0.85
params[["rho"]] <- 1/10
params[["delta"]] <- 0.2

params[["N"]] <- 14.57e6 ## Population of Ontario (2019)

### What parameters do we want to optimize?

opt_pars <- list(#params=c(log_E0=2, log_beta0=-1, logit_mu = -1, logit_nonhosp_mort=-1)
	params=c(log_E0 = log(5)
		, log_beta0=log(5)
		# , mu = 0.8
		, logit_nonhosp_mort = -0.5
		)
	, log_nb_disp = c(report=30, death=15)
	# , log_nb_disp = c(report=30, death=10)
	# , log_nb_disp = c(report=20)
)


current <- do.call(calibrate_comb
		, c(nlist(params=params
		, debug_plot=FALSE
		, data = calibrate_data
		, mob_data = cachedat$clean_mobility
		, opt_pars = opt_pars
		, use_DEoptim = FALSE
		, DE_cores = 1
		, use_phenomhet = TRUE
		, use_mobility = TRUE
		# , mob_breaks = c("2020-04-01","2020-08-07","2020-10-01","2021-01-14","2021-03-01")
		# , mob_breaks = c("2020-04-01","2020-08-07","2020-10-01","2021-01-14")
		, mob_breaks = c("2020-04-01","2020-08-07")
		, mob_breaks_int = TRUE
		, mob_logist_scale = 3
		, use_spline = FALSE
		, spline_type = "ns"
		, spline_df = NA
		, spline_days = 14
		, use_testing = FALSE
		)
	)
)

print(plot(current, data=filter(cachedat$calibrate_data_fill,date <= as.Date("2020-09-01"))) 
      + ggtitle("Current model: mobility")
      + scale_x_date(date_breaks = "1 month", date_labels = "%b"))
}

if(save){
ont_calib_comb_reports_mobbreaks <- list(fit=current, data=cachedat$calibrate_data_fill,mobdat=cachedat$clean_mobility)
saveRDS(ont_calib_comb_reports_mobbreaks,"code/cachestuff/ont_calib_comb_mobbreaks.rds")
}
