library(McMasterPandemic)
library(tidyverse)
library(parallel)
library(shellpipes)
library(cowplot)
library(zoo)
library(gtable)

library(shellpipes)
startGraphics(width=7, height=7)
loadEnvironments()

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

## Chesterton's fence
## print (gg + coord_cartesian(ylim = c(0,1500)))
print(gg)

saveEnvironment()
