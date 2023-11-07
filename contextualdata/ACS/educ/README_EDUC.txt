README.txt for main ACS build folders

Author: Patricia Ferido

Last Update: 2019, August 6

Purpose:
	These programs read in and clean education data from ACS. Specifically, from
	Table S1501. These programs should be updated annually with every new release
	of the ACS.
	
Source: https://factfinder.census.gov/faces/nav/jsf/pages/index.xhtml

File structure:
	1) Macros
		 - Macros are general programs, some with specific year ranges if 
		   variables have changed from update to update
	2) Programs run the macros for specific years
		 - Programs are numbered in run order. 
		 	1 - First is to read in
		 	2 - second to clean and stack
	
Steps for Updating:
	1) Download new annual table S1501 from ACS and put in raw_data folder, following
		 same folder structure
	2) Compare metadata in downloaded file to contents of previously 
		 created files to make sure that you'll be using the correct macros
	3) Choose the read_in macro with the year range that matches the variables in your data
	4) Create a new program for the read in (named 1+next letter in sequence)
		 to run the macro for that year, filling in the variables listed in the header
	5) Create a new program for the clean program (named 2+next letter in sequence) 
		 to run the clean macro, filling in the variables listed in the header
	
	