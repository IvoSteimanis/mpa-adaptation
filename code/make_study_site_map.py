"""
Build the study-site map (revised) per 2026-05-05 user spec.

Switches from geopandas+custom geojson (v2) to cartopy + Natural Earth shapefiles.
Uses hardcoded coordinates so the figure is self-contained and reproducible without
the spatial-join intermediate file. Adds an ocean fill (was missing in v2) and uses
shape (circle vs diamond) to disambiguate the two village classes alongside color.

Output:
  - Analysis/STATA/results/figures/fig_study_sites_map.png  (raster, 600 dpi)

(Renamed 2026-05-07 from figure8_revised.png to match the semantic-naming
convention; Python-side rename only — the v2 outputs in figure8_study_sites.*
are left untouched for diffing.)
"""

from pathlib import Path

import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.patches import Polygon, Rectangle

# Resolve paths relative to this script (replication_package/code/...)
HERE = Path(__file__).resolve()
REPO_DIR = HERE.parents[1]                      # replication_package/
OUT_DIR = REPO_DIR / "results" / "main" / "figures"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PNG = OUT_DIR / "fig_study_sites_map.png"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Real coordinates from quality_reports/intermediate/figureS1_village_lookup.csv
# (spatial join of village_level_data.dta against muncoord.dta).
# Three classes:
#   * mpa_exp (n=18)     — MPA village, in longitudinal panel + experimental analysis
#   * nonmpa_exp (n=3)   — non-MPA village, in longitudinal panel + experimental analysis
#   * panel_only (n=1)   — MPA village in panel survey only; dropped from experimental
#                          analysis because the session was played twice and the first
#                          session's data was lost (Batonan-Sur — see 04_main_analysis.do:40)
# Total = 22 villages = longitudinal panel; 21 of those are in the experimental sample.
mpa_exp = {
    "San Roque":     (121.9931, 11.8265),
    "Pucio":         (122.0033, 11.8255),
    "Pajo":          (121.8611, 11.7633),
    "Bulanao":       (121.9678, 11.7548),
    "Talotoan":      (123.1535, 11.3049),
    "Polopina":      (123.1698, 11.1801),
    "Maliogliog":    (123.1337, 11.1512),
    "Nanding Lopez": (122.7457, 10.8425),
    "Calampitao":    (122.3027, 10.6649),
    "Suclaran":      (122.7242, 10.6237),
    "Tapikan":       (122.1635, 10.6159),
    "Sinogbuhan":    (122.1143, 10.5908),
    "Santa Rita":    (122.1012, 10.5825),
    "Igcondao":      (122.0651, 10.5453),
    "Cata-an":       (122.0687, 10.5205),
    "Paciencia":     (121.9375, 10.5125),
    "Igdalaguit":    (121.9316, 10.4893),
    "Bucaya":        (122.0289, 10.4880),
}

nonmpa_exp = {
    "Maramig":     (121.9339, 11.7632),
    "Paloc Bique": (122.7808, 10.8762),
    "Baras":       (122.2795, 10.6582),
}

panel_only = {
    "Batonan-Sur": (122.0661, 11.3805),  # dropped from experiment per 04_main_analysis.do:40
}

TEAL   = "#2A7BB5"
ORANGE = "#E8853D"
EDGE_COASTLINE = "#888888"
EDGE_ADMIN = "#AAAAAA"
LAND_COLOR  = "#F2F2F2"
OCEAN_COLOR = "#D6EAF8"


# Per-label offsets (dx_pts, dy_pts, ha) for the 22 villages.
# Discipline: ALL magnitudes ≈ 10 pts (so leader-line lengths look uniform).
# Direction varies per label (8 cardinal/diagonal directions).
# This keeps leader lines visually consistent and the eye can match label-to-point
# by direction rather than line length.
LABEL_OFFSETS = {
    # Northern cluster (lat ~11.7-11.9)
    "San Roque":     (  7,   7, "left"),    # NE
    "Pucio":         ( -7,   7, "right"),   # NW
    "Pajo":          (-10,   0, "right"),   # W
    "Bulanao":       (  7,  -7, "left"),    # SE
    "Maramig":       ( -7,  -7, "right"),   # SW (diamond)
    # Isolated mid (lat ~11.4)
    "Batonan-Sur":   (-10,   0, "right"),   # W
    # Mid-east column (lat ~11.1-11.3) — all labels go west since points are at right edge
    "Talotoan":      (-10,   0, "right"),   # W
    "Polopina":      (-10,   0, "right"),   # W
    "Maliogliog":    ( -7,  -7, "right"),   # SW (separate from Polopina vertically)
    # Mid (lat ~10.85)
    "Nanding Lopez": (  7,  -7, "left"),    # SE
    "Paloc Bique":   (  7,   7, "left"),    # NE (diamond, separate from NL)
    # SE area (lat ~10.6) — Calampitao/Baras share ~same point; stagger N/E
    "Calampitao":    (  0,  10, "center"),  # N (straight up)
    "Baras":         ( 10,   0, "left"),    # E (diamond) — Santa Rita / Baras separation
    "Suclaran":      ( 10,   0, "left"),    # E
    # Dense southern cluster (lat 10.4-10.6)
    "Tapikan":       (  0,  10, "center"),  # N (straight up)
    "Sinogbuhan":    ( -7,   7, "right"),   # NW
    "Santa Rita":    (-20,  -8, "right"),   # pushed west into ocean to clear Bucaya/Igcondao markers
    "Igcondao":      ( 10,   0, "left"),    # E
    "Cata-an":       (  7,  -7, "left"),    # SE
    "Paciencia":     ( -7,   7, "right"),   # NW (back inside map)
    "Igdalaguit":    ( -7,  -7, "right"),   # SW (back inside map)
    "Bucaya":        (  0, -10, "center"),  # S (straight down)
}


def add_label(ax, name, lon, lat, proj):
    dx, dy, ha = LABEL_OFFSETS.get(name, (10, 0, "left"))
    # relpos: where the leader line attaches to the LABEL bbox.
    # Pick the side closest to the data point so the line points cleanly inward.
    rx = 1.0 if dx < 0 else (0.0 if dx > 0 else 0.5)
    ry = 1.0 if dy < 0 else (0.0 if dy > 0 else 0.5)
    ax.annotate(
        name,
        xy=(lon, lat), xycoords=proj._as_mpl_transform(ax),
        xytext=(dx, dy), textcoords="offset points",
        fontsize=6, ha=ha, va="center",
        color="#222222",
        arrowprops=dict(
            arrowstyle="-", lw=0.4, color="#888888", alpha=0.85,
            relpos=(rx, ry),
            shrinkA=1.5,  # gap between label and start of line
            shrinkB=2.5,  # gap between end of line and the marker
        ),
        zorder=6,
    )


def main():
    # Sans-serif as user specified (Helvetica/Arial)
    plt.rcParams["font.family"] = "sans-serif"
    plt.rcParams["font.sans-serif"] = ["Arial", "Helvetica", "DejaVu Sans"]
    plt.rcParams["pdf.fonttype"] = 42
    plt.rcParams["ps.fonttype"] = 42

    proj = ccrs.PlateCarree()
    # Western extent extended to 121.5 to give the SW cluster (Paciencia, Igdalaguit)
    # room for their left-anchored labels.
    extent = [121.5, 123.4, 10.3, 12.05]

    # Figure size: 1-column PNAS (8.7 cm wide), tall enough for the N-S extent
    fig = plt.figure(figsize=(8.7 / 2.54, 11.0 / 2.54), dpi=200)
    ax = fig.add_subplot(1, 1, 1, projection=proj)
    ax.set_extent(extent, crs=proj)

    # ---- Basemap layers ----
    ax.add_feature(cfeature.OCEAN.with_scale("10m"), facecolor=OCEAN_COLOR, zorder=0)
    ax.add_feature(cfeature.LAND.with_scale("10m"),  facecolor=LAND_COLOR,  zorder=1)
    admin1 = cfeature.NaturalEarthFeature(
        category="cultural", name="admin_1_states_provinces_lines", scale="10m",
        edgecolor=EDGE_ADMIN, facecolor="none",
    )
    ax.add_feature(admin1, linewidth=0.3, zorder=2)
    ax.add_feature(
        cfeature.COASTLINE.with_scale("10m"),
        edgecolor=EDGE_COASTLINE, linewidth=0.5, zorder=3,
    )

    # ---- Points ----
    n_mpa_exp     = len(mpa_exp)
    n_nonmpa_exp  = len(nonmpa_exp)
    n_panel_only  = len(panel_only)

    for name, (lon, lat) in mpa_exp.items():
        ax.plot(
            lon, lat, marker="o", color=TEAL, markersize=5,
            markeredgewidth=0.4, markeredgecolor="white",
            transform=proj, zorder=5, linestyle="None",
        )
        add_label(ax, name, lon, lat, proj)

    for name, (lon, lat) in nonmpa_exp.items():
        ax.plot(
            lon, lat, marker="D", color=ORANGE, markersize=5,
            markeredgewidth=0.4, markeredgecolor="white",
            transform=proj, zorder=5, linestyle="None",
        )
        add_label(ax, name, lon, lat, proj)

    # Hollow circle: MPA village in longitudinal panel only (Batonan-Sur)
    for name, (lon, lat) in panel_only.items():
        ax.plot(
            lon, lat, marker="o", markerfacecolor="white",
            markeredgecolor=TEAL, markeredgewidth=1.0, markersize=5,
            transform=proj, zorder=5, linestyle="None",
        )
        add_label(ax, name, lon, lat, proj)

    # ---- Legend (Line2D proxies, since Patch does not accept marker) ----
    legend_handles = [
        Line2D([0], [0], marker="o", color="w",
               markerfacecolor=TEAL, markeredgecolor="white", markeredgewidth=0.4,
               markersize=5, linestyle="None",
               label=f"Both longitudinal + experiment (n={n_mpa_exp})"),
        Line2D([0], [0], marker="D", color="w",
               markerfacecolor=ORANGE, markeredgecolor="white", markeredgewidth=0.4,
               markersize=5, linestyle="None",
               label=f"Experiment only (n={n_nonmpa_exp})"),
        Line2D([0], [0], marker="o", color="w",
               markerfacecolor="white", markeredgecolor=TEAL, markeredgewidth=1.0,
               markersize=5, linestyle="None",
               label=f"Longitudinal only (n={n_panel_only})"),
    ]
    # Legend below the axes — too narrow for upper-right (would clash with inset).
    leg = ax.legend(
        handles=legend_handles,
        loc="upper center", bbox_to_anchor=(0.5, -0.06),
        fontsize=6, framealpha=0.92,
        edgecolor="#CCCCCC", handlelength=1.2,
        ncol=1, labelspacing=0.4,
    )
    leg.get_frame().set_linewidth(0.4)

    # ---- Axes labels & ticks ----
    ax.set_xticks([121.6, 122.0, 122.4, 122.8, 123.2], crs=proj)
    ax.set_yticks([10.4, 10.8, 11.2, 11.6, 12.0], crs=proj)
    ax.set_xticklabels([f"{x:.1f}°E" for x in [121.6, 122.0, 122.4, 122.8, 123.2]],
                       fontsize=6)
    ax.set_yticklabels([f"{y:.1f}°N" for y in [10.4, 10.8, 11.2, 11.6, 12.0]],
                       fontsize=6)
    ax.tick_params(length=2.5, width=0.4, color="#666666", pad=2)
    for s in ["top", "right"]:
        ax.spines[s].set_visible(False)
    for s in ["left", "bottom"]:
        ax.spines[s].set_color("#666666")
        ax.spines[s].set_linewidth(0.4)

    # ---- Inset: Philippines context, INSIDE main axes (upper-right area) ----
    # Shifted slightly inward (left + down) to free the very top-right corner for
    # the N arrow per user feedback.
    ax_inset = ax.inset_axes([0.62, 0.66, 0.30, 0.26], projection=proj)
    ax_inset.set_extent([116, 127, 4, 21], crs=proj)
    ax_inset.add_feature(cfeature.OCEAN.with_scale("50m"), facecolor="#EAF4FB", zorder=0)
    ax_inset.add_feature(cfeature.LAND.with_scale("50m"),  facecolor="#CCCCCC", zorder=1)
    ax_inset.add_feature(cfeature.COASTLINE.with_scale("50m"),
                         linewidth=0.3, edgecolor="#666666", zorder=2)
    # Indicator red dot — moved west of the islands into the Sulu Sea so it sits
    # fully in open water (was on Panay before). Acts as a visual flag rather than
    # a geographic centroid.
    ax_inset.plot(121.0, 11.0, marker="o", color="#C0392B", markersize=4,
                  markeredgecolor="#7C1A0F", markeredgewidth=0.5,
                  transform=proj, zorder=5)
    # Red bounding box outline
    ax_inset.add_patch(Rectangle(
        (extent[0], extent[2]),
        extent[1] - extent[0], extent[3] - extent[2],
        fill=False, edgecolor="#C0392B", linewidth=0.8,
        transform=proj, zorder=4,
    ))
    ax_inset.set_xticks([])
    ax_inset.set_yticks([])
    # Visible thin frame so it reads as an inset window
    for s in ["top", "right", "bottom", "left"]:
        ax_inset.spines[s].set_visible(True)
        ax_inset.spines[s].set_color("#666666")
        ax_inset.spines[s].set_linewidth(0.5)

    # ---- GIS-style north arrow at TOP-RIGHT of main map (fully inside axes) ----
    # Split black/white wedge, common cartographic style. Position is in axes
    # fraction; tip + N label kept well inside the axes (y_max ≤ 0.97) so nothing
    # gets clipped at the border.
    cx_n = 0.955
    arrow_top, arrow_bot = 0.92, 0.84
    arrow_half_w = 0.022   # half-width in axes fraction
    notch_y = arrow_bot + (arrow_top - arrow_bot) * 0.25  # inner notch slightly above base
    # Left half (black, filled)
    ax.add_patch(Polygon(
        [(cx_n, arrow_top), (cx_n - arrow_half_w, arrow_bot), (cx_n, notch_y)],
        closed=True, facecolor="#222222", edgecolor="#222222",
        linewidth=0.5, transform=ax.transAxes, zorder=11, clip_on=False,
    ))
    # Right half (white, outlined)
    ax.add_patch(Polygon(
        [(cx_n, arrow_top), (cx_n + arrow_half_w, arrow_bot), (cx_n, notch_y)],
        closed=True, facecolor="white", edgecolor="#222222",
        linewidth=0.5, transform=ax.transAxes, zorder=11, clip_on=False,
    ))
    # N label above the wedge
    ax.text(
        cx_n, arrow_top + 0.012, "N",
        transform=ax.transAxes, ha="center", va="bottom",
        fontsize=7, fontweight="bold", color="#222222", zorder=11,
    )

    # ---- Geographer-style segmented scale bar ----
    # Two alternating 25-km segments (black / white), tick labels at 0/25/50,
    # "km" suffix to the right of the last label.
    import numpy as np
    bar_lat = (extent[2] + extent[3]) / 2.0
    km_per_deg_lon = 111.32 * np.cos(np.deg2rad(bar_lat))
    bar_total_km = 50
    bar_total_deg = bar_total_km / km_per_deg_lon
    seg_deg = bar_total_deg / 2.0
    bar_height_deg = 0.030  # ~3.3 km tall — proportional and readable
    bar_x0 = extent[1] - 0.12 - bar_total_deg   # as far right as the "km" suffix allows
    bar_y0 = extent[2] + 0.14
    # Segment 1 (filled black, 0-25 km)
    ax.add_patch(Rectangle(
        (bar_x0, bar_y0), seg_deg, bar_height_deg,
        facecolor="#222222", edgecolor="#222222", linewidth=0.5,
        transform=proj, zorder=10,
    ))
    # Segment 2 (white with black outline, 25-50 km)
    ax.add_patch(Rectangle(
        (bar_x0 + seg_deg, bar_y0), seg_deg, bar_height_deg,
        facecolor="white", edgecolor="#222222", linewidth=0.5,
        transform=proj, zorder=10,
    ))
    # Tick labels: 0, 25, 50 — anchored to start of each segment / end
    for i, label in enumerate(["0", "25", "50"]):
        ax.text(
            bar_x0 + i * seg_deg, bar_y0 - 0.025, label,
            ha="center", va="top", fontsize=6, color="#222222",
            transform=proj, zorder=10,
        )
    # "km" unit label after the right-end tick
    ax.text(
        bar_x0 + bar_total_deg + 0.04, bar_y0 + bar_height_deg / 2.0, "km",
        ha="left", va="center", fontsize=6, color="#222222",
        transform=proj, zorder=10,
    )

    # ---- Save (PNG only, per user preference) ----
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(str(OUT_PNG), dpi=600, bbox_inches="tight", facecolor="white", format="png")
    print(f"Saved (raster): {OUT_PNG}")


if __name__ == "__main__":
    main()
