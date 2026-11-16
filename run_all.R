# run_all.R
# Reproduces every result in the project, in order.

source(here::here("R", "01_download_prices.R"))
# later scripts get added here as we write them

source(here::here("R", "02_build_returns.R"))

source(here::here("R", "03_volatility.R"))

source(here::here("R", "04_tsmom.R"))

source(here::here("R", "05_aqr_compare.R"))

rmarkdown::render(here::here("slides", "presentation.Rmd"))
