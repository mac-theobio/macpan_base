library(tidyverse); theme_set(theme_bw(base_size = 10))
library(McMasterPandemic)

base <- readRDS("cachestuff/ont_calib_comb_mobbreaks.rds")
plot(base$fit,data=filter(base$data,date<=as.Date("2020-08-30")))
ggsave("ontario_base.png",width = 10,height = 6)


testify <- readRDS("cachestuff/ont_calib_testify.rds")
dd <- predict(testify$fit
			  , ensemble=FALSE
			  , keep_vars=c("postest")
)

ddcombo <- (testify$data
	%>% mutate(var = ifelse(var == "report","postest",var))
	%>% transmute(date, var,data=value)
	
	# %>% gather(key = "var", value="data",-date)
	%>% left_join(dd,.)
)

gg <- (ggplot(ddcombo, aes(x=date, color=var))
	   + geom_line(aes(y=value))
	   + geom_point(aes(y=data),alpha=0.3)
	   + scale_y_log10(limits=c(1,NA))
	   + theme_bw()
)

print(gg)
ggsave("ontario_testify.png",width = 10,height = 6)

testing <- (ggplot(testify$testdat,aes(x=Date,y=intensity))
	+ geom_point()
	+ ylab("Testing Intensity")
)

print(testing)
ggsave("ontario_testing.png",width = 10,height = 6)

