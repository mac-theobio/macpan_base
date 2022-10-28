library(tidyverse);theme_set(theme_bw())
library(shellpipes)

dat <- readRDS("code/cachestuff/calibrate_comb_setup.rds")

end_date <- as.Date("2020-10-01")

mob <- (dat$clean_mobility
	%>% filter(date < end_date)
)

print(mob)

gg <- (ggplot(mob,aes(x=date,y=rel_activity))
	+ geom_line()
)

print(gg)


ggsave("figure/ontario_mobility.png",width = 10, height = 10)
