#!/usr/bin/env python

# docstring
""" This module is an example run.

Example:
        $ python example_run.py

Attributes:

Todo:
"""

# imports
import domain_setup as dset

dset.getDEM_points("/home/joel/sim/topomap_test/", "/home/joel/data/DEM/srtm",0.75,"/home/joel/data/GCOS/points_all.txt",2,3)


