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
          box.size=0.05,
          curve = 0,
          arr.type = "triangle",
          shadow.size = 0,
          arr.length = 0.2,
          arr.width = 0.2,
          y_space = 0.7
          )

dev.off()
knitr::plot_crop("figure/flowchart.pdf")

pdf("figure/ratematrix.pdf",height=6,width=6)
vis_model(pp,method="Matrix")
dev.off()

if (FALSE) {
    ## useful, but we might not need to actually show it:
    ## full flow matrix for testify
    pp2 <- read_params("PHAC_testify.csv")
    ## block_size = 4 would be nice but offsets aren't right ... fix?
    vis_model(pp2, testify = TRUE, method = "Matrix")
}
