## Basic plot

library(McMasterPandemic)

default_macpan_plot <- plot(ff$fit,data=ff$trimdat,predict_args = list(keep_vars=c("report")))

ggsave("cachestuff/ontario.png",width = 8, height = 8)


