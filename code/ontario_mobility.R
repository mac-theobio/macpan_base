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
    + labs(x = "Date", y = "Relative activity")
    + geom_hline(lty = 2, yintercept = 1)
    + scale_x_date(date_labels = "%b-%Y")
)

print(gg)


ggsave("figure/ontario_mobility.png",width = 8, height = 6)

saveEnvironment()
