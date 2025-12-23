library(tidyverse)
library(geosphere)
library(stringr)
library(lubridate)
library(rstan)
library(zoo)
library(here)

here::here()

summarise_sahi_counts <- function(
        pred_dir,
        record_data,
        drop_image_id = "NN",
        session_nchar = 8,
        image_ext_regex = "\\.tif$"
) {
    stopifnot(dir.exists(pred_dir))
    
    files <- list.files(pred_dir, full.names = TRUE)
    if (length(files) == 0) return(dplyr::tibble())
    
    # Read & bind
    res <- dplyr::bind_rows(lapply(files, function(f) {
        tmp <- read.csv(f)
        tmp[, -1, drop = FALSE]  # keep your current behavior
    }))
    
    # Clean + de-duplicate bbox
    res2 <- res %>%
        dplyr::filter(image_id != drop_image_id) |>
        dplyr::mutate(
            bbox_id = paste(image_id, bbox, sep = "-"),
            session = substr(image_id, 1, session_nchar),
            image = gsub(image_ext_regex, "", image_id)
        ) %>%
        dplyr::distinct(bbox_id, .keep_all = TRUE)
    
    # Aggregate counts
    res3 <- res2 %>%
        dplyr::group_by(session, category_id) %>%
        dplyr::summarise(number = dplyr::n(), .groups = "drop")
    
    # Join metadata
    record <- read.csv(here::here('data/raw/flight_record.csv'),header=T)
    res4 <- dplyr::left_join(res3, record, by = "session") %>%
        dplyr::mutate(category = "sahi")
    
    # Wide format
    out <- res4 %>%
        tidyr::pivot_wider(
            names_from = category_id,
            values_from = number,
            values_fill = 0
        )
    
    # Rename classes if present
    if ("0" %in% names(out)) names(out)[names(out) == "0"] <- "Fly"
    if ("1" %in% names(out)) names(out)[names(out) == "1"] <- "G"
    
    # Total
    if (all(c("Fly", "G") %in% names(out))) {
        out <- dplyr::mutate(out, n_total = Fly + G)
    }
    
    return(out)
}

uas_data <-  summarise_sahi_counts(pred_dir = here::here('data/raw/prediction_sahi'),
                                   record_data = here::here('data/raw/flight_data.csv'))
readr::write_csv(uas_data, here::here("data/derived/uas_data.csv"))