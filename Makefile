## This is macpan_base 
## A public repo to write our main macpan report paper

## See makestuff/slowtarget.md for workflow control and assuring you are up to date
all: macpan_ms.pdf
## macpan_ms.pdf.final: macpan_ms.tex
## slowsync:

macpan_ms.pdf: macpan_ms.tex  code/ontario_tables.Rout figure/ontario_base_forecast_plot.Rout.pdf

######################################################################

current: target
-include target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt"

######################################################################

## macpan_ms.pdf: macpan_ms.tex

Sources += $(wildcard */*.R)
Sources += macpan_ms.tex McMasterReport_preamble.tex notes.md 

Ignore +=	base_table.tex testify_table.tex litparm_table.tex

######################################################################

Sources += README.md TODO.md

######################################################################

autopipeR = defined

## MS plots
pdfDesc += figure/ontario_testing_plot
figure/ontario_testing_plot.Rout: code/ontario_testing_plot.R slow/ontario_calibrate_comb.rds slow/ontario_testify.rds slow/calibrate_comb_setup.rds
	$(pipeR)

## MS tables
litparm_table.tex base_table.tex testify_table.tex combo_table.tex: code/ontario_tables.Rout ;
code/ontario_tables.Rout: code/ontario_tables.R slow/ontario_calibrate_comb.rds slow/ontario_testify.rds 
	$(pipeR)

######################################################################

## recreating pipeline 2023 Jun

### set up
slowtarget/calibrate_comb_setup.Rout: code/calibrate_comb_setup.R
	$(pipeR)

slowtarget/ontario_calibrate_comb.Rout: code/ontario_calibrate_comb.R slow/calibrate_comb_setup.rds
	$(pipeR)

slowtarget/ontario_base_calibration_check.Rout: code/ontario_base_calibration_check.R slow/ontario_calibrate_comb.rds
	$(pipeR)

## checkup.Rout.final: code/checkup.R 
checkup.Rout: code/checkup.R slow/ontario_base_calibration_check.rda
	$(pipeR)

slowtarget/ontario_base_forecast.Rout: code/ontario_base_forecast.R slow/ontario_calibrate_comb.rds 
	$(pipeR)

slowtarget/ontario_testify.Rout: code/ontario_testify.R slow/calibrate_comb_setup.rds
	$(pipeR)

slowtarget/ontario_testify_forecast.Rout: code/ontario_testify_forecast.R slow/ontario_testify.rds
	$(pipeR)

## figure/ontario_base_forecast_plot.Rout.final:
figure/ontario_base_forecast_plot.Rout: code/ontario_base_forecast_plot.R slow/ontario_base_forecast.rda
	$(pipeR)

figure/ontario_base_rt_plot.Rout: code/ontario_base_rt_plot.R slow/ontario_base_forecast.rda
	$(pipeR)

figure/ontario_testify_forecast_plot.Rout: code/ontario_testify_forecast_plot.R slow/ontario_testify_forecast.rda
	$(pipeR)

figure/ontario_mobility.Rout: code/ontario_mobility.R slow/calibrate_comb_setup.rds
	$(pipeR)

######################################################################

## Archaeology 2025 Jul 29 (Tue)

retro_forecast.Rout: linked/ontario_base_forecast_plot.R ontario_base_forecast.rda
	$(pipeR)

ontario_base_forecast.rda:
	$(LNF) slow/$@

linked/ontario_base_forecast_plot.R: | linked
	wget -O $@ https://raw.githubusercontent.com/papsti/macpan_retro/f710d93202bb0873d94d67e03dc272440da02174/data/ontario_base_forecast_plot.R?token=GHSAT0AAAAAADD65ES3U6WYE3AWWJASGASG2EIR5HA

Ignore += linked/
linked:
	$(mkdir)


######################################################################

## FIXME Deleted lots of manual figure links

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
