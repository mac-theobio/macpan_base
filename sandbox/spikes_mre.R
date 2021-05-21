library(tidyverse); theme_set(theme_bw(base_size = 10))
library(McMasterPandemic)

ONfit <- readRDS("../code/cachestuff/ON.breaks.RDS")
plot(ONfit$fit)
dd <- predict(ONfit$fit,keep_vars=c("death","D"))

dd2 <- (dd
    %>% select(date,var,value)
    %>% pivot_wider(id_cols=date,names_from="var")
    %>% mutate(death2=c(NA,diff(D)))
    %>% pivot_longer(cols=-date,names_to="var")
    %>% mutate(diff=grepl("^death",var))
)

gg0 <- (ggplot(dd2,aes(date,value,colour=var,linetype=var))
    + facet_wrap(~diff,ncol=1, scale="free")
)

gg0 + geom_line()

## jitter a bit so we can confirm that the manual differencing is
## really identical
gg0 + geom_jitter(width=2)

## try with ODE instead (bogus!)
dd3 <- predict(ONfit$fit,keep_vars=c("death","D"),
               sim_args=list(use_ode=TRUE)) %>%
    mutate(diff=grepl("^death",var))

gg0 %+% dd3 + geom_line()

dd4 <- predict(ONfit$fit,keep_vars=c("death","D"),
               sim_args=list(ndt=20)) %>%
    mutate(diff=grepl("^death",var))

gg0 %+% dd4 + geom_line()

