# 05_aqr_compare.R
# Validates the replication against AQR's published commodity TSMOM factor
# over overlapping months: correlation, regression fit, and Sharpe ratios.

source(here::here("R", "00_config.R"))
library(dplyr)
library(readxl)
library(ggplot2)

sheet <- "TSMOM Factors"

# Locate the header row below AQR's notes (first cell == "DATE")
raw        <- read_excel(AQR_FILE, sheet = sheet, col_names = FALSE)
# Header row = first row whose second column starts with "TSMOM"
header_row <- which(grepl("^TSMOM", trimws(raw[[2]])))[1]
stopifnot(!is.na(header_row))
aqr <- read_excel(AQR_FILE, sheet = sheet, skip = header_row - 1)

# Commodity factor column (AQR labels it with a commodity superscript)
cm_col <- grep("CM|COM", names(aqr), value = TRUE, ignore.case = TRUE)
message("AQR columns: ", paste(names(aqr), collapse = ", "))
stopifnot(length(cm_col) == 1)

# Excel dates can arrive as dates, text, or serial numbers
to_date <- function(x) {
  if (is.numeric(x)) as.Date(x, origin = "1899-12-30") else as.Date(x)
}

aqr_cm <- aqr %>%
  transmute(month  = as.Date(format(to_date(.data[[names(aqr)[1]]]), "%Y-%m-01")),
            aqr_cm = as.numeric(.data[[cm_col]])) %>%
  filter(!is.na(month), !is.na(aqr_cm))

portfolio <- readRDS(here("data", "processed", "tsmom_portfolio.rds"))
both      <- inner_join(portfolio, aqr_cm, by = "month")

sharpe <- function(x) sqrt(12) * mean(x) / sd(x)

compare_period <- function(d, label) {
  fit <- lm(tsmom ~ aqr_cm, data = d)
  data.frame(period       = label,
             n_months     = nrow(d),
             correlation  = cor(d$tsmom, d$aqr_cm),
             beta         = unname(coef(fit)[2]),
             r_squared    = summary(fit)$r.squared,
             sharpe_ours  = sharpe(d$tsmom),
             sharpe_aqr   = sharpe(d$aqr_cm))
}

comparison <- bind_rows(
  compare_period(both, "Full overlap"),
  compare_period(filter(both, month <= as.Date("2009-12-01")), "Through 2009"),
  compare_period(filter(both, month >= as.Date("2010-01-01")), "2010 onward")
)

write.csv(comparison, here("output", "tables", "aqr_comparison.csv"), row.names = FALSE)

# Overlay: both series scaled to the same volatility so the paths are comparable
plot_df <- both %>%
  mutate(ours = tsmom  * sd(aqr_cm) / sd(tsmom),
         aqr  = aqr_cm) %>%
  transmute(month,
            `This replication (vol-matched)` = cumprod(1 + ours),
            `AQR commodity TSMOM`            = cumprod(1 + aqr)) %>%
  tidyr::pivot_longer(-month, names_to = "series", values_to = "cum")

p <- ggplot(plot_df, aes(month, cum, colour = series)) +
  geom_line() +
  scale_y_log10() +
  labs(x = NULL, y = "Growth of $1 (log scale)", colour = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(here("output", "figures", "aqr_comparison.png"), p, width = 7, height = 4)
