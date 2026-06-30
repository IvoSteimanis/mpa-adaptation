# fig5_cdp_raincloud.R
# Raincloud plot: perceived governance (CDP indices) on raw 0-10 scale
# with OLS regression statistics in brackets (ggbetweenstats style)
#
# Required: haven, dplyr, tidyr, ggplot2, ggsignif, fixest, showtext, sysfonts
# Input:  processed/fishery_game_wide.dta
# Output: results/main/figures/fig_cdp_treatment_effects_raincloud.png

library(haven)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggsignif)
library(fixest)
library(showtext)
library(sysfonts)

set.seed(20260528)

# ── Font setup ─────────────────────────────────────────────────────────
arial_reg <- switch(Sys.info()[["sysname"]],
  Windows = "C:/Windows/Fonts/arial.ttf",
  Darwin  = "/Library/Fonts/Arial.ttf",
  "/usr/share/fonts/truetype/msttcorefonts/Arial.ttf"
)
if (file.exists(arial_reg)) {
  font_add("arial_font",
           regular    = arial_reg,
           bold       = sub("arial", "arialbd", sub("Arial", "Arial Bold", arial_reg)),
           italic     = sub("arial", "ariali",  sub("Arial", "Arial Italic", arial_reg)),
           bolditalic = sub("arial", "arialbi", sub("Arial", "Arial Bold Italic", arial_reg)))
  fig_font <- "arial_font"
} else {
  fig_font <- "sans"
}
showtext_auto()
showtext_opts(dpi = 1200)

# ── Half-violin geom (Allen et al. 2019) ──────────────────────────────
GeomFlatViolin <- ggproto("GeomFlatViolin", GeomViolin,
  draw_group = function(self, data, ..., draw_quantiles = NULL) {
    data <- transform(data,
      xminv = x,
      xmaxv = x + violinwidth * (xmax - x)
    )
    newdata <- data[order(data$y), ]
    newdata <- transform(newdata, x = xmaxv)
    newdata <- rbind(
      transform(newdata[1, , drop = FALSE], x = data$x[1]),
      newdata,
      transform(newdata[nrow(newdata), , drop = FALSE], x = data$x[1])
    )
    GeomPolygon$draw_panel(newdata, ...)
  }
)

geom_flat_violin <- function(mapping = NULL, data = NULL, stat = "ydensity",
                              position = "dodge", trim = TRUE, scale = "area",
                              show.legend = NA, inherit.aes = TRUE, ...) {
  layer(data = data, mapping = mapping, stat = stat,
        geom = GeomFlatViolin, position = position,
        show.legend = show.legend, inherit.aes = inherit.aes,
        params = list(trim = trim, scale = scale, ...))
}

# ── Paths & palette ───────────────────────────────────────────────────
data_path <- "processed/fishery_game_wide.dta"
out_path  <- "results/main/figures/fig_cdp_treatment_effects_raincloud.png"
dir.create("results/main/figures", showWarnings = FALSE, recursive = TRUE)

treat_colors <- c(
  "Fixed"       = rgb(170, 40, 40, maxColorValue = 255),
  "Constrained" = rgb(200, 110, 30, maxColorValue = 255),
  "Flexible"    = rgb(30, 130, 100, maxColorValue = 255),
  "Open"        = rgb(0, 65, 25, maxColorValue = 255)
)

# ── Load and prepare data ──────────────────────────────────────────────
d <- read_dta(data_path) %>%
  zap_labels() %>%
  filter(village != "Batonan-Sur") %>%
  distinct(unique_id, .keep_all = TRUE) %>%
  filter(treatment %in% 1:4)

treat_labels <- c("1" = "Fixed", "2" = "Constrained",
                  "3" = "Flexible", "4" = "Open")

# Group counts for x-axis labels
n_per_treat <- table(d$treatment)

d <- d %>%
  mutate(
    treat_lab = factor(treatment, levels = 1:4, labels = treat_labels),
    Autonomy              = exp_cdp18,
    `Social Cohesion`     = rowMeans(across(c(exp_cdp1, exp_cdp5, exp_cdp6,
                                              exp_cdp10, exp_cdp14)), na.rm = TRUE),
    `Governance Quality`  = rowMeans(across(c(exp_cdp7, exp_cdp8, exp_cdp9,
                                              exp_cdp11, exp_cdp15)), na.rm = TRUE)
  )

cat("N individuals:", nrow(d), "\n")
cat("By treatment:", paste(n_per_treat, collapse = " / "), "\n")

# ── OLS regressions with clustered SEs (matches Stata spec) ───────────
# Stata: reg z_outcome i.treatment $controls i.assist, cluster(group_id)
# We use raw 0-10 scale here, not z-scores, but report coefficients in
# raw units (interpretable as mean difference on 0-10 scale)

controls <- c("age", "gender", "married", "only_elementary", "hh_size", "ymonth")

# Safe names for fixest (no spaces)
d <- d %>%
  rename(social_cohesion_raw = `Social Cohesion`,
         governance_quality_raw = `Governance Quality`)

outcome_map <- c(
  "Autonomy"           = "Autonomy",
  "Social Cohesion"    = "social_cohesion_raw",
  "Governance Quality" = "governance_quality_raw"
)
outcomes <- names(outcome_map)

reg_results <- list()
for (outcome in outcomes) {
  var_name <- outcome_map[outcome]
  fml <- as.formula(paste0(var_name, " ~ i(treatment, ref = 1) + ",
                           paste(controls, collapse = " + "),
                           " + i(assist) | 0"))
  fit <- feols(fml, data = d, cluster = ~group_id)
  ct <- coeftable(fit)

  for (trt in 2:4) {
    coef_name <- paste0("treatment::", trt)
    idx <- which(rownames(ct) == coef_name)
    if (length(idx) == 0) next
    b  <- ct[idx, "Estimate"]
    se <- ct[idx, "Std. Error"]
    p  <- ct[idx, "Pr(>|t|)"]
    ci_lo <- b - qt(0.975, fit$nobs - length(coef(fit))) * se
    ci_hi <- b + qt(0.975, fit$nobs - length(coef(fit))) * se

    reg_results <- c(reg_results, list(data.frame(
      dimension  = outcome,
      comparison = treat_labels[as.character(trt)],
      beta       = b,
      se         = se,
      pval       = p,
      ci_lo      = ci_lo,
      ci_hi      = ci_hi,
      stringsAsFactors = FALSE
    )))
  }
}
reg_df <- bind_rows(reg_results)

cat("\nOLS regression coefficients (vs Fixed, clustered by group):\n")
print(reg_df, digits = 3)

# ── Format bracket annotations ─────────────────────────────────────────
bracket_df <- reg_df %>%
  mutate(
    label = ifelse(pval < 0.05,
      sprintf("β = %.2f, p = %.3f, 95%% CI [%.2f, %.2f]", beta, pval, ci_lo, ci_hi),
      "n.s."),
    xmin = "Fixed",
    xmax = comparison,
    dimension = factor(dimension, levels = outcomes,
      labels = c("bold(A)~Autonomy", "bold(B)~Social~Cohesion", "bold(C)~Governance~Quality")),
    y_position = rep(c(10.8, 11.6, 12.4), times = 3)
  )

# ── Per-treatment means for μ annotation ───────────────────────────────
d_long <- d %>%
  rename(`Social Cohesion` = social_cohesion_raw,
         `Governance Quality` = governance_quality_raw) %>%
  select(unique_id, treat_lab, Autonomy, `Social Cohesion`, `Governance Quality`) %>%
  pivot_longer(cols = c(Autonomy, `Social Cohesion`, `Governance Quality`),
               names_to = "dimension", values_to = "score") %>%
  mutate(dimension = factor(dimension, levels = outcomes,
    labels = c("bold(A)~Autonomy", "bold(B)~Social~Cohesion", "bold(C)~Governance~Quality"))) %>%
  filter(!is.na(score))

mean_df <- d_long %>%
  group_by(dimension, treat_lab) %>%
  summarise(mu = mean(score, na.rm = TRUE), .groups = "drop")

# ── X-axis labels with (n=XX) ─────────────────────────────────────────
legend_labels <- setNames(
  paste0(treat_labels, " (n=", n_per_treat, ")"),
  treat_labels
)

# ── Build raincloud plot ───────────────────────────────────────────────
p <- ggplot(d_long, aes(x = treat_lab, y = score, fill = treat_lab)) +
  geom_flat_violin(
    alpha = 0.30, color = "grey50", linewidth = 0.15,
    position = position_nudge(x = 0.15),
    scale = "width", trim = TRUE, width = 0.5,
    adjust = 2.0
  ) +
  geom_jitter(
    aes(color = treat_lab),
    size = 0.8, shape = 16, alpha = 0.25,
    position = position_jitter(width = 0.08, height = 0.1),
    show.legend = FALSE
  ) +
  stat_summary(
    fun.data = function(x) {
      m <- mean(x, na.rm = TRUE)
      se <- sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x)))
      data.frame(y = m, ymin = m - 1.96*se, ymax = m + 1.96*se)
    },
    geom = "errorbar", width = 0.08,
    linewidth = 0.5, color = "grey20"
  ) +
  stat_summary(
    fun = mean, geom = "point", shape = 23, size = 3,
    fill = "white", color = "grey20", stroke = 0.8
  ) +
  geom_text(
    data = mean_df,
    aes(x = treat_lab, y = mu, label = sprintf("μ=%.1f", mu)),
    nudge_x = -0.18, size = 2.8, color = "grey30",
    inherit.aes = FALSE, hjust = 1
  ) +
  geom_signif(
    data = bracket_df,
    aes(xmin = xmin, xmax = xmax, annotations = label, y_position = y_position),
    manual = TRUE, inherit.aes = FALSE,
    textsize = 2.8, vjust = -0.1,
    tip_length = 0.008, color = "grey30"
  ) +
  facet_wrap(~ dimension, nrow = 1, labeller = label_parsed) +
  scale_fill_manual(values = treat_colors, labels = legend_labels, name = NULL) +
  scale_color_manual(values = treat_colors, guide = "none") +
  guides(fill = guide_legend(nrow = 1)) +
  scale_y_continuous(breaks = seq(0, 10, 2), limits = c(0, 13.5)) +
  labs(
    x = NULL,
    y = "Score (0–10 Likert scale)"
  ) +
  theme_minimal(base_size = 11, base_family = fig_font) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(size = 13, margin = margin(b = 2)),
    axis.title.y = element_text(size = 12),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 11),
    legend.position = "bottom",
    legend.margin = margin(t = -5, b = 0),
    legend.text = element_text(size = 11, face = "italic"),
    legend.key.size = unit(0.4, "cm"),
    plot.margin = margin(t = 2, r = 10, b = 5, l = 15)
  )

ggsave(out_path, p, width = 9, height = 5.5, dpi = 1200, bg = "white")

cat("\nFigure written:", out_path, "\n")
cat("\nBracket annotations:\n")
bracket_df %>% select(dimension, comparison, label) %>% as.data.frame() %>% print()
