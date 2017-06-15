#!/usr/bin/env python
from datetime import datetime, timedelta
from collections import OrderedDict
import calendar
import sys
from ecmwfapi import ECMWFDataServer
import time
start_time = time.time()
server = ECMWFDataServer()
 
def retrieve_interim():
    """      
       A function to demonstrate how to iterate efficiently over several years and months etc    
       for a particular interim_request.     
       Change the variables below to adapt the iteration to your needs.
       You can use the variable "target" to organise the requested data in files as you wish.
       In the example below the data are organised in files per month. (eg "interim_daily_201510.grb")
    """
    grd =   str(sys.argv[7])
    tol = float(grd)/2 # this tol adjust extent based on out perimeter (ele.tif) to one based on grid centers (ERA).
    strtDate = str(sys.argv[1])
    endDate = str(sys.argv[2]) 
    latNorth = str(float(sys.argv[3]) - tol)
    latSouth =  str(float(sys.argv[4]) + tol)
    lonEast = str(float(sys.argv[5]) - tol)
    lonWest = str(float(sys.argv[6]) + tol)
    
    eraDir =  str(sys.argv[8])

    string = strtDate
    strsplit = string.split('-' )
    yearStart = int(strsplit[0])
    monthStart = int(strsplit[1])
    dayStart = int(strsplit[2])

    """
    following control statement makwes sure previous month is downloaded for cases where startDate is first of month to ensure 00:00:00 timestamp is acquired.
    """
    if dayStart == 1:
        if monthStart == 1:
            monthStart = 12
            yearStart = yearStart -1
        else: 
            monthStart = monthStart - 1

    string = endDate
    strsplit = string.split('-' )
    yearEnd = int(strsplit[0])
    monthEnd = int(strsplit[1])

    grid=str(grd) + "/" + str(grd)
    bbox=(str(latNorth) + "/" + str(lonWest) + "/" + str(latSouth) + "/" + str(lonEast)) 

    print("Retrieving ERA-Interim data")
    print("Bbox = " + bbox)
    print("Grid = " + grd)
    print("Start date = " + str(yearStart) + "-" + str(monthStart))
    print("End date = " + str(yearEnd) + "-" + str(monthEnd))


    dates = [str(yearStart) + '-' + str(monthStart) + '-' + str(dayStart), str(endDate)]
    start = datetime.strptime(dates[0], "%Y-%m-%d")
    end = datetime.strptime(dates[1], "%Y-%m-%d")
    dateList = OrderedDict(((start + timedelta(_)).strftime(r"%Y-%m"), None) for _ in xrange((end - start).days)).keys()

    #for year in list(range(yearStart, yearEnd + 1)):
        #for month in list(range(monthStart, monthEnd + 1)):
    for date in dateList:    
            strsplit = date.split('-' )
            year =  int(strsplit[0])
            month = int(strsplit[1])   
            startDate = "%04d%02d%02d" % (year, month, 1)
            numberOfDays = calendar.monthrange(year, month)[1]
            lastDate = "%04d%02d%02d" % (year, month, numberOfDays)
            target = eraDir + "/interim_daily_SURF_%04d%02d.nc" % (year, month)
            requestDates = (startDate + "/TO/" + lastDate)
            interim_request(requestDates, target, grid, bbox)
 
def interim_request(requestDates, target, grid, bbox):
    """      
        An ERA interim request for analysis pressure level data.
        Change the keywords below to adapt it to your needs.
        (eg to add or to remove  levels, parameters, times etc)
        Request cost per day is 112 fields, 14.2326 Mbytes
    """
    server.retrieve({
        "dataset": "interim",
        "date": requestDates,
        "stream" : "oper",
        "levtype": "sfc",
        "param": "129.128/168.128/175.128/169.128/228.128/167.128/212.128",
        "dataset": "interim",
        "step": "3/6/9/12",
        "grid": grid,
        "time": "00/12",
        "class": "ei",
        "format": "netcdf",
        "target": target,
        "type": "fc",
        "area": bbox,
        'RESOL' : "AV",
    })
if __name__ == "__main__":
    retrieve_interim()

print("--- %s seconds ---" % (time.time() - start_time))



