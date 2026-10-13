# Air Quality Explorer

An interactive **R Shiny** dashboard for exploring air pollution trends by city, pollutant, and year.

![Dashboard screenshot](screenshot.png)

> Add your own screenshot as `screenshot.png` in the project root after running the app.

## Features

- Filter by city, pollutant, and year
- Summary cards: average level, worst month, and days within the safe limit
- Interactive monthly trend chart (hover to see values)
- Pollutant levels compared against safe limits
- Works out of the box with built-in sample data, or with your own CSV

## Tech stack

- R
- Shiny
- tidyverse packages (`dplyr`, `tidyr`, `lubridate`, `ggplot2`, `readr`)
- plotly

## Project structure

```
air-quality-explorer/
├── app.R                 # Shiny UI and server
├── requirements.txt      # List of R packages
├── install_packages.R    # Installs the packages above
├── data/raw/             # Place your CSV here (optional)
├── .gitignore
└── README.md
```

## Getting started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR-USERNAME/air-quality-explorer.git
cd air-quality-explorer
```

### 2. Install the packages

Open R (or RStudio) in the project folder and run:

```r
source("install_packages.R")
```

### 3. Run the app

```r
shiny::runApp()
```

The dashboard opens in your browser.

## Using your own data

By default the app generates sample data for Delhi, Chennai, and Mumbai so you can try it immediately.

To use real data, save a CSV at `data/raw/air_quality.csv` in this format:

```
date,city,pollutant,value
2023-01-01,Delhi,PM2.5,180
2023-01-01,Delhi,PM10,310
2023-01-01,Chennai,PM2.5,62
```

| Column      | Description                                  |
|-------------|----------------------------------------------|
| `date`      | Date in `YYYY-MM-DD` format                  |
| `city`      | City name                                    |
| `pollutant` | `PM2.5`, `PM10`, or `NO2`                    |
| `value`     | Concentration in µg/m³                       |

The app detects the file automatically on the next run.

Suggested data sources:
- [OpenAQ](https://openaq.org)
- [Kaggle: India air quality datasets](https://www.kaggle.com/datasets)

## Safe limits used

The dashboard compares readings to the Indian 24-hour standards (NAAQS):

| Pollutant | Limit (µg/m³) |
|-----------|---------------|
| PM2.5     | 60            |
| PM10      | 100           |
| NO2       | 80            |

You can change these in the `safe_limits` line near the top of `app.R`.

## Future improvements

- Add a `leaflet` map of monitoring stations
- Calculate the official AQI category for each day
- Compare two cities side by side
- Deploy to [shinyapps.io](https://www.shinyapps.io)

## License

This project is licensed under the MIT License.

## Author

Your Name - [GitHub](https://github.com/YOUR-USERNAME)
