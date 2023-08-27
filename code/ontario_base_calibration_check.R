library(McMasterPandemic)
library(dplyr)
library(bbmle)
library(numDeriv)
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
system.time(
    newopt <- do.call("optim", optargs)
)

hessargs <- optargs
hessargs[[1]] <- newopt$par

system.time(
    newhess_optim <- do.call("optimHess", hessargs)
)

hessargs2 <- hessargs
names(hessargs2)[1:2] <- c("x", "func")
system.time(
    newhess_numderiv <- do.call("hessian", hessargs2)
)
## pp <- profile(mod$fit$mle2, std.err=.01, trace=TRUE, devtol=Inf)

try(solve(newhess_numderiv))
try(solve(newhess_optim))

sqrt(diag(MASS::ginv(newhess_numderiv)))
sqrt(diag(MASS::ginv(newhess_optim)))
sqrt(diag(solve(newhess_optim)))
##rdsSave(pp)
saveEnvironment()


