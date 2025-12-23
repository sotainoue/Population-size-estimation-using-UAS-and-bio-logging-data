library(tidyverse)
library(geosphere)
library(stringr)
library(lubridate)
library(rstan)
library(zoo)
library(here)

here::here()
dir.exists(here::here("data/raw/vhf_summary"))

read_vhf_summary <- function(
        dir,
        start_date = as.Date("2023-05-01"),
        year_keep = 2023,
        hdop_max = 7,
        thin_every = 2,
        time_group_minutes = 10,
        colony_radius_m = 180,
        point_kabu = c(141.5576031, 40.5386062)
) {
    # Check that the directory exists
    stopifnot(dir.exists(dir))
    
    # List all files in the directory
    files <- list.files(dir, full.names = TRUE)
    
    # Initialize output list
    out <- vector("list", length(files))
    k <- 0L
    
    # Loop over files (individuals)
    for (i in seq_along(files)) {
        
        # Read raw VHF summary file
        tmp <- read.csv(files[i], header = TRUE)
        
        # Check for required columns
        req <- c("dt", "hdop", "Latitude", "Longitude")
        miss <- setdiff(req, names(tmp))
        if (length(miss) > 0) next
        
        # Assume dt is in "date time" format and split it
        dt_split <- stringr::str_split_fixed(tmp$dt, " ", 2)
        tmp$date <- as.Date(dt_split[, 1])
        tmp$time <- dt_split[, 2]
        
        # Keep records after the specified start date
        tmp <- tmp[tmp$date >= start_date, , drop = FALSE]
        if (nrow(tmp) == 0) next
        
        # Thin records to reduce temporal oversampling
        # (e.g., thin_every = 2 keeps every second record)
        if (!is.null(thin_every) && thin_every > 1) {
            idx <- seq.int(from = thin_every, to = nrow(tmp), by = thin_every)
            tmp <- tmp[idx, , drop = FALSE]
        }
        
        # Assign individual ID from file name
        tmp$id <- tools::file_path_sans_ext(basename(files[i]))
        
        # Select and rename relevant columns
        tmp <- dplyr::select(tmp, id, date, time, Latitude, Longitude, hdop)
        names(tmp) <- c("id", "date", "time", "lat", "lon", "hdop")
        
        # Store processed data
        k <- k + 1L
        out[[k]] <- tmp
    }
    
    # Return empty tibble if no valid data were found
    if (k == 0L) return(dplyr::tibble())
    
    # Combine all individuals into a single data frame
    data <- dplyr::bind_rows(out[seq_len(k)])
    
    # Filter by HDOP threshold
    data <- dplyr::filter(data, hdop < hdop_max)
    
    # Extract year, month, and day from date
    data <- dplyr::mutate(
        data,
        year = as.integer(format(date, "%Y")),
        month = as.integer(format(date, "%m")),
        day = as.integer(format(date, "%d"))
    )
    
    # Convert coordinates to absolute values if required
    data <- dplyr::mutate(data, lat = abs(lat), lon = abs(lon))
    
    # Remove records with missing coordinates
    data <- dplyr::filter(data, !is.na(lat), !is.na(lon))
    
    # Create a unique identifier for duplicate removal
    data <- dplyr::mutate(
        data,
        time_id = paste(date, time, lat, lon, id, sep = "-")
    ) %>%
        dplyr::distinct(time_id, .keep_all = TRUE)
    
    # Keep only records from the specified year
    data <- dplyr::filter(data, year == year_keep)
    
    ##Timestamps recorded in UTC 
    data <- data %>%
        mutate(
            datetime_utc = ymd_hms(paste(date, time), tz = "UTC")
        )
    
    ##distance
    coords <- as.matrix(dplyr::select(data, lon, lat))
    storage.mode(coords) <- "double"
    data <- data %>%
        mutate(distance = geosphere::distGeo(point_kabu, coords)) %>%
        mutate(position = ifelse(distance >= colony_radius_m, 'trip','stay'))
    
    return(data)
}

data <- read_vhf_summary(dir = here::here('data/raw/vhf_summary'))

readr::write_csv(data, here::here("data/derived/logging_data.csv"))

