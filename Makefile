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

## BMB: is there a way to automate this/auto-generate .deps to
##  find files referred to in uncommented \includegraphics{} calls??
macpan_ms.pdf: macpan_ms.tex McMasterReport_preamble.tex figure/flowchart.pdf figure/testing_flow_graph.pdf

## JD: De-recipe-ed this 2022 Jul 27 (Wed); should figure out why it's here
figure/testing_flow_graph.pdf: figure/flowmatrix.Rout

figure/flowchart.pdf figure/ratematrix.pdf: figure/flowmatrix.Rout ;

## BMB: do this the hard way because I don't understand makestuff/shellpipes
## using $(run-R) here results in creating the file
## figure/testing_flow_graph.pdf.pdf ??
figure/testing_flow_graph.pdf: figure/testing_flow_graph.R
	R --vanilla --slave <figure/testing_flow_graph.R
##	$(run-R)



figure/flowmatrix.Rout: figure/flowmatrix.R
	$(run-R)

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
