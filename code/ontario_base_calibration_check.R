library(McMasterPandemic)
library(dplyr)
library(bbmle)
library(shellpipes)

mod <- rdsRead()

print(mod$fit$mle2@details$convergence)

##print(summary(mod$fit$mle2))

print(diag(mod$fit$mle2@vcov))

pp <- profile(mod$fit$mle2, std.err=.01, trace=TRUE, devtol=Inf)

rdsSave(pp)
