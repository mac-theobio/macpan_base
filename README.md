# macpan_base

## Instructions

* If necessary export extra R libraries `export R_LIBS_USER=/usr/local/lib/R/site-library`

```r
install.packages(c("directlabels"))
remotes::install_github("mac-theobio/McMasterPandemic@testify_eigvec")
```

`make macpan_ms.pdf` 

Required packages:

```r
c("McMasterPandemic", "batchtools", "furrr", "future", "future.batchtools", 
"cowplot", "dplyr", "shellpipes", "tidyverse", "zoo", 
"ggplot2", "gsheet", "readr", "splines", "tidyr", "bbmle", "gtable", 
"knitr", "diagram")
```

## Structure


