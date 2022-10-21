# TODOs 
	- Do the forecasting part (find or write new code).
	- make latex tables (grab tables from code/ontario_tables.R and kable it?) All the pieces should be there, if it doesn't work, please check out testify_eigvec branch and reinstall macpan. 
	- make better looking plots (the code is in code/ontario_plots.R)
	- Need to write a better results section!
	- clean the repo! 

## everyone

- what are we including in the actual example?

MLi:
	- fitting with mobility (with mobility breaks) + phenomhet to reports and death
	- testify
	- splines: currently not doing, but I did run testify spline and it is in cache.


## JD

- Check "kernel moments calculation" section for accuracy and completeness

## Mike/Irena

- Confirm that description of calibration, forecasting procedure is actually what we are doing
- no process error? 
- ensemble of parameters via MVN sampling? (Importance sampling?)
- NB observation error?
- quantile-based envelopes? (mention Juul et al.?)

## BB

- "ascertainment ratio" is a term I couldn't remember. Use it where appropriate.
- discuss calculation of $R_t$ (i.e., by scaling $R_0$ by $\beta(t)$ ?
