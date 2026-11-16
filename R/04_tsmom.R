# 04_tsmom.R
# Builds the TSMOM strategy following MOP (2012): each month, go long markets
# with positive past-LOOKBACK-month returns and short those with negative,
# sized to TARGET_VOL using ex-ante volatility, held one month. Portfolio is the
# equal-weighted average across available markets.

source(here::here("R", "00_config.R"))
library(dplyr)
library(ggplot2)

daily <- readRDS(here("data", "processed", "daily_vol.rds"))

# Drop the current, incomplete month
last_full_month <- as.Date(format(max(daily$date), "%Y-%m-01"))

monthly <- daily %>%
  mutate(month = as.Date(format(date, "%Y-%m-01"))) %>%
  filter(month < last_full_month) %>%
  group_by(market, month) %>%
  summarise(log_ret = sum(ret, na.rm = TRUE),
            sigma   = dplyr::last(sigma),   # ex-ante vol on the month's last day
            .groups = "drop") %>%
  arrange(market, month)

# Fill missing months (cattle, Jan 2006) with NA so that lagging 12 rows = 12 months
monthly <- monthly %>%
  group_by(market) %>%
  reframe(month = seq(min(month), max(month), by = "month")) %>%
  left_join(monthly, by = c("market", "month"))

# Rolling LOOKBACK-month sum; NA if any month in the window is missing
roll_sum <- function(x, k) {
  cs   <- cumsum(ifelse(is.na(x), 0, x))
  n_na <- cumsum(is.na(x))
  out  <- cs - dplyr::lag(cs, k)
  out[n_na - dplyr::lag(n_na, k) > 0] <- NA
  out
}

tsmom <- monthly %>%
  group_by(market) %>%
  mutate(ret_m     = exp(log_ret) - 1,
         past_k    = roll_sum(log_ret, LOOKBACK),
         position  = sign(past_k) * TARGET_VOL / sigma,
         strat_ret = dplyr::lag(position) * ret_m) %>%   # set at end of t, earns t+1
  ungroup()

portfolio <- tsmom %>%
  filter(!is.na(strat_ret)) %>%
  group_by(month) %>%
  summarise(tsmom = mean(strat_ret), n_markets = n())

saveRDS(tsmom,     here("data", "processed", "tsmom_by_market.rds"))
saveRDS(portfolio, here("data", "processed", "tsmom_portfolio.rds"))

# Performance table: full sample, MOP overlap, post-MOP
perf <- function(x) {
  data.frame(ann_mean = 12 * mean(x),
             ann_vol  = sqrt(12) * sd(x),
             sharpe   = sqrt(12) * mean(x) / sd(x),
             t_stat   = mean(x) / (sd(x) / sqrt(length(x))),
             n_months = length(x))
}

perf_table <- bind_rows(
  cbind(period = "Full sample", perf(portfolio$tsmom)),
  cbind(period = "Through 2009 (MOP overlap)",
        perf(portfolio$tsmom[portfolio$month <= as.Date("2009-12-01")])),
  cbind(period = "2010 onward",
        perf(portfolio$tsmom[portfolio$month >= as.Date("2010-01-01")]))
)

write.csv(perf_table, here("output", "tables", "tsmom_performance.csv"), row.names = FALSE)

# Cumulative return figure (log scale)
p <- portfolio %>%
  mutate(cum = cumprod(1 + tsmom)) %>%
  ggplot(aes(month, cum)) +
  geom_line() +
  scale_y_log10() +
  labs(x = NULL, y = "Growth of $1 (log scale)") +
  theme_minimal()

ggsave(here("output", "figures", "tsmom_cumulative.png"), p, width = 7, height = 4)
