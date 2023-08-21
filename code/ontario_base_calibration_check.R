library(McMasterPandemic)
library(dplyr)
library(bbmle)
library(shellpipes)

mod <- rdsRead()

print(mod$fit$mle2@details$convergence)

print(summary(mod$fit$mle2))

print(diag(mod$fit$mle2@vcov))

