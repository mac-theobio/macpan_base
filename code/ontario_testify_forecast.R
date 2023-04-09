## point to OLD/stored MacPan
.libPaths(c("Rlib", .libPaths()))
library(McMasterPandemic)
library(tidyverse)
library(parallel)
library(shellpipes)
library(cowplot)
library(zoo)
library(gtable)
library(shellpipes)

mod <- readRDS("code/cachestuff/ont_calib_testify.rds")

fit <- mod$fit

## Hack end date
extend_days <- 30

fit$forecast_args$end_date <- fit$forecast_args$end_date + extend_days 
## MLi: need to increase scale_Sigma to get something sensible

## What happens if we extend same testing intensity for the forecast window?
testdat <- fit$forecast_args$time_args$testing_data
testdat_extend <- data.frame(Date = seq.Date(max(testdat$Date)+1,max(testdat$Date)+extend_days,by=1)
		, Symbol = "testing_intensity"
		, Relative_value = last(testdat$Relative_value)
#		, Relative_value = 1e5
)
fit$forecast_args$time_args$testing_data <- bind_rows(testdat,testdat_extend)

ensemble <- forecast_ensemble(fit,nsim=1000,scale_Sigma = 10)

postest <- ensemble %>% filter(var %in% c("postest"))
# postest <- ensemble %>% filter(var %in% c("report"))
plot(postest)

gg <- (ggplot(postest,aes(x=date,y=value))
	+ geom_point(data=mod$data %>% filter(var%in%c("report"),date < as.Date("2020-09-30")),color="red",size=0.95)
	+ geom_point(data=mod$data %>% filter(var%in%c("report"),date < as.Date("2020-08-30")),color="grey")
	# + facet_wrap(~var,scale="free",nrow=2)
	+ geom_line()
	+ geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.1)
	+ theme_bw()		
	+ ylab("Daily Positives")
	## Overlaying the data
)
gg
gg <- gg + coord_cartesian(ylim = c(0,1500))

gg
ggsave("figure/ontario_testify_forecast.png",width = 10, height = 10)
