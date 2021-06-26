library(McMasterPandemic)
library(tidyverse)

source("calibrate_comb_setup.R")
# load("calibrate_comb_setup.rda")

stop_date <-  as.Date("2021-05-29")
stop_date <-  as.Date("2021-06-15")


calibrate_data <- (calibrate_data_fill
	%>% filter(date <= stop_date)
	%>% filter(var == "report")
	%>% filter(date >= as.Date("2020-02-25"))
	# %>% mutate(var = ifelse(var == "report", "postest", var))
	## first intensity cannot be zero
	# %>% filter(date >= test_data_fill$Date[which(test_data_fill$intensity>0)[1]])
)

# test_data_fill <- test_data_fill %>% filter(Date >= test_data_fill$Date[which(test_data_fill$intensity>0)[1]])


## loading parameters

params <- fix_pars(read_params("ON.csv")
	, target=c(R0=3, Gbar=6)	
	# , pars_adj=list(c("sigma","gamma_s","gamma_m","gamma_a"))
)

params[["E0"]] <- 5
params[["N"]] <- 14.57e6 ## Population of Ontario (2019)

### What parameters do we want to optimize?

opt_pars <- list(#params=c(log_E0=2, log_beta0=-1, logit_mu = -1, logit_nonhosp_mort=-1)
	params=c(log_E0 = log(5)
		, log_beta0=log(5))
	# , log_nb_disp = c(report=20, death=1,H=1)
	, log_nb_disp = c(report=20)
)


current <- do.call(calibrate_comb
		, c(nlist(params=params
		, debug_plot=FALSE
		, data = calibrate_data
		, mob_data = clean_mobility
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
		, use_testing = FALSE
		)
	)
)

print(plot(current, data=calibrate_data_fill) 
      + ggtitle("Current model: PH + mobility cap")
      + scale_x_date(date_breaks = "1 month", date_labels = "%b"))

ont_calib_comb <- list(fit=current, data=calibrate_data_fill,mobdat=clean_mobility)
saveRDS(ont_calib_comb,"cachestuff/ont_calib_comb.rds")
