#====================================================================
#	Retrive latest sentinel 2
#====================================================================
#https://www.evernote.com/Home.action#n=e77ce355-1b1e-4a89-896b-4036f905dfea&ses=1&sh=5&sds=5&x=sentinel&

#This CLI works:
sentinelsat -u jfiddes -p sT0kkang -g extent.json -s 20151201 -e 20151207 --sentinel 2 --cloud 90 -d

#This API doesnt work yet (input posiitions from getExtent.py:

from geojson import Polygon
 gj = Polygon([[(float(lonW), float(latN)), (float(lonW), float(latS)) , (float(lonE),float(latS)), (float(lonE), float(latN)), (float(lonW), float(latN))]])

{"coordinates": [[[lonW, latN], [lonW, latN],  [lonE,latS],  [lonE, latN] ]], "type": "Polygon"}

import geojson
gj.is_valid



from sentinelsat import SentinelAPI, read_geojson, geojson_to_wkt
from datetime import date
api = SentinelAPI('jfiddes', 'sT0kkang', 'https://scihub.copernicus.eu/dhus')
footprint = gj
products = api.query(footprint, beginposition = '[20160101 TO 20160103]', platformname = 'Sentinel-2', cloudcoverpercentage = '[0 TO 30]')
