library(tidyverse); theme_set(theme_bw(base_size = 10))

dd <- read_csv("cachestuff/breaks.forecast.csv")
dd_ontario <- filter(dd,province_name == "Ontario")
dd_other <- filter(dd,province_name != "Ontario")

gg_ontario <- (ggplot(dd_ontario,aes(x=date))
  + geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.2,fill="black")
  + geom_line(aes(y=med),size=2,color="red")
  + facet_wrap(~var,scale="free")
  + xlim(c(as.Date("2020-10-01"),as.Date("2021-05-01")))
)

print(gg_ontario + geom_point(data=dd_ontario,aes(x=date,y=value)))
ggsave("cachestuff/ontario.png",width = 8, height = 8)


gg_all <- (gg_ontario 
  %+% dd_other
  + geom_point(data=dd_other,aes(x=date,y=value))
  + facet_wrap(~interaction(var,province_name),scale="free", ncol=4)
)

gg_all
ggsave("cachestuff/all_province.png",width = 8, height = 10)