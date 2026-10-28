# SARURA | Rwanda Agricultural Intelligence


library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(scales)
library(leaflet)
library(sf)
library(geodata)

source("export_engine.R", local = TRUE)
source("crop_production_module.R", local = TRUE)

crop_path <- if (file.exists("data/crop_production/agriculture_season_A_2026_clean.csv")) {
  "data/crop_production/agriculture_season_A_2026_clean.csv"
} else "agriculture_season_A_2026_clean.csv"
# Rwanda district boundaries.
load_rwanda_districts <- function() {
  local_path <- "data/maps/rwanda_districts.geojson"
  if (file.exists(local_path)) {
    return(sf::st_read(local_path, quiet = TRUE))
  }
  dir.create("data/maps/gadm_cache", recursive = TRUE, showWarnings = FALSE)
  tryCatch({
    x <- geodata::gadm(country = "RWA", level = 2,
                       path = "data/maps/gadm_cache")
    sf::st_as_sf(x)
  }, error = function(e) {
    warning("Rwanda district map unavailable: ", conditionMessage(e))
    NULL
  })
}

rwanda_districts <- load_rwanda_districts()

normalize_district <- function(x) {
  x <- iconv(as.character(x), to = "ASCII//TRANSLIT")
  tolower(gsub("[^a-z0-9]", "", x))
}

if (!is.null(rwanda_districts)) {

  name_col <- intersect(c("NAME_2", "District", "district", "NAME_1"),
                        names(rwanda_districts))
  if (length(name_col) == 0) {
    warning("Map boundaries have no recognized district-name column.")
    rwanda_districts <- NULL
  } else {
    rwanda_districts$map_district <- as.character(rwanda_districts[[name_col[1]]])
    rwanda_districts$district_key <- normalize_district(rwanda_districts$map_district)
    rwanda_districts <- sf::st_transform(rwanda_districts, 4326)
  }
}

agriculture <- load_crop_production(crop_path)
products <- sort(unique(na.omit(exports_clean$product)))
stopifnot(length(products) > 0)
fmt <- function(x, digits = 0) format(round(x, digits), big.mark = ",", scientific = FALSE, trim = TRUE)

video_layer <- if (file.exists("www/background.mp4")) {
  tags$video(class = "video-bg", autoplay = NA, muted = NA, loop = NA,
             playsinline = NA, preload = "auto",
             tags$source(src = "background.mp4", type = "video/mp4"))
} else {
  message("SARURA: no background video found at www/background2.mp4; using gradient fallback.")
  NULL
}

ui <- fluidPage(
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$style(HTML('
      :root { --ink:#f8fbff; --muted:#d4e1f4; --blue:#7ab6ff; --violet:#c5a7ff; --amber:#ffd98d; }
      html { min-height:100%; }
      body { background:#101c2e; color:var(--ink); font-family:system-ui,-apple-system,"Segoe UI",Arial,sans-serif; }
      .video-bg { position:fixed; inset:0; width:100%; height:100%; object-fit:cover; z-index:0; pointer-events:none; }
      /* Adjustable overlay: visible video without losing foreground contrast. */
      .video-overlay { position:fixed; inset:0; z-index:1; pointer-events:none; opacity:.58;
        background:linear-gradient(115deg,rgba(7,17,34,.86),rgba(13,26,52,.73) 52%,rgba(12,22,42,.82)); }
      .container-fluid { max-width:1480px; padding:18px 26px; }
      .container-fluid > .hero, .container-fluid > .tabbable, .container-fluid > .footer { position:relative; z-index:2; }
      .hero { padding:30px 34px; margin:12px 0 20px; border:1px solid rgba(255,255,255,.38);
        border-radius:22px; background:rgba(8,24,47,.63); box-shadow:0 18px 55px rgba(0,0,0,.22);
        -webkit-backdrop-filter:blur(12px); backdrop-filter:blur(12px); }
      .hero h1 { margin:0; font-size:40px; font-weight:850; letter-spacing:2.5px; color:#fff; text-shadow:0 2px 14px #07172d; }
      .hero p { color:#e4eeff; margin:8px 0 0; line-height:1.55; }
      .video-control { display:flex; flex-wrap:wrap; gap:12px; align-items:center; margin-top:18px; }
      .video-control label { font-size:12px; font-weight:700; margin:0; color:#f6f9ff; }
      .video-control input[type=range] { width:170px; cursor:pointer; accent-color:#8bc9ff; }
      .video-control small { color:#e4efff; font-size:11px; }
      .panel-sarura { background:rgba(10,28,52,.76); border:1px solid rgba(219,235,255,.29);
        border-radius:18px; padding:22px; margin:15px 0; box-shadow:0 14px 38px rgba(0,0,0,.24);
        -webkit-backdrop-filter:blur(14px); backdrop-filter:blur(14px);
        transition:transform .2s ease,background .2s ease,border-color .2s ease; }
      .panel-sarura:hover { background:rgba(10,29,55,.84); border-color:rgba(190,221,255,.52); }
      .panel-sarura h3 { margin-top:0; color:#f0f5ff; font-size:21px; font-weight:750; }
      .panel-sarura p { color:#e0eafb; line-height:1.6; }
      .metric { border-left:4px solid #9dd4ff; min-height:116px; }
      .metric .value { font-size:29px; font-weight:800; color:white; overflow-wrap:anywhere; text-shadow:0 2px 8px #091a30; }
      .metric .label { color:#dbeaff; font-size:13px; font-weight:650; margin-bottom:9px; }
      .nav-tabs { border-bottom:1px solid rgba(226,238,255,.4); }
      .nav-tabs>li>a { color:#fff; font-weight:650; border:1px solid transparent; border-radius:12px 12px 0 0; background:rgba(10,28,54,.46); margin-right:5px; }
      .nav-tabs>li>a:hover { color:#fff; background:rgba(47,97,150,.8); border-color:transparent; }
      .nav-tabs>li.active>a,.nav-tabs>li.active>a:hover,.nav-tabs>li.active>a:focus { background:rgba(225,239,255,.96); color:#102b49; border:1px solid #d8e8ff; }
      label,.control-label,h2,h3,h4 { color:#f5f8ff; }
      .form-control,.selectize-input { background:#f8fbff; color:#14283f; border:1px solid #bfd2e9; border-radius:9px; }
      .form-control:focus,.selectize-input.focus { border-color:#78b9ff; box-shadow:0 0 0 3px rgba(120,185,255,.25); }
      .btn-primary { background:#4c92e4; border:1px solid #85c6ff; border-radius:10px; padding:10px 17px; font-weight:750; color:#fff; }
      .btn-primary:hover,.btn-primary:focus { background:#246dbd; color:#fff; }
      .table { background:rgba(250,252,255,.97); color:#14253b; font-size:12px; border-radius:8px; }
      .table th { background:#e7f0ff; color:#122b48; }
      .well { background:rgba(15,39,68,.76); border:1px solid rgba(201,229,255,.35); color:white; border-radius:13px; }
      .well h4 { color:#fff; } .well p,.well small { color:#e2edff; }
      .chart-panel { background:rgba(8,22,43,.38); border:1px solid rgba(202,229,255,.16);
        border-radius:14px; padding:14px; margin:10px 0 16px; }
      .chart-panel h4 { font-size:16px; font-weight:700; }
      .leaflet-container { background:#dceaf0 !important; border-radius:12px; }
      .chart-caption,.help { color:#e1ecff !important; font-size:12px; }
      .warning { border-left:4px solid var(--amber); background:rgba(65,42,28,.82); color:#ffeed6; padding:14px; border-radius:10px; }
      .footer { color:#f0f5ff; text-align:center; padding:25px; font-size:12px; text-shadow:0 1px 5px #06182c; }
      @media(max-width:700px) { .hero h1{font-size:30px} .container-fluid{padding:10px} .hero{padding:20px} .panel-sarura{padding:15px} .video-control input[type=range]{width:130px} }
      @media(prefers-reduced-motion:reduce) { .panel-sarura{transition:none} }
    '))
  ),
  video_layer,
  div(class = "video-overlay"),
  div(class = "hero", h1("SARURA"),
      p("Rwanda Agricultural Intelligence | Export opportunities, production and economic scenarios"),
      
      div(class = "video-control",
          tags$label(`for` = "videoShade", "Background darkness"),
          tags$input(id = "videoShade", type = "range", min = "20", max = "95", value = "58", step = "1",
                     `aria-label` = "Adjust background darkness",
                     oninput = "document.querySelector('.video-overlay').style.opacity = this.value / 100;"),
          tags$small("Slide left for clearer video; right for easier reading"))),
  tabsetPanel(id = "section",
              tabPanel("Overview", br(),
                       fluidRow(
                         column(4, div(class="panel-sarura metric",div(class="label","Sample export records"),div(class="value",nrow(exports_clean)))),
                         column(4, div(class="panel-sarura metric",div(class="label","Crop production records"),div(class="value",nrow(agriculture)))),
                         column(4, div(class="panel-sarura metric",div(class="label","Districts in crop dataset"),div(class="value",n_distinct(agriculture$District))))
                       ),
                       div(class="panel-sarura",h3("Explore SARURA"),p("Smarter Exports. Better Markets. Greater Growth."))
                       
              ),
              tabPanel("Export Intelligence",br(),
                       fluidRow(
                         column(3,div(class="panel-sarura",h3("Scenario filters"),
                                      selectInput("product","Agricultural product",choices=products,
                                                  selected=if("Arabica Coffee (Fully Washed)" %in% products) "Arabica Coffee (Fully Washed)" else products[1]),
                                      numericInput("quantity","Export quantity (kg)",value=10000,min=1,step=100),
                                      actionButton("analyze","Analyze opportunities",class="btn-primary"),
                                      hr(),p(class="help","Agriculture intelligence recommending system"))),
                         column(9,
                                div(class="panel-sarura",h3("Destination ranking"),plotlyOutput("destination_chart",height="350px")),
                                div(class="panel-sarura",h3("Illustrative revenue by destination"),plotlyOutput("revenue_chart",height="350px"))
                         )
                       ),
                       div(class="panel-sarura",h3("Export recommendations"),tableOutput("recommendations")),
                       div(class="panel-sarura",h3("Illustrative economic impact"),tableOutput("economic_impact"))
              ),
              tabPanel("Crop Production",br(),
                       div(class="panel-sarura",
                           cropProductionUI("crop_module")),
                       div(class="panel-sarura",
                           div(class="section-eyebrow", " "),
                           h3("Production visualizations"),
                           p(class="help", "Crop and District filters on agricultural charts."),
                           fluidRow(
                             column(6, selectInput("extra_crop", "Crop", choices=c("All Crops", sort(unique(na.omit(agriculture$Crop)))))),
                             column(6, selectInput("extra_district", "District", choices=c("All Districts", sort(unique(na.omit(agriculture$District))))))
                           ),
                           fluidRow(
                             column(6, div(class="chart-panel", h4("Harvested area by district"), plotlyOutput("area_chart",height="380px"))),
                             column(6, div(class="chart-panel", h4("Mean yield by district — Rwanda map"), leafletOutput("dominance_map",height="380px"),
                                           p(class="chart-caption", "Darker districts have greater calculated production (kg). Hover for values; the leading district is outlined in gold.")))
                           ),
                           fluidRow(
                             column(6, div(class="chart-panel", h4("Harvested area vs. yield"), plotlyOutput("scatter_chart",height="390px")
                             )),
                             column(6, div(class="chart-panel", h4("Crop share of calculated production"), plotlyOutput("crop_donut",height="390px"),
                                           p(class="chart-caption", "Top crops by production (kg); remaining crops grouped as Other.")))
                           ),
                           fluidRow(
                             column(12, div(class="chart-panel", h4("District yield profile"), plotlyOutput("yield_profile",height="360px")
                             ))
                           )
                       ),
                       div(class="panel-sarura",
                           div(class="section-eyebrow", " "),
                           h3("Export product comparison"),
                           
                           div(class="chart-panel", h4("Share of sample export records by product"), plotlyOutput("export_donut",height="410px"))
                       )
              ),
              tabPanel("About", br(),
                       div(class="panel-sarura",
                           h3("About SARURA"),
                           p("SARURA — Rwanda Agricultural Intelligence — is an interactive prototype designed to help users explore agricultural production in Rwanda and assess illustrative export opportunities through clear, data-driven visualizations."),
                           p("The application brings together two separate areas of analysis: export intelligence and crop production. It aims to make agricultural information easier to explore, compare and communicate.")),
                       fluidRow(
                         column(6, div(class="panel-sarura",
                                       h3("Export Intelligence"),
                                       p("Choose an agricultural product and an export quantity to compare destinations using sample historical price and volume information."),
                                       p("Explore destination rankings, illustrative revenue estimates and economic-impact scenarios through interactive charts and tables."))),
                         column(6, div(class="panel-sarura",
                                       h3("Crop Production"),
                                       p("Explore the separate 2026 Season A crop dataset across Rwanda's districts, with filters for crops and districts."),
                                       p("Compare harvested area, average yield and calculated production using summary indicators, bar charts, a scatter plot, donut charts and a district yield profile.")))
                       ),
                       div(class="panel-sarura",
                           h3("Who can use SARURA?"),
                           p("SARURA transforms agricultural data into market intelligence, helping users discover export opportunities, explore trade scenarios, and make smarter decisions about where Rwanda's agricultural products can compete globally."))
                       
              )
  ),
  div(class="footer","SARURA • Agricultural intelligence app 2026 •")
)

server <- function(input,output,session) {
  cropProductionServer("crop_module",agriculture=reactive(agriculture))
  
  analysis <- eventReactive(input$analyze,{
    validate(need(!is.null(input$product) && length(input$product)==1,"Choose a product."),
             need(length(input$quantity)==1 && is.finite(input$quantity) && input$quantity>0,"Enter a positive quantity."))
    analyze_export_opportunities(product_name=input$product,quantity_kg=input$quantity)
  },ignoreNULL=FALSE)
  formatted <- reactive(format_export_results(analysis()))
  output$recommendations <- renderTable({
    formatted() %>% select(Rank,Destination,`Historical Price / KG`,`Historical Export Volume (KG)`,`Estimated Revenue`,`Recommendation Score`)
  },striped=TRUE,bordered=TRUE,spacing="s")
  output$economic_impact <- renderTable({
    formatted() %>% select(Destination,`Estimated Revenue`,`Estimated GVA`)
  },striped=TRUE,bordered=TRUE,spacing="s")
  numeric_display <- function(x) suppressWarnings(as.numeric(gsub("[^0-9.-]","",as.character(x))))
  output$destination_chart <- renderPlotly({
    d <- formatted(); validate(need(nrow(d)>0,"No destinations for this product."))
    d$score <- numeric_display(d$`Recommendation Score`)
    d <- d[is.finite(d$score),,drop=FALSE]
    validate(need(nrow(d)>0,"Scores unavailable."))
    plot_ly(d,x=~score,y=~reorder(Destination,score),type="bar",orientation="h",
            marker=list(color="#8091ff"),hovertemplate="%{y}<br>Score: %{x}<extra></extra>") %>%
      layout(xaxis=list(title="Illustrative ranking score"),yaxis=list(title=""),
             paper_bgcolor="rgba(0,0,0,0)",plot_bgcolor="rgba(0,0,0,0)",font=list(color="#dce5ff"))
  })
  output$revenue_chart <- renderPlotly({
    d <- formatted(); validate(need(nrow(d)>0,"No destinations for this product."))
    d$revenue <- numeric_display(d$`Estimated Revenue`)
    d <- d[is.finite(d$revenue),,drop=FALSE]
    validate(need(nrow(d)>0,"Revenue estimates unavailable."))
    plot_ly(d,x=~revenue,y=~reorder(Destination,revenue),type="bar",orientation="h",
            marker=list(color="#bd90ff"),hovertemplate="%{y}<br>Scenario revenue: %{x:$,.0f}<extra></extra>") %>%
      layout(xaxis=list(title="Illustrative revenue (USD)"),yaxis=list(title=""),
             paper_bgcolor="rgba(0,0,0,0)",plot_bgcolor="rgba(0,0,0,0)",font=list(color="#dce5ff"))
  })
  
  extra_data <- reactive({
    d <- agriculture
    if(!is.null(input$extra_crop) && input$extra_crop!="All Crops") d <- d %>% filter(Crop==input$extra_crop)
    if(!is.null(input$extra_district) && input$extra_district!="All Districts") d <- d %>% filter(District==input$extra_district)
    d
  })
  output$area_chart <- renderPlotly({
    d <- extra_data() %>% group_by(District) %>% summarise(area=sum(Harvested_Area_Ha,na.rm=TRUE),.groups="drop")
    validate(need(nrow(d)>0,"No area data."))
    plot_ly(d,x=~area,y=~reorder(District,area),type="bar",orientation="h",marker=list(color="#8091ff")) %>%
      layout(title="Harvested area by district",xaxis=list(title="Hectares"),yaxis=list(title=""),
             paper_bgcolor="rgba(0,0,0,0)",plot_bgcolor="rgba(0,0,0,0)",font=list(color="#dce5ff"))
  })
  # Map uses mean yield (kg/ha), matching the chart it replaces.
  # This is the arithmetic mean of valid crop-yield records for each district.
  output$dominance_map <- renderLeaflet({
    validate(need(!is.null(rwanda_districts),
                  "District boundaries unavailable. Provide data/maps/rwanda_districts.geojson or allow the initial GADM download."))
    d <- extra_data() %>%
      filter(!is.na(District), is.finite(Yield_Kg_Ha)) %>%
      group_by(District) %>%
      summarise(mean_yield = mean(Yield_Kg_Ha), .groups = "drop") %>%
      mutate(district_key = normalize_district(District))
    validate(need(nrow(d) > 0, "No valid yield observations for these filters."))
    
    # Match district boundaries by normalized district names.
    shape <- dplyr::left_join(rwanda_districts, d, by = "district_key")
    unmatched <- setdiff(d$district_key, shape$district_key)
    if (length(unmatched)) {
      warning("Districts without matching map boundary: ",
              paste(d$District[d$district_key %in% unmatched], collapse = ", "))
    }
    validate(need(any(is.finite(shape$mean_yield)),
                  "No district names matched the map boundaries."))
    
    top_yield <- max(shape$mean_yield, na.rm = TRUE)
    shape$is_leader <- is.finite(shape$mean_yield) &
      shape$mean_yield == top_yield
    pal <- leaflet::colorNumeric(
      palette = c("#e0f1fa", "#9fdad8", "#46a9ac", "#156778"),
      domain = shape$mean_yield, na.color = "#c7d1dd"
    )
    yield_label <- ifelse(
      is.finite(shape$mean_yield),
      paste0(format(round(shape$mean_yield), big.mark = ",",
                    scientific = FALSE), " kg/ha"),
      "No yield data"
    )
    shape$hover_label <- paste0(
      shape$map_district, ": ", yield_label,
      ifelse(shape$is_leader, " (highest mean yield)", "")
    )
    
    
    
    bounds <- sf::st_bbox(shape)
    leaflet::leaflet(shape,
                     options = leaflet::leafletOptions(zoomControl = TRUE,
                                                       attributionControl = FALSE)) %>%
      leaflet::addPolygons(
        fillColor = ~pal(mean_yield), fillOpacity = 0.91,
        color = ~ifelse(is_leader, "#ffd36d", "#ffffff"),
        weight = ~ifelse(is_leader, 4, 1),
        label = ~hover_label,
        popup = ~htmltools::HTML(paste0(
          "<strong>", htmltools::htmlEscape(map_district), "</strong><br>",
          "Mean yield: ", yield_label,
          ifelse(is_leader, "<br><strong>Highest mean yield</strong>", "")
        )),
        highlightOptions = leaflet::highlightOptions(
          weight = 3, color = "#fff0a4", bringToFront = TRUE
        )
      ) %>%
      leaflet::addLegend(position = "bottomright", pal = pal,
                         values = ~mean_yield,
                         title = "Mean yield (kg/ha)", opacity = 0.9) %>%
      leaflet::fitBounds(lng1 = unname(bounds["xmin"]),
                         lat1 = unname(bounds["ymin"]),
                         lng2 = unname(bounds["xmax"]),
                         lat2 = unname(bounds["ymax"]))
  })
  
  # Consistent Plotly theme for new production and export charts.
  sarura_layout <- function(p, ...) {
    layout(p, ..., paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
           font=list(color="#e1e9ff"), legend=list(font=list(color="#e1e9ff")),
           margin=list(l=65,r=24,t=22,b=58))
  }
  
  output$scatter_chart <- renderPlotly({
    d <- extra_data() %>%
      group_by(District) %>%
      summarise(area=sum(Harvested_Area_Ha, na.rm=TRUE),
                production=sum(Production_Kg, na.rm=TRUE),
                yield=mean(Yield_Kg_Ha, na.rm=TRUE), .groups="drop") %>%
      filter(is.finite(area), is.finite(yield), area>0, yield>=0)
    validate(need(nrow(d)>0, "No valid district area/yield observations for these filters."))
    d$bubble <- pmax(10, pmin(42, 10+10*sqrt(pmax(d$production,0)/max(1,max(d$production,na.rm=TRUE)))))
    p <- plot_ly(d, x=~area, y=~yield, type="scatter", mode="markers",
                 text=~paste0(District,"<br>Harvested area: ",round(area)," ha",
                              "<br>Mean yield: ",round(yield)," kg/ha",
                              "<br>Calculated production: ",round(production)," kg"),
                 hoverinfo="text", marker=list(color="#76d5ff", opacity=.82,
                                               line=list(color="#e6f3ff",width=1)),
                 size=~bubble, sizes=c(12,42), showlegend=FALSE)
    sarura_layout(p, xaxis=list(title="Harvested area (ha)",gridcolor="#ffffff1b"),
                  yaxis=list(title="Mean yield (kg/ha)",gridcolor="#ffffff1b"))
  })
  
  output$crop_donut <- renderPlotly({
    d <- agriculture %>% group_by(Crop) %>%
      summarise(value=sum(Production_Kg,na.rm=TRUE),.groups="drop") %>%
      filter(!is.na(Crop), is.finite(value), value>0) %>% arrange(desc(value))
    validate(need(nrow(d)>0,"No positive calculated production for these filters."))
    if(nrow(d)>7) d <- bind_rows(d[1:7,], tibble(Crop="Other crops", value=sum(d$value[-(1:7)])))
    p <- plot_ly(d, labels=~Crop, values=~value, type="pie", hole=.62,
                 textinfo="percent", textposition="inside",
                 hovertemplate="%{label}<br>%{value:,.0f} kg<br>%{percent}<extra></extra>",
                 marker=list(colors=c("#8091ff","#ffc67e","#a88bff","#76d5ff","#fb8cb6","#69dcc6","#d1a8ff","#b9c4de")))
    sarura_layout(p, showlegend=TRUE)
  })
  
  output$yield_profile <- renderPlotly({
    d <- extra_data() %>% group_by(District) %>%
      summarise(yield=mean(Yield_Kg_Ha,na.rm=TRUE),.groups="drop") %>%
      filter(is.finite(yield)) %>% arrange(yield)
    validate(need(nrow(d)>0,"No valid district yield data for these filters."))
    
    d$District <- factor(d$District, levels=d$District)
    p <- plot_ly(d,x=~District,y=~yield,type="scatter",mode="lines+markers",
                 line=list(color="#b69aff",width=3),marker=list(color="#ffc67e",size=9),
                 hovertemplate="%{x}<br>Mean yield: %{y:,.0f} kg/ha<extra></extra>")
    sarura_layout(p,xaxis=list(title="Districts ordered by mean yield",tickangle=-40),
                  yaxis=list(title="Mean yield (kg/ha)",gridcolor="#ffffff1b"),showlegend=FALSE)
  })
  
  output$export_donut <- renderPlotly({
    d <- exports_clean %>% filter(!is.na(product),nzchar(as.character(product))) %>%
      count(product,name="records",sort=TRUE)
    validate(need(nrow(d)>0,"No export prototype records available."))
    if(nrow(d)>7) d <- bind_rows(d[1:7,],tibble(product="Other products",records=sum(d$records[-(1:7)])))
    p <- plot_ly(d,labels=~product,values=~records,type="pie",hole=.62,
                 textinfo="percent",textposition="inside",
                 hovertemplate="%{label}<br>Sample records: %{value}<br>%{percent}<extra></extra>",
                 marker=list(colors=c("#8091ff","#ffc67e","#a88bff","#76d5ff","#fb8cb6","#69dcc6","#d1a8ff","#b9c4de")))
    sarura_layout(p,showlegend=TRUE)
  })
  
}

shinyApp(ui,server)
