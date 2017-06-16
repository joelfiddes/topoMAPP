#!/usr/bin/env python

# docstring
""" This module is an example run. """

# imports
import getDEM_points as dget

dget("/home/joel/sim/topomap_test/", "/home/joel/data/DEM/srtm", 0.75, "/home/joel/data/GCOS/points_all.txt", 2, 3)

#"/home/joel/sim/topomap_test/" "/home/joel/data/DEM/srtm" 0.75 "/home/joel/data/GCOS/points_all.txt" 2 3

python getDEM_points.py "/home/joel/sim/topomap_test/" "/home/joel/data/DEM/srtm" 0.75 "/home/joel/data/GCOS/points_all.txt" 2 3