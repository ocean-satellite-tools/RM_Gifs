###
# Step 1. Install ImageMagick if needed
# Here is how to do it on a Mac; Google to figure this out for Windows or Unix
# Open up utilities (in apps), and open Terminal.  Type the following on the command line
# ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go/install)"
# brew install imagemagick

#https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.smallPng?analysed_sst[(2018-08-28T12:00:00Z):1:(2018-08-28T12:00:00Z)][(9.7):1:(10.2)][(75.5):1:(76.3)]
url="https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.smallPng?analysed_sst%5B(2018-08-28T12:00:00Z)%5D%5B(9.525):(10.625)%5D%5B(75.925):(78.025)%5D&.draw=surface&.vars=longitude%7Clatitude%7Canalysed_sst&.colorBar=%7C%7C%7C%7C%7C&.bgColor=0xffccccff"
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.htmlTable?analysed_sst%5B(2018-08-28T12:00:00Z)%5D%5B(9.525):(10.625)%5D%5B(74.925):(76.525)%5D&.draw=surface&.vars=longitude%7Clatitude%7Canalysed_sst&.colorBar=%7C%7C%7C16%7C%7C&.bgColor=0xffccccff

# Notes on other SST sources are below
#Global SST & Sea Ice Analysis, L4 OSTIA, UK Met Office, Global, 0.05°, Daily, 2013-present
# Fine scale.  Looks similar to the OISST but finer scale
url1="https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.png?"
url2="T12:00:00Z)%5D%5B("
tag="jplUKMO_OSTIAv20"
val="analysed_sst"
years=2013:2017
# url="https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.png?analysed_sst%5B("
# url2="T12:00:00Z)%5D%5B(7.125):(15.125)%5D%5B(72.625):(78.375)%5D&.draw=surface&.vars=longitude%7Clatitude%7Canalysed_sst&.colorBar=%7C%7C%7C24%7C34%7C&.bgColor=0xffccccff&.trim=0&.size="
lon1 <- 72.125; lon2 <- 79.375; lat1 <- 6.125; lat2 <- 15.125
# SST, Daily Optimum Interpolation (OI), AVHRR Only, Version 2, Final+Preliminary, 1981-present
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/ncdcOisst2Agg.graph?sst[(2016-08-21T00:00:00Z)][(0.0)][(6.125):(15.125)][(72.625):(79.375)]&.draw=surface&.vars=longitude%7Clatitude%7Csst&.colorBar=%7C%7C%7C24%7C34%7C&.bgColor=0xffccccff
# This is interpolated to fill in gaps
# https://www.ncdc.noaa.gov/oisst
# Look good
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/ncdcOisst2Agg
# url1="https://coastwatch.pfeg.noaa.gov/erddap/griddap/ncdcOisst2Agg.png?sst%5B("
# url2="T00:00:00Z)%5D%5B("
tag="ncdcOisst2Agg"
val="sst"
years=2015:2017
url1="https://coastwatch.pfeg.noaa.gov/erddap/griddap/ncdcOisst2Agg.png?"
url2="T00:00:00Z)][(0.0)][("
lon1 <- 72.125; lon2 <- 80.125; lat1 <- 6.125; lat2 <- 15.125
lon1 <- 72.125; lon2 <- 79.375; lat1 <- 6.125; lat2 <- 15.125

# Step 2. Create a folder called sst_pngs
for(year in as.character(years)){
fil_dir <- paste0("pngs/",tag,"_pngs_",year)
if(!dir.exists(fil_dir)) dir.create(fil_dir)

# Step 3. Download png from coastwatch
#url1 is the url before the date; url2 is after the data
#url4=")%5D%5B("
#url3="):("
#url5="):("
url5=")%5D&.draw=surface&.vars=longitude%7Clatitude%7C"
url6="&.colorBar=%7C%7C%7C24%7C34%7C&.bgColor=0xffccccff&.trim=0&.size="
size=300

# If your gifs are corrupted, you may need to change mode or method for download.file() call
for(mon in 1:12){
  for(i in seq(1,31,7)){ # i is day
    # day needs to be like 01 instead of 1
    day=formatC(i, width = 2, format = "d", flag = "0")
    month=formatC(mon, width = 2, format = "d", flag = "0")
    # put the url together
    url=paste0(url1, val, "[(", year, "-", month, "-", day, url2, lat1,"):(",lat2,")][(",
              lon1,"):(",lon2,url5,val,url6,size)
#    url=paste0(url1, year, "-", month, "-", day, url2, size)
    
    # make the filename
    fil=paste0(fil_dir,"/file-",year,"-",month,"-",day,".png")
    # wrap in try() so doesn't crash if no file for that day
    try(download.file(url,destfile=fil, mode="wb"))
  }
}

# Step 4. Make the gif
library(ggplot2) # plotting
library(dplyr) # for %>% pipe
library(purrr) # for map()
library(magick) # for image_read(), image_join(), image_animate(), image_write()

# Add a header with the year, month and day
library(stringr)
files = list.files(path = fil_dir, pattern = "*.png", full.names = T)
for(i in files){
  yr=str_split(i,"-")[[1]][2]
  mon=month.abb[as.numeric(str_split(i,"-")[[1]][3])]
  day=as.numeric(str_split(str_split(i,"-")[[1]][4],"[.]")[[1]][1])
  ann.text = paste(yr,mon,day)
  img = image_read(i)
  img = image_annotate(img, ann.text, size = 20, color = "black", location = "+130+0")
  image_write(img, i, 'png')  
}
  
# List those Plots, Read them in, and then make animation
gif_fil <- paste0(tag,"_kochin_sst_", year, "_fast.gif")
list.files(path = fil_dir, pattern = "*.png", full.names = T) %>% 
  map(image_read) %>% # reads each path file
  image_join() %>% # joins image
  image_animate(fps=4) %>% # animates, can opt for number of loops
  image_write(gif_fil) # write to current dir
} 

# # Here is how to make a cropped png
# require(png)
# require(raster)
# require(ggplot2)
# require(grid)
# img <- readPNG(fil)
# dim_img <- dim(img)
# footersize <- 190 #will be different for different pngs
# img_height <- dim_img[3]-footersize
# img_width <- dim_img[2]
# png(paste0("crop-",fil),width=img_width, height=img_height)
# grid.raster(img[1:img_height,1:img_width,])
# dev.off()

# Notes on other SST sources
# AVHRR Pathfinder Version 5.3 L3-Collated (L3C) SST, Global, 0.0417°, 1981-2018, Daytime (1 Day Composite)
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/nceiPH53sstd1day
# Many missing pixel for 1-day and doesn't match other sources; 1-month composite looks 'ok' but low resolution

# SST, GHRSST Blended, MW-IR-OI-RT, Near Real Time, Global, 2006-2012 (1 Day Composite)
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdGRssta1day
# Should be same/similar to 
# SST, GHRSST Blended, MW-IR-OI, Science Quality, Global, 2006-2011 (1 Day Composite)
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdG1ssta1day
# But doesn't seem to capture the upwelling quite as well; almost the same though
# The 'Science Quality' data set is indicated as the better one to use in the background.
# This product is available in v5.0 from 1998-2017 here
# http://www.remss.com/measurements/sea-surface-temperature/oisst-description/

# SST, POES AVHRR, GAC, Global, Day and Night, 2006-2016 (1 Day Composite)
# too many missing pixels; infared gets to coast but blocked by clouds

# SST, Daily Optimum Interpolation (OI), AVHRR Only, Version 2, Final+Preliminary, 1981-present
# This is interpolated to fill in gaps
# https://www.ncdc.noaa.gov/oisst
# Look good
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/ncdcOisst2Agg

#SST, GHRSST Blended, MW-IR-OI-RT, Near Real Time, Global, 2006-2012 (1 Day Composite)
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdGRssta1day
# Finer scale than above and looks 'similar-ish' but not one above looks more simiar to the UK data

# get the names of each file
imgs=list()
for(j in 1:4){
  year=as.character(years)[j]
  fil_dir <- paste0("pngs/",tag,"_pngs_",year)
  imgs[[j]] = list.files(path = fil_dir, pattern = "*.png", full.names = TRUE)
}

# Then make the gif 4x4
img = c()
imgleg = image_read("pngs/legend.png")
for(i in 1:length(imgs[[1]])){
  theimgs=list()
  for(j in 1:4){
    theimgs[[j]]=image_read(imgs[[j]][i])
    theimgs[[j]] = image_crop(theimgs[[j]], geometry_area(width = 300, height = 332, x_off = 7, y_off = 0))
  }
  imtop <- image_append(image_join(theimgs[[1]],theimgs[[2]]))
  imbot <- image_append(image_join(theimgs[[3]],theimgs[[4]]))
#  imtop <- image_append(image_join(theimgs[[1]],theimgs[[2]],theimgs[[3]],theimgs[[4]],theimgs[[5]]))
#  imbot <- image_append(image_join(theimgs[[6]],theimgs[[7]],theimgs[[8]],theimgs[[9]],theimgs[[10]]))
  im <- magick::image_append(image_join(imtop, imbot, imgleg), stack=TRUE)
  img <- image_join(img, im)
}
imggif = image_animate(img, fps=4, loop=1)
image_write(imggif, paste0("gifs/",tag,"_",years[1],"-",years[4],".gif"))

# 1981:2017 data
# Make legend
require(png)
require(raster)
require(ggplot2)
require(grid)
img <- readPNG(fil) #read in last image
dim_img <- dim(img)
footersize <- 100 #will be different for different pngs
img_height <- dim_img[1]
img_width <- dim_img[2]
png("pngs/sst_legend.png",width=img_width, height=footersize)
grid.raster(img[(img_height-footersize):img_height, 1:img_width, ])
dev.off()


# Then make the gif 
for(year in c(1987,1997,2007)){
  years=year:(year+9)
  # get the names of each file
  imgs=list()
  for(j in 1:10){
    year=as.character(years)[j]
    fil_dir <- paste0("pngs/",tag,"_pngs_",year)
    imgs[[j]] = list.files(path = fil_dir, pattern = "*.png", full.names = TRUE)
  }
img = c()
imgleg = image_read("pngs/sst_legend.png")
for(i in 1:length(imgs[[1]])){
  theimgs=list()
  for(j in 1:10){
    theimgs[[j]]=image_read(imgs[[j]][i])
    theimgs[[j]] = image_crop(theimgs[[j]], geometry_area(width = 300, height = 332, x_off = 7, y_off = 0))
  }
  imtop <- image_append(image_join(theimgs[[1]],theimgs[[2]],theimgs[[3]],theimgs[[4]],theimgs[[5]]))
  imbot <- image_append(image_join(theimgs[[6]],theimgs[[7]],theimgs[[8]],theimgs[[9]],theimgs[[10]]))
  im <- magick::image_append(image_join(imtop, imbot, imgleg), stack=TRUE)
  img <- image_join(img, im)
}
imggif = image_animate(img, fps=4, loop=1)
image_write(imggif, paste0("gifs/",tag,"_",years[1],"-",years[10],".gif"))
}

# Now upload gifs to https://ezgif.com/gif-to-mp4

