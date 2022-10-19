library(tidyverse)
library(McMasterPandemic)

base <- readRDS("cachestuff/ont_calib_comb_mobbreaks.rds")
plot(base$fit,data=base$data)


