<<<<<<< HEAD
# LatAm Macro Tracker 🇦🇷

> A B2B-grade automated macroeconomic and sovereign risk tracking tool, developed in R and Shiny.

[![R](https://img.shields.io/badge/R-4.6%2B-blue.svg)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-Web%20App-orange.svg)](https://shiny.posit.co/)
[![Deployment](https://img.shields.io/badge/Status-Online-success.svg)](https://www.shinyapps.io/)

## 📊 Project Overview
**LatAm Macro Tracker** is an interactive analytical dashboard designed for real-time tracking of critical Argentine macroeconomic variables and their correlation with international financial sovereign risk.

The platform is tailored for risk analysts, trading desks, and financial consultants who require fast, resilient, and automatically updated dashboards without operational friction.

👉 **[View Live App on Shinyapps.io](https://francolupi.shinyapps.io/latam_macro_tracker/)**

---

## 🚀 Key Features
*   **Dynamic KPI Cards:** Top-tier metrics panel displaying the latest available value and period for instant executive reading.
*   **Official Data Integration:** Direct connection via public APIs with **INDEC** (General CPI Inflation Index) and **BCRA** (Average Wholesale Exchange Rate).
*   **Resilient Architecture (Fail-Safe):** Hybrid data ingestion engine featuring robust error handling (`tryCatch`, timeouts) and a local CSV fallback mechanism for secondary financial risk indicators (EMBI), ensuring 100% uptime.
*   **Interactive Visualizations:** High-fidelity charts built with `Plotly`, featuring synchronized axes, detailed tooltips, and independent thematic tabs.

---

## 🛠️ Tech Stack
*   **Language:** R
*   **Web Framework:** Shiny
*   **Visualization:** Plotly, Native HTML/CSS
*   **Data Wrangling & API Consumption:** `dplyr`, `httr`, `jsonlite`
*   **Infrastructure:** Deployed and hosted on the cloud via `rsconnect` and `shinyapps.io`.

---

## ⚙️ Architecture & Engineering Decisions
1.  **Reporting Lag Management:** Monthly and daily datasets are processed and normalized asynchronously using standardized month-start dates via `full_join`, solving publication time gaps.
2.  **Hybrid Strategy for Sovereign Risk (EMBI):** To mitigate volatility and intermittency in public API metadata for secondary financial series, the system implements a local CSV *fallback* mechanism that prevents total application crashes.

---

## 💻 How to Run Locally

If you want to clone and run this repository in your local RStudio environment:

1. Clone the repository:
   ```bash
   git clone [https://github.com/franco-lupi-data/latam-macro-tracker.git](https://github.com/franco-lupi-data/latam-macro-tracker.git)