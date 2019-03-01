#' @title get-harvey-prelims
#'
#' @author Tim Trice
#'
#' @description Download NWS preliminary reports for Hurricane Harvey
#'
#' @details Download Hurricane Harvey preliminary reports and save as raw text.
#' The text of the source files may change over time; therefore, the text
#' products are saved and should not be downloaded again if they already exist.
#' If they do exist, exit.
#'

# ---- libraries ----
# cran #
library(glue)
library(here)
library(purrr)

# ---- variables ----
# URLs to prelim reports, per NWS station.
rpts <- c(
  "acus74.kbro.psh.bro.txt",
  "acus74.kcrp.psh.crp.txt",
  "acus74.kewx.psh.ewx.txt",
  "acus74.khgx.psh.hgx.txt",
  "acus74.klch.psh.lch.txt",
  "acus74.klix.psh.lix.txt"
)

# ---- data ----
walk(rpts, .f = function(x) {
  if (!file.exists(x)) {
    download.file(
      sprintf("ftp://tgftp.nws.noaa.gov/data/raw/ac/%s", x),
      destfile = here(glue("./data/{x}"))
    )
  }
})
