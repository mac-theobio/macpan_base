## point to OLD/stored MacPan
#.libPaths(c("Rlib", .libPaths()))
library(McMasterPandemic)
library(anytime)
#packageVersion("McMasterPandemic")
library(tidyverse)
library(shellpipes)

loadEnvironments()


mod <- rdsRead()

## mod <- readRDS("slow/ontario_calibrate_comb.rds")

fit <- mod$fit

## Hack end date
extend_days <- 30

nsims <- 1000

fit$forecast_args$end_date <- fit$forecast_args$end_date + extend_days 
## Need to freeze mobility?
# 
# fit$forecast_args$time_args$X_date <- c(fit$forecast_args$time_args$X_date
# 	, fit$forecast_args$time_args$X_date[length(fit$forecast_args$time_args$X_date)] + 1:30
# )
# 
# freeze_mob <- fit$forecast_args$time_args$X[rep(nrow(fit$forecast_args$time_args$X),30),]
# 
# fit$forecast_args$time_args$X <- rbind(fit$forecast_args$time_args$X
# 	, fit$forecast_args$time_args$X[rep(nrow(fit$forecast_args$time_args$X),30),]
# )

print(plot(fit,data=mod$data) + xlim(c(as.Date("2020-04-01"),as.Date("2020-09-30"))))

ensemble <- forecast_ensemble(fit, nsim=nsims, scale_Sigma = 10, raw_ensembles = TRUE)

forecast <- ensemble %>% filter(var %in% c("report","death","S","I","foi"))

saveVars(forecast, mod)

