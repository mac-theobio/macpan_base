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

## JD: This seems to chain without being uncommented; 
## let me know if you have a reproducible bug
## macpan_ms.pdf: macpan_ms.tex McMasterReport_preamble.tex

######################################################################

## Deprecated figures

figure/testing_flow_graph.pdf: figure/testing_flow_graph.Rout ;
figure/testing_flow_graph.Rout: figure/testing_flow_graph.R
	$(pipeR)

figure/flowchart.pdf figure/ratematrix.pdf: figure/flowmatrix.Rout ;
figure/flowmatrix.Rout: figure/flowmatrix.R
	$(pipeR)

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
