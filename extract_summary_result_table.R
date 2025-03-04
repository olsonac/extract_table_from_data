library(tidyverse)

rm(list = ls()) # clear global environment

# set which summary to do based on the configuration file
Sys.setenv(R_CONFIG_ACTIVE = "adults_function_summary") # matched and unmatched speed/accuracy X child/adult
#Sys.setenv(R_CONFIG_ACTIVE = "children_function_summary")
#Sys.setenv(R_CONFIG_ACTIVE = "overall_function_summary")
#Sys.setenv(R_CONFIG_ACTIVE = "speed_accuracy_function_summary")

# read the configuration file
config <- config::get(file="./src_table_extract/config_extract_summary.yml")

# read configuration options
root_dir <- config$root_dir

source(paste0(root_dir,"/src_table_extract/extract_summary_functions.R"))

results_directory <- paste0(root_dir,"/",config$results_dir)

file_control_file <- config$file_control_file
line_control_file <- config$line_control_file
column_control_file <- config$column_control_file
file_list_output_file <- config$file_list_output_file

file_control_df <- read.csv(paste0(root_dir,"/",file_control_file))
line_control_df <- read.csv(paste0(root_dir,"/",line_control_file))
column_control_df <- read.csv(paste0(root_dir,"/",column_control_file))

# get list of files
file_list <- get_results_file_list(results_directory,file_control_df)
write.csv(file_list,paste0(root_dir,"/",file_list_output_file),row.names = FALSE)

# set up table df
table_column_names <- unique(column_control_df$table_column_name)
if(any(c("line_name","line_order") %in% table_column_names)){
  print("**ERROR** can't have a column called 'line_name' or 'line_order'")
  exit(-1)
}
table_column_names <- c("line_name","line_order",table_column_names)

# figure out how many lines will be in the final table
# this is based on the number of files / number of files per line
# line_info_df <- line_control_df %>% select("filetype_ID", line_order)
# files_per_line <- nrow(distinct(line_info_df))
# number_of_table_rows <- nrow(file_list)/files_per_line

# add one line at a time to this overall table
table_df <- data.frame(matrix(nrow=1, ncol = length(table_column_names)))

# temporarily hold info for one line here before adding to the overall table
one_table_line <- data.frame(matrix(nrow=1, ncol=length(table_column_names)))
colnames(table_df) <- table_column_names
colnames(one_table_line) <- table_column_names

# get lines from files
# line_counter <- 1
previous_line_order <- 1
previous_file_group <- 1
for(i in seq(1,nrow(file_list))){
  # read a raw datafile from the list
  print(paste0("reading file: ",file_list$file[i]))
  raw_data_df <- read.csv(paste0(results_directory,"/",file_list$file[i]))
  # use the filetype_ID to filter the line_control_df
  current_line_control <- line_control_df[line_control_df$filetype_ID == file_list$filetype_ID[i],]
  if(file_list$file_group[i] != previous_file_group){
    # line_counter <- line_counter + 1
    table_df <- rbind(table_df,one_table_line)
    one_table_line[1,] <- NA
  }
  for(j in seq(1,nrow(current_line_control))){
    print(paste0("j = ",j," current line order: ", 
                 current_line_control$line_order[j], " past line order: ",
                 previous_line_order))      
    if(current_line_control$line_order[j] != previous_line_order){
    # line_counter <- line_counter + 1
      table_df <- rbind(table_df,one_table_line)
      one_table_line[1,] <- NA
    }
    current_line <- raw_data_df[grepl(current_line_control$search_string[[j]],
                                      unlist(raw_data_df[current_line_control$select_column_name[j]])),]
    if(nrow(current_line) > 0){ # found a match
      #table_df$line_name[line_counter] = current_line_control$line_name[j]
      #table_df$line_order[line_counter] = current_line_control$line_order[j]
      one_table_line$line_name[1] = current_line_control$line_name[j]
      one_table_line$line_order[1] = current_line_control$line_order[j]      

      # use the columnID to filter the column_control_df
      current_column_control <- column_control_df[column_control_df$column_ID == current_line_control$column_ID[j],]
      # loop through the columns in the column control to put them in the table df
      for(k in seq(1,nrow(current_column_control))){
 #       table_df[line_counter,current_column_control$table_column_name[k]] <- current_line[current_column_control$data_column[k]][[1]]
        one_table_line[1,current_column_control$table_column_name[k]] <- current_line[current_column_control$data_column[k]][[1]]
      }
      previous_line_order <- current_line_control$line_order[j]      
    }
  }
  previous_file_group <- file_list$file_group[i]
}

table_df <- rbind(table_df,one_table_line) # add line that was constructed on last cycle of loop

table_df <- table_df[-1,] # get rid of blank first line 
table_df <- table_df[order(table_df$line_order),]
column_order_info <- column_control_df[c("table_column_name","column_order")]
column_order_info <- distinct(column_order_info)
order_values <- unlist(column_order_info$column_order)+2 # because of name/order columns at the beginning
column_order <- c(1,2,order_values)
table_df <- table_df[,column_order]
table_df <- table_df[,colnames(table_df) != "line_order"]
write.csv(table_df, paste0(root_dir,"/",config$output_file), row.names = FALSE)