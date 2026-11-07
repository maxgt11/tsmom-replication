# 01_download_prices.R
# Downloads daily front-month futures prices from Yahoo Finance.
# Skips the download if the snapshot already exists, so reruns use identical data.
# To refresh the data, delete data/raw/yahoo_futures.csv and rerun.

source(here::here("R", "00_config.R"))
library(quantmod)

get_one <- function(name, tk) {
  x <- getSymbols(tk, src = "yahoo", from = START_DATE, auto.assign = FALSE)
  data.frame(market = name,
             date   = index(x),
             close  = as.numeric(Cl(x)),
             volume = as.numeric(Vo(x)))
}

if (!file.exists(RAW_PRICES)) {
  px_raw <- do.call(rbind, Map(get_one, names(TICKERS), TICKERS))
  write.csv(px_raw, RAW_PRICES, row.names = FALSE)
  writeLines(as.character(Sys.Date()), RAW_META)   # records when the snapshot was taken
}
