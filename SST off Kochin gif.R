###
# Step 1. Install ImageMagick if needed
# Here is how to do it on a Mac; Google to figure this out for Windows or Unix
# Open up utilities (in apps), and open Terminal.  Type the following on the command line
# ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go/install)"
# brew install imagemagick

#https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.smallPng?analysed_sst[(2018-08-28T12:00:00Z):1:(2018-08-28T12:00:00Z)][(9.7):1:(10.2)][(75.5):1:(76.3)]
url="https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.smallPng?analysed_sst%5B(2018-08-28T12:00:00Z)%5D%5B(9.525):(10.625)%5D%5B(75.925):(78.025)%5D&.draw=surface&.vars=longitude%7Clatitude%7Canalysed_sst&.colorBar=%7C%7C%7C%7C%7C&.bgColor=0xffccccff"
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.htmlTable?analysed_sst%5B(2018-08-28T12:00:00Z)%5D%5B(9.525):(10.625)%5D%5B(74.925):(76.525)%5D&.draw=surface&.vars=longitude%7Clatitude%7Canalysed_sst&.colorBar=%7C%7C%7C16%7C%7C&.bgColor=0xffccccff

# Step 2. Create a folder called chl_pngs
for(year in as.character(2014:2017)){
fil_dir <- paste0("india_sst_pngs_",year)
if(!dir.exists(fil_dir)) dir.create(fil_dir)

# Step 3. Download png from coastwatch
require(rerddap)
require(rerddapXtracto)
#url1 is the url before the date; url2 is after the data
url1="https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.png?analysed_sst%5B("
url2="T12:00:00Z)%5D%5B("
url3="):("
url4=")%5D%5B("
url5="):("
url6=")%5D&.draw=surface&.vars=longitude%7Clatitude%7Canalysed_sst&.colorBar=%7C%7C%7C24%7C34%7C&.bgColor=0xffccccff&.trim=0&.size="
size=300
lon1 <- 72.025; lon2 <- 78.025
lat1 <- 7.525; lat2 <- 10.625
lon1 <- 72.625; lon2 <- 78.375
lat1 <- 7.125; lat2 <- 15.125

# If your gifs are corrupted, you may need to change mode or method for download.file() call
for(mon in 1:12){
  for(i in seq(1,31,2)){ # i is day
    # day needs to be like 01 instead of 1
    day=formatC(i, width = 2, format = "d", flag = "0")
    month=formatC(mon, width = 2, format = "d", flag = "0")
    # put the url together
    url=paste0(url1, year, "-", month, "-", day, url2,lat1,url3,lat2,url4,
               lon1,url5,lon2,url6,size)
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
gif_fil <- paste0("kochin_sst_", year, "_fast.gif")
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

# https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplUKMO_OSTIAv20.png?analysed_sst%5B(2017-12-17T12:00:00Z)%5D%5B(9.7):(10.2)%5D%5B(72.025):(76.525)%5D&.draw=surface&.vars=longitude%7Clatitude%7Canalysed_sst&.colorBar=%7C%7C%7C16%7C34%7C&.bgColor=0xffccccff&.trim=0&.size=800
