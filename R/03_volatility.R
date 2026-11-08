# 03_volatility.R
# Ex-ante volatility following MOP (2012): an exponentially weighted average of
# past squared daily returns, center of mass VOL_COM days, annualized.
# sigma on day t uses returns through t-1 only, so there is no look-ahead.
# MOP also subtract an EWMA mean; daily means are about 100x smaller than daily
# vol here, so that changes the variance by well under 1% and is omitted.

source(here::here("R", "00_config.R"))
library(dplyr)
library(ggplot2)

delta <- VOL_COM / (1 + VOL_COM)   # center of mass delta/(1-delta) = VOL_COM

# Recursive EWMA variance: S_t = delta * S_{t-1} + (1 - delta) * r_{t-1}^2.
# Initialized with the mean squared return over the first burn_in valid days;
# days with missing returns leave the estimate unchanged.
ewma_var <- function(r, delta, burn_in) {
  n     <- length(r)
  s     <- rep(NA_real_, n)
  first <- which(!is.na(r))[seq_len(burn_in)]
  if (anyNA(first) || max(first) >= n) return(s)
  cur <- mean(r[first]^2)
  for (t in (max(first) + 1):n) {
    s[t] <- cur                                       # uses returns through t-1
    if (!is.na(r[t])) cur <- delta * cur + (1 - delta) * r[t]^2
  }
  s
}

vol <- readRDS(here("data", "processed", "daily_returns.rds")) %>%
  arrange(market, date) %>%
  group_by(market) %>%
  mutate(sigma = sqrt(TRADING_DAYS * ewma_var(ret, delta, VOL_COM))) %>%
  ungroup()

saveRDS(vol, here("data", "processed", "daily_vol.rds"))

# Sanity-check figure: ex-ante vol for three markets with very different risk
p <- vol %>%
  filter(market %in% c("natgas", "crude", "gold"), !is.na(sigma)) %>%
  ggplot(aes(date, sigma, colour = market)) +
  geom_line(linewidth = 0.3) +
  labs(x = NULL, y = "Annualized ex-ante volatility", colour = NULL) +
  theme_minimal()

ggsave(here("output", "figures", "ex_ante_vol.png"), p, width = 7, height = 4)
