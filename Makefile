## This is macpan_base 
## A public repo to write our main macpan report paper

all: macpan_ms.pdf

current: target
-include target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt"

######################################################################

Sources += $(wildcard *.tex figure/*.R)

######################################################################

## MS

## dependencies

code/ontario_plots.Rout: code/ontario_plots.R 
	$(pipeR)

code/ontario_tables.Rout: code/ontario_tables.R
	$(pipeR)

code/ontario_base_forecast.Rout: code/ontario_base_forecast.R
	$(pipeR)

code/ontario_testify_forecast.Rout: code/ontario_testify_forecast.R
	$(pipeR)

code/ontario_mobility.Rout: code/ontario_mobility.R
	$(pipeR)

ontario_deps: code/ontario_plots.Rout code/ontario_tables.Rout code/ontario_base_forecast.Rout code/ontario_testify_forecast.Rout code/ontario_mobility.Rout

## JD: This seems to chain without being uncommented; 
## let me know if you have a reproducible bug
macpan_ms.pdf: macpan_ms.tex McMasterReport_preamble.tex ontario_deps figure/flow.chart.crop.pdf figure/testFlow.1.Rout.pdf
	pdflatex macpan_ms.tex

######################################################################

## repiped figures
pipeRdesc += figure/flow
figure/flow.Rout: figure/flow.R
	$(pipeR)

## figure/flow.chart.crop.pdf:

pipeRdesc += figure/testFlow
## figure/testFlow.1.Rout: figure/testFlow.R
figure/testFlow.%.Rout: figure/testFlow.R
	$(pipeR)

## %.crop.pdf: %.pdf
figure/flow.chart.crop.pdf: figure/flow.chart.pdf
	Rscript -e 'knitr::plot_crop("$<")'
	$(copy)

## pre-piping versions
## git rm figure/testing_flow_graph.R figure/flowmatrix.R 2022 Aug 09 (Tue)
## figure/testing_flow_graph.R.c66c057d.oldfile:
## figure/flowmatrix.R.c66c057d.oldfile:

######################################################################

shellpipes.out:
	Rscript -e 'remotes::install_github("dushoff/shellpipes")'

pkg:
	echo "remotes::install_github('bbolker/McMasterPandemic')" | R --slave

######################################################################

### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

Makefile: makestuff/Makefile
makestuff/Makefile:
	git clone $(msrepo)/makestuff
	ls makestuff/Makefile

-include makestuff/os.mk

-include makestuff/pipeR.mk
-include makestuff/texi.mk

-include makestuff/git.mk
-include makestuff/visual.mk
