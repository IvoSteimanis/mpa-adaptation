# fig6_enforcement_flow.R
# Alluvial flow diagram: enforcement regime transitions across game phases
# (R / ggalluvial — not called by run.do; render manually with Rscript)
#
# Required packages: haven, dplyr, ggplot2, ggalluvial, scales, showtext, sysfonts
# Input:  processed/fishery_game_long.dta
# Output: results/main/figures/fig_enforcement_flow.png

library(haven)
library(dplyr)
library(ggplot2)
library(ggalluvial)
library(scales)
library(showtext)
library(sysfonts)

# Arial font — adjust paths for your OS:
#   Windows: C:/Windows/Fonts/arial.ttf
#   macOS:   /Library/Fonts/Arial.ttf
#   Linux:   install ttf-mscorefonts-installer, then /usr/share/fonts/truetype/msttcorefonts/
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
  message("Arial not found; using system sans-serif. Output may differ slightly.")
  fig_font <- "sans"
}
showtext_auto()

# ── Paths (relative to replication_package/) ─────────────────────────────
data_path  <- "processed/fishery_game_long.dta"
output_dir <- "results/main/figures"

# ── Palette ──────────────────────────────────────────────────────────────
regime_colors <- c(
  "Coherent (M+F)"      = "#285082",
  "Voluntary (None)"    = "#B4B4B4",
  "Incoherent (M or F)" = "#DCA03C"
)

regime_label_colors <- c(
  "Coherent (M+F)"      = "white",
  "Voluntary (None)"    = "grey10",
  "Incoherent (M or F)" = "white"
)

n_per_treatment <- 22
regime_labels <- c("1" = "Coherent (M+F)",
                   "2" = "Voluntary (None)",
                   "3" = "Incoherent (M or F)")

# ── Load and prepare data ────────────────────────────────────────────────
raw <- read_dta(data_path)

round_filter <- c(7, 13, 18)
x_labels     <- c("Round 7", "Round 13", "Round 18")

plot_df <- raw %>%
  filter(round_number %in% round_filter, !is.na(treatment), treatment %in% 2:4) %>%
  distinct(group_id, treatment, round_number, enforcement_type) %>%
  mutate(
    treatment_f = factor(treatment, levels = 2:4,
                         labels = c("Constrained", "Flexible", "Open")),
    regime = factor(enforcement_type, levels = 1:3, labels = regime_labels),
    round_f = factor(round_number, levels = round_filter, labels = x_labels)
  ) %>%
  arrange(group_id, round_number) %>%
  group_by(group_id) %>%
  mutate(
    dest_regime = factor(
      lead(as.character(regime), default = as.character(last(regime))),
      levels = levels(regime)
    )
  ) %>%
  ungroup()

# ── Print transition counts ──────────────────────────────────────────────
cat("\n── Transition summary ──────────────────────────────────\n")
transitions <- plot_df %>%
  filter(round_f != "Round 18") %>%
  group_by(treatment_f, round_f, regime, dest_regime) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(treatment_f, round_f, regime, dest_regime)
print(as.data.frame(transitions), row.names = FALSE)

cat("\n── Regime distribution per round ───────────────────────\n")
regime_dist <- plot_df %>%
  group_by(treatment_f, round_f, regime) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(treatment_f, round_f) %>%
  mutate(pct = round(n / sum(n) * 100)) %>%
  ungroup()
print(as.data.frame(regime_dist), row.names = FALSE)

# ── Build alluvial ───────────────────────────────────────────────────────
sw       <- 0.32
cm_to_in <- 1 / 2.54
fig_w    <- 16 * cm_to_in

p <- ggplot(plot_df,
            aes(x = round_f,
                stratum = regime,
                alluvium = group_id)) +
  geom_flow(aes(fill = dest_regime),
            alpha = 0.45, width = sw,
            color = "white", linewidth = 0.3,
            curve_type = "arctangent", na.rm = TRUE) +
  geom_stratum(aes(fill = regime), width = sw,
               color = "grey30", linewidth = 0.4, na.rm = TRUE) +
  scale_fill_manual(values = regime_colors, name = NULL) +
  geom_text(stat = "stratum",
            aes(label = ifelse(after_stat(count) >= 3,
                               paste0(round(after_stat(count) /
                                            n_per_treatment * 100), "%"), ""),
                color = after_stat(stratum)),
            size = 5.5, family = fig_font, fontface = "bold",
            show.legend = FALSE, na.rm = TRUE) +
  scale_color_manual(values = regime_label_colors) +
  scale_x_discrete(expand = expansion(mult = c(0.04, 0.04))) +
  scale_y_continuous(
    breaks = n_per_treatment * c(0, 0.25, 0.5, 0.75, 1),
    labels = c("0", "25", "50", "75", "100")
  ) +
  facet_wrap(~ treatment_f, nrow = 1) +
  labs(x = NULL, y = "Percent of groups") +
  theme_minimal(base_size = 18, base_family = fig_font) +
  theme(
    plot.title         = element_blank(),
    plot.subtitle      = element_blank(),
    plot.caption       = element_blank(),
    panel.grid         = element_blank(),
    panel.border       = element_blank(),
    panel.background   = element_rect(fill = "white", color = NA),
    plot.background    = element_rect(fill = "white", color = NA),
    panel.spacing      = unit(1.2, "lines"),
    axis.line          = element_blank(),
    axis.ticks         = element_blank(),
    axis.text.x        = element_text(size = rel(1.0), color = "grey20"),
    axis.text.y        = element_text(size = rel(1.0), color = "grey20"),
    axis.title         = element_text(size = rel(1.1)),
    axis.ticks.length  = unit(0, "pt"),
    legend.position    = "bottom",
    legend.text        = element_text(size = rel(1.0)),
    legend.key         = element_rect(fill = "transparent", color = NA),
    legend.key.size    = unit(0.5, "cm"),
    legend.background  = element_rect(fill = "transparent", color = NA),
    legend.box.spacing = unit(2, "pt"),
    legend.margin      = margin(t = 0, b = 0),
    strip.text         = element_text(size = rel(1.4), face = "italic",
                                      margin = margin(t = 1, b = 1)),
    strip.background   = element_blank(),
    plot.margin        = margin(t = 1, r = 8, b = 2, l = 2, unit = "pt")
  )

ggsave(file.path(output_dir, "fig_enforcement_flow.png"),
       plot = p, width = fig_w, height = fig_w * 0.58,
       dpi = 300, bg = "white")

cat("\nFigure saved to:", file.path(output_dir, "fig_enforcement_flow.png"), "\n")
