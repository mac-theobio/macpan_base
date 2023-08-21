library(McMasterPandemic)
library(tidyverse)
library(shellpipes)
library(cowplot)
library(zoo)
library(gtable)

loadEnvironments()

R0val <- get_R0(coef(mod$fit), method = "analytical")

R0t <- R0val

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


ggrt <- (ggplot(rt,aes(x=date,y=med))
    + geom_line(aes(linetype = type))
    + geom_ribbon(aes(ymin=lwr,ymax=upr, group = type),alpha=0.1)
    + theme_bw()		
    + ylab("Reproductive number")
    + geom_hline(aes(yintercept=1))
    + scale_x_date(date_labels = "%b-%Y")
    + scale_linetype_manual(values = 1:2, labels = c("Reff", "Rt"))
) 

print(ggrt)
