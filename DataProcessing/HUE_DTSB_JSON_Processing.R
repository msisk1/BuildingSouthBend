#Setup
rm(list=ls(all=TRUE)) # clear memory

packages<- c("maptools","rgdal","leaflet","htmlwidgets") # list the packages that you'll need
lapply(packages, require, character.only=T) # load the packages, if they don't load you might need to install them first
setwd("N:/www_pages_moved_to_AWS/BuildingSouthBend/DataProcessing")
out.dir.name <- "WebData"
data.dir.name <- "SpatialData"
district.json.name <- file.path("../LeafletModules/WebData","Districts.js")
out.path <- file.path(getwd(),out.dir.name)


property.download <- TRUE
latlong <- "+init=epsg:4326"

active.sections <- c("West Washington","Downtown","Chapin Park","West North Shore", "River Bend","Riverside Drive","East Wayne Street",
                     "Edgewater Place","Lincolnway East","North St. Joseph Street","Taylor's Field")
if(property.download){
        download.file("http://buildingsouthbend.nd.edu/properties.csv", destfile = "properties.csv")
        buildings.table <- read.csv("properties.csv",stringsAsFactors = F)
        buildings.table<- buildings.table[complete.cases(buildings.table[ ,c("Longitude","Latitude")]),]
        coordinates(buildings.table)=~Longitude+Latitude
        proj4string(buildings.table) <- CRS(latlong)
        writeOGR(buildings.table, dsn="." ,layer="All_SB_Buildings_20171117",driver="ESRI Shapefile",overwrite_layer = T)
        
}


#Loading and subsetting historic district data
historic.districts <- readOGR(dsn = "SpatialData", layer = "Historic_Districts_LL")
proj4string(historic.districts) <- CRS("+init=epsg:3857")  #I have no idea why this is required.
historic.districts<- spTransform(historic.districts, CRS("+init=epsg:3857"))

#adding label locations to historic districts
label.locs <- read.csv(file.path(data.dir.name, "District_extraData.csv"))
# label.locs$lab_both <- paste("[",label.locs$lab_Lat,",",label.locs$lab_Lon,"]",sep = "")

historic.districts <- merge(historic.districts,label.locs,by="District_N")
historic.districts@data$used <- 0
historic.districts@data$used[historic.districts@data$District_N %in% active.sections] <- 1

#Creating a leaflet module for each district

buildings.table$popupw <- paste(sep = "",  "<b>",buildings.table$Slug,"</b><br/>",
                                          "Name = ",buildings.table$Custom.Name,"<br/>"
)

leaflet() %>% 
  addTiles() %>% #basic OSM
  addMarkers(data = buildings.table, popup = buildings.table$popupw)  %>%#For the points
  addPolygons(data = historic.districts[which(historic.districts$used==1),])














writeOGR(historic.districts, "temp", layer="historic.districts", driver="GeoJSON")
file.copy("temp", district.json.name, overwrite = T) #for some reason I can't get writeOGR to write to a subdirectory, so this just copys it.
file.remove("temp") #and deletes the temp file
text.json <- readChar(district.json.name, file.info(district.json.name)$size)
text.json <- paste("var districts = ",text.json,";", sep="") 
write(text.json,district.json.name)


#Loading and subsetting building data
buildings.table <- read.csv("Historic-District-Structures_ALL.csv")
coordinates(buildings.table)=~Long+Lat
proj4string(buildings.table) <- CRS("+init=epsg:3857")
sub.buildings <- buildings.table[sub.districts, ]
# 
# 


#writeOGR(sub.districts, dsn="sub.districts.kml", layer= "sub.districts", driver="KML", dataset_options=c("NameField=name"))

#This is for updating the buildings

download.file("http://buildingsouthbend.nd.edu/properties.csv", destfile = "properties.csv")
buildings.table <- read.csv("properties.csv",stringsAsFactors = F)
coordinates(buildings.table)=~Longitude+Latitude
proj4string(buildings.table) <- CRS(latlong)
writeOGR(buildings.table, dsn="." ,layer="All_SB_Buildings_20170706",driver="ESRI Shapefile",overwrite_layer = T)





if(F){ #This is a bunch of testing garbage
        again.json <- readChar( file.path("../LeafletModules/WebData","again.js"), file.info( file.path("../LeafletModules/WebData","again.js"))$size)
        District.json <- readChar(district.json.name, file.info(district.json.name)$size)
        identical(again.json,District.json)        
}
