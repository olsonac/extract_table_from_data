library(tidyverse)

rm(list = ls()) # clear global environment

# set config file
Sys.setenv(R_CONFIG_ACTIVE = "speed_accuracy_function_summary") # matched and unmatched speed/accuracy X child/adult
config <- config::get(file="./src_table_extract/config_extract_summary.yml")

# read configuration options
root_dir <- config$root_dir

source(paste0(root_dir,"/src_table_extract/extract_summary_functions.R"))

results_directory <- paste0(root_dir,"/",config$results_dir)

file_control_file <- config$file_control_file
line_control_file <- config$line_control_file
column_control_file <- config$column_control_file

file_control_df <- read.csv(paste0(root_dir,"/",file_control_file))
line_control_df <- read.csv(paste0(root_dir,"/",line_control_file))
column_control_df <- read.csv(paste0(root_dir,"/",column_control_file))

# get list of files
SA_file_list <- get_results_file_list(results_directory,file_control_df) 

# set up table df
table_column_names <- unique(column_control_df$table_column_name)
if(any(c("line_name","line_order") %in% table_column_names)){
  print("**ERROR** can't have a column called 'line_name' or 'line_order'")
  exit(-1)
}
table_column_names <- c("line_name","line_order",table_column_names)
table_df <- data.frame(matrix(nrow=nrow(line_control_df), ncol = length(table_column_names)))
colnames(table_df) <- table_column_names

# get lines from files
line_counter <- 1
for(i in seq(1,nrow(SA_file_list))){
  # read a raw datafile from the list
  raw_data_df <- read.csv(paste0(results_directory,"/",SA_file_list$file[i]))
  # use the filetype_ID to filter the line_control_df
  current_line_control <- line_control_df[line_control_df$filetype_ID == SA_file_list$filetype_ID[i],]
  for(j in seq(1,nrow(current_line_control))){
    table_df$line_name[line_counter] = current_line_control$line_name[j]
    table_df$line_order[line_counter] = current_line_control$line_order[j]
    current_line <- raw_data_df[grepl(current_line_control$search_string[[j]],
                                 unlist(raw_data_df[current_line_control$select_column_name[j]])),]
#    current_line <- raw_data_df[raw_data_df[current_line_control$select_column_name[j]] ==
#                                current_line_control$search_string[j],]
    # use the columnID to filter the column_control_df
    current_column_control <- column_control_df[column_control_df$column_ID == current_line_control$column_ID[j],]
    # loop through the columns in the column control to put them in the table df
    for(k in seq(1,nrow(current_column_control))){
      table_df[line_counter,current_column_control$table_column_name[k]] <- current_line[current_column_control$data_column[k]][[1]]
    }
    line_counter <- line_counter + 1
  }
}

table_df <- table_df[order(table_df$line_order),]
column_order_info <- column_control_df[c("table_column_name","column_order")]
column_order_info <- distinct(column_order_info)
order_values <- unlist(column_order_info$column_order)+2 # because of name/order columns at the beginning
column_order <- c(1,2,order_values)
table_df <- table_df[,column_order]
table_df <- table_df[,colnames(table_df) != "line_order"]
write.csv(table_df, paste0(root_dir,"/",config$output_file))




