# TO RUN
1. set config by:
- edit writeConfig.py
- python writeConfig.py

2. creat wd manually
3. ./run.sh

# DEPENDENCIES

- GDAL > 2 MODIS R package

# STRUCTURE
Describe python/ R setup here

# CONFIG  

# Todo
- check files exist and skip module if so

# Notes

- lon and lat written to lsp in toposub.R as mean values of grid - this is required by toposcale_sw in FALSE mode
- makeSurface.R requires massive matrix calc (10+GB) and crashes frequently
