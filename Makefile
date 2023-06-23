## This is macpan_base 
## A public repo to write our main macpan report paper

## See makestuff/slowtarget.md for workflow control and assuring you are up to date
all: macpan_ms.pdf
## macpan_ms.pdf.final:
## slowsync:

######################################################################

current: target
-include target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt"

######################################################################

## macpan_ms.pdf: macpan_ms.tex

Sources += $(wildcard */*.R)
Sources += macpan_ms.tex McMasterReport_preamble.tex 

Ignore +=	base_table.tex testify_table.tex litparm_table.tex
litparm_table.tex base_table.tex testify_table.tex combo_table.tex: code/ontario_tables.Rout ;

######################################################################

Sources += README.md TODO.md

######################################################################

autowrapR = defined

## MS

## dependencies

code/ontario_plots.Rout: code/ontario_plots.R 
	$(pipeR)

code/ontario_tables.Rout: code/ontario_tables.R
	$(pipeR)

slowtarget/ontario_base_forecast.Rout: code/ontario_base_forecast.R code/cachestuff/ont_calib_comb_mobbreaks.rds
	$(pipeR)

code/ontario_base_forecast_plot.Rout: slow/ontario_base_forecast.rda code/ontario_base_forecast_plot.R
	$(pipeR)

slowtarget/ontario_testify_forecast.Rout: code/ontario_testify_forecast.R code/cachestuff/ont_calib_testify.rds
	$(pipeR)

code/ontario_testify_forecast_plot.Rout: slow/ontario_testify_forecast.rda code/ontario_testify_forecast_plot.R
	$(pipeR)

code/ontario_mobility.Rout: code/ontario_mobility.R code/cachestuff/calibrate_comb_setup.rds
	$(pipeR)

######################################################################

## recreating pipeline 2023 Jun

### setting up pieces for calibration
code/calibrate_comb_setup.Rout: code/calibrate_comb_setup.R
	$(pipeR)

code/fresh_ontario_calibrate_comb.Rout: code/ontario_calibrate_comb.R code/calibrate_comb_setup.rds
	$(pipeR)

code/fresh_ontario_base_forecast.Rout: code/ontario_base_forecast.R code/fresh_ontario_calibrate_comb.rds 
	$(pipeR)

code/fresh_ontario_base_forecast_plot.Rout: code/ontario_base_forecast_plot.R code/fresh_ontario_base_forecast.rda
	$(pipeR)

code/fresh_ontario_testify.Rout: code/ontario_testify.R code/calibrate_comb_setup.rds
	$(pipeR)

code/fresh_ontario_testify_forecast.Rout: code/ontario_testify_forecast.R code/fresh_ontario_testify.rds
	$(pipeR)

code/fresh_ontario_testify_forecast_plot.Rout: code/ontario_testify_forecast_plot.R code/fresh_ontario_testify_forecast.rda
	$(pipeR)


######################################################################

## Explicit pointers for old pathways

## BMB: added, but maybe in the wrong place? FIXME
figure/ontario_base_rt.png: code/ontario_base_forecast_plot.Rout ;

## 
figure/ontario_mobility.png: code/ontario_mobility.Rout ;
figure/ontario_base.png: code/ontario_plots.Rout ;
figure/ontario_base_forecast.png: code/fresh_ontario_base_forecast_plot.Rout ;
figure/ontario_testing.png figure/ontario_testify.png: code/ontario_plots.Rout ;
figure/ontario_testify_forecast.png: code/ontario_testify_forecast_plot.Rout ;
######################################################################

## repiped figures
figure/flow.chart.pdf: figure/flow.Rout ;
figure/flow.Rout: figure/flow.R
	$(pipeR)

## figure/flow.chart.crop.pdf:
## figure/flow.chart.pdf: figure/flow.R

## figure/testFlow.1.Rout: figure/testFlow.R
figure/testFlow.%.Rout: figure/testFlow.R
	$(pipeR)
## MLi do we ever use v2? 

## %.crop.pdf: %.pdf
figure/flow.chart.crop.pdf: figure/flow.chart.pdf
	Rscript -e 'knitr::plot_crop("$<")'
	$(copy)

######################################################################

shellpipes.out:
	Rscript -e 'remotes::install_github("dushoff/shellpipes")'

pkg:
	Rscript -e 'remotes::install_github("mac-theobio/McMasterPandemic@v0.0.20.1")'

######################################################################

### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

Makefile: makestuff/macpan_base_01.stamp
makestuff/%.stamp: 
	- $(RM) makestuff/*.stamp
	(cd makestuff && $(MAKE) pull) || git clone $(msrepo)/makestuff
	touch $@

-include makestuff/os.mk

-include makestuff/pipeR.mk
-include makestuff/slowtarget.mk
-include makestuff/texi.mk

-include makestuff/git.mk
-include makestuff/visual.mk
