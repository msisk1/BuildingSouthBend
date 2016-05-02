#Setup
rm(list=ls(all=TRUE)) # clear memory

packages<- c("maptools","rgdal","leaflet","htmlwidgets") # list the packages that you'll need
lapply(packages, require, character.only=T) # load the packages, if they don't load you might need to install them first
#setwd("E:\\GIT_Checkouts\\BuildingSouthBend\\DataProcessing\\")
out.dir.name <- "WebData"
data.dir.name <- "SpatialData"
district.json.name <- file.path("../LeafletModules/WebData","Districts.js")
out.path <- file.path(getwd(),out.dir.name)



active.sections <- c("West Washington","Downtown","Chapin Park","West North Shore")

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


#Loading and subsetting building data
# buildings.table <- read.csv("Historic-District-Structures_ALL.csv")
# coordinates(buildings.table)=~Long+Lat
# proj4string(buildings.table) <- CRS("+init=epsg:3857")
# sub.buildings <- buildings.table[sub.districts, ]
# 
# 


#writeOGR(sub.districts, dsn="sub.districts.kml", layer= "sub.districts", driver="KML", dataset_options=c("NameField=name"))


writeOGR(historic.districts, "temp", layer="historic.districts", driver="GeoJSON")
file.copy("temp", district.json.name, overwrite = T)
file.remove("temp")
text.json <- readChar(district.json.name, file.info(district.json.name)$size)
text.json <- paste("var districts = ",text.json,";", sep="") 
write(text.json,district.json.name)




if(F){
        again.json <- readChar( file.path("../LeafletModules/WebData","again.js"), file.info( file.path("../LeafletModules/WebData","again.js"))$size)
        District.json <- readChar(district.json.name, file.info(district.json.name)$size)
        identical(again.json,District.json)        
}

# 
# #Creating the leaflet instance
# 
# m <- leaflet() %>%
#         addProviderTiles("Esri.WorldTopoMap", group = "ESRI World Topo") %>%
# #         addTiles(group = "OpenStreetMap") %>%  # Add default OpenStreetMap map tiles
# # #         addMarkers(data=sub.buildings, group = "Locations") %>%
# #         addCircleMarkers(data=sub.buildings,
# #                          radius = 3,
# #                          color = "green",
# #                          stroke = FALSE, fillOpacity = 1, group = "Locations") %>%
#         addPolygons(data=sub.districts, group = "Historic Disctricts")
# # %>%
# #         addLayersControl(
# #                 baseGroups = c("ESRI World Topo","OpenStreetMap","Letarouilly"),
# #                 overlayGroups = c("Locations", "Historic Disctricts"),
# #                 options = layersControlOptions(collapsed = FALSE)
# #         )
# m
# 

# saveWidget(widget = m, file=paste("","your_map.html",sep=""), selfcontained = FALSE)