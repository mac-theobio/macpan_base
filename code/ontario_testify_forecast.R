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

ensemble <- forecast_ensemble(fit,nsim=100,scale_Sigma = 10)

postest <- ensemble %>% filter(var %in% c("postest"))
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

gg <- gg + coord_cartesian(ylim = c(0,1500))

gg
ggsave("figure/ontario_testify_forecast.png",width = 10, height = 10)
