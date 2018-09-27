###
# Step 1. Install ImageMagick if needed
# Here is how to do it on a Mac; Google to figure this out for Windows or Unix
# Open up utilities (in apps), and open Terminal.  Type the following on the command line
# ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go/install)"
# brew install imagemagick

# Chlorophyll-a, Aqua MODIS, NPP, L3SMI, Global, 4km, Science Quality, 2003-present (Monthly Composite)
# https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdMH1chlamday.png?chlorophyll%5B(2015-08-16T00:00:00Z)%5D%5B(15.02083):(6.020831)%5D%5B(72.02084):(79.52084)%5D&.draw=surface&.vars=longitude%7Clatitude%7Cchlorophyll&.colorBar=%7C%7C%7C%7C%7C&.bgColor=0xffccccff
url1="https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdMH1chlamday.png?chlorophyll[("
url2="T00:00:00Z)%5D%5B(15.02083):(6.020831)%5D%5B(72.02084):(79.52084)%5D&.draw=surface&.vars=longitude%7Clatitude%7Cchlorophyll&.colorBar=%7C%7C%7C%7C%7C&.bgColor=0xffccccff&.trim=0&.size="
tag="erdMH1chlamday"
size=300

# Step 2. Create a folder called sst_pngs
years = 2003:2017
for(year in as.character(years)){
fil_dir <- paste0("pngs/",tag,"_chl_pngs_",year)
if(!dir.exists(fil_dir)) dir.create(fil_dir)

# Step 3. Download png from coastwatch

# If your gifs are corrupted, you may need to change mode or method for download.file() call
for(mon in 1:12){
  for(i in 16){ # i is day
    # day needs to be like 01 instead of 1
    day=formatC(i, width = 2, format = "d", flag = "0")
    month=formatC(mon, width = 2, format = "d", flag = "0")
    # put the url together
    url=paste0(url1, year, "-", month, "-", day, url2,size)
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
gif_fil <- paste0(tag,"_kochin_chl_", year, "_fast.gif")
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

# Here is how to make a cropped png
require(png)
require(raster)
require(ggplot2)
require(grid)
img <- readPNG(fil) #read in last image
dim_img <- dim(img)
footersize <- 100 #will be different for different pngs
img_height <- dim_img[1]
img_width <- dim_img[2]
png("pngs/chl_legend.png",width=img_width, height=footersize)
grid.raster(img[(img_height-footersize):img_height, 1:img_width, ])
dev.off()

# get the names of each file
imgs=list()
years=2007:2016
for(j in 1:10){
  year=as.character(years)[j]
  fil_dir <- paste0("pngs/",tag,"_chl_pngs_",year)
  imgs[[j]] = list.files(path = fil_dir, pattern = "*.png", full.names = TRUE)
}

# Then make the gif
img = c()
imgleg = image_read("pngs/chl_legend.png")
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
image_write(imggif, "gifs/Kochin_CHL_2007-16.gif")
