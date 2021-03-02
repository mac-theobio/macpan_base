library(McMasterPandemic)
library(tidyverse)
library(parallel)
library(shellpipes)
library(cowplot)

flist <- list.files(path="cachestuff/",pattern=paste0(end_date,"[.]"))


lift_frame <- data.frame(province = c("AB","BC","MB","ON","QC","SK")
   , lift_date = c("2020-11-20", "2020-11-15", "2020-11-10","2020-12-15","2020-12-15","2020-11-15")  
   , voc_start = c("2020-12-18","2020-12-18","2021-02-01","2020-12-18","2020-12-18","2021-01-24")
   , flip_date = c("2021-02-01","2021-02-01","2021-02-10","2021-02-01","2021-02-01","2021-02-10")
   , scale_factor = c(40,10,30,20,30,10)
)

betaforecast <- function(x,p0 = 0, lift_start = NULL,reduction=0){
 	tempmod <- readRDS(paste0("../macpan_forecast/cachestuff/",x))
 	
 	## getting all the switch dates
 	lift_date <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"lift_date"] %>% as.Date()
  scale_factor <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"scale_factor"]
 	voc_start <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"voc_start"] %>% as.Date()
 	flip_date <- (lift_frame %>% filter(province == tempmod$inputs$province))[,"flip_date"] %>% as.Date()
 	
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
	
	## If we are lifting, we are going to revert bt back to that date 
	if(!is.na(lift_start)){
	   rel_lift <- filter(dateframe,Date == as.Date(lift_date))[,"Relative_value"]
	   dateframe <- (dateframe
	      %>% mutate(Relative_value = ifelse(Date >= as.Date(lift_start),rel_lift,Relative_value))
	   )
	   
	}
			
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
	
	## calculate little r for each bt and bt*1.5
	
	
	dateframe <- (dateframe
	  %>% rowwise()
	  %>% mutate(ref_beta = Relative_value * as.numeric(cc$params["beta0"])
	    , VoC_beta = ref_beta*1.5      
	    , ref_r = get_r(update(all_cc,beta0=ref_beta))
	    , VoC_r = get_r(update(all_cc,beta0=VoC_beta))
	    , rdiff = VoC_r - ref_r
	    , VoCprop = ifelse(Date >= as.Date(voc_start),p0,VoCprop)
	    , t = as.numeric(Date - voc_start)
	    , bt_voc = 1
	   )
	)
	
	## Stepping through and calculating bt_voc
	
	for(i in 2:nrow(dateframe)){
	  lf <- logistic_fun(r=dateframe$rdiff[i], t=dateframe$t[i],p0=dateframe$VoCprop[i])
	  dateframe$bt_voc[i] <- ((1-lf)*dateframe$ref_beta[i] + lf*dateframe$VoC_beta[i])/cc$params["beta0"]
	  dateframe$VoCprop[i] <- lf
	}
	
	## Repegging to ~ mid point of the last bt_avg interval
	pegscale <- 1
	
	if(!is.null(flip_date)){
	  tempdf <- dateframe %>% filter(Date == as.Date(flip_date))
	  pegscale <- as.numeric(tempdf["bt_voc"]/tempdf["Relative_value"])
	}
	
	dateframe <- (dateframe
	  %>% mutate(tempvalue = bt_voc/pegscale
	    , Relative_value = ifelse(tempvalue>=Relative_value,tempvalue,Relative_value)
	 )
	)
	dateframe = as.data.frame(dateframe)
	
	## This is kind of bad code, it needs a strong if condition
	## If we are lifting, how much reduction do we need (i.e. the blue curve on public slide)
	
	if(!is.na(lift_start)){
	dateframe <- (dateframe 
      %>% mutate(Relative_value = ifelse(Date >= as.Date(lift_start)
         , Relative_value*(1-reduction)
         , Relative_value
         )
      )
	)
	}
	
	fa <- tempmod$fit$forecast_args
	fa$end_date <- max(dateframe$Date)
	fa$params_timevar <- dateframe
	fa$sim_fun <- run_sim
	fa$time_args <- NULL
	fa$sim_args <- NULL
	fa$extra_pars <- NULL
	rr <- forecast_ensemble(tempmod$fit
									 , nsim=300
									 , forecast_args = fa
									, scale_Sigma = scale_factor 
									, seed = 1
	)
	
	
	rr2 <- (rr 
		%>% mutate(province = tempmod$inputs$province
					, new_strain_fraction = p0
					, voc_start = voc_start
					, lift_start = lift_start
					, lift_date = lift_date
					, flip_date = flip_date
					, reduction = reduction
					, R0 = get_R0(coef(tempmod$fit,"all"))
					, pop = tempmod$inputs$population
		)
		%>% left_join(.,dateframe, by=c("date"="Date"))
	)
	return(rr2)
}

## No Lift
sim0<- mclapply(flist,function(y){betaforecast(x=y,p0=0.0, lift_start = NA, reduction = 0)},mc.cores=4)
sim1<- mclapply(flist,function(y){betaforecast(x=y,p0=0.005, lift_start = NA, reduction = 0)},mc.cores=4)

betaforecast_dat <- bind_rows(sim0,sim1)
use_local_data_repo <- FALSE
source("clean.R")

betaforecast_dat2 <- (all_sub
	%>% transmute(date, var, province,obs = value)
	%>% left_join(betaforecast_dat,.)
	%>% filter(date >= as.Date("2020-09-15"))
	# %>% mutate(obstype = ifelse(date>= as.Date("2020-12-19"),"new_obs","fitted"))
	%>% mutate( #new_strain_fraction = factor(new_strain_fraction)
		VoC_effect = ifelse(new_strain_fraction == 0,"Implicit","Replacement")
		, Maintained = ifelse(is.na(lift_start),"Yes","No")
		, obs = ifelse(date > as.Date("2021-02-21"),NA,obs)
		)
	%>% filter(var %in% c("report"))
)

write.csv(betaforecast_dat2,paste0("outputs/",end_date,"_VOC.csv"))
simple_dat <- (betaforecast_dat2
  %>% select(date, lwr, value, upr, province, VoC_effect)               
)
write.csv(simple_dat,paste0("outputs/simple_VOC_",end_date,".csv"))


betaforecast_datx <- (betaforecast_dat2
   # %>% mutate(voc_start = ifelse(voc_start == "No VoC", "No VoC", "VoC"))
   # %>% filter(voc_start != "No VoC")
)

obs_dat <- (all_sub
  %>% filter(var == "report")
  %>% filter(province %in% c("BC","AB","SK","MB","ON","QC"))
  %>% transmute(date, var, province,obs = value)
  
)


ggx <- (ggplot(betaforecast_datx,aes(x=date))
	+ geom_line(aes(y=value,color=VoC_effect),size=2)
	+ geom_ribbon(aes(ymin=lwr,ymax=upr,fill=VoC_effect),alpha=0.2,guide=FALSE)
	+ scale_color_manual(values=c("purple","gray","blue","black","black"))
	+ scale_fill_manual(values=c("purple","gray","blue","black","black"))
	+ theme_bw()
		+ theme(legend.position = "bottom"
			  # , legend.box="vertical"
   , axis.text=element_text(size=14)
	, strip.text.x = element_text(size = 14)
	)
	+ xlab("")
	+ scale_x_date(date_minor_breaks = "1 week"
			, breaks = "1 month"
			, date_labels = "%b"
			, limits = c(as.Date("2020-10-01"),as.Date("2021-05-01"))
	)
	+ ylab("Daily Report")
	# + geom_vline(xintercept = as.Date("2021-02-15"))
	+ facet_wrap(~province,scale="free")

)


print(bc <-  ggx %+% (filter(betaforecast_datx, (province=="BC")))
		+ coord_cartesian(ylim = c(1, 3000)
	, xlim = c(as.Date("2020-10-01"),as.Date("2021-05-01"))
	)
	+ geom_point(data=filter(obs_dat,province == "BC"),aes(y=obs),size=2)
)

ggsave("figures/bc.png",width = 10,height = 6)

print(ab <-  ggx %+% (filter(betaforecast_datx, (province=="AB")))
		+ coord_cartesian(ylim = c(1, 3000)
								, xlim = c(as.Date("2020-10-01"),as.Date("2021-05-01"))
		)
		+ geom_point(data=filter(obs_dat,province == "AB"),aes(y=obs),size=2)
		)

ggsave("figures/ab.png",width = 10,height = 6)

print(sk <-  ggx %+% (filter(betaforecast_datx, (province=="SK")))
		+ coord_cartesian(ylim = c(1, 1000)
								, xlim = c(as.Date("2020-10-01"),as.Date("2021-05-01"))
		)
		+ geom_point(data=filter(obs_dat,province == "SK"),aes(y=obs),size=2)
)

ggsave("figures/sk.png",width = 10,height = 6)

print(mb <-  ggx %+% (filter(betaforecast_datx, (province=="MB")))
		+ coord_cartesian(ylim = c(1, 1000)
								, xlim = c(as.Date("2020-10-01"),as.Date("2021-05-01"))
		)
		+ geom_point(data=filter(obs_dat,province == "MB"),aes(y=obs),size=2)
		)

ggsave("figures/mb.png",width = 10,height = 6)

print(on <-  ggx %+% (filter(betaforecast_datx, (province=="ON")))
		+ coord_cartesian(ylim = c(1, 5000)
								, xlim = c(as.Date("2020-10-01"),as.Date("2021-05-01"))
		)
		+ geom_point(data=filter(obs_dat,province == "ON"),aes(y=obs),size=2)
)

ggsave("figures/on.png",width = 10,height = 6)


print(qc <-  ggx %+% (filter(betaforecast_datx, (province=="QC")))
		+ coord_cartesian(ylim = c(1, 5000)
								, xlim = c(as.Date("2020-10-01"),as.Date("2021-05-01"))
		)
		+ geom_point(data=filter(obs_dat,province == "QC"),aes(y=obs),size=2)
		)

ggsave("figures/qc.png",width = 10,height = 6)

ggall <- plot_grid(bc + theme(legend.position = "none")
  , ab + theme(legend.position = "none")
  , sk + theme(legend.position = "none")
  , mb + theme(legend.position = "none")
  , on + theme(legend.position = "none")
  , qc + theme(legend.position = "none")  
  ,ncol=2)
ggall
ggsave("figures/all_prov_voc.png",width = 10,height = 6)

canada_dat <- (betaforecast_datx
               %>% group_by(date, var, VoC_effect)
               %>% summarise(value = sum(value)
                             , lwr = sum(lwr,na.rm=TRUE)
                             , upr = sum(upr,na.rm=TRUE)
                             , province = "Canada"
               )
               # %>% mutate(obs = ifelse(date > as.Date("2021-02-09"), NA, obs)
                          # , Maintained = ifelse(Maintained == "No", "Not Maintained", "Maintained")
               # )
               # %>% filter(date != as.Date("2021-01-31"))
)

canada_obs <- (obs_dat
  %>% group_by(date)
  %>% summarise(obs = sum(obs,na.rm=TRUE))
)


gg_canada <- (ggx %+% canada_dat 		
  + coord_cartesian(ylim = c(1, 20000)
      , xlim = c(as.Date("2020-10-01"),as.Date("2021-05-01")))
  + geom_point(data=canada_obs,aes(y=obs))
)
gg_canada
ggsave("figures/canada.png",width = 10,height = 6)

