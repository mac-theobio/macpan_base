library(McMasterPandemic)
library(tidyverse)
library(shellpipes)
library(cowplot)
library(zoo)
library(gtable)

mod <- readRDS("code/cachestuff/ont_calib_comb_mobbreaks.rds")

fit <- mod$fit

## Hack end date
extend_days <- 30

fit$forecast_args$end_date <- fit$forecast_args$end_date + extend_days 
## MLi: need to increase scale_Sigma to get something sensible

## BMB: slow, separate this into a separate component so we can
##  play with graphics more efficiently
ensemble <- forecast_ensemble(fit, nsim=1000, scale_Sigma = 1000)

forecast <- ensemble %>% filter(var %in% c("report","death"))

gg_report <- (ggplot(filter(forecast,var=="report"),aes(x=date,y=value))
	## Overlaying the data
    + geom_point(data=mod$data %>% filter(var%in%c("report"),date < as.Date("2020-09-30")),color="red",size=0.95)
    + geom_point(data=mod$data %>% filter(var%in%c("report"),date < as.Date("2020-08-30")),color="grey")
    ## + facet_wrap(~var,scale="free",nrow=2)
    + geom_line()
    + geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.1)
    + theme_bw()		
    + ylab("Daily Reported Cases")
    + coord_cartesian(ylim=c(0,1000))
)
gg_report

gg_death <- (ggplot(filter(forecast,var=="death"),aes(x=date,y=value))
	## Overlaying the data
	+ geom_point(data=mod$data %>% filter(var%in%c("death"),date < as.Date("2020-09-30")),color="red",size=0.95)
	+ geom_point(data=mod$data %>% filter(var%in%c("death"),date < as.Date("2020-08-30")),color="grey")
	# + facet_wrap(~var,scale="free",nrow=2)
	+ geom_line()
	+ geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.1)
	+ theme_bw()		
	+ ylab("Daily Death")
	+ coord_cartesian(ylim=c(0,100))
)
gg_death

ggcombo <- plot_grid(gg_report,gg_death,nrow=2)
ggcombo

ggsave("figure/ontario_base_forecast.png",width = 10, height = 10)
