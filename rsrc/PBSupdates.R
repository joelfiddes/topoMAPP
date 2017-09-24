# PBS updates
# in : rasterstack of weights (bigPix)
# : landform (smlPix)

assign weights bigPix to landform resolution, dissagrgate (rasterstack = smlPix * w)

clusterloop i in 1:50:
	extract vectors for each pixel in cluster[i] and average = size 1*100 # https://stackoverflow.com/questions/19833784/how-to-extract-values-from-rasterstack-with-coordinates-xy
	end
matrix = 100 * 50






# out = sample weights (100 * 50) [ensemb * w]
