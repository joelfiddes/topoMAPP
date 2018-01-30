#' @title MODIStsp main function
#' @description Main function for the MODIS Time Series Processing Tool
#'   (MODIStsp)
#' @details The function is used to:
#'  - initialize the processing (folder names, packages, etc.);
#'  - launch the GUI ([MODIStsp_GUI()]) and receive its outputs on interactive
#'    execution, or load an options file on non-interactive execution;
#'  - launch the routines for downloading and processing the requested datasets.
#'    ([MODIStsp_process()])
#' @param gui `logical` if TRUE: the GUI is opened before processing. If FALSE:
#'  processing parameters are retrieved from the provided `options_file`
#'  argument), Default: FALSE (TRUE now defunct)
#' @param options_file `character` full path to a JSON file
#'  containing MODIStsp processing options saved from the GUI. If NULL,
#'  parameters of the last successful run are retrieved from file
#'  "MODIStsp_Previous.json" in subfolder "Previous"), Default: NULL
#' @param spatial_file_path `character` (optional) full path of a spatial file
#'  to use to derive the processing extent. If not NULL, the processing options
#'  which define the extent, the selected tiles and the "Full Tile / Resized"
#'  in the JSON options file are overwritten and new files are created on the
#'  extent of the provided spatial file, Default: NULL

##' @param test `integer` if set, MODIStsp is executed in "test mode", using a
##'  preset Options File instead than opening the GUI or accepting the
##'  `options_file` parameter. This allows both to check correct installation on
##'  user's machines, and to implement unit testing. The number indicates which
##'  tests to execute (six are available). If == 0, the test is selected
##'  randomly. If == -1, MODIStsp is executed in normal mode. Default: -1
##' @param n_retries `numeric` maximum number of retries on download functions.
##'   In case any download function fails more than `n_retries` times consecutively,
##'   MODIStsp_process will abort, Default: 20
##' @param verbose `logical` If FALSE, suppress processing messages,
##'  Default: TRUE

                          
# jf 2018.30.01                        
# code below adapted from lbusett R-package MODIStsp https://github.com/lbusett/MODIStsp
# Removed all gui stuff and associated dependencies which cause a lot of headaches on multiple server deployments (eg. X11 requirement gtkWidgets etc)
# see this issuefor a description https://github.com/lbusett/MODIStsp/issues/94

# requires options file as inputs
# optionally takes points/polygon shape to define AOI
args = commandArgs(trailingOnly=TRUE)
previous_jsfile=args[1] # option file
spatial_file_path=args[2]  # can be "null" if use bbox specified in options file                        
                                                
# source all required funcytions                          
sourceDir <- function(path) {
	for (nm in list.files(path, pattern = '\\.[Rr]$')) {
	source(file.path(path, nm))
	}
}

sourceDir(path="./rsrc/modistsp_functions/")

# read in MODIS product descriptions file
prodopts_file = "./rsrc/modistsp_functions/MODIStsp_ProdOpts.RData"                  

                         

# fixed parameters
verbose=TRUE
test=-1
n_retries=20
gui=FALSE
mod_proj_str <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs" #nolint
start_time <- Sys.time()
  

    #   ________________________________________________________________________
    #   on start, load options from `previous_jsfile` and MODIS products    ####
    #   info from `prodopts_file`
    
    if (file.exists(previous_jsfile)) {
      general_opts <- try(jsonlite::fromJSON(previous_jsfile))
      # stop on error
      if (class(general_opts) == "try-error") {
        stop(
          "Unable to read the provided JSON options file. Please check your ", 
          "inputs!"
        )
      }
    } else {
      message("[", date(), "] Processing Options file not found! Aborting!")
      stop()
    }
    if (file.exists(prodopts_file)) {
      prod_opt_list <- get(load(prodopts_file))
    } else {
      message("[", date(), "] Product information file not found! Aborting!")
      stop()
    }
    # retrieve options relative to the selected product and version from the
    # "prod_opt_list" data frame
    
    sel_prod   <- general_opts$sel_prod
    sel_ver    <- general_opts$prod_version
    prod_opts  <- prod_opt_list[[sel_prod]][[sel_ver]]
    
    # Load also the custom indexes saved by the user
    custom_idx <- general_opts$custom_indexes[[sel_prod]][[sel_ver]]
    
    # Workaround to avoid error if only one custom index exists
    if (class(custom_idx) == "character") {
      custom_idx <- data.frame(
        indexes_bandnames  = custom_idx["indexes_bandnames"],
        indexes_fullnames  = custom_idx["indexes_fullnames"],
        indexes_formulas   = custom_idx["indexes_formulas"],
        indexes_nodata_out = custom_idx["indexes_nodata_out"],
        stringsAsFactors   = FALSE
      )
    }
    
    # Create variables needed to launch the processing
    
    general_opts$start_date <- as.character(
      format(as.Date(general_opts$start_date), "%Y.%m.%d")
    )
    general_opts$end_date  <- as.character(
      format(as.Date(general_opts$end_date), "%Y.%m.%d")
    )
    
    # If the product is NOT tiled, set or_proj to WGS84 and or_res from
    # metres to degrees
    if (prod_opts$tiled == 0) {
      mod_proj_str <- "+init=epsg:4008 +proj=longlat +ellps=clrk66 +no_defs"
      prod_opts$native_res <- format(
        as.numeric(prod_opts$native_res) * (0.05 / 5600)
      )
    }
    # get native resolution if out_res empty
    if (general_opts$out_res == "" | general_opts$out_res_sel == "Native") {
      general_opts$out_res <- prod_opts$native_res
    }
    
    #   ________________________________________________________________________
    #   If `spatial_file_path` is passed, values of the bounding boxe derived
    #   from `previous_jsfile` for the bbox are overwritten
    
    if (!is.null(spatial_file_path)) {
      
      # Check if the input file is a valid spatial file and redefine the
      # bounding box
      
      external_bbox <- try(bbox_from_file(spatial_file_path,
                                          general_opts$user_proj4),
                           silent = TRUE)
      if (class(external_bbox) == "try-error") {
        stop("Failed in retrieving processing extent from ",
             spatial_file_path,
             " . Please check your inputs! Aborting."
        )
      }
      general_opts$bbox <- external_bbox
      
      # Redefine the out_folder to include "spatial_file_path" as subfolder
      # (this to avoid that, running in a loop on multiple spatial files,
      # outputs are overwritten every time)
      general_opts$out_folder <- file.path(
        general_opts$out_folder,
        tools::file_path_sans_ext(basename(spatial_file_path))
      )
      
      # Overwrite the full_ext option (avoids that, if the options_file
      # specifies a full processing, the incorrect parameter is passed)
      general_opts$full_ext <- "Resized"
      
      # Automatically retrieve the tiles required to cover the extent
      modis_grid  <- get(load(system.file("ExtData", "MODIS_Tiles.RData",
                                          package = "MODIStsp")))
      external_bbox_mod    <- reproj_bbox(external_bbox,
                                          general_opts$user_proj4,
                                          mod_proj_str,
                                          enlarge = TRUE)
      d_bbox_mod_tiled     <- raster::crop(modis_grid,
                                           raster::extent(external_bbox_mod))
      general_opts$start_x <- min(d_bbox_mod_tiled$H)
      general_opts$end_x   <- max(d_bbox_mod_tiled$H)
      general_opts$start_y <- min(d_bbox_mod_tiled$V)
      general_opts$end_y   <- max(d_bbox_mod_tiled$V)
      
    }
    
    #   ________________________________________________________________________
    #   If running a test, redefine  output folders to use `R` temporary
    #   folder to store results and the testdata subfolder of MODIStsp
    #   to look for example files.
    
    if (test != -1) {
      general_opts$out_folder     <- normalizePath(tempdir())
      general_opts$out_folder_mod <- normalizePath(tempdir())
    }
    
    #   ________________________________________________________________________
    #   launch MODIStsp_process to Download and preprocess the selected     ####
    #   images. To do so, retrieve all processing parameters from either
    #   gemeral_opts (processing options), or prod_opts (characteristics of
    #   the selected product - band names, available indexes, etcetera.) and
    #   put them in the `p_opts` list. Then launch `MODIStsp_process`
    
    MODIStsp_process(sel_prod = general_opts$sel_prod,
                     start_date         = general_opts$start_date,
                     end_date           = general_opts$end_date,
                     out_folder         = general_opts$out_folder,
                     out_folder_mod     = general_opts$out_folder_mod,
                     reprocess          = general_opts$reprocess,
                     delete_hdf         = general_opts$delete_hdf,
                     sensor             = general_opts$sensor,
                     download_server    = general_opts$download_server,
                     user               = general_opts$user,
                     password           = general_opts$password,
                     https              = prod_opts$http,
                     ftps               = prod_opts$ftp,
                     start_x            = general_opts$start_x,
                     start_y            = general_opts$start_y,
                     end_x              = general_opts$end_x,
                     end_y              = general_opts$end_y,
                     full_ext           = general_opts$full_ext,
                     bbox               = general_opts$bbox,
                     out_format         = general_opts$out_format,
                     out_res_sel        = general_opts$out_res_sel,
                     out_res            = as.numeric(general_opts$out_res),
                     native_res         = prod_opts$native_res,
                     tiled              = prod_opts$tiled,
                     resampling         = general_opts$resampling,
                     ts_format          = general_opts$ts_format,
                     compress           = general_opts$compress,
                     mod_proj_str       = mod_proj_str,
                     outproj_str        = general_opts$user_proj4,
                     nodata_in          = prod_opts$nodata_in,
                     nodata_out         = prod_opts$nodata_out,
                     rts                = general_opts$rts,
                     nodata_change      = general_opts$nodata_change,
                     scale_val          = general_opts$scale_val,
                     scale_factor       = prod_opts$scale_factor,
                     offset             = prod_opts$offset,
                     datatype           = prod_opts$datatype,
                     bandsel            = general_opts$bandsel,
                     bandnames          = prod_opts$bandnames,
                     indexes_bandsel    = c(general_opts$indexes_bandsel),
                     indexes_bandnames  = c(prod_opts$indexes_bandnames,
                                            custom_idx$indexes_bandnames),
                     indexes_formula    = c(prod_opts$indexes_formula,
                                            custom_idx$indexes_formulas),
                     indexes_nodata_out = c(prod_opts$indexes_nodata_out,
                                            custom_idx$indexes_nodata_out),
                     quality_bandnames  = prod_opts$quality_bandnames,
                     quality_bandsel    = general_opts$quality_bandsel,
                     quality_bitN       = prod_opts$quality_bitN,
                     quality_source     = prod_opts$quality_source,
                     quality_nodata_in  = prod_opts$quality_nodata_in,
                     quality_nodata_out = prod_opts$quality_nodata_out,
                     file_prefixes      = prod_opts$file_prefix,
                     main_out_folder    = prod_opts$main_out_folder,
                     gui                = gui,
                     use_aria           = general_opts$use_aria,
                     download_range     = general_opts$download_range,
                     n_retries          = n_retries, 
                     verbose            = verbose)
    
    # At the end of a successful execution, save the options used in the main 
    # output folder as a JSON file with name containing the date of processing.
    # Also update "MODIStsp_previous.json.
    opts_jsfile  <- file.path(general_opts$out_folder,
                              paste0("MODIStsp_", Sys.Date(), ".json"))
    general_opts <- jsonlite::fromJSON(previous_jsfile)
    jsonlite::write_json(general_opts, opts_jsfile, pretty = TRUE,
                         auto_unbox = TRUE)
    
    # Clean up at the end of processing ----
    end_time   <- Sys.time()
    time_taken <- end_time - start_time
    if (verbose) message("Total Processing Time: ", time_taken)

  
