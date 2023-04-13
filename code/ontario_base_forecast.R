## point to OLD/stored MacPan
.libPaths(c("Rlib", .libPaths()))
library(McMasterPandemic)
packageVersion("McMasterPandemic")
library(tidyverse)
library(shellpipes)

mod <- readRDS("code/cachestuff/ont_calib_comb_mobbreaks.rds")

fit <- mod$fit

## Hack end date
extend_days <- 30

fit$forecast_args$end_date <- fit$forecast_args$end_date + extend_days 
## MLi: need to increase scale_Sigma to get something sensible

ensemble <- forecast_ensemble(fit, nsim=1000, scale_Sigma = 1000)

forecast <- ensemble %>% filter(var %in% c("report","death"))

saveVars(forecast, mod)

