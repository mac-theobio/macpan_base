library(tidyverse); theme_set(theme_bw(base_size = 10))

dd <- read_csv("cachestuff/VOC_vac.csv")

dd <- dd %>% filter(var=="report") 

gg_ontario <- (ggplot(dd,aes(x=date))
  + geom_ribbon(aes(ymin=lwr,ymax=upr,fill=VoC_effect),alpha=0.2)
  + geom_line(aes(y=value,color=VoC_effect),size=2)
  + facet_wrap(~var,scale="free")
  + xlim(c(as.Date("2020-10-01"),as.Date("2021-05-01")))
)

print(gg_ontario + geom_point(data=dd,aes(x=date,y=obs)))
ggsave("cachestuff/ontario.png",width = 8, height = 8)


# gg_all <- (gg_ontario 
#   %+% dd_other
#   + geom_point(data=dd_other,aes(x=date,y=value))
#   + facet_wrap(~interaction(var,province_name),scale="free", ncol=4)
# )
# 
# gg_all
# ggsave("cachestuff/all_province.png",width = 8, height = 10)