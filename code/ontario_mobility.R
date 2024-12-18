library(tidyverse);theme_set(theme_bw())

library(shellpipes)
rpcall("figure/ontario_mobility.Rout .pipestar code/ontario_mobility.R slow/calibrate_comb_setup.rds")

## FIXME, this should be piped!
mobdat <- readRDS("slow/ontario_calibrate_comb.rds")

startGraphics(width = 8, height = 6)

dat <- rdsRead()

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
    + geom_vline(xintercept = as.Date(mobdat$breakpoints), lty = 2)
)

print(gg)

saveEnvironment()
