library(McMasterPandemic)
library(tidyverse)

# source("calibrate_comb_setup.R")
## This is a very slow step because it is downloading large mobility csvs
# load("calibrate_comb_setup.rda")

stop_date <-  as.Date("2021-05-29")
stop_date <-  as.Date("2021-06-15")
stop_date <-  as.Date("2020-08-30")

cachedat <- readRDS("cachestuff/calibrate_comb_setup.rds")



calibrate_data <- (cachedat$calibrate_data_fill
	%>% filter(date <= stop_date)
	# %>% filter(var %in% c("report","H","death"))
	%>% filter(var %in% c("report"))
	%>% filter(date >= as.Date("2020-02-24"))
	%>% mutate(var = ifelse(var == "report", "postest", var))
	## first intensity cannot be zero
	%>% filter(date >= cachedat$test_data_fill$Date[which(cachedat$test_data_fill$intensity>0)[1]])
)

test_data_fill <- (cachedat$test_data_fill 
	%>% filter(Date >= cachedat$test_data_fill$Date[which(cachedat$test_data_fill$intensity>0)[1]]
			)
	%>% filter(Date >= as.Date("2020-02-24"))
	%>% filter(Date <= stop_date)
	

)

## loading parameters

params <- fix_pars(read_params("ON.csv")
	, target=c(R0=3, Gbar=6)	
	# , pars_adj=list(c("sigma","gamma_s","gamma_m","gamma_a"))
)

params[["E0"]] <- 5
params[["N"]] <- 14.57e6 ## Population of Ontario (2019)
params[["omega"]] <- 0.25

### What parameters do we want to optimize?

opt_pars <- list(#params=c(log_E0=2, log_beta0=-1, logit_mu = -1, logit_nonhosp_mort=-1)
	params=c(log_E0 = log(5)
		, log_beta0=log(5)
	  # , mu = 0.99
	)
	# , log_nb_disp = c(report=20, death=1,H=1)
	, log_nb_disp = c(report=20)
)

sim_args <- list(ratemat_args = list(testify=TRUE
	, testing_time="sample")
	, step_arg = list(testwt_scale = "N")
	, use_eigvec = NULL)


current <- do.call(calibrate_comb
		, c(nlist(params=params
		, debug_plot=FALSE
		, data = calibrate_data
		, mob_data = cachedat$clean_mobility
		, opt_pars = opt_pars
		, use_DEoptim = FALSE
		, DE_cores = 1
		, use_phenomhet = FALSE
		, use_mobility = TRUE
		# , mob_breaks = c("2020-04-01","2020-08-07","2020-10-01","2021-01-14","2021-03-01")
		, mob_breaks = c("2020-04-01","2020-08-07","2020-10-01","2021-01-14")
		, mob_breaks_int = TRUE
		, mob_logist_scale = 3
		, use_spline = FALSE
		, spline_type = "ns"
		, spline_df = NA
		, spline_days = 14
		, use_testing = TRUE
		, testing_dat = test_data_fill
		, sim_args = sim_args		
		)
	)
)

print(plot(current, data=cachedat$calibrate_data_fill) 
      + ggtitle("Current model: mobility")
      + scale_x_date(date_breaks = "1 month", date_labels = "%b"))

ont_calib_comb_reports_mobbreaks <- list(fit=current, data=calibrate_data_fill,mobdat=clean_mobility)
saveRDS(ont_calib_comb_reports_mobbreaks,"cachestuff/ont_calib_comb_mobbreaks.rds")
