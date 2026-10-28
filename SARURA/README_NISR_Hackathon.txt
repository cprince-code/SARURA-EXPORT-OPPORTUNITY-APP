SARURA APP README
========================

NISR 2026 BIG DATA HACKATHON 


1. PROJECT SUMMARY AND PROBLEM STATEMENT

SARURA (Rwanda Agricultural Intelligence) is an interactive app
created to make agricultural production patterns and illustrative export
market comparisons easier to explore and make better export recommendation destinations.

Problem addressed:

Agricultural production and export information in Rwanda can be challenging to analyze when data is presented in separate datasets or 
spreadsheets. This makes it difficult for farmers, agricultural exporters, and decision-makers to compare crop production across districts, 
identify districts with higher crop yields, and understand agricultural performance.

Proposed solution:
SARURA addresses these challenges by providing an interactive agricultural intelligence dashboard 
that visualizes crop production across Rwanda's districts, highlights districts with the highest mean yield 
for selected crops, and enables users to explore agricultural patterns through interactive charts and maps.

The application also compares potential export destinations using sample historical price and volume data, generates 
illustrative export recommendations, and estimates hypothetical export revenue and gross value added (GVA) that can be added
after the exporting is done.

2. RELEVANCE TO RWANDA AND EXPECTED IMPACT
-----------------------------------------
SARURA is designed to support clearer discussion of agricultural
productivity, geographic differences, and possible export opportunities.
Potential applications include:
- Exploring which districts have higher recorded mean yields for a crop.
- Comparing harvested land area with recorded yield and calculated output.
- Helping learners interpret geographic patterns in agricultural data.
-Analyzing historical export data to identify the most promising international destinations for
 a given agricultural product, estimate potential export revenue, and assess the expected Gross 
 Value Added (GVA) associated with the export scenario.


3. DATA USED

 -Tables_2026_SeasonA 
 -agriculture_season_A_2026_clean(used necessary sheets)
 -Sample CSV containing exports and imports


4. WHAT INFORMATION THE DASHBOARD COMMUNICATES
----------------------------------------------
A. OVERVIEW
- Count of sample export records.
- Count of crop-production records.
- Count of districts represented by the crop data.
- Brief introduction to the purpose of the app.

B. EXPORT INTELLIGENCE
- Select an agricultural product.
- Enter an export quantity in kilograms.
- Click 'Analyze opportunities' to calculate a scenario.
- View a destination ranking chart and illustrative revenue chart.
- Read an Export Recommendations table with:
    Rank
    Destination
    Historical Price / KG
    Historical Export Volume (KG)
    Estimated Revenue
    Recommendation Score
- Read an Illustrative Economic Impact table with ONLY:
    Destination
    Estimated Revenue
    Estimated GVA

C. CROP PRODUCTION
- Three overview metrics: calculated production, harvested area,
  and average recorded yield.
- Crop and District dropdown filters for relevant analytical charts.
- Harvested area by district.
- Rwanda map showing mean yield (kg/ha) by district.
- highlighted boundary for the highest-mean-yield district in the
  currently selected comparison.
- Harvested area versus yield scatter plot.
- District yield profile.
- Crop share of calculated production donut chart.
- Sample export product record share donut chart.

D. ABOUT
- Explains SARURA's purpose, features, intended users.

5. HOW USERS INTERACT WITH SARURA
--------------------------------
EXPORT WORKFLOW:
1. Open 'Export Intelligence'.
2. Choose an agricultural product.
3. Enter a positive quantity in kilograms.
4. Click 'Analyze opportunities'.
5. Compare destination ranking, gross revenue, and available GVA values.
6. Interpret results as exploratory scenarios, not verified market advice.

CROP WORKFLOW:
1. Open 'Crop Production'.
2. Review the three summary metrics.
3. Select a Crop or keep 'All Crops'.
4. Select a District or keep 'All Districts'.
5. Compare harvested-area chart and district mean-yield map.
6. Hover over map regions to inspect district values.
7. Explore the scatter plot and yield profile.
8. Observe that the crop-share donut does not change with filters.


6. DATA PREPROCESSING AND ANALYTICAL METHODOLOGY
------------------------------------------------
CROP DATA:
The crop loader checks for required columns and converts Year and crop
area/yield fields to numeric values. Production is calculated as:

  Production_Kg = Harvested_Area_Ha * Yield_Kg_Ha

Harvested area by district is calculated as the sum of harvested hectares
in the selected records.

Averaging different crops under 'All Crops' may be misleading because
crop yield ranges differ. No multi-year trends can be inferred from the
single 2026 Season A dataset.

EXPORT DATA:
Illustrative gross revenue is calculated as:

  Estimated Revenue (USD) = Quantity (kg) * Reference Price (USD/kg)

Example: 10,000 kg * $5.80/kg = $58,000.


7. TECHNICAL IMPLEMENTATION
---------------------------
Language: R
Application framework: R Shiny
Packages used:shiny,dplyr,ggplot2,plotly,scales,leaflet,sf,geodata

Main source files:
- app.R: Main Shiny interface, filters, charts, map and tables.
- export_engine.R: Loads prototype export data and computes scenarios.
- crop_production_module.R: Loads/validates crop CSV and renders metrics.


8. INSTALLATION AND REPRODUCIBILITY
----------------------------------
PREREQUISITES:
- R installed.
- RStudio recommended.
- Network access for initial package installation and possibly map data.

Install packages in R Console using the following code:

install.packages(c(
  "shiny", "dplyr", "ggplot2", "plotly", "scales",
  "leaflet", "sf", "geodata"
))

HOW TO RUN THE CODE:
-Open the SARURA Folder
-Open the app.R
-set this Folder as the working directory before running the code
 
Steps in R studio to set a working directory:
*Go to Session>Set working directory>Choose directory
*Then choose the SARURA FOLDER and then run the code

*********************************************************************************************************************************
N.B: While running the app it may happen that when you move to Export intelligence or Crop production, it may take few seconds to
     display.Just be patient and then it will work.
**************************************************************************************************************************************

9.APPLICATION USERS

-The Governments and farmers 
-Researchers
-Students
-Different data based organisations
