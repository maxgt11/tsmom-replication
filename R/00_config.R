# 00_config.R
# All settings for the project. Every other script sources this file.

library(here)

TICKERS <- c(
  crude = "CL=F", brent = "BZ=F", natgas = "NG=F", heatoil = "HO=F", rbob = "RB=F",
  gold = "GC=F", silver = "SI=F", platinum = "PL=F", copper = "HG=F",
  corn = "ZC=F", wheat = "ZW=F", soybeans = "ZS=F", soymeal = "ZM=F", soyoil = "ZL=F",
  coffee = "KC=F", cocoa = "CC=F", sugar = "SB=F", cotton = "CT=F",
  cattle = "LE=F", hogs = "HE=F"
)

START_DATE <- "1990-01-01"

RAW_PRICES <- here("data", "raw", "yahoo_futures.csv")
RAW_META   <- here("data", "raw", "yahoo_futures_download_date.txt")

# Market-specific start dates, overriding START_DATE.
# Platinum: Yahoo is missing roughly half of trading days in 2006-2009,
# so daily returns before 2010 would mix 1-day and multi-day horizons.
MARKET_START <- c(platinum = "2010-01-01")
