# https://princeshinyprojects.shinyapps.io/SARURA/
SARURA – Rwanda Agricultural Intelligence app

SARURA is an interactive R Shiny application that helps users explore agricultural production across Rwanda and 
compare potential international export destinations using historical reference data.
Features
- Overview: Explore key statistics and summaries of the available agricultural and export data.
- Crop Production: Compare crop production, harvested area, and mean yields across Rwanda's districts using interactive charts and a district-level map.
- Export Intelligence: Compare potential export destinations based on historical reference prices and export volumes.
- Illustrative Economic Impact: Estimate hypothetical export revenue and Gross Value Added (GVA) for selected export scenarios.
  
Technologies
- R
- Shiny
- Plotly
- Interactive mapping and data visualization tools
Running the Application
1. Install R and RStudio.
2. Clone or download this repository.
3. Install the R packages required by the source files.
4. Open app.R in RStudio and click Run App, or run:
   shiny::runApp()
Keep the data/ folder and other project files in their original relative locations.
Project Structure
SARURA/
├── app.R
├── export_engine.R
├── crop_production_module.R
├── data/
│   ├── crop_production/
│   └── prototype_v1/
├── www/
└── README.md

Purpose
SARURA aims to make agricultural information easier to understand and explore, supporting evidence-informed discussion about crop performance and potential export opportunities in Rwanda.

TEAM
-URUJENI BENIGNE
-CYUZUZO MUHOZA PRINCE

Acknowledgements
University of Rwanda: For supporting the project.
NISR: Further Guidance and supporting this project.


