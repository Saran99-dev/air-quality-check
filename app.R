# ------------------------------------------------------------
# Air Quality Explorer - R Shiny dashboard
# Run with: shiny::runApp()
#
# Install packages once:
# install.packages(c("shiny", "dplyr", "tidyr", "lubridate",
#                    "ggplot2", "plotly", "readr"))
# ------------------------------------------------------------

library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(readr)

# ---------------- Safe limits (ug/m3, 24-hour, India NAAQS) ----
safe_limits <- c("PM2.5" = 60, "PM10" = 100, "NO2" = 80)

# ---------------- Data loading ---------------------------------
# Expected CSV format (long): date, city, pollutant, value
#   2023-01-01, Delhi, PM2.5, 180
# Place your file at data/raw/air_quality.csv to use real data.
# If the file is missing, sample data is generated so the app still runs.

make_sample_data <- function() {
  set.seed(42)
  cities <- c("Delhi", "Chennai", "Mumbai")
  dates  <- seq(as.Date("2022-01-01"), as.Date("2023-12-31"), by = "day")
  scale  <- c(Delhi = 1.6, Chennai = 0.8, Mumbai = 1.0)

  expand.grid(date = dates, city = cities, stringsAsFactors = FALSE) |>
    as_tibble() |>
    mutate(
      season = 1 + 0.6 * cos(2 * pi * (yday(date) - 330) / 365),
      k      = scale[city],
      n      = n(),
      `PM2.5` = pmax(5,  70  * k * season + rnorm(n, 0, 12)),
      PM10    = pmax(10, 120 * k * season + rnorm(n, 0, 20)),
      NO2     = pmax(5,  40  * k * season + rnorm(n, 0, 8))
    ) |>
    select(date, city, `PM2.5`, PM10, NO2) |>
    pivot_longer(c(`PM2.5`, PM10, NO2),
                 names_to = "pollutant", values_to = "value")
}

load_data <- function(path = "data/raw/air_quality.csv") {
  if (file.exists(path)) {
    read_csv(path, show_col_types = FALSE) |>
      mutate(date = as.Date(date)) |>
      filter(!is.na(value))
  } else {
    make_sample_data()
  }
}

air <- load_data()

# ---------------- UI -------------------------------------------
card_style <- paste(
  "background:#f5f5f4; border-radius:8px; padding:12px 16px;",
  "margin-bottom:12px;"
)

ui <- fluidPage(
  titlePanel("Air quality explorer"),

  fluidRow(
    column(4, selectInput("city", "City",
                          choices = sort(unique(air$city)))),
    column(4, selectInput("pollutant", "Pollutant",
                          choices = sort(unique(air$pollutant)))),
    column(4, selectInput("year", "Year",
                          choices = sort(unique(year(air$date)),
                                         decreasing = TRUE)))
  ),

  fluidRow(
    column(4, div(style = card_style,
                  tags$small("Average level (ug/m3)"),
                  h3(textOutput("avg_level")))),
    column(4, div(style = card_style,
                  tags$small("Worst month"),
                  h3(textOutput("worst_month")))),
    column(4, div(style = card_style,
                  tags$small("Days within safe limit"),
                  h3(textOutput("safe_days"))))
  ),

  fluidRow(
    column(12,
           h4("Monthly trend"),
           plotlyOutput("trend_plot", height = "320px"))
  ),

  fluidRow(
    column(12,
           h4("Pollutant levels vs safe limit"),
           plotOutput("limit_plot", height = "220px"))
  )
)

# ---------------- Server ---------------------------------------
server <- function(input, output, session) {

  # Rows for the chosen city, pollutant and year
  filtered <- reactive({
    air |>
      filter(city == input$city,
             pollutant == input$pollutant,
             year(date) == as.integer(input$year))
  })

  # Average value for each month
  monthly <- reactive({
    filtered() |>
      mutate(month = month(date, label = TRUE, abbr = TRUE)) |>
      group_by(month) |>
      summarise(avg = mean(value), .groups = "drop")
  })

  output$avg_level <- renderText({
    req(nrow(filtered()) > 0)
    round(mean(filtered()$value), 1)
  })

  output$worst_month <- renderText({
    req(nrow(monthly()) > 0)
    as.character(monthly()$month[which.max(monthly()$avg)])
  })

  output$safe_days <- renderText({
    req(nrow(filtered()) > 0)
    limit <- safe_limits[[input$pollutant]]
    if (is.null(limit)) return("n/a")
    sum(filtered()$value <= limit)
  })

  output$trend_plot <- renderPlotly({
    req(nrow(monthly()) > 0)
    limit <- safe_limits[input$pollutant]

    p <- ggplot(monthly(), aes(month, avg, group = 1)) +
      geom_line(colour = "#2a78d6", linewidth = 1) +
      geom_point(colour = "#2a78d6", size = 2) +
      labs(x = NULL, y = paste(input$pollutant, "(ug/m3)")) +
      theme_minimal()

    if (!is.na(limit)) {
      p <- p + geom_hline(yintercept = limit, linetype = "dashed",
                          colour = "#e34948")
    }
    ggplotly(p)
  })

  output$limit_plot <- renderPlot({
    levels_df <- air |>
      filter(city == input$city, year(date) == as.integer(input$year)) |>
      group_by(pollutant) |>
      summarise(avg = mean(value), .groups = "drop") |>
      mutate(limit = safe_limits[pollutant],
             pct   = avg / limit * 100) |>
      filter(!is.na(pct))

    req(nrow(levels_df) > 0)

    ggplot(levels_df, aes(reorder(pollutant, pct), pct,
                          fill = pct > 100)) +
      geom_col(width = 0.5) +
      geom_hline(yintercept = 100, linetype = "dashed") +
      coord_flip() +
      scale_fill_manual(values = c("TRUE" = "#e34948",
                                   "FALSE" = "#1baf7a"),
                        guide = "none") +
      labs(x = NULL, y = "% of safe limit") +
      theme_minimal()
  })
}

shinyApp(ui, server)
