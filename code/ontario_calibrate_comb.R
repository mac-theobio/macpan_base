library(McMasterPandemic)
library(tidyverse)
library(shellpipes)

loadEnvironments()

stop_date <-  as.Date("2020-08-30")

cachedat <- rdsRead()

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
## params[["log_nb_disp"]] = c(report=30, death=15)

params[["N"]] <- 14.57e6 ## Population of Ontario (2019)

args(calibrate_comb)

### What parameters do we want to optimize?

opt_pars <- list(#params=c(log_E0=2, log_beta0=-1, logit_mu = -1, logit_nonhosp_mort=-1)
	params=c(log_E0 = log(5)
		, log_beta0=log(5)
		# , mu = 0.8
		, logit_nonhosp_mort = -0.5
		)
	# , log_nb_disp = c(report=30, death=15)
)

## Try holding these constant to simplify JD 2023 Sep 11 (Mon)
fixed_pars <- list(
	log_nb_disp = c(report=30, death=15)
)

mob_breaks <- c("2020-04-01","2020-08-07")

current <- do.call(calibrate_comb
		, c(nlist(params=params
		, debug_plot=FALSE
		, data = calibrate_data
		, mob_data = cachedat$clean_mobility
		, opt_pars = opt_pars
		, fixed_pars = fixed_pars
		, use_DEoptim = FALSE
		## , DE_cores = 3
		, use_phenomhet = TRUE
		, use_mobility = TRUE
		, mob_breaks = mob_breaks
		, mob_breaks_int = TRUE
		, mob_logist_scale = 3
		, use_spline = FALSE
		## , spline_type = "ns" , spline_df = NA , spline_days = 14
		, use_testing = FALSE
		)
	)
)

# print(plot(current, data=filter(cachedat$calibrate_data_fill,date <= as.Date("2020-09-01"))) 
#      + ggtitle("Current model: mobility")
#      + scale_x_date(date_breaks = "1 month", date_labels = "%b"))

ont_calib_comb_reports_mobbreaks <- list(fit=current, data=cachedat$calibrate_data_fill,mobdat=cachedat$clean_mobility, breakpoints = mob_breaks)

rdsSave(ont_calib_comb_reports_mobbreaks)
