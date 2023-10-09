*** LSE Rwanda Coffee Farmer Project Sample Code ***


*** In this sample code, I clean and wrangle two panel datasets from the International Coffee Organization. Both datasets consist of the domestic consumption and export quantites of coffee by country and year ***

	cd "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE"

	

** Data Cleaning: Dataset 1 (Exports) **

	clear all
	import delimited "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/exports-calendar-year.csv", varnames(1)

	
	* homogenizing strings and removing excess spacing
	forvalues i = 1/56 {
		replace country = trim(country)
	}	

	
	* replacing variable names with year 
	local X 1989
	foreach var of varlist(v2 - v30){
		local X = `X' + 1
		rename `var' yr`X'
	}

	
	* correct misspelled strings
	list country
	replace country = "Jamaica" in 28
	replace country = "Bolivia" in 3
	replace country = "Timor Leste" in 48
	replace country = "Vietnam" in 53
	
	
	* reshape panel data into long form by country-year
	reshape long yr, i(country) j(year)
	rename yr exports
	replace exports = round(exports, 0.001)

	
	save "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/Exports_Clean"


	
** Data Cleaning: Dataset 2 (Consumption) **
	
	clear all
	import delimited "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/domestic-consumption.csv", varnames(1)

	
	* replacing variable names with years
	local X 1989
	foreach var of varlist(v3 - v31){
		local X = `X' + 1
		rename `var' yr`X'
	}

	
	* homogenizing strings: capitalizing country names
	gen new_country = upper(substr(country,1,1)) + substr(country,2,.)
	drop country
	rename new_country country

	
	* check for duplicates and remove them
	sort country
	quietly by country: gen dup = cond(_N==1,0,_n)
	duplicates list country
	drop if dup == 1
	drop dup

	
	* correct for mis-spelled strings
	order country
	list country region
	replace region = "Central America" in 10
	replace region = "Carribean" in 11
	replace region = "Carribean" in 28

	
	* reshape panel data into long form by country-year
	reshape long yr, i(country) j(year)
	rename yr consumption
	replace consumption = round(consumption, 0.001)

	
	save "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/Consumption_Clean"


	
** Merging Datasets 

	* merge dataset 1 and dataset 2 	
	merge m:1 country year using "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/Exports_Clean.dta", keepusing(exports)
	drop _merge

	* create identification number for each country-year observation
	egen id = group(country)
	order id

	* conduct balance test
	tsset id year
	save "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/Panel_Clean"


	
** Data Visualization **

	* use merged panel data
	clear all
	use "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/Panel_Clean.dta"

	
	* identify countries in the top quartile of avg. export quantity
	egen avg_export = mean(exports), by(country)
	xtile quart = avg_export, nq(4)
	tab country if quart == 4

	
	* generate figure of countries in top quartile
	preserve
		keep if quart==4
		graph hbar (mean) consumption exports, over(country) ///
		title("Coffee 1990 - 2018") ///
		legend(label(1 Avg. Consumption) label(2 Avg. Exports))
	restore
	drop quart
	
	
	
** Generate Variables **

	* compute new variables from old
	gen total_production = (exports + consumption)
	gen pct_exports = (exports / total_production)

	
	* round quantities 
	replace avg_export = round(avg_export, 0.001)
	replace total_production = round(total_production, 0.001)
	replace pct_exports = round(pct_exports, 0.001)

	
	* label new variables 
	label variable total_production "sum of domestic consumption and exports"
	label variable pct_exports "percentage share of exports out of the total production"

	save "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/Panel_NewVars"


	
** Regression: I employ a difference-in-differences specification strategy to assess the effect of the Rwandan government's 2002 National Coffee Strategy to boost coffee production by incentivizing investments that shifted production from low-quality to high-quality specialty strains. I utilize Burundi's export and domestic consumption data (which was not subject to a national coffee strategy) as the control group in the specification strategy, given its geographical similarity and proximity to Rwanda. **

	clear all
	use "/Users/ignaciogutierrez/Desktop/J-PAL Resources/J-PAL LSE/Panel_NewVars.dta"

	
	* keep only treatment and control countries for diff-in-diff
	keep if country == "Rwanda" | country == "Burundi"

	
	* generate treatment dummy variable 
	gen treatment_Rwanda = 1 if country == "Rwanda"		
	replace treatment_Rwanda = 0 if country == "Burundi"

	
	* generate time dummy variable for the National Coffee Strategy intervention		
	gen post_treatment = 1 if year < 2002
	replace post_treatment = 0 if year >= 2002

	
	* generate diff-in-diff estimator
	gen diff_in_diff = (treatment_Rwanda * post_treatment)

	
	* diff-in-diff estimation
	reg total_production treatment_Rwanda post_treatment diff_in_diff
	reg pct_exports treatment_Rwanda post_treatment diff_in_diff
		
		
	* graphical figure of Diff-in-Diff results
	twoway (line total_production year if treatment_Rwanda==1, yaxis(1)) ///
	(line total_production year if treatment_Rwanda==0, yaxis(1)) ///
	(line pct_exports year if treatment_Rwanda==1, yaxis(2)) ///
	(line pct_exports year if treatment_Rwanda==0, yaxis(2)), /// 
	ytitle("Total Production", axis(1)) ///
	ytitle("% Share of Exports", axis(2)) ///
	xline(2002, lpattern(dash) lcolor(black)) ///
	legend(order(1 "Prod. Rwanda" 2 "Prod. Burundi" 3 "% Exp. Rwanda" 4 "% Exp. Burundi")) ///
	title("Diff-in-Diff: Rwanda National Coffee Strategy")
	


** Conclusion: Based on the results of the difference-in-difference regression, as represented by the associated data visualization, Rwanda's 2002 National Coffee Strategy stabilized the volatility of its coffee exports as a share of its total coffee production, particularly when compared to Burundi's more pronounced export share volatility after 2002. In addition, Rwanda's smoother export share trajectory exceeds that of Burundi in absolute terms following the 2002 intervention. In contrast, Rwanda's 2002 National Coffee Strategy does not materially affect its total coffee production until about 2008, when production stabilizes following significant prior volatility. Total production levels also do remain similar on average to Burundi's after 2002, although Burundi's total coffee production experiences consistent volatility on a downward trend until 2018. **  

	
	
****************************** end of sample code ******************************
	


