#!/usr/bin/env python
from datetime import datetime, timedelta
from collections import OrderedDict
import calendar
import sys
from ecmwfapi import ECMWFDataServer
import time
from dateutil.relativedelta import *
start_time = time.time()
server = ECMWFDataServer()
 
def retrieve_interim(startDate,endDate,latNorth,latSouth,lonEast,lonWest,grd,eraDir, dataset):
    """      
       A function to demonstrate how to iterate efficiently over several years and months etc    
       for a particular interim_request.     
       Change the variables below to adapt the iteration to your needs.
       You can use the variable "target" to organise the requested data in files as you wish.
       In the example below the data are organised in files per month. (eg "interim_daily_201510.grb")

       useful sources:

       Step and time
       https://software.ecmwf.int/wiki/pages/viewpage.action?pageId=56658233
    """

    cores =4
    grid=str(grd) + "/" + str(grd)
    bbox=(str(latNorth) + "/" + str(lonWest) + "/" + str(latSouth) + "/" + str(lonEast)) 

    # prescribe non-varying dataset specific settings here
    if dataset == "interim":
        timeVec = "00/12"
        step = "3/6/9/12"
        eraClass = "ei"
        
    if dataset == "era5":
        timeVec = "06/18"
        step = "1/2/3/4/5/6/7/8/9/10/11/12"
        eraClass = "ea"

    # download buffer of +/- 1 month to ensure all necessary timestamps are there for interpolations and consistency between plevel and surf
    dates = [str(startDate), str(endDate)]
    start = datetime.strptime(dates[0], "%Y-%m-%d")
    end = datetime.strptime(dates[1], "%Y-%m-%d")
    start = start+relativedelta(months=-1)
    end = end+relativedelta(months=+1)
    dateList = OrderedDict(((start + timedelta(_)).strftime(r"%Y-%m"), None) for _ in xrange((end - start).days)).keys()

    print("Retrieving"+dataset+" dataset")
    print("Bbox = " + bbox)
    print("Grid = " + grd)
    print("Start date = " , dateList[0])
    print("End date = " , dateList[len(dateList)-1])
    print("cores used = " + str(cores))

    requestDatesVec = []
    targetVec=[]
    for date in dateList:    
        strsplit = date.split('-' )
        year =  int(strsplit[0])
        month = int(strsplit[1])   
        firstDate = "%04d%02d%02d" % (year, month, 1)
        numberOfDays = calendar.monthrange(year, month)[1]
        lastDate = "%04d%02d%02d" % (year, month, numberOfDays)
        target = eraDir + "/interim_daily_SURF_%04d%02d.nc" % (year, month)
        requestDates = (firstDate + "/TO/" + lastDate)
        
        requestDatesVec.append(requestDates)
        targetVec.append(target)  

    # https://zacharyst.com/2016/03/31/parallelize-a-multifunction-argument-in-python/
    from joblib import Parallel, delayed 
    import multiprocessing 
  
    Parallel(n_jobs=cores)(delayed(interim_request)(requestDatesVec[i], targetVec[i] , grid, bbox, dataset,timeVec, step, eraClass) for i in range(0,len(requestDatesVec)))
       
@backoff.on_predicate(backoff.constant, interval=10) 
def interim_request(requestDates, target, grid, bbox, dataset, time, step, eraClass):
    """      
        An ERA interim request for analysis pressure level data.
        Change the keywords below to adapt it to your needs.
        (eg to add or to remove  levels, parameters, times etc)
        Request cost per day is 112 fields, 14.2326 Mbytes
    """
    server.retrieve({
        "dataset": dataset,
        "date": requestDates,
        "class" : eraClass,
        "stream" : "oper",
        "levtype": "sfc",
        "param": "129.128/168.128/175.128/169.128/228.128/167.128/212.128",
        "dataset": dataset,
        "step": step,
        "grid": grid,
        "time": time,
        "format": "netcdf",
        "target": target,
        "type": "fc",
        "area": bbox,
        'RESOL' : "AV",
    })
if __name__ == "__main__":
    startDate    = str(sys.argv[1])
    endDate     = str(sys.argv[2]) 
    latNorth    = str(float(sys.argv[3]))
    latSouth    =  str(float(sys.argv[4]))
    lonEast     = str(float(sys.argv[5]))
    lonWest     = str(float(sys.argv[6]))
    grd         =   str(sys.argv[7])
    eraDir      =  sys.argv[8]
    dataset     = sys.argv[9]
    retrieve_interim(startDate,endDate,latNorth,latSouth,lonEast,lonWest,grd,eraDir, dataset)

print("--- %s seconds ---" % (time.time() - start_time))



