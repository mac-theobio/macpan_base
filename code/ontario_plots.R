library(tidyverse); theme_set(theme_bw(base_size = 10))
## point to OLD/stored MacPan
.libPaths(c("Rlib", .libPaths()))
library(McMasterPandemic)
packageVersion("McMasterPandemic")
library(shellpipes)
library(anytime) ## required because cached objects still think we are loading this pkg

base <- rdsRead("ontario_calibrate")
testify <- rdsRead("ontario_testify")
dat <- rdsRead("_setup")

(plot(base$fit, data=filter(base$data, date<=as.Date("2020-08-30")))
    ## 'dlspace' not working, alas
    + scale_x_date(date_breaks="1 month", date_labels="%b-%Y")
    + expand_limits(x = as.Date("2020-10-01"))
) %>% teeGG(desc="base",width = 10,height = 6)

## 2023 Jul 17 (Mon) Does this really belong here or should it be upstream?
dd <- suppressWarnings(predict(testify$fit
			  , ensemble=FALSE
			  , keep_vars=c("postest"))
)

ddcombo <- (testify$data
	%>% mutate(var = ifelse(var == "report","postest",var))
	%>% transmute(date, var,data=value)
	
	# %>% gather(key = "var", value="data",-date)
    %>% left_join(dd,., by = c("date", "var"))
    %>% select(date, var, value, data)
)


start_date <- as.Date("2020-03-01")
end_date <- as.Date("2020-10-01")

## https://r-graph-gallery.com/line-chart-dual-Y-axis-ggplot2.html
iscale <- 100 ## approx testing intensity/positive test ratio

testdat <- (dat$test_data_fill
    %>% filter(between(Date,start_date,end_date))
    %>% rename(date = "Date", data = "intensity")
    %>% mutate(var = "intensity", data = data/iscale)
)

ddcombo2 <- bind_rows(ddcombo, testdat)

(ggplot(ddcombo2, aes(x=date))
    + geom_line(data = ddcombo, aes(y=value), colour = "black")
    + geom_point(aes(y=data, colour  = var), alpha=0.3)
    + theme_bw()
    + scale_colour_manual(values = c("red", "black"))
    + scale_shape_manual(values = 1:2)
    + scale_x_date(date_breaks="1 month", date_labels="%b-%Y")
    + scale_y_continuous(name = "positive tests",
                         sec.axis = sec_axis(~.*iscale, name = "testing intensity"))
    + geom_vline(aes(xintercept=as.Date("2020-09-01")), lty = 2)
    ## can't combine log/lin scale, so use linear for both
) %>% teeGG(desc="testify", width = 10,height = 6)

## testing <- (ggplot(testdat,aes(x=Date,y=intensity))
## 	+ geom_point()
## 	+ ylab("Daily Testing")
## 	+ scale_x_date(date_breaks="1 month", date_labels="%b"
## #		, limits=c(start_date,end_date))
## 	)
## 	+ geom_vline(aes(xintercept=as.Date("2020-09-01")))
## )

## print(testing)
## ggsave("figure/ontario_testing.png",width = 10,height = 6)

## saveEnvironment() ## don't saveEnvironment unless there's a reason; plotting files should usually not?
