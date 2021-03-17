## Setting up to be run from main directory, since this one has no Makefile
## Sorry for any inconvenience 2021 Mar 16 (Tue) JD
library(McMasterPandemic)
pp <- read_params("ICU1.csv")
pp <- fix_pars(pp)

pdf("figure/flowchart.pdf",height=8,width=8)
par(mar=rep(0,4))
vis_model(pp,method="diagram",
          do_symbols=FALSE,
          box.prop=0.5,
          box.size=0.05
)
dev.off()
knitr::plot_crop("figure/flowchart.pdf")

pdf("figure/ratematrix.pdf",height=6,width=6)
vis_model(pp,method="Matrix")
dev.off()
