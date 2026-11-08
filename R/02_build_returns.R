# 02_build_returns.R
# Cleans raw Yahoo prices and builds daily log returns.
# Yahoo's front-month series is not roll-adjusted; the roll-bias check script
# measures how much that matters. One exception: a non-positive price
# (crude, 2020-04-20) makes the log return undefined, so returns touching it are dropped.

source(here::here("R", "00_config.R"))
library(dplyr)

# Start date for each market (default, overridden by MARKET_START)
mkt_start <- setNames(rep(START_DATE, length(TICKERS)), names(TICKERS))
mkt_start[names(MARKET_START)] <- MARKET_START

rets <- read.csv(RAW_PRICES) %>%
  mutate(date = as.Date(date)) %>%
  filter(!is.na(close),
         date >= as.Date(mkt_start[market])) %>%
  arrange(market, date) %>%
  group_by(market) %>%
  mutate(prev_close = dplyr::lag(close),
         ret = log(ifelse(close > 0 & prev_close > 0, close / prev_close, NA))) %>%
  ungroup() %>%
  select(market, date, close, volume, ret)

# Checks: no infinite or NaN returns; report non-positive prices
stopifnot(!any(is.nan(rets$ret) | is.infinite(rets$ret)))
message("Rows with non-positive prices: ", sum(rets$close <= 0))

saveRDS(rets, here("data", "processed", "daily_returns.rds"))

# Data summary table for the presentation
data_summary <- rets %>%
  group_by(market) %>%
  summarise(start    = min(date),
            end      = max(date),
            n_days   = sum(!is.na(ret)),
            ann_mean = TRADING_DAYS * mean(ret, na.rm = TRUE),
            ann_vol  = sqrt(TRADING_DAYS) * sd(ret, na.rm = TRUE))

write.csv(data_summary, here("output", "tables", "data_summary.csv"), row.names = FALSE)
