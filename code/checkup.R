library(McMasterPandemic)
library(bbmle)
library(shellpipes)

loadEnvironments()

mle2_obj <- mod$fit$mle2

## optim thinks convergence is OK:
## print(mle2_obj@details$convergence)

print(summary(mod$fit$mle2))

print(diag(vcov(mle2_obj)))


objects()
