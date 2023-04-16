## This is macpan_base 
## A public repo to write our main macpan report paper

all: macpan_ms.pdf

current: target
-include target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt"

######################################################################

Sources += $(wildcard */*.R)
Sources += macpan_ms.tex McMasterReport_preamble.tex
Ignore +=	base_table.tex testify_table.tex

Ignore +=	base_table.tex testify_table.tex
base_table.tex testify_table.tex: code/ontario_tables.Rout ;

######################################################################

autowrapR = defined

## MS

## dependencies

code/ontario_plots.Rout: code/ontario_plots.R 
	$(pipeR)

code/ontario_tables.Rout: code/ontario_tables.R
	$(pipeR)

slowtarget/ontario_base_forecast.Rout: code/ontario_base_forecast.R
	$(pipeR)

code/ontario_base_forecast_plot.Rout: slow/ontario_base_forecast.rda code/ontario_base_forecast_plot.R
	$(pipeR)

slowtarget/ontario_testify_forecast.Rout: code/ontario_testify_forecast.R
	$(pipeR)

code/ontario_testify_forecast_plot.Rout: slow/ontario_testify_forecast.rda code/ontario_testify_forecast_plot.R
	$(pipeR)

code/ontario_mobility.Rout: code/ontario_mobility.R
	$(pipeR)

######################################################################

# ontario_deps: code/ontario_plots.rda code/ontario_tables.rda code/ontario_base_forecast_plot.rda code/ontario_testify_forecast_plot.rda code/ontario_mobility.rda

## JD: This seems to chain without being uncommented; 
## let me know if you have a reproducible bug
# macpan_ms.pdf: macpan_ms.tex McMasterReport_preamble.tex ontario_deps figure/flow.chart.crop.pdf figure/testFlow.1.Rout.pdf; pdflatex macpan_ms.tex
## these seem useful, but break when included
## code/ontario_plots.Rout code/ontario_tables.Rout code/ontario_testify_forecast_plot.Rout 

######################################################################

## Explicit pointers for old pathways

figure/ontario_mobility.png: code/ontario_mobility.Rout ;
figure/ontario_base.png: code/ontario_plots.Rout ;
figure/ontario_base_forecast.png: code/ontario_base_forecast_plot.Rout ;
figure/ontario_testing.png figure/ontario_testify.png: code/ontario_plots.Rout ;
figure/ontario_testify_forecast.png: code/ontario_testify_forecast_plot.Rout ;

######################################################################

## repiped figures
pipeRdesc += figure/flow
figure/flow.Rout: figure/flow.R
	$(pipeR)

## figure/flow.chart.crop.pdf:
## figure/flow.chart.pdf: figure/flow.R

pipeRdesc += figure/testFlow
## pipeRimplicit += figure/testFlow
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

Makefile: makestuff/macpan_base_00.stamp
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
