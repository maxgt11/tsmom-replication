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

# Roll detection
ROLL_THRESHOLD <- 1    # log change in volume that flags a roll (about a 2.7x jump)
ROLL_MIN_GAP   <- 10   # trading days; two rolls can't be closer than this
ROLL_WINDOW    <- 1    # drop returns on days d-1, d, d+1 around each roll

# Active contract months per year (for validating roll detection).
# Yahoo may follow a different cycle; the roll check will show it.
EXPECTED_ROLLS <- c(
  crude = 12, brent = 12, natgas = 12, heatoil = 12, rbob = 12,
  gold = 6, silver = 5, platinum = 4, copper = 5,
  corn = 5, wheat = 5, soybeans = 7, soymeal = 8, soyoil = 8,
  coffee = 5, cocoa = 5, sugar = 4, cotton = 5,
  cattle = 6, hogs = 8
)

# MOP annualize daily variance with 261 trading days
TRADING_DAYS <- 261

# Volatility estimate and position sizing (MOP 2012)
VOL_COM    <- 60     # center of mass of EWMA weights, in days
TARGET_VOL <- 0.40   # annualized volatility target per position
