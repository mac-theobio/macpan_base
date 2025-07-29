library(tidyverse)

load("ontario_base_forecast.rda")

head(forecast)
longforecast <- (forecast
	%>% filter(var %in% c("report","death"))
	%>% pivot_longer( cols = -c(date, var), # Exclude 'ID' and 'Name'
					  names_to = "Seed",
					  values_to = "Value"
	)
)

forecast_summary <- (longforecast
	%>% group_by(date,var)
	%>% summarise(lwr = quantile(Value,prob=0.025,na.rm=TRUE)
			, med = quantile(Value,prob=0.5,na.rm=TRUE)
			, upr = quantile(Value,prob=0.975,na.rm=TRUE))
)

dat <- mod$data %>% filter(var %in% c("report","death"))

gg <- (ggplot(data=forecast_summary,aes(x=date,y=med))
	+ geom_line()
	+ geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.2)
	+ facet_wrap(~var,scale="free",nrow=2)
	+ theme_bw()   
)

(gg 
	+ geom_point(data=filter(dat,between(date,as.Date("2020-01-01"),as.Date("2020-08-31"))),aes(x=date,y=value),color="black")
	+ geom_point(data=filter(dat,between(date,as.Date("2020-09-01"),as.Date("2020-10-01"))),aes(x=date,y=value),color="red")
)
