library(McMasterPandemic)
pp <- read_params("ICU1.csv")
pp <- fix_pars(pp)

pdf("flowchart.pdf",height=8,width=8)
par(mar=rep(0,4))
vis_model(pp,method="diagram",
          do_symbols=FALSE,
          box.prop=0.5,
          box.size=0.05
)
dev.off()
knitr::plot_crop("flowchart.pdf")

pdf("ratematrix.pdf",height=6,width=6)
vis_model(pp,method="Matrix")
dev.off()
