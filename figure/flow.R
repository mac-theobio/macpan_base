## Setting up to be run from main directory, since this one has no Makefile
## Sorry for any inconvenience 2021 Mar 16 (Tue) JD
library(McMasterPandemic)

library(shellpipes)
pp <- read_params("ICU1.csv") ## This is not a local file
pp <- fix_pars(pp)

par(mar=rep(0,4))

startGraphics(height=8, width=8, desc="chart")
print(vis_model(pp,method="diagram",
	do_symbols=FALSE,
	box.prop=0.5,
	box.size=0.05,
	curve = 0,
	arr.type = "triangle",
	shadow.size = 0,
	arr.length = 0.2,
	arr.width = 0.2,
	y_space = 0.7
))

startGraphics(height=6, width=6, desc="rates")
print(vis_model(pp,method="Matrix"))

## full flow matrix for testify (not used right now)
startGraphics(height=6, width=6, desc="testify")
pp2 <- read_params("PHAC_testify.csv")
## block_size = 4 would be nice but offsets aren't right ... fix?
print(vis_model(pp2, testify = TRUE, method = "Matrix"))
