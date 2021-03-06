#' @name multiREG
#' @aliases multiREG
#' @title Network Model Search using Regularization
#' @description This function utilizes regression with regularization to build models for individuals 
#' consisting of individual and group-level paths.
#' @usage 
#' multiREG(data                       = NULL,
#'          out                        = NULL,
#'          sep                        = NULL,
#'          header                     = TRUE,
#'          ar                         = TRUE,
#'          plot                       = TRUE,
#'          conv_vars                  = NULL,
#'          conv_length                = 16,
#'          conv_interval              = 1,
#'          standardize                = FALSE,
#'          groupcutoff                = .75,
#'          alpha                      = .5,
#'          model_crit                 = 'bic',
#'          penalties                  = NULL,
#'          test_penalties             = FALSE,
#'          exogenous                  = NULL,
#'          lag_exogenous              = FALSE,
#'          interactions               = NULL,
#'          subgroup                   = FALSE,
#'          subgroupcutoff             = .5,
#'          sub_method                 = 'Walktrap',
#'          sub_feature                = 'count',
#'          confirm_subgroup           = NULL,
#'          heuristic                  = 'GIMME',
#'          verbose                    = TRUE)
#'             
#' @param data The path to the directory where individual data files are located,
#' or the name of the list containing individual data. Each file or matrix within the list
#' must contain a single matrix containing the a T (time) by p (number of variables) matrix,
#' where the rows represent time and columns represent individual variables. Individuals may
#' have different numbers of observations (T), but must have the same number of variables (p).
#' 
#' @param out (Optional) The path to directory where results will be stored. If specified,
#' a copy of output data will be saved into the directory. If the specified directory does
#' not exist, it will be created.
#' 
#' @param sep Spacing scheme for input files. 
#' '' indicates space-separated; ',' indicates comma separated; '/t' indicates tab-separated
#' Only necessary when reading in files from physical directory.
#' 
#' @param header (Logical) Indicate TRUE if variable names included in input file, FALSE otherwise.
#' Only necessary when reading in files from physical directory.
#' 
#' @param ar (Logical) If TRUE, begin model search with all autoregressive pathways estimated
#' with no shrinkage (i.e., penalty = 0).
#' 
#' @param plot (Logical) IF TRUE, will create pdf plots of network maps during output.
#' 
#' @param conv_vars Vector of variable names to be convolved via smoothed Finite Impulse 
#' Response (sFIR). Note, conv_vars are not not automatically considered exogenous variables.
#' To treat conv_vars as exogenous use the exogenous argument. Variables listed in conv_vars 
#' must be binary variables. If there is missing data in the endogenous variables their values 
#' will be imputed for the convolution operation only. Defaults to NULL. ### If there are multiple 
#' variables listed in conv_vars they are not used in the convolution of additional conv_vars.## 
#' Lagged variables cannot be convolved.
#' 
#' @param conv_length Expected response length in seconds. For functional magnetic resonance imagine (fMRI)
#' blood-oxygenation-level-dependent (BOLD) response, 16 seconds (default) is typical
#' for the hemodynamic response function. 
#' 
#' @param conv_interval Interval between data acquisition. Currently must be a constant. For 
#' fMRI studies, this is the repetition time. Defaults to 1.
#' 
#' @param standardize Logical. If TRUE, all variables will be standardized to have a mean of zero and a
#' standard deviation of one. Defaults to FALSE.
#' 
#' @param groupcutoff Cutoff value for inclusion of a given path at the group-level.
#' For instance, group_cutoff = .75 indicates that a path needs to be estimated for 75% of
#' individuals to be included as a group-level path.
#' 
#' @param alpha Elastic-net parameter for the regularization approach. Values close to 0 mimic 
#' the ridge penalty, which tends to shrink correlated parameters towards one another. Values 
#' close to 1 mimic the lasso penalty, which tends to select one parameter and shrink
#' the others. The default value (alpha=.5) balances these two considerations, and tends to select
#' groups of correlated parameters and shrink other groups towards zero.
#' 
#' @param model_crit Argument to indicate the model selection criterion to use for model selection.
#' Defaults to 'bic' (select on BIC). Options: 'bic', 'aic', 'aicc', 'hqc', 'cv' (cross-validation).
#' BIC = Bayesian information criterion, AIC = Akaike information criterion, 
#' aicc = Akaike information criterion for small samples, hqc = Hannan-Quinn information criterion
#' 
#' @param penalties (Optional) A matrix of user-provided penalties to initialize group-model search. 
#' Should contain a column for all variables (including lagged versions and interactions) that will 
#' be included in the model search. Values of 1 (the default) will initialize a variable to be 
#' normally considered in the regularization, values of 0 will initialize a variable to be estimated
#' (i.e., no shrinkage), and values of Inf will exclude variables from the model.
#' 
#' @param test_penalties (Optional, Logical) Optional argument to output a sample penalty matrix
#' based on function parameters. Helpful for specifying a matrix to use in the penalties argument.
#' Function will exit gracefully before running anything if test_penalties = TRUE.
#' 
#' @param exogenous (Optional) A list of user-specified variables to consider as exogenous
#' (e.g., cannot be predicted) in the model search procedure. If variable names are supplied,
#' variables should be referred to by name. If not, then variables should be referenced by
#' the pattern 'V#', where # represents the column number in the original data file (e.g., 'V5').
#' 
#' @param lag_exogenous (Optional, Logical) If TRUE, a lagged version of the exogenous variable 
#' will be created. If set to TRUE, but exogenous variables are not indicated in the argument
#' above, the function will not run properly.
#'
#' @param interactions (Optional) A list of user-specified interaction variables to be created automatically
#' by the algorithm. Individual interactions can be specified as: c('V1\*V2', 'V3\*V5Lag', 'V2\*V4Lag\*V5).
#' WARNING: If specifying an N-way interaction where N>2, make sure to specify the (N>x>1)-way interactions.
#' These lower-order interactions will NOT be created automatically. Variables are automatically centered 
#' before creating interaction.
#' 
#' For convenience, several shortcuts have been provided.
#' Including 'all' in the list will create all possible 2-way interactions (including V^2 polynomials).
#' Including 'all_cross' in the list will create all possible 2-way interactions between variables (excluding V^2 polynomials).
#' Including 'all_exogenous' will create all 2-way interactions between exogenous variables (excluding V^2 polynomials).
#' Including 'all_endogenous' will create all 2-way interactions between endogenous variables (excluding V^2 polynomials).
#' Including 'all_endog_by_exog' will create all 2-way interactions between pairs of endogenous and exogenous variables.
#' Duplicated interactions are removed automatically, but caution when using shortcuts is encouraged.
#' 
#' Shortcuts and specific interactions can be specified at the same time: c('all_endog_by_exog', 'V3\*V4Lag'). However, including 
#' the options 'all' or 'all_cross' will cause other user-specified interactions to be ignored.
#' 
#' @param subgroup Logical. If TRUE, subgroups are generated based on
#' similarities in model features using the \code{walktrap.community}
#' function from the \code{igraph} package. When ms_allow=TRUE, subgroup
#' should be set to FALSE.  Defaults to FALSE.
#' 
#' @param subgroupcutoff Cutoff value for inclusion of a given path at the subgroup-level.
#' For instance, subgroup_cutoff = .5 indicates that a path needs to be estimated for 50% of
#' individuals within the subgroup to be included as a subgroup-level path.
#' 
#' @param sub_method Community detection method used to cluster individuals into subgroups. Options align 
#' with those available in the igraph package: "Walktrap" (default), "Infomap", "Louvain", "Edge Betweenness", 
#' "Label Prop", "Fast Greedy", "Leading Eigen", and "Spinglass". 
#' 
#' @param sub_feature Features used to generate similarity matrix for subgrouping individuals if subgroup 
#' option invoked. "count" uses the counts of similar paths (default); "PCA" (principal components analysis) reduces the data to those components 
#' that explain at least 95 percent of variance and correlates these for each pair of individuals; "correlation" correlates all paths 
#' for each given pair of individuals to arrive at elements in the N-individual by N-individual similarity matrix.
#' 
#' @param confirm_subgroup Option to specify a priori the subgroup membership. If not NULL, the user should provide a data frame with the first 
#' column a string vector of subject names and the second column a vector subgroup assignments. 
#' 
#' @param heuristic Approach for building individual network maps. The default ('GIMME' or the Group Iterative Multiple Model Estimation approach) 
#' proceeds using group- and individual information. For more information on the GIMME heuristic, see Gates & Molenaar, 2012 NeuroImage. The 'individual' 
#' option causes the algorithm to ignore group-level information and estimate individuals independently. The 'group' option aggregates across individuals 
#' by concatenating all timeseries data; note that no individual-level results will be generated in this case and subgroup search will be disabled.
#' 
#' @param verbose Logical. If TRUE, algorithm will print progress to console.
#' 
#' @examples output = multiREG(data=examplesim, exogenous='V5', plot=FALSE)
#' 
#' @import utils grDevices gimme igraph imputeTS
#' @importFrom stats ts na.omit cor prcomp
#' @importFrom dplyr between
#' 
#' @return Object containing individual regression matrices as well as plots if desired.
#' @author Ethan M. McCormick and Kathleen M. Gates
#' @keywords multiREG
#' @export multiREG

multiREG = function(data                       = NULL,
                    out                        = NULL,
                    sep                        = NULL,
                    header                     = TRUE,
                    ar                         = TRUE,
                    plot                       = TRUE,
                    conv_vars                  = NULL,
                    conv_length                = 16,
                    conv_interval              = 1,
                    standardize                = FALSE,
                    groupcutoff                = .75,
                    alpha                      = .5,
                    model_crit                 = 'bic',
                    penalties                  = NULL,
                    test_penalties             = FALSE,
                    exogenous                  = NULL,
                    lag_exogenous              = FALSE,
                    interactions               = NULL,
                    subgroup                   = FALSE,
                    subgroupcutoff             = .5,
                    sub_method                 = 'Walktrap',
                    sub_feature                = 'count',
                    confirm_subgroup           = NULL,
                    heuristic                  = 'GIMME',
                    verbose                    = TRUE){

  #### Create Output Directory if Needed ####
  if (!is.null(out)){
    if (!dir.exists(out)){
      if(verbose){print('Creating output directories', quote = FALSE)}
      dir.create(out)
      }
  }
  
  #### Add Function Parameters to Output ####
  output = list()
  output[['function_parameters']] = as.list(sys.frame(which = 1))
  
  #### Adjust Group Threshold if Heuristic == Individual ####
  if (heuristic == 'individual') {output$function_parameters$groupcutoff = 1.1}
  
  #### Wrangle Data into List ####
  if(verbose){print('Reading in data.', quote = FALSE)}
  if (!is.list(data)){
    subdata = list()
    for (i in list.files(data, full.names = TRUE)){
      tempname = basename(tools::file_path_sans_ext(i))
      if(verbose){print(paste0('   Reading in ', tempname, '.'), quote = FALSE)}
      subdata[[tempname]] = read.delim(i, sep=sep, header=header)
    } 
  } else if (is.list(data)){
      subdata = data
  }
  
  #### Generate Variable Names as Needed ####
  varnames = colnames(subdata[[1]])
  if(is.null(varnames)){
    varnames = c(paste0('V', seq(1, length(subdata[[1]][1,]))))
    subdata = lapply(subdata, function(x){ colnames(x) = varnames; x })
  }

  #### Convolve if indicated. ####
  if(!is.null(conv_vars)){
    varLabels <- list(
      conv = conv_vars, # variables to be convolved
      exog = exogenous, # user-specified exogenous variables
      coln = varnames   # all variable names
    )
    
    subdata <- setupConvolve(
      ts_list       = subdata, 
      varLabels     = varLabels, 
      conv_length   = conv_length, 
      conv_interval = conv_interval
    )
    if(!standardize){warning('Recommended standarizing all variables if convolving, but standardize = FALSE. The algorithm will still run, but results may be impacted')}
  }
  
  #### Standardize each variable if requested ####
  if(standardize){subdata = lapply(subdata, function(x){scale(x, center=TRUE, scale=TRUE)[,]})}
  
  #### Categorize Variables. & Omit NaN Rows ####
  for (i in 1:length(subdata)){
    yvar = subdata[[i]][, !colnames(subdata[[i]]) %in% exogenous, drop=FALSE]
    yvarnames = colnames(yvar)
    lagvar = rbind(rep(NA, ncol(yvar)), yvar[1:(nrow(yvar)-1),])
    colnames(lagvar) = paste(colnames(lagvar), 'Lag', sep='')
    exogvar = subdata[[i]][, colnames(subdata[[i]]) %in% exogenous, drop=FALSE]
    exognames = colnames(exogvar)
    if (lag_exogenous){
      lagexogvar = rbind(rep(NA, ncol(exogvar)), exogvar[1:(nrow(exogvar)-1), , drop=FALSE])
      colnames(lagexogvar) = paste(colnames(exogvar), 'Lag', sep='')
      exognames = c(exognames, colnames(lagexogvar))
      subdata[[i]] = create_interactions(endog = cbind(yvar, lagvar), exog = cbind(exogvar, lagexogvar), interactions = interactions)
    } else {
      subdata[[i]] = create_interactions(endog = cbind(yvar, lagvar), exog = exogvar, interactions = interactions)
    }
    subdata[[i]] = na.omit(subdata[[i]])
    interactnames = colnames(subdata[[i]])[grepl('_by_', colnames(subdata[[i]]))]
  }
  
  if(verbose){print('Data successfully read in.', quote = FALSE)}
  output[['variablenames']][['y_vars']] = yvarnames
  output[['variablenames']][['exogenous_vars']] = exognames
  output[['variablenames']][['interaction_vars']] = interactnames
  
  #### Check for Data Variability ####
  variability = check_variability(data = subdata)
  if (variability[['flag']]){
    if(verbose){print('Zero-variability variable detected, see output object for details.', quote=FALSE)}
    return(variability)
  }
  
  #### Calculate Data Thresholds ####
  nsubs = length(subdata)
  numvars = ncol(subdata[[1]])
  if (is.null(penalties)){
    initial_penalties = array(data = rep(1, numvars*numvars), 
                              dim = c(numvars, numvars),
                              dimnames = list(c(colnames(subdata[[1]])),
                                              c(colnames(subdata[[1]]))))
  } else {
    initial_penalties = penalties
    colnames(initial_penalties) = colnames(subdata[[1]])
    rownames(initial_penalties) = colnames(subdata[[1]])
  }
  diag(initial_penalties) = NA
  
  #### Free AR Paths if Desired ####
  for (varname in yvarnames){
    if (ar == TRUE){
      initial_penalties[paste0(varname,'Lag'), varname] = 0 
    }
  }
  
  #### Return Sample Penalty Matrix and Exit if Needed ####
  if (test_penalties == TRUE){
    return(initial_penalties)
    if(verbose){print('Returning sample penatly matrix and exiting.', quote=FALSE)}
  }
  
  #### Concatenate Subdata for Group-Search Only ####
  if (heuristic == 'group'){
    if(verbose){print('Aggregating data across subjects.', quote = FALSE)}
    aggsub = array()
    for (i in 1:length(subdata)){
      aggsub = rbind(aggsub, subdata[[i]])
    }
    subdata = list()
    subdata[[1]] = aggsub[2:nrow(aggsub), ]
    names(subdata)[1] = 'aggsub'
    nsubs = length(subdata)
    subgroup = output$function_parameters$subgroup = FALSE
  }
  
  #### Group level search ####
  if (heuristic == 'GIMME'){
    grppaths = group_search(subdata,
                            groupcutoff,
                            yvarnames,
                            interactnames,
                            output,
                            grppen = NULL,
                            initial_penalties,
                            verbose)
    
  } else {
    grppaths = list()
    grppaths = list('output' = output,
                    'group_thresh_mat' = array(data = rep(0, numvars*numvars), 
                                               dim = c(numvars, numvars),
                                               dimnames = list(c(colnames(subdata[[1]])),
                                                               c(colnames(subdata[[1]])))),
                    'group_penalties' = array(data = rep(1, numvars*numvars), 
                                              dim = c(numvars, numvars),
                                              dimnames = list(c(colnames(subdata[[1]])),
                                                              c(colnames(subdata[[1]])))))
  }
  
  #### Loop Through Subjects Again with the Group Level Information ####
  finalpaths = ind_search(subdata,
                          yvarnames,
                          interactnames,
                          grppen = grppaths$group_penalties,
                          output,
                          verbose)
  
  #### Optional search for subgroups using results from above. ####
  if(subgroup && heuristic != 'group'){
    subgroup_results = subgroup_search(subdata, 
                                       indpaths = finalpaths, 
                                       output,
                                       verbose)
    if(length(subdata)>subgroup_results$n_subgroups && subgroup_results$n_subgroups>1 && heuristic == 'GIMME'){
      subgrouppaths = list()
      indpaths_sub  = list()
      for (j in 1:subgroup_results$n_subgroups){
        if(verbose){print(paste0('Starting model-building for subgroup',j,'.'), quote = FALSE)}
        sub_s_subjids = subset(subgroup_results$sub_mem$names,
                               subgroup_results$sub_mem$sub_membership == j)
        subgroupdata = subdata[sub_s_subjids]
        
        subgrouppaths[[j]] = group_search(subdata = subgroupdata,
                                          subgroupcutoff,
                                          yvarnames,
                                          interactnames,
                                          output, 
                                          grppen = grppaths$group_penalties,
                                          verbose = verbose)
        
        indpaths_sub[[j]] = ind_search(subdata = subgroupdata,
                                       yvarnames,
                                       interactnames,
                                       grppen = subgrouppaths[[j]]$group_penalties,
                                       output,
                                       verbose)  
        # combine subgroup-specific resuts into final estimates
        for (sub in names(subgroupdata)){
          finalpaths[,,sub] = indpaths_sub[[j]][,,sub]
        }
      }
    }
  }

  
  #### Organize Output ####
  binfinalpaths = finalpaths
  binfinalpaths[which(abs(binfinalpaths)>0)] = 1
  countmatrix = matrix(0,length(binfinalpaths[,1,1]), length(binfinalpaths[1,,1]))
  for (p in 1:nsubs){
    countmatrix = countmatrix + binfinalpaths[,,p]
  }
  
  if (heuristic == 'group'){
    output[['group']][['group_paths_present']] = binfinalpaths[ , ,1]
  } else {
    grppaths$group_thresh_mat[is.na(grppaths$group_thresh_mat)] = 0
    output[['group']][['group_paths_present']] = grppaths$group_thresh_mat
  }
  output[['group']][['group_paths_counts']] = countmatrix
  output[['group']][['group_paths_proportions']] = countmatrix/nsubs
  output[['group']][['group_penalties']] = grppaths$group_penalties
  
  if(subgroup){if(length(subdata)>subgroup_results$n_subgroups && subgroup_results$n_subgroups>1){
    output[['subgroup']][['membership']] = subgroup_results$sub_mem
    output[['subgroup']][['modularity']] = subgroup_results$modularity
    output[['subgroup']][['subgroup_number']] = subgroup_results$n_subgroups
    output[['subgroup']][['similarity_matrix']] = subgroup_results$sim
    output[['subgroup']][['subgroup_method']] = sub_method
    output[['subgroup']][['subgroup_feature']] = sub_feature
    if (heuristic == 'GIMME'){ for (j in 1:subgroup_results$n_subgroups){
      subgrouppaths[[j]]$group_thresh_mat[is.na(subgrouppaths[[j]]$group_thresh_mat)] = 0
      output[['subgroup']][['subgroup_paths_present']][[j]] = subgrouppaths[[j]]$group_thresh_mat
      output[['subgroup']][['subgroup_penalties']][[j]] = subgrouppaths[[j]]$group_penalties
      selectPeople = output$subgroup$membership[which(output$subgroup$membership[,2]==j),]
      subcountmatrix = matrix(0,length(binfinalpaths[,1,1]), length(binfinalpaths[1,,1]))
      for (p in 1:length(selectPeople[,1])){
        subcountmatrix = subcountmatrix + binfinalpaths[,,as.numeric(rownames(selectPeople)[p])]
      }
      output[['subgroup']][['subgroup_paths_counts']][[j]] = subcountmatrix
      output[['subgroup']][['subgroup_paths_proportions']][[j]] = subcountmatrix/length(selectPeople[,1])
    }} 
  }}
  for (sub in names(subdata)){
    output[[sub]][['data']] = subdata[[sub]]
    output[[sub]][['regression_matrix']] = finalpaths[, , sub]
  }
  
  #### Add Visualization ####
  if (plot){
    output = network_vis(output, finalpaths, verbose)
  }
  
  #### Save Output to Files ####
  if (!is.null(out)){
    manage_output(out = out, plot = plot, output = output, verbose)
  }
  
  #### End Algorithm ####
  if(verbose){print('Algorithm successfully completed.', quote = FALSE)}
  return(output)
}
