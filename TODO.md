
CAN WE DO THIS IN MACPAN2? What do we need, what components are at what level of maturity?

* base macpan model already exists in `starter_models`, structure looks OK

```r
library(macpan2)
library(macpan2helpers)
cfun <- function(m) {
    Compartmental(system.file("starter_models", m, package = "macpan2"))
}
mb <- cfun("macpan_base")
visCompartmental(mb)
```

* time-varying beta depending on mobility, with logistic transitions (should be straightforward)

* phenomhet (should be straightforward)

* cases from convolution of incidence (should be straightforward)

* setting initial conditions from `E0`? (fancy macpan base stuff might be hard to replicate)

* fitting to multiple data streams (easy if streams are regular/synchronized; slightly harder if not)

* testing model: maybe hard; we have a testing model but it's not product-ized. How hard to build by hand?

```r
try(testify <- cfun("testing")) ## broken ...
```

* 

-------------

F4-5; we do not have a well-conditioned covariance matrix. This is unlikely to be something we can fix effectively _unless_ we can find a better fit and it fixes itself. BB will look into refitting, fitting with greater precision in some way?, ... There is also a more expensive way to try to get the second-derivative matrix from a given fit by using numDeriv::Hessian

----------------------------------------------------------------------

F4: death forecast looks bad because the mort parameters are not time-varying
* Make a decision about: time variation for mortality (but what would be the reason?); drop death (can we find another multi-stream example?)

Can we solidify good figures and decent captions for all the results by 4 Aug? Without help from Jonathan, who will be on vacation.

Testify:
* Are we OK with doing it only on cases?

Fix Rt plot
* Are we changing just β (R0(t)), or are we also multiply by S/N (Re(t))? make any decision and state it clearly

Add breakpoints to mobility plot

Clean up figures, improve captions  

Discussion and conclusions

Rewrite results to serve some sort of updated Discussion

Preprint: medrXiv 

Submit: PLoS ONE?

Profit!!
