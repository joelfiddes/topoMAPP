#daplay.R

wd = "/home/joel/mnt/myserver/nas/sim/SIMS_JAN18/gcos_cor_ensemble/"
priorwd= "/home/joel/mnt/myserver/nas/sim/SIMS_JAN18/gcos_cor/"
grid= 1
nens= 100
Nclust= 150
sdThresh= 13
R= 0.016
DSTART= 160
DEND= 360
senDir= "/home/joel/mnt/myserver/nas/data/sentinel/"


#inputs

# readin data
landform = raster(paste0(priorwd, "/grid", grid, "/landform.tif"))

# project to utm
lf.utm=projectRaster(from=landform, crs=crs(rstack), method="ngb")

#rstack = brick(paste0(priorwd, "/fsca_stack.tif"))
rstack = brick(paste0(senDir, "/fsca_stack1km.tif"))
obsTS = read.csv(paste0(priorwd, "/fsca_dates.csv"))
obsind = which(ds%in%as.Date(obsTS$x))
        # cut to start end points (melt season )
        obsind <- obsind[obsind >= DSTART & obsind <= DEND]
# convert to doy soince sept 1

load(paste0(wd, "/ensembRes_", grid, ".rd"))

# valshp
shp = shapefile("/home/joel/mnt/myserver/nas/data/GCOS/metadata_easy.csv")
shp.utm = spTransform(shp,'+proj=utm +zone=32 +ellps=WGS84 +datum=WGS84 +units=m +no_defs')

# cluster ids
ids = extract(lf_utm, shp.utm)
stat=shp.utm$STAT_AB

# pixel numbers
pixIDS = extract(rstack[[1]],shp.utm, cellnumbers=T)

# id table
idtab = cbind(ids, stat, pixIDS[,1])

# piuxel based timeseries
pixTS = extract(rstack, 1:ncell(rstack))

# compute weights
i = as.numeric(idtab[7,3])



npix = na.omit(pixIDS)[,1]
wmat=c()
for (i in npix){
        # Extract pixel based timesries of MODIS obs and scale
        obs = pixTS[i, ]


        start = DSTART  #lastdateover95

        end = DEND  #firstnodata
    
        # set default here TRIAL start = DSTART end = DEND

        # identify missing dates and reset start end index
         



        # MODIS pixel,i mask
        singlecell = rasterFromCells(rstack[[1]], i, values = TRUE)

        # extract smallpix using mask
        smlPix = crop(lf.utm, singlecell)

        # compute sample IDs that occur in MODIS pixel,i, this is ragged and varies
        # tri+-modally (sample of 4609) between eg.289, 272,256 (based on an experiment)
        sampids = values(smlPix)


        # ensemble loop init HX
        HX = c()
        for (j in 1:nens) {

            #print(j)
            # number of smallpix in MODIS pixel nsmlpix <- length(sampids)
            nsmlpix <- length(which(!is.na(sampids) == TRUE))


            # get unique sim ids
            simindexs <- unique(sampids[!is.na(sampids)])

            # number of unique samples in pixel
            nSamp <- length(simindexs)

            # number of NA's in pixel
            nNA = length(which(is.na(sampids) == TRUE))



            # extract vector of each sample sca that occurs in pixel
            mat <- ensembRes[, simindexs, j]

            # mat <- mat[1:length(obs),] # this has to be replaced by correct date matching

            # count occurance of each in sample
            tab <- as.data.frame(table(sampids))
            tabmat <- t(mat) * tab$Freq

            # fSCA for pixel i and ensemble j
            fsca = colSums(tabmat)/nsmlpix

            # append to ensemble matrix
            HX = cbind(HX, fsca)

        }

        # wmat = cbind(wmat,w) y=as.vector(HX) 
        # sink("dopar.log", append=TRUE)
        # cat(paste("% complete:", (i/npix) * 100,"  -  Starting wmat iteration", i, "\n"))
        print(paste("% complete WMAT:", (i/npix[length(npix)] * 100)))
        # sink()

        w = PBS(HX[obsind, ], obs, R)
        wmat=cbind(wmat,w)
}

