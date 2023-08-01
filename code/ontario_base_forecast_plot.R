library(McMasterPandemic)
library(tidyverse)
library(shellpipes)
library(cowplot)
library(zoo)
library(gtable)

loadEnvironments()


reports_death <- (forecast
	%>% filter(var %in% c("report","death"))
	%>% pivot_longer(names_to="seed",values_to="est",-c("date","var"))
	%>% group_by(date,var)
	%>% summarise(value = quantile(est,prob=0.5,na.rm=TRUE)
		, lwr = quantile(est, prob=0.025,na.rm=TRUE)
		, upr = quantile(est, prob=0.975,na.rm=TRUE)
	)
)


gg_report <- (ggplot(filter(reports_death,var=="report"),aes(x=date,y=value))
	## Overlaying the data
    + geom_point(data=mod$data %>% filter(var%in%c("report"),date < as.Date("2020-09-30")),color="red",size=0.95)
    + geom_point(data=mod$data %>% filter(var%in%c("report"),date < as.Date("2020-08-30")),color="grey")
    ## + facet_wrap(~var,scale="free",nrow=2)
    + geom_line()
    + geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.1)
    + theme_bw()		
    + ylab("Daily Reported Cases")
    + coord_cartesian(ylim=c(0,1000))
    + scale_x_date(date_labels = "%b-%Y")
)

gg_death <- (ggplot(filter(reports_death,var=="death"),aes(x=date,y=value))
    ## Overlaying the data
    + geom_point(data=mod$data %>% filter(var%in%c("death"),date < as.Date("2020-09-30")),color="red",size=0.95)
    + geom_point(data=mod$data %>% filter(var%in%c("death"),date < as.Date("2020-08-30")),color="grey")
    ## + facet_wrap(~var,scale="free",nrow=2)
    + geom_line()
    + geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.1)
    + theme_bw()		
    + ylab("Daily Death")
    + coord_cartesian(ylim=c(0,100))
    + scale_x_date(date_labels = "%b-%Y")
)

ggcombo <- plot_grid(gg_report,gg_death,nrow=2)

print(ggcombo)

