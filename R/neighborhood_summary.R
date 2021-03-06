#' Summarize neighborhoods
#'
#' Calculates species-specific densities and species richness for each 
#' neighborhood in the provided data frame. Densities can be provided as
#' area covered in the neighborhood, area covered per hectare, or the sum of
#' horizontal angles.
#'
#' @param neighbors Data frame of neighborhoods outputted by
#' \code{neighborhoods} function.
#' @param radius Numeric vector describing neighborhood radius in meters.
#' @param densities Character specifying the type of density measurements to
#' calculate - raw (m^2 per hectare), proportional (as proportions of overall
#' tree density), angular (angular size of trees).
#' @return Data frame containing a summary for each neighborhood in
#' \code{neighbors}.

neighborhood_summary <- function(neighbors, radius, densities = "raw"){
  
  # Calculate species richness of each neighborhood
  sps_rich <- neighbors %>%
    group_by(tree_id) %>%
    summarize(sps_richness = length(unique(sps_comp)))
  
  # Extract required columns
  dens <- neighbors %>%
    select(tree_id, dbh, prox, dbh_comp, sps_comp, abh_comp)
  
  # Convert to wide format
  if(densities == "angular"){
    dens <- dens %>%
      mutate(sum_angle = atan(dbh_comp / (prox * 100))) %>%
      pivot_wider(id_cols = c(tree_id, dbh, prox, dbh_comp),
                  names_from = sps_comp, names_sort = T,
                  values_from = sum_angle, values_fill = 0) %>%
      select(-c(dbh, prox, dbh_comp)) %>%
      group_by(tree_id) %>%
      summarize(across(.fn = sum))
  } else{
    dens <- dens %>%
      pivot_wider(id_cols = c(tree_id, dbh, prox, dbh_comp),
                  names_from = sps_comp, names_sort = T,
                  values_from = abh_comp, values_fill = 0) %>%
      select(-c(dbh, prox, dbh_comp)) %>%
      group_by(tree_id) %>%
      summarize(across(.fn = sum))
    
    # Convert densities to units of m^2 / hectare
    dens <- dens %>%
      rowwise() %>%
      mutate(across(2:ncol(dens), ~ ./circ_area(radius)))
  }
  
  # Calculate all_density
  dens <- dens %>%
    ungroup() %>%
    mutate(all = rowSums(dens[, 2:ncol(dens)]))
  
  # Add "angle_sum" or "density" to column names
  if(densities == "angular"){
    names(dens)[-1] <- paste(names(dens)[-1], "angle_sum", sep = "_")
  } else{
    names(dens)[-1] <- paste(names(dens)[-1], "density", sep = "_")
  }
  
  # Convert densities to proportions if requested
  if(densities == "proportional"){
    dens <- dens %>%
      rowwise() %>%
      mutate(across(2:(ncol(dens) - 1), ~ ./all_density))
  }
  
  # Join species richness to densities
  output <- sps_rich %>%
    left_join(dens, by = "tree_id")
  
  # Return output
  return(output)
  
}
