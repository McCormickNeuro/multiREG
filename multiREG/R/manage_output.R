#' Manage Output from multiREG
#' @param out Controls whether output should be written to file.
#' @param plot Controls whether plots should be generated.
#' @param output Output object.
#' @param verbose Logical. If TRUE, algorithm will print progress to console.
#' @return Returns output object and prints output files if necessary.
#' @keywords internal 
manage_output = function(out = NULL, plot = NULL, output = NULL, verbose = TRUE){

    yvarnames = output[['variablenames']][['y_vars']]
    groupcutoff = output[['function_parameters']][['groupcutoff']]
    subgroupcutoff = output[['function_parameters']][['subgroupcutoff']]
    
    
    if(verbose){print('Writing output to file.', quote = FALSE)}
    
    #### Write out Function Arguments & Variable Names ####
    capture.output(print('Function Arguments', quote = FALSE), 
                   print(output$function_parameters), 
                   print('Variable Names', quote = FALSE), 
                   print(output$variablenames), 
                   file = paste(out, 'function_summary.txt', sep=.Platform$file.sep))
    
    #### Write Group Level Data with Plots if Needed ####
    write.csv(output$group$group_paths_counts[, colnames(output$group$group_paths_counts) %in% yvarnames],
              file = paste(out, 'groupPathCountsMatrix.csv', sep=.Platform$file.sep))
    write.csv(output$group$group_paths_present[, colnames(output$group$group_paths_present) %in% yvarnames],
              file = paste(out, 'groupPathCountsPresent.csv', sep=.Platform$file.sep))
    if (plot) {
      pdf(file.path(out, 'groupMainEffectsPlots.pdf'))
      plot(output[['group']][['main_effects_fig']])
      dev.off()
      if (!is.null(output[['group']][['interaction_fig']])){
        pdf(file.path(out, 'groupInteractionsPlots.pdf'))
        plot(output[['group']][['interaction_fig']])
        dev.off()
      }
    }
    
    #### Write SUbgroup Level Data with Plots if Needed ####
    if(output[['function_parameters']][['subgroup']] && output[['function_parameters']][['heuristic']] == 'GIMME'){
      write.csv(output$subgroup$membership, file = paste(out, 'subgroupAssignments.csv', sep = .Platform$file.sep))
      write.csv(output$subgroup$similarity_matrix, paste(out, 'similarityMatrix.csv', sep = .Platform$file.sep))
      dir.create(paste(out,'subgroup', sep=.Platform$file.sep))
      for (j in 1:output[['subgroup']][['subgroup_number']]){
        write.csv(output[['subgroup']][['subgroup_paths_present']][[j]][, colnames(output$subgroup$subgroup_paths_present[[j]]) %in% yvarnames],
                  file = paste(out, 'subgroup', paste0('subgroup',j,'PathCountsPresent.csv'), sep=.Platform$file.sep))
        if (plot){
          pdf(file.path(out, 'subgroup', paste0('subgroup',j,'MainEffectsPlots.pdf')))
          plot(output[['subgroup']][['main_effects_fig']][[j]])
          dev.off()
          if (!is.null(output[['subgroup']][['interaction_fig']])){
            pdf(file.path(out, 'subgroup', paste0('subgroup',j,'InteractionsPlots.pdf')))
            plot(output[['subgroup']][['interaction_fig']][[j]])
            dev.off()
          }
        }
      }
    }
     
    #### Categorize Path Types ####
    dir.create(paste(out, 'individual', sep=.Platform$file.sep))
    indpaths = data.frame()
    pathtypes = output[['group']][['group_paths_proportions']]
    pathtypes[pathtypes >= groupcutoff] = 'group'
    if (output[['function_parameters']][['subgroup']]){
      for (j in 1:output[['subgroup']][['subgroup_number']]){
        pathtypes[(output$subgroup$subgroup_paths_present[[j]] - output$group$group_paths_present) == 1] = 'subgroup'
      }
    }
    pathtypes[!is.na(pathtypes) & pathtypes > 0 & pathtypes != 'group' & pathtypes != 'subgroup'] = 'individual'
    pathtypes[pathtypes != 'group' & pathtypes != 'subgroup' & pathtypes != 'individual'] = 'none'
    
    #### Write Individual Level Data with Plots if Needed ####
    subnames = names(output[!names(output) %in% c('group','function_parameters','variablenames')])
    if (output[['function_parameters']][['subgroup']]){subnames = subnames[subnames != 'subgroup']}
    for (sub in subnames){
      write.csv(output[[sub]][['regression_matrix']][, colnames(output$group$group_paths_counts) %in% yvarnames],
                file = paste(out, 'individual', paste0(sub,'Betas.csv'), sep=.Platform$file.sep))
      if (plot & length(output[['variablenames']][['y_vars']]) <= 100) {
        pdf(file.path(out, 'individual', paste0(sub,'MainEffectsPlot.pdf')))
        plot(output[[sub]][['main_effects_fig']])
        dev.off()
        if (!is.null(output[[sub]][['interaction_fig']])){
          pdf(file.path(out, 'individual', paste0(sub,'InteractionsPlot.pdf')))
          plot(output[[sub]][['interaction_fig']])
          dev.off()
        }
      }
      ind=cbind(which(output[[sub]][['regression_matrix']] != 0 & !is.na(output[[sub]][['regression_matrix']]), arr.ind = TRUE, useNames = F), 
                output[[sub]][['regression_matrix']][output[[sub]][['regression_matrix']] != 0 & !is.na(output[[sub]][['regression_matrix']])])
      temp = ind
      temp[,1]=rownames(output$group$group_paths_counts)[ind[,1]]
      temp[,2]=rownames(output$group$group_paths_counts)[ind[,2]]
      temp = cbind(sub, temp, rep(0, nrow(temp)))
      for (r in 1:nrow(temp)){ temp[r,5] = pathtypes[temp[r,2], temp[r,3]] }
      colnames(temp) = c('file','iv','dv','beta_estimate','type')
      temp = temp[order(temp[,'type']),]
      indpaths = rbind(indpaths, temp)
    }
    write.csv(indpaths,
              file = paste(out, 'indivPathEstimates.csv', sep=.Platform$file.sep))
  
}
