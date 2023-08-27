library(McMasterPandemic)
library(dplyr)
library(bbmle)
library(shellpipes)

rpcall("code/ontario_base_calibration_check.R slow/ontario_calibrate_comb.rds")

mod <- rdsRead()

mle2_obj <- mod$fit$mle2

## optim thinks convergence is OK:
print(mle2_obj@details$convergence)

##print(summary(mod$fit$mle2))

print(diag(vcov(mle2_obj)))

optargs <- c(list(par = coef(mle2_obj),
                  fn = mle2_obj@minuslogl,
                  data = mod$data),
             mod$fit$forecast_args)
newopt <- do.call("optim", optargs)
                  
## pp <- profile(mod$fit$mle2, std.err=.01, trace=TRUE, devtol=Inf)

##rdsSave(pp)
rdsSave(newopt)

