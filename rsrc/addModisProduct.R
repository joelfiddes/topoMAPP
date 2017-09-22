#https://n5eil01u.ecs.nsidc.org/MOST/MOD10A1.006/ - TERRA
#https://n5eil01u.ecs.nsidc.org/MOSA/MYD10A1.006/ - AQUA
#require earthdata login

MODIS PACKAGE (cant add snow product)

MODIS:::addProduct(product = "MOD10A1", sensor = "MODIS", platform = "Terra",pf1 = "MOST", pf2 = "MOD10A1.006", res = "500m", temp_res ="1 Day", topic = "Daily snow covered area", server = "https://n5eil01u.ecs.nsidc.org",path_ext="/home/joel/R/x86_64-pc-linux-gnu-library/3.4/MODIS/external", overwrite=TRUE)

myextent=raster('predictors/ele.tif') # output is projected and clipped to this extent

runGdal(product='MOD10A1', collection = NULL, begin = "2000-08-12", end = "2000-08-12", extent = myextent, tileH = NULL, tileV = NULL, buffer = 0,SDSstring = "1 0 0 0 0 0 0 0 0 0 0 0", job = NULL, checkIntegrity = TRUE, wait = 0.5, forceDownload = TRUE, overwrite = FALSE)


Python (does not doenløoad())


sat="MOD10A1"
date= lubridate::ymd("2016-01-01")
h = 18
v = 5
printFTP = TRUE
#function (date, sat = "MYD10A1", h = 10, v = 10, printFTP = FALSE, 
#    ...) 
#{

    if (!class(date) %in% c("Date", "POSIXlt", "POSIXct")) {
        stop("MODISSnow: date should be an object of class Date")
    }
    if (!sat %in% c("MYD10A1", "MOD10A1")) {
        stop("MODISSnow: unknown satellite requested")
    }
    folder_date <- base::format(date, "%Y.%m.%d")
    

    # ftp <- if (sat == "MYD10A1") {
    #     paste0("https://n5eil01u.ecs.nsidc.org/MOLA/", sat, ".006/", folder_date, "/")
    # }    else {
    #     paste0("https://n5eil01u.ecs.nsidc.org/MOST/", sat, ".006/", folder_date, "/")
    # }
ftp <-   paste0("https://n5eil01u.ecs.nsidc.org/MOST/", sat, ".006/", folder_date, "/")
  


    if (printFTP) 
        print(ftp)
    curl <- RCurl::getCurlHandle()
    fls <- RCurl::getURL(ftp, curl = curl, dirlistonly = TRUE)
    rm(curl)
    base::gc()
    base::gc()
    fls <- unlist(strsplit(fls, "\\n"))
    fls <- fls[grepl("hdf$", fls)]
    tile <- fls[grepl(paste0(sat, ".A", lubridate::year(date), 
        "[0-9]{3}.h", formatC(h, width = 2, flag = 0), "v", formatC(v, 
            width = 2, flag = 0)), fls)]
    if (length(tile) != 1) {
        stop("MODISSnow: requested tile not found")
    }
    get_tile(ftp, tile, ...)
#}

#=====================================================================================================================
# MODIStsp
#=====================================================================================================================
require(MODIStsp) 
require(raster)
#https://github.com/lbusett/MODIStsp

#gui accepts tiff command line not
#cant pass time satrt end at command line

# r=raster("/home/joel/sim/topomap_test/predictors/ele.tif")
# e=extent(r)
# p = as(e, 'SpatialPolygons')
# projection(p) <- CRS("+init=epsg:4326")
# shapefile(p, '/home/joel/sim/topomap_test/predictors/extent.shp')
options_file = '/home/joel/data/MODIS_ARC/SCA/options.json'
longWest=7
longEast=9
latNorth=47
latSouth=46
startDate="2017-02-01"
EndDate="2017-02-11"

bboxNew=paste0(' "bbox": [ ',     longWest, ',',    latSouth,  ',',     longEast,  ',',    latNorth,' ],')
sdate=('"start_date": startDate,')
edate=('"end_date": endDate,')

sedCommand= paste0('sed -i "s/bbox/',bboxNew,'/g"' , options_file)
system(sedCommand)

"bbox": [      5,     46,      6,     47 ],



MODIStsp(gui = FALSE, options_file = options_file) 

#, start_date= "2017-03-01",end_date= "2017-03-11")
