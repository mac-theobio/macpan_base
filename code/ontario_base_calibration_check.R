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

## refit, increasing maxit and decreasing tolerance
optargs <- c(list(par = coef(mle2_obj),
                  fn = mle2_obj@minuslogl,
                  data = mod$data),
             mod$fit$forecast_args,
             list(method = "Nelder-Mead",
                  control = list(maxit = 2e4,
                                 reltol = 1e-12)))
system.time(
    newopt <- do.call("optim", optargs)
)

all.equal(newopt$par, coef(mle2_obj))  ## rel diff 0.079

## compute hessian via optimHess
hessargs <- optargs
hessargs[[1]] <- newopt$par
system.time(
    newhess_optim <- do.call("optimHess", hessargs)
)

## compute hessian via numDeriv::hessian
hessargs2 <- hessargs
names(hessargs2)[1:2] <- c("x", "func")
hessargs2$method <- NULL
system.time(
    newhess_numderiv <- do.call("hessian", hessargs2)
)

try(solve(newhess_numderiv))
try(solve(newhess_optim))

sqrt(diag(MASS::ginv(newhess_numderiv)))
sqrt(diag(MASS::ginv(newhess_optim)))

newmle <- mle2_obj
newmle@coef <- newopt$par
pp1 <- profile(newmle, std.err=.01)
## coef() fills in the fixed value of the focal parameter --
##   so x@coef is different from coef(x)

optargs2 <- c(list(par = coef(pp0),
                  fn = mle2_obj@minuslogl,
                  data = mod$data),
             mod$fit$forecast_args,
             list(method = "Nelder-Mead",
                  control = list(maxit = 2e4,
                                 reltol = 1e-12)))

## compare implied fit with old/new params?

## re-fit with new params
system.time(
    newopt2 <- do.call("optim", optargs2)
)
## much better (should compare fit projections)
hessargs[[1]] <- newopt2$par
system.time(
    newhess_optim2 <- do.call("optimHess", hessargs)
)

## compute hessian via numDeriv::hessian
hessargs2[[1]] <- newopt2$par
system.time(
    newhess_numderiv2 <- do.call("hessian", hessargs2)
)

## still singular
try(solve(newhess_numderiv2))
try(solve(newhess_optim2))

## should we try to find singular dimensions to diagnose? (SVD?)

sqrt(diag(MASS::ginv(newhess_numderiv2)))
sqrt(diag(MASS::ginv(newhess_optim2)))


## name hack ...
names(newopt2$par)[1] <- names(newopt$par)[1]
newmle2 <- mle2_obj
newmle2@coef <- newopt2$par
pp2 <- profile(newmle2, std.err=.01, trace = TRUE, tol.newmin = 0.5)

optargs3 <- c(list(par = coef(pp2),
                   fn = mle2_obj@minuslogl,
                   data = mod$data),
              mod$fit$forecast_args,
              list(method = "Nelder-Mead",
                   control = list(maxit = 2e4,
                                  reltol = 1e-12)))
system.time(
    newopt3 <- do.call("optim", optargs3)
)

## comparative log-likelihoods (decrease in NLL)
newopt$value - c(newopt$value,newopt2$value, newopt3$value)

## name hack ...
names(newopt3$par)[1] <- names(newopt$par)[1]
newmle3 <- mle2_obj
newmle3@coef <- newopt2$par
pp3 <- profile(newmle3, std.err=.01, trace = TRUE, tol.newmin = 0.5)


saveEnvironment()



