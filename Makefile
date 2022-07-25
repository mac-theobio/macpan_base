## This is macpan_base 
## A public repo to write our main macpan report paper

current: target
-include target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt"

######################################################################

Sources += $(wildcard *.tex figure/*.R)

######################################################################

macpan_ms.pdf: macpan_ms.tex McMasterReport_preamble.tex figure/flowchart.pdf figure/ratematrix.pdf

figure/flowchart.pdf figure/ratematrix.pdf: figure/flowmatrix.Rout ;

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

