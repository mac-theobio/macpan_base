## Basic plot

library(McMasterPandemic)

startGraphics()

plot(ff$fit,data=ff$trimdat,predict_args = list(keep_vars=c("report")))
