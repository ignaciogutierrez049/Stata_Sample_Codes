
*** World Bank Stata Sample Code ***

** This sample code analyzes a randomized control trial performed in India to increase voter turnout, with an emphasis on female participation, for a 2010 election in India. The RCT was conducted in 27 towns, with roughly half of the polling booths in each town randomly selected for treatment. The outcomes of interest were total turnout (the number of votes cast at each polling booth) and female turnout (the number of votes cast by women at each polling booth). Data was also collected on the number of registered voters at each polling booth, disaggregated by gender, but for some polling booths this data could not be obtained, so data entry operations entered "-999" whenever they were missing data.


* Section 1: Data Cleaning 
	
	* Import data and flag missing data
	cd "/Users/ignaciogutierrez/Desktop/World Bank Assessment"
	
	clear all
	import excel "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Instructions/Source data.xlsx", sheet("Sheet1") firstrow
	
	list registered if registered == -999
	list registered if registered == -998

	
	* Replace missing ("-999/-998") values with 0 
	foreach value in registered{
		replace registered = 0 if registered == -999
	}
	
	foreach value in registered{
		replace registered = 0 if registered == -998
	}
	
	
	* Reshape data wide
	reshape wide turnout registered, i(observation_id) j(group) string 
	
	rename turnouttotal turnout_total
	rename registeredtotal registered_total
	
	rename turnoutmale turnout_male
	rename turnoutfemale turnout_female
	
	rename registeredmale registered_male
	rename registeredfemale registered_female	
	
	order observation_id town_id turnout_total turnout_male turnout_female registered_total registered_male registered_female treatment
	drop observation_id
		
		
	* Verify that total turnout/registered values equal the same values disaggregated by gender
	assert (registered_total == registered_male + registered_female)
	assert (turnout_total == turnout_female + turnout_male)

		* Dummy variable to identify contradictions to the verification expression for registered
		egen row = rowtotal(registered_female registered_male)
		gen indicator = 1 if row == registered_total
		replace indicator = 0 if row != registered_total
		list indicator if indicator == 0
		drop row
		drop indicator
		
		* Dummy variable to identify contradictions to the verification expression for turnout
		egen row2 = rowtotal(turnout_female turnout_male)
		gen indicator = 1 if row2 == turnout_total
		replace indicator = 0 if row2 != turnout_total
		list indicator if indicator == 0
		drop row2
		drop indicator
		
		
	* Create polling booth ID variable, ranking polling booths by turnout (1 = highest turnout)
	egen index = group(town_id)
	egen poll_booth = rank(turnout_total), by(index)
	drop index
	
	
	* Create dummy variable for each value of the town ID number
	levelsof town_id, local(unique)
	foreach lev of local unique {
		generate town_id_`lev' = 0
		replace town_id_`lev' = 1 if town_id == `lev'
	}
	
	save "/Users/ignaciogutierrez/Desktop/World Bank Assessment/World Bank Test Data"
		
		
	* Add town names into dataset from supplementary Excel file
	import excel "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Town Names for Stata Test.xlsx", sheet("Sheet1") firstrow clear
	rename TownID town_id
	drop if town_id == 250
		
	merge 1:m town_id using "/Users/ignaciogutierrez/Desktop/World Bank Assessment/World Bank Test Data.dta"
	drop _merge
	rename TownName town_name
	sort town_id
	

	* Label all variables either ID variable, Electoral data, or Intervention
	foreach var of varlist(town_id - town_name) {
		label variable `var' "ID variable"
	}
	
	foreach var of varlist(turnout_total - registered_female) {
		label variable `var' "Electoral data"
	}
	
	foreach var of varlist(treatment - town_id_239) {
		label variable `var' "Intervention"
	}
	
	
	* Label values for treatment variable
	label define polling_booth 1 "Treatment Polling Booth" 0 "Control Polling Booth"
	label values treatment polling_booth  
	tabulate treatment
	
	save "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Final_Data"

	
* Section 2: Regressions and Results Table

	clear all
	use "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Final_Data.dta"
	
	ssc install estout
	ssc install ftools
	
	* Regress total turnout on treatment with town fixed effects and store results
	reghdfe turnout_total treatment, absorb(town_id)
	eststo: reghdfe turnout_total treatment, absorb(town_id)
	
	* Regress total turnout on treatment, with town fixed effects, controlling for total registered voters at each polling station; store results
	reghdfe turnout_total treatment registered_total, absorb(town_id)
	eststo: reghdfe turnout_total treatment registered_total, absorb(town_id)
	
	* Compute mean turnout from the control group 
	mean turnout_total if treatment == 0
	
	* Create regression table and export to excel (include mean from control group as reference)
	esttab, addnotes("Mean of total_turnout from control group = 461.254")
	esttab using regression_results.csv, replace addnotes("Mean of total_turnout from control group = 461.254")
	
	
* Section 3: Data Visualization
	
	use "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Final_Data.dta"
	
	* Generate bar graph showing difference in female turnout between treatment and control polling booths  
	graph hbar (count) turnout_female, over(treatment) ///
	title("Intervention Effects on Female Election Turnout") ///
	ytitle("Total Female Turnout")
	
	* save graph
	graph save "Graph" "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Graph.gph"
	
	
* Conclusion: 

	** Regression Analysis: Based on the results of the regression analysis, the treatment increased total election turnout in the polling booth where it was implemented with a 5% statistical significance level. When we control for the total number of registered voters at each booth, as well as impose town-level fixed effects to control for inherent differences across towns, the results are the same. The average total election turnout for the control polling booths was roughly 461, whereas the total election turnout in the treatment polling booths increased by roughly 7 voters for the first regression and roughly 8 voters for the second regression, which included a control variable and town-fixed effects. 
	
	** Data Visualization: Based on the results of our bar graph, total female turnout in the treatment polling booths did not surpass female turnout in the control polling booths. This suggests that while the treatment might have increased total voter turnout in the polling booths where it was implemented, it may have failed to elevate total female turnout in those same booths.

	


	
	
	
	