library(shiny)
library(dplyr)

load_crop_production <- function(path) {
  if (!file.exists(path)) stop("Crop production CSV not found: ", path)
  d <- read.csv(path, stringsAsFactors = FALSE)
  required <- c("District", "Crop", "Year", "Season", "Cultivated_Area_Ha", "Harvested_Area_Ha", "Yield_Kg_Ha")
  missing <- setdiff(required, names(d))
  if (length(missing)) stop("Missing crop data columns: ", paste(missing, collapse = ", "))
  d$District <- as.character(d$District)
  d$Crop <- as.character(d$Crop)
  d$Year <- as.numeric(d$Year)
  d$Season <- as.character(d$Season)
  for (field in c("Cultivated_Area_Ha", "Harvested_Area_Ha", "Yield_Kg_Ha")) d[[field]] <- as.numeric(d[[field]])
  d$Production_Kg <- d$Harvested_Area_Ha * d$Yield_Kg_Ha
  d
}

cropProductionUI <- function(id) {
  ns <- NS(id)
  tagList(
    h2("Crop Production"),
    p("Explore crop production, harvested area and yield across Rwanda."),
    fluidRow(
      column(4, wellPanel(h4("Total Production"), textOutput(ns("crop_total_production")), tags$small("Kilograms"))),
      column(4, wellPanel(h4("Harvested Area"), textOutput(ns("crop_total_area")), tags$small("Hectares"))),
      column(4, wellPanel(h4("Average Yield"), textOutput(ns("crop_average_yield")), tags$small("Kg per hectare")))
    )
  )
}

cropProductionServer <- function(id, agriculture) {
  moduleServer(id, function(input, output, session) {
    output$crop_total_production <- renderText({
      paste0(format(round(sum(agriculture()$Production_Kg, na.rm = TRUE)), big.mark = ",", scientific = FALSE), " kg")
    })
    output$crop_total_area <- renderText({
      paste0(format(round(sum(agriculture()$Harvested_Area_Ha, na.rm = TRUE)), big.mark = ",", scientific = FALSE), " ha")
    })
    output$crop_average_yield <- renderText({
      value <- mean(agriculture()$Yield_Kg_Ha, na.rm = TRUE)
      if (!is.finite(value)) return("Not available")
      paste0(format(round(value), big.mark = ",", scientific = FALSE), " kg/ha")
    })
  })
}