#!/usr/bin/env python
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
server.retrieve({
    "class": "ei",
    "dataset": "interim",
    "stream": "oper",
    "expver": "1",
    "date": "2007-01-01/to/2017-01-31",
    "type": "fc",
    "levtype": "sfc",
    "param": "228.128",             # parameter 'total precipitation'
    "step": "12",                   # accumulation over 12 hours
    "time": "00:00:00/12:00:00",    # from the two forecasts initialized at 00:00 and 12:00
    "grid": "0.75/0.75",
    "format": "netcdf",
    "area": "42/66/36/76",
    "target": "tp.nc",             # change this to your output file name
})
