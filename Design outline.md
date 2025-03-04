For extracting tables from raw data there are 3 steps.
1) Get a list of files that have the data to extract
2) Get a list of lines to extract from each file
3) Get a list of columns to extract from each line
A combination of file/line/columns produces one line of a summary table

To accomplish this, we need 3 specifications in .csv files
1) A set of search specifications for files, each associated with a filetype ID.  Each line has:
	- A regular expression (list.files() pattern) search string
	- A filetypeID (used when we extract lines at the next step)
		- The filetypeID is needed because different file types can need to extract lines in different ways and the filetypeID is used in the next line extraction step to extract lines in different ways from different types of files.
	- group_line_results TRUE means all results from a line of the control file are grouped together (all files from line 1 followed by all files from line 2 etc.).  FALSE means that the files from the lines are interspersed/interwoven (file 1 from line 1, file 1 from line 2 then file 2 from line 1, file 2 from line 2 etc...)
		
2) A set of search specifications for columns associated with filetypeIDs from above and setting columnIDs for below.  Each line has:
	- A filetypeID used to select only the lines that apply to this filetype according to the filetypeID set in 1)
	- A list of comma separated column names to use in the search expression
	- A search expression based on the column names above
	- A line name that identifies groups of lines
	- A line order value (to order the lines in the table)
	- A columnID value
	A filetypeID identifies which file line information comes from.  Each line in the line control file identifies a single **type** of line and associates this with a set of columns will be extracted from that type of line.
	The line name can be repeated.  Where it is repeated, values from different line types are concatenated onto the same line in the table.
	If the line name is repeated the line order value should be the same (i.e. only one line order value per line name).
	The columnID value says which columns should be extracted from each line.  Where the line name value is repeated, the columnID values would normally be different (e.g. extract columns 1, 2, 3 from the line with N information and columns 2, 5, 7 from the line with stat information -- put these six columns with N and statistical information on a single line of the summary table)
	
3) A set of column names associated with different columnID (from above).  ColumnID values group the column specifications for one type of line (from above). Each column to be extracted is on a separate line.  The full set of lines that specify columns describes a single line of the table.  One line of a table may come from more than one type of line (and so put together different column IDs).  Each line of this file should have:
	- A columnID value.  This can be repeated to extract different columns from the same line type.
	- A column name that identifies the column in the raw data
	- A column name for the summary table
	- A column order that orders the columns in the table

Example:  Raw datafiles have information from different age groups: children and adults.  There is a third type of datafile that has information about the interaction between ages.


| group       | effect size | z-value | p-value | N   | AIC   | p-value |
| ----------- | ----------- | ------- | ------- | --- | ----- | ------- |
| Children    | x.xxx       | y.yyy   | .00z    | xxx |       |         |
| Adults      | x.xxx       | y.yyy   | .00z    | yyy |       |         |
| Interaction |             |         |         |     | a.aaa | .00b    |

File extract control file

| search_string           | filetype_ID | group_line_results |
| ----------------------- | ----------- | ------------------ |
| `.*_Children_.*`        | Children    | FALSE              |
| `.*_Adults_.*`          | Adults      | FALSE              |
| `.*_Children_Adults_.*` | Interaction | FALSE              |
Line extract control file

| filetype_ID | select_column_names | search_string                             | line_name   | line_order | column_ID   |
| ----------- | ------------------- | ----------------------------------------- | ----------- | ---------- | ----------- |
| Children    | group,linetype      | group == "Children" & linetype == "stats" | Children    | 1          | ChildStats  |
| Children    | group, linetype     | group == "Children" & linetype == "N"     | Children    | 1          | ChildN      |
| Adults      | group,linetype      | group == "Adults" & linetype == "stats"   | Adults      | 2          | AdultStats  |
| Adults      | group, linetype     | group == "Adults" & linetype == "N"       | Adults      | 2          | AdultN      |
| Interaction | group               | group == "Interaction"                    | Interaction | 3          | Interaction |
Column extract control file

| columnID    | data_column | table_column_name | column_order |
| ----------- | ----------- | ----------------- | ------------ |
| ChildStats  | ES          | effect size       | 1            |
| ChildStats  | z_value     | z value           | 2            |
| ChildStats  | p_value     | p-value           | 3            |
| ChildN      | PKU_N       | N                 | 4            |
| AdultStats  | ES          | effect size       | 1            |
| AdultStats  | z_value     | z value           | 2            |
| AdultStats  | p_value     | p-value           | 3            |
| AdultN      | PKU_N       | N                 | 4            |
| Interaction | delta_AIC   | AIC difference    | 5            |
| Interaction | AIC_p_value | AIC p-value       | 6            |
