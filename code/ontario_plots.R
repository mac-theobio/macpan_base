library(tidyverse); theme_set(theme_bw(base_size = 10))
library(McMasterPandemic)
library(shellpipes)
library(anytime) ## required because cached objects still think we are loading this pkg

## How do I read in two rds again in shellpipe-verse?

base <- readRDS("code/cachestuff/ont_calib_comb_mobbreaks.rds")
(plot(base$fit,data=filter(base$data,date<=as.Date("2020-08-30")))
	+ scale_x_date(date_breaks="1 month", date_labels="%b")
)
ggsave("figure/ontario_base.png",width = 10,height = 6)


testify <- readRDS("code/cachestuff/ont_calib_testify.rds")
dd <- predict(testify$fit
			  , ensemble=FALSE
			  , keep_vars=c("postest")
)
## debugging:
## debug(sim_fun)
## debug(run_sim)
## Error in `[<-`(`*tmp*`, 1, names(state), value = c(S_u = 14569404.7660548,  : 
##   subscript out of bounds
## options(error=recover)
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
	+ scale_x_date(date_breaks="1 month", date_labels="%b")
)

print(gg)
ggsave("figure/ontario_testify.png",width = 10,height = 6)

dat <- readRDS("code/cachestuff/calibrate_comb_setup.rds")

start_date <- as.Date("2020-03-01")
end_date <- as.Date("2020-10-01")

testdat <- (dat$test_data_fill
	%>% filter(between(Date,start_date,end_date))
)


testing <- (ggplot(testdat,aes(x=Date,y=intensity))
	+ geom_point()
	+ ylab("Daily Testing")
	+ scale_x_date(date_breaks="1 month", date_labels="%b"
#		, limits=c(start_date,end_date))
	)
	+ geom_vline(aes(xintercept=as.Date("2020-09-01")))
)

print(testing)
ggsave("figure/ontario_testing.png",width = 10,height = 6)

