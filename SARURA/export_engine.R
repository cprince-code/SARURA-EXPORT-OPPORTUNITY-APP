
# ===================================================
# RWANDA AGRICULTURAL EXPORT INTELLIGENCE
# EXPORT ENGINE - PROTOTYPE VERSION 1.0
# ===================================================

library(dplyr)

# STEP 1 - LOAD FROZEN DATASETS

exports_clean <- readRDS(
  "data/prototype_v1/exports_v1.rds"
)

gdp_reconciled <- readRDS(
  "data/prototype_v1/gdp_impact_v1.rds"
)

gva_reference <- readRDS(
  "data/prototype_v1/gva_reference_v1.rds"
)

reconciliation_final <- readRDS(
  "data/prototype_v1/reconciliation_v1.rds"
)

# STEP 2 - DEFINE ILLUSTRATIVE GDP ASSUMPTIONS

assumed_agri_gdp <- 3500000000
assumed_national_gdp <- 14000000000


# STEP 3 - MARKET RECOMMENDATION FUNCTION

recommend_export_advanced <- function(
    product_name,
    quantity_kg,
    price_weight = 0.60,
    volume_weight = 0.40
) {
  
  if (
    !is.numeric(quantity_kg) ||
    length(quantity_kg) != 1 ||
    is.na(quantity_kg) ||
    !is.finite(quantity_kg) ||
    quantity_kg <= 0
  ) {
    stop("Quantity must be a positive number.")
  }
  
  if (
    length(price_weight) != 1 ||
    length(volume_weight) != 1 ||
    any(!is.finite(c(price_weight, volume_weight))) ||
    any(c(price_weight, volume_weight) < 0) ||
    abs(price_weight + volume_weight - 1) > 1e-8
  ) {
    stop("Weights must be non-negative and sum to 1.")
  }
  
  product_data <- exports_clean %>%
    filter(product == product_name)
  
  if (nrow(product_data) == 0) {
    stop("Product not found.")
  }
  
  product_data %>%
    group_by(country) %>%
    summarise(
      historical_quantity_kg = sum(quantity_kg),
      historical_value_usd = sum(export_value_usd),
      .groups = "drop"
    ) %>%
    mutate(
      historical_price_per_kg =
        historical_value_usd / historical_quantity_kg,
      
      price_score =
        historical_price_per_kg /
        max(historical_price_per_kg),
      
      volume_score =
        historical_quantity_kg /
        max(historical_quantity_kg),
      
      recommendation_score = 100 * (
        price_weight * price_score +
          volume_weight * volume_score
      ),
      
      input_quantity_kg = quantity_kg,
      
      estimated_revenue_usd =
        input_quantity_kg * historical_price_per_kg
    ) %>%
    arrange(desc(recommendation_score)) %>%
    mutate(rank = row_number()) %>%
    select(
      rank,
      country,
      historical_price_per_kg,
      historical_quantity_kg,
      estimated_revenue_usd,
      recommendation_score
    )
}


# STEP 4 - INTEGRATED EXPORT ANALYSIS

analyze_export_opportunities <- function(
    product_name,
    quantity_kg
) {
  
  recommendations <- recommend_export_advanced(
    product_name,
    quantity_kg
  ) %>%
    mutate(product = product_name)
  
  recommendations %>%
    left_join(
      gva_reference,
      by = c("product", "country")
    ) %>%
    mutate(
      estimated_gva_usd =
        estimated_revenue_usd * gva_ratio,
      
      agricultural_gdp_share_pct =
        estimated_gva_usd / assumed_agri_gdp * 100,
      
      national_gdp_share_pct =
        estimated_gva_usd / assumed_national_gdp * 100,
      
      gva_status = case_when(
        is.na(gva_ratio) ~ "Unavailable",
        match_type == "Provisional product mapping" ~
          "Provisional assumption",
        TRUE ~ "Exact transaction match"
      )
    ) %>%
    select(
      rank,
      product,
      country,
      historical_price_per_kg,
      historical_quantity_kg,
      estimated_revenue_usd,
      recommendation_score,
      gva_ratio,
      estimated_gva_usd,
      agricultural_gdp_share_pct,
      national_gdp_share_pct,
      gva_status
    )
}


# STEP 5 - FORMAT RESULTS FOR THE APPLICATION

format_export_results <- function(results) {
  
  # Format monetary values
  format_usd <- function(x) {
    
    formatted <- ifelse(
      is.na(x),
      "Not available",
      paste0(
        "$",
        format(
          round(x, 2),
          big.mark = ",",
          scientific = FALSE,
          trim = TRUE,
          nsmall = 2
        )
      )
    )
    
    return(formatted)
  }
  
  # Format percentages
  format_percentage <- function(x) {
    
    formatted <- ifelse(
      is.na(x),
      "Not available",
      paste0(
        sprintf("%.6f", x),
        "%"
      )
    )
    
    return(formatted)
  }
  
  # Format historical quantities
  format_quantity <- function(x) {
    
    ifelse(
      is.na(x),
      "Not available",
      format(
        x,
        big.mark = ",",
        scientific = FALSE,
        trim = TRUE
      )
    )
  }
  
  # Format recommendation scores
  format_score <- function(x) {
    
    ifelse(
      is.na(x),
      "Not available",
      paste0(
        sprintf("%.1f", x),
        "/100"
      )
    )
  }
  
  # Produce a user-friendly results table
  results %>%
    transmute(
      Rank = rank,
      
      Product = product,
      
      Destination = country,
      
      `Historical Price / KG` =
        format_usd(historical_price_per_kg),
      
      `Historical Export Volume (KG)` =
        format_quantity(historical_quantity_kg),
      
      `Estimated Revenue` =
        format_usd(estimated_revenue_usd),
      
      `Recommendation Score` =
        format_score(recommendation_score),
      
      `Estimated GVA` =
        format_usd(estimated_gva_usd),
      
      `Agricultural GDP Share` =
        format_percentage(
          agricultural_gdp_share_pct
        ),
      
      `National GDP Share` =
        format_percentage(
          national_gdp_share_pct
        ),
      
      `GVA Reliability` =
        ifelse(
          is.na(gva_status),
          "Unavailable",
          gva_status
        )
    )
}


# STEP 6 - PROTOTYPE DATA-QUALITY INFORMATION

get_prototype_warnings <- function() {
  
  c(
    "PROTOTYPE VERSION 1.0 - UNVERIFIED SAMPLE DATA",
    
    paste(
      "Export figures come from AI-compiled",
      "sample datasets and are not officially verified."
    ),
    
    "The original reporting year is unknown.",
    
    paste(
      "Recommendation scores are experimental",
      "price-and-volume rankings, not demand forecasts."
    ),
    
    paste(
      "Estimated revenue assumes the supplied quantity",
      "can be sold at the sample historical unit price."
    ),
    
    paste(
      "GVA estimates use unverified ratios.",
      "Provisional mappings require further review."
    ),
    
    paste(
      "GDP shares use assumed denominators",
      "rather than verified national accounts."
    ),
    
    paste(
      "The reconciliation identified 14 review items,",
      "including product-description conflicts",
      "and unmatched transactions."
    )
  )
}


# STEP 7 - ENGINE STATUS

cat("\nEXPORT ENGINE LOADED SUCCESSFULLY\n")

cat(
  "Export records:",
  nrow(exports_clean),
  "\n"
)

cat(
  "GDP-impact records:",
  nrow(gdp_reconciled),
  "\n"
)

cat(
  "GVA references:",
  nrow(gva_reference),
  "\n"
)

cat(
  "APPLICATION DISPLAY FORMATTER READY\n"
)

cat(
  "DATA-QUALITY WARNING SYSTEM READY\n"
)
