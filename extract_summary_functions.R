
does_not_contain <-function(search_string,input_string){ # not used
  full_search_string <- paste0("[.]*",search_string,"[.]*")
  logical_result <- !grepl(full_search_string,input_string)
  return(logical_result)
}

does_contain <-function(search_string,input_string){ # not used
  full_search_string <- paste0("[.]*",search_string,"[.]*")
  logical_result <- grepl(full_search_string,input_string)
  return(logical_result)
}

# add extracted summary from one file to cumulative summary
# need to pass an appropriate extraction function (e.g. for overall or child_adult)
extract_results_summary<-function(cumulative_results, # data frame to append results to
                                  file_to_extract_from,
                                  results_cols_to_extract,
                                  extract_function # either overall or child_adult
){
  if(file.exists(file_to_extract_from)){
    print(paste0("Extracting from file: ",file_to_extract_from))
    one_result_file_df <- read.csv(file_to_extract_from)
    one_result_cols_df <- one_result_file_df %>% select(all_of(results_cols_to_extract))
    one_result_summary <- extract_function(one_result_cols_df)
  }else{
    print(paste("**ERROR** file: ",file_to_extract_from," not found."))
    quit(-1)
  }
  cumulative_results <- rbind(cumulative_results,one_result_summary)
  return(cumulative_results)
}

# extract results from overall result files
make_result_table<-function(results_directory,
                            search_pattern,
                            search_name,
                            result_cols_to_extract,
                            extract_function      
){
  #  result_file_search_pattern = "ResultSummary\\_[^.]*\\.csv"
  result_file_list <- list.files(results_directory, pattern=search_pattern)
  
  cumulative_results <- data.frame()
  for(current_file in result_file_list){
    print(paste0("extracting ",current_file))
    # extract overall data
    file_to_extract_from <- paste0(results_directory,"/",current_file)
    cumulative_results<-extract_results_summary(
      cumulative_results,
      file_to_extract_from,
      results_cols_to_extract,
      extract_function)
  }
  write.csv(cumulative_results,paste0(results_directory,"/cumulative_table_",search_name,".csv"))
}

extract_N_data<-function(results_df){
  
  age_group <- results_df$age_group
  wt_mean_phe <- results_df$wt_mean_phe_mean
  N_groups <- results_df$N_groups
  N_measures <- results_df$N_measures
  PKU_N <- results_df$PKU_N
  control_N <- results_df$control_N
  
  task <- rep(results_df$Group[1],length(wt_mean_phe))
  
  return_df <- data.frame(task = task,
                          age_group = age_group,
                          wt_mean_phe = wt_mean_phe,
                          N_groups = N_groups,
                          N_measures = N_measures,
                          PKU_N = PKU_N,
                          control_N = control_N)
  return(return_df)
}

# for testing
# directory_to_search <- results_directory
# current_file_search_string <- file_search_string[1]
# prefix <- result_prefix
# suffix <- adult_suffix
# suffix <- "_C.*_Adults_with_outliers.csv"
# current_file_search_string <- gsub(" ","_",current_file_search_string)
# current_file_search_string <- gsub("/","-",current_file_search_string)
# current_file_search_string <- paste0(prefix,current_file_search_string,suffix)
# current_file_search_string
# 
# current_file_search_string2 <- "ResultSummary_EF-Flexibility.*"
# list.files(directory_to_search,current_file_search_string2)
# 
# current_file_search_string <- "ResultSummary_EF-Flexibility.*_Adults_with_outliers\\.csv$"
# list.files(directory_to_search,current_file_search_string)

# testing
# directory_to_search <- results_directory

removeQuotes <- function(x) gsub("\"", "", x)

get_results_file_list <- function(directory_to_search,file_control_df){
  # extract_file_information is a data frame (usually from a .csv file)
  # that lists the search information used to create a list of files
  # prefixes and suffixes are used to restrict files to particular types 
  # (e.g. just N_summary, just with_outliers)
  all_file_list <- c()
  file_IDs <- c()
  for(i in seq(1,nrow(file_control_df))){
    file_group <- list.files(directory_to_search, pattern=file_control_df$search_string[i])
    all_file_list <- c(all_file_list, file_group)
    file_IDs<-c(file_IDs,rep(file_control_df$filetype_ID[i],length(file_group)))
  }
  file_list_df <- data.frame(file = all_file_list,filetype_ID=file_IDs)
  return(file_list_df)
}

# for testing
# line_identifiers <- adult_lines_to_extract$search_string
# search_column <- adult_lines_to_extract$column_to_search
# file_list <- adult_results_file_list

get_summary_lines <- function(line_identifiers, search_column, results_directory, file_list){
  lines_to_save = NULL
  line_identifiers <- as.tibble(line_identifiers)
  search_column <- as.tibble(search_column)
  for(current_file in file_list){
    current_df <- read_csv(paste0(results_directory,"/",current_file),show_col_types = FALSE)
    for(i in seq(1,nrow(line_identifiers))){
      current_identifier <- line_identifiers[[1]][i]
      current_search_column <- search_column[[1]][i]
      current_lines_to_save <- current_df[grepl(current_identifier,
                                                current_df[[current_search_column]],perl=TRUE),]
      lines_to_save <- rbind(lines_to_save,current_lines_to_save)
    }
  }
  return(lines_to_save)
}

# testing
# summary_lines <- adult_summary_lines
# table_columns <- results_table_columns
# i<-1
#summary_lines <- ES_summary_lines
#table_columns <- results_table_columns

get_table <- function(summary_lines,table_columns){
  for(i in seq(1,nrow(table_columns))){
    current_summary_lines <- summary_lines[grepl(table_columns$select_string[i],
                                                 summary_lines[[table_columns$select_column[i]]]),]
    current_column <- current_summary_lines %>% select(table_columns$column[i])
    current_col_name <- gsub("\\^","",table_columns$select_string[i])
    current_col_name <- gsub("\\$","",current_col_name)    
    names(current_column) <- paste0(current_col_name,"-",names(current_column))
    current_join_key <- current_summary_lines %>% select(table_columns$name_column[i])
    current_df <- tibble(current_join_key, current_column)
    if(i == 1){
      block_df <- current_df
    }else{
      block_df <- full_join(block_df, current_df, by=table_columns$name_column[i])
    }
  }
  return(block_df)
}

convert_mod_coef_to_phe_200<- function(mod_coef){
  mod_coef[is.na(mod_coef)] <- "NA;NA"
  n_phe_values <- length(mod_coef)
  phe_coef <- matrix(unlist(strsplit(mod_coef,";")),ncol=2,byrow=TRUE)[,2]
  phe_coef <- as.double(phe_coef)
  change_per_200_phe <- phe_coef * 200
  return(change_per_200_phe)
}