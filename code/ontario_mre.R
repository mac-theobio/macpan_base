source("clean.R")
source("batchtools.R")

library(McMasterPandemic)
library(splines)
library(dplyr)
library(parallel)
library(readr)
library(tidyr)
library(zoo)
library(furrr)
library(future.batchtools)
library(ggplot2)

trim_date <- as.Date("2020-09-15")

if(!exists("end_date")){
  end_date <- as.Date(max(all_sub$date))
}

# break dates
all_inputs <- read_csv("breaks.csv")

info <- all_inputs %>% filter(province_name == "Ontario")

params <- fix_pars(read_params("ON.csv"), target = c(R0 = 1.3 , Gbar=6))
  
bd <- as.Date(unlist(strsplit(info[["break_dates"]],split = ";")))
n.bd = length(bd)

summary(params)
params[["N"]] <- info[["population"]]
  
## transform such that initial parameter starts from params
lgf <- function(x){log(x/(1-x))}
  

## creating a time_pars frame, maybe even add priors as another column?
time_pars <- data.frame(Date=rep(bd,2)
  , Symbol=rep(c("beta0","mu"),each=length(bd))
  , Relative_value=rep(1,length(bd)*2)
)
  
opt_pars <- list(params = c(log_beta0= log(params[["beta0"]])
    ,logit_mu = lgf(params[["mu"]])
    , logit_phi1 = lgf(params[["phi1"]])
    )
  , log_value = log(time_pars$Relative_value) ## relative value
  , log_nb_disp = NULL
)
  
province_dat <- (all_sub
  %>% group_by(var)
  %>% filter(province == info[["province"]])
  %>% filter(grepl(var, info[["vars"]]))
)
  
  # Define time window
start_date <- trim_date
start_date_offset <- 60
date_vec <- as.Date(start_date:end_date)
date_df <- data.frame(date = rep(date_vec,length(unique(province_dat[["var"]]))), 
  var  = rep(unlist(strsplit(info[["vars"]],"/")),each=length(date_vec))
)
  
dat <- (left_join(date_df, province_dat)
  %>% mutate(value = ifelse(value == 0, NA, value))
)
  
  
fitdat <- dat
  
### Do not run the calibration.
### Here is the finish produce 



run <- FALSE

res_list <- readRDS("cachestuff/2021-05-18.ON.breaks.RDS")

plot(res_list$fit,data=res_list$trimdat)

if(run){
res <- calibrate(base_params  = params
  , time_args=list(break_dates=time_pars$Date, Symbol=time_pars$Symbol)
  , debug_plot = FALSE
  , debug      = FALSE
  , data       = fitdat
  , opt_pars   = opt_pars
  , sim_args   = list(ndt = 2)
  , start_date_offset = start_date_offset
  , use_DEoptim = FALSE
  , DE_cores = 4
)
    
plot(res,data=fitdat)
  
res_list <- list(fit=res, inputs=info, trimdat = fitdat, fulldat=dat)
saveRDS(object=res_list, file=paste0("./cachestuff/",end_date,".ON.breaks.RDS"))
}
