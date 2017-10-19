#!/usr/bin/env python
from datetime import datetime, timedelta
from collections import OrderedDict
import calendar
import sys
from ecmwfapi import ECMWFDataServer
import time
from dateutil.relativedelta import *

server = ECMWFDataServer()
 
def interim_request(requestDates, target, grid, bbox, dataset,time, step, eraClass):
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
        "levtype": "pl",
        "param": "129.128/130.128/157.128/131.128/132.128",
        "step": step,
        "grid": grid,
        "time": time,
        "format": "netcdf",
        "target": target,
        "type": "an",
        "area": bbox,
        "levelist": "1000/975/950/925/900/875/850/825/800/775/750/700/650/600/550/500", #"500/650/775/850/925/1000", #set this according to max height of domain based on dem
        'RESOL' : "AV",
    })
if __name__ == "__main__":
    
    startDate = str(sys.argv[1])
    endDate = str(sys.argv[2]) 
    latNorth = str(float(sys.argv[3]))
    latSouth =  str(float(sys.argv[4]))
    lonEast = str(float(sys.argv[5]))
    lonWest = str(float(sys.argv[6]))
    grd =   str(sys.argv[7])
    eraDir =  sys.argv[8]
    dataset = sys.argv[9]

    start_time = time.time()
    grid=str(grd) + "/" + str(grd)
    bbox=(str(latNorth) + "/" + str(lonWest) + "/" + str(latSouth) + "/" + str(lonEast)) 

   # prescribe non-varying dataset specific settings here
    if dataset == "interim":
        time = "00/06/12/18"
        step = "0"
        eraClass = "ei"

    if dataset == "era5":
        time ="00/01/02/03/04/05/06/07/08/09/10/11/12/13/14/15/16/17/18/19/20/21/22/23"
        step = "0"
        eraClass = "ea"

    # download buffer of +/- 1 month to ensure all necessary timestamps are there for interpolations and consistency between plevel and surf
    dates = [str(strtDate), str(endDate)]
    start = datetime.strptime(dates[0], "%Y-%m-%d")
    end = datetime.strptime(dates[1], "%Y-%m-%d")
    start = start+relativedelta(months=-1)
    end = end+relativedelta(months=+1)
    dateList = OrderedDict(((start + timedelta(_)).strftime(r"%Y-%m"), None) for _ in xrange((end - start).days)).keys()

    print("Retrieving "+dataset+" dataset")
    print("Bbox = " + bbox)
    print("Grid = " + grd)
    print("Start date = " , dateList[0])
    print("End date = " , dateList[len(dateList)-1])

    # make vector here generate datelist variable
    requestDatesVec = []
    targetVec=[]
    for date in dateList:    
        strsplit = date.split('-' )
        year =  int(strsplit[0])
        month = int(strsplit[1])   
        firstDate = "%04d%02d%02d" % (year, month, 1)
        numberOfDays = calendar.monthrange(year, month)[1]
        lastDate = "%04d%02d%02d" % (year, month, numberOfDays)
        target = eraDir + "/interim_daily_PLEVEL_%04d%02d.nc" % (year, month)
        requestDates = (firstDate + "/TO/" + lastDate)
        
        requestDatesVec.append(requestDates)
        targetVec.append(target)  

        # https://zacharyst.com/2016/03/31/parallelize-a-multifunction-argument-in-python/
        from joblib import Parallel, delayed 
        import multiprocessing 
             
        Parallel(n_jobs=6)(delayed(interim_request)(requestDatesVec[i], targetVec[i] , grid, bbox, dataset,time, step, eraClass) for i in range(0,len(requestDatesVec)))
print("--- %s seconds ---" % (time.time() - start_time))


  
