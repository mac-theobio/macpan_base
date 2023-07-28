library(McMasterPandemic)
library(tidyverse)
library(shellpipes)
library(cowplot)
library(zoo)
library(gtable)

rpcall("code/ontario_base_forecast_plot.Rout .pipestar slow/ontario_base_forecast.rda")

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

print(reports_death,n=Inf)

R0val <- get_R0(coef(mod$fit), method = "analytical")

rt_ensemble <- (forecast
	%>% filter(var %in% c("S","foi","I"))
	%>% pivot_longer(names_to="seed",values_to="est",-c("date","var"))
	%>% spread(var,est)
	%>% group_by(seed)
	%>% mutate(S0 = first(S)
                 , beta = foi/I
                 , beta0 = first(beta)
                 , rt = R0val*beta/beta0,
                 , reff = rt*S/S0
	)
	%>% ungroup()
)

## rt_ensemble |> filter(date == min(date)) |> pull(rt) |> hist()

rt <- (rt_ensemble
    %>% select(date,seed,rt, reff)
    %>% pivot_longer(c(rt, reff), names_to = "type", values_to = "value")
    %>% group_by(date, type)
    %>% summarise(med = quantile(value,prob=0.5,na.rm=TRUE)
                , lwr = quantile(value, prob=0.025,na.rm=TRUE)
                , upr = quantile(value, prob=0.975,na.rm=TRUE)
                , .groups = "drop")
)

print(rt)

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
teeGG(ggcombo, desc="rptDeath")

(ggplot(rt,aes(x=date,y=med))
    + geom_line(aes(linetype = type))
    + geom_ribbon(aes(ymin=lwr,ymax=upr, group = type),alpha=0.1)
    + theme_bw()		
    + ylab("Reproductive number")
    + geom_hline(aes(yintercept=1))
    + scale_x_date(date_labels = "%b-%Y")
    + scale_linetype_manual(values = 1:2, labels = c("Reff", "Rt"))
) %>% teeGG(desc="rt")
