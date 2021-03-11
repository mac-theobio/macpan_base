## This is macpan_base 

current: target
-include target.mk

# -include makestuff/perl.def

vim_session:
	bash -cl "vmt"

######################################################################

Sources += $(wildcard *.tex)

pkg:
	echo "remotes::install_github('bbolker/McMasterPandemic')" | R --slave

macpan_ms.pdf: macpan_ms.tex McMasterReport_preamble.tex figure/flowchart.pdf figure/ratematrix.pdf

figure/flowchart.pdf:
	cd figure; R CMD BATCH flowmatrix.R

figure/ratematrix.pdf:
	cd figure; R CMD BATCH flowmatrix.R

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

## -include makestuff/pipeR.mk
-include makestuff/texi.mk

-include makestuff/git.mk
-include makestuff/visual.mk

