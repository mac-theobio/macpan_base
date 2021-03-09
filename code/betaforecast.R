library(McMasterPandemic)
library(tidyverse)
library(parallel)
library(shellpipes)
library(cowplot)
library(zoo)

flist <- list.files(path="cachestuff/",pattern="RDS")

## need to peg!
lift_frame <- data.frame(province = c("AB","BC","MB","ON","QC","SK")
   , lift_date = c("2020-11-20", "2020-11-15", "2020-11-10","2020-12-15","2020-12-15","2020-11-15")  
   , reopen_date = c("2021-06-01","2021-06-01","2021-03-04","2021-03-08","2021-02-26","2021-03-18")
   , voc_start = c("2020-12-17","2020-12-12","2021-02-02","2020-12-19","2020-12-22","2021-01-26")
   , pegprop = c(0.0015,0.001,0.0025,0.0042,0.0016,0.0025)
   , scale_factor = c(40,10,50,15,20,30)
)

betaforecast <- function(x,voc=FALSE, reopen_factor=1, Rmult=1){
 	tempmod <- readRDS(paste0("cachestuff/",x))
 	
 	end_date <- tempmod$fit$forecast_args$end_date
 	bd <- tempmod$fit$forecast_args$time_args$break_dates
 	last_break <- bd[length(bd)]
 	flip_date <- as.Date((as.numeric(end_date)+as.numeric(last_break))/2)
 	## getting all the switch dates
 	lift_date <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"lift_date"] %>% as.Date()
  scale_factor <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"scale_factor"]
 	voc_start <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"voc_start"] %>% as.Date()
 	reopen_date <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"reopen_date"] %>% as.Date()
 	pegprop <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"pegprop"] 
 	
 	## flip date is when do we switch to beta_avg instead of beta_hat
 	
 	
	dateframe <- data.frame(Date = seq.Date(from = tempmod$fit$forecast_args$start_date
		, to=tempmod$fit$forecast_args$end_date + 200,by=1)
		, Symbol = "beta0"
		, Relative_value = 1
		, VoCprop = 0
	)
  ## Create a dataframe such that the relative values are in place
	for(i in 1:length(tempmod$fit$forecast_args$time_args$break_dates)){
		for(j in 1:nrow(dateframe)){
			if(dateframe[j,"Date"] >= as.Date(tempmod$fit$forecast_args$time_args$break_dates[i])){
				dateframe[j,"Relative_value"] <- coef(tempmod$fit,"fitted")$rel_beta0[[i]]
			}
		}
	}
	
	## If we are reopening, increase transmission by reopen_factor

	dateframe <- (dateframe
	      %>% mutate(Relative_value = ifelse(Date >= as.Date(reopen_date),Relative_value*reopen_factor,Relative_value))
	   )
			
	## creating a dummy frame, probably don't need
	pp <- coef(tempmod$fit,"all")
	state <- make_state(params=pp)
	rr <- run_sim(pp
			, state
			, start_date=min(dateframe$Date)
			, end_date=max(dateframe$Date)
			, params_timevar = dateframe
			)
	
	cc <- coef(tempmod$fit,"fitted")
	all_cc <- coef(tempmod$fit,"all")
	logistic_fun <- function(r,t, p0=0.01){
	  p0/(p0+(1-p0)*exp(-r*t))
	}
	
	## calculate little r for each bt and bt*Rmult
	if(voc){
	  p0 = pegprop
	}
	if(!voc){
	  p0=0
	}
	
	dateframe0 <- (dateframe
	  %>% rowwise()
	  %>% mutate(ref_beta = Relative_value * as.numeric(cc$params["beta0"])
	    , VoC_beta = ref_beta*Rmult
	    , ref_r = get_r(update(all_cc,beta0=ref_beta))
	    , VoC_r = get_r(update(all_cc,beta0=VoC_beta))
	    , rdiff = VoC_r - ref_r
	    , VoCprop = ifelse(Date >= as.Date(voc_start),p0,VoCprop)
	    , bt_voc = 1
	   )
	)
	
	dateframe <- dateframe0 # %>% mutate(VoCprop = ifelse(VoCprop==p0,0.00004,VoCprop))
	
	## Stepping through and calculating bt_voc
	i <- 1
	while(i < nrow(dateframe)){
	  lf <- logistic_fun(r=dateframe$rdiff[i], t=1,p0=dateframe$VoCprop[i])
	  dateframe$bt_voc[i] <- ((1-lf)*dateframe$ref_beta[i] + lf*dateframe$VoC_beta[i])/cc$params["beta0"]
	  if(dateframe$VoCprop[i] != 0){
	  dateframe$VoCprop[i+1] <- lf
	  }
	  i <- i + 1
	}
	
	## Repegging to ~ mid point of the last bt_avg interval
	pegscale <- 1
	
	if(!is.null(flip_date)){
	  tempdf <- dateframe %>% dplyr::filter(Date == as.Date(as.character(flip_date)))
	  pegscale <- as.numeric(tempdf["bt_voc"]/tempdf["Relative_value"])
	}
	
	dateframe <- (dateframe
	  %>% mutate(tempvalue = bt_voc/pegscale
	    , Relative_value = ifelse(tempvalue>=Relative_value,tempvalue,Relative_value)
	    , final_bt = Relative_value * as.numeric(cc$params["beta0"])
	 )
	)
	dateframe = as.data.frame(dateframe)
	
	fa <- tempmod$fit$forecast_args
	fa$end_date <- max(dateframe$Date)
	fa$params_timevar <- dateframe
	fa$sim_fun <- run_sim
	fa$time_args <- NULL
	fa$sim_args <- NULL
	fa$extra_pars <- NULL
	rr <- forecast_ensemble(tempmod$fit
									 , nsim=200
									 , forecast_args = fa
									, scale_Sigma = scale_factor 
									, seed = 1
	)
	
	
	rr2 <- (rr 
		%>% mutate(province = tempmod$inputs$province
					, new_strain_fraction = p0
					, voc_start = voc_start
					, reopen_date = reopen_date
					, reopen_factor = reopen_factor
					, flip_date = flip_date
					, R0 = get_R0(coef(tempmod$fit,"all"))
					, pop = tempmod$inputs$population
		)
		%>% left_join(.,dateframe, by=c("date"="Date"))
	)
	return(rr2)
}

## No Lift
sim0<- mclapply(flist,function(y){betaforecast(x=y,voc=FALSE, reopen_factor = 1, Rmult = 1.5)},mc.cores=4)
sim1<- mclapply(flist,function(y){betaforecast(x=y,voc=TRUE, reopen_factor = 1, Rmult = 1.5)},mc.cores=4)
# sim2<- mclapply(flist,function(y){betaforecast(x=y,voc=TRUE, reopen_factor = 1.2, Rmult = 1.5)},mc.cores=4)

betaforecast_dat <- bind_rows(sim0,sim1,sim2)
use_local_data_repo <- FALSE
source("clean.R")

betaforecast_dat2 <- (all_sub
	%>% transmute(date, var, province,obs = value)
	%>% left_join(betaforecast_dat,.)
	%>% filter(date >= as.Date("2020-09-15"))
	# %>% mutate(obstype = ifelse(date>= as.Date("2020-12-19"),"new_obs","fitted"))
	%>% mutate( #new_strain_fraction = factor(new_strain_fraction)
		VoC_effect = ifelse(new_strain_fraction == 0,"Implicit","Replacement")
		# , obs = ifelse(date > as.Date("2021-02-21"),NA,obs)
		)
	# %>% filter(var %in% c("report"))
)

write.csv(betaforecast_dat2 %>% filter(var %in% c("report")),paste0("outputs/",end_date,"_VOC.csv"))

## Ontario
Ontario_dat <- betaforecast_dat2 %>% filter(province == "ON") %>% filter(var %in% c("report","S"))
write.csv(Ontario_dat,paste0("~/workspace/mac/MacOMT_report/forecast/",end_date,"_VOC.csv"))


simple_dat <- (betaforecast_dat2
  %>% filter(var %in% c("report"))
  %>% select(date, lwr, value, upr, province, VoC_effect,reopen_date,reopen_factor)    
)
write.csv(simple_dat,paste0("outputs/simple_VOC_",end_date,".csv"))
