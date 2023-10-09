
*** DATA CLEANING, WRANGLING, MERGING: 2016 INDIA BANKNOTE DEMONETIZATION POLICY ***

	* Set working directory 
	clear
	cd "/Users/ignaciogutierrez/Desktop/Research Assistant"

	
	* Clean India's state-district data list to facilitate merging with Aspirational India's household survey

		** correct capitalization errors for 'state' and 'district' data
		use "/Users/ignaciogutierrez/Desktop/Research Assistant/chest_exposure.dta"
		rename district Cap_District
		rename state Cap_State
		gen district = proper(Cap_District)
		gen state = proper(Cap_State)
		drop Cap_District
		drop Cap_State
		
		** save clean state-district dataset version
		save "/Users/ignaciogutierrez/Desktop/Research Assistant/UPDATED_chest_exposure.dta"
		file /Users/ignaciogutierrez/Desktop/Research Assistant/UPDATED_chest_exposure.dta saved


		** merge India's state-district data with household survey data
		import delimited "/Users/ignaciogutierrez/Desktop/Research Assistant/aspirational_india_20140101_20140430_R.csv", clear
		merge m:1 state district using "/Users/ignaciogutierrez/Desktop/Research Assistant/UPDATED_chest_exposure.dta", keepusing(chest_exposure)
		drop _merge
		clear all
		
		** save merged dataset
		use "/Users/ignaciogutierrez/Desktop/Research Assistant/Jan2014_India.dta"
		file /Users/ignaciogutierrez/Desktop/Research Assistant/Jan2014_India.dta saved
		
		
	* Merge datasets and reviewed mismatches in new dataset

		** review 'state-district' mismatches from Master and export to Excel sheet
		browse state hr district if(_merge==1)
		duplicates drop state hr district, force
		export excel using "HH_Survey_Mismatches", sheet("State_District") replace firstrow(variables) 
		
		** review 'state-district' mismatches from Using and export to Excel sheet
		browse state district if(_merge==2)
		export excel using "Exposure_Mismatches", sheet("State_District") replace firstrow(variables) 

	
	* Update data cleaning
		
		** use India's state-district data 
		use "/Users/ignaciogutierrez/Desktop/Research Assistant/UPDATED_chest_exposure.dta"
		replace state="Odisha" if state=="Orissa"
		replace district="Y.S.R." if district=="Ysr"
		replace state="Telangana" if(state=="Andhra Pradesh" & district != "Y.S.R.")
		
		** save updated clean state-district dataset version
		save "/Users/ignaciogutierrez/Desktop/Research Assistant/V2_UPDATED_chest_exposure.dta"
		file /Users/ignaciogutierrez/Desktop/Research Assistant/V2_UPDATED_chest_exposure.dta saved
		
		** merge updated state-district data with household survey data
		import delimited "/Users/ignaciogutierrez/Desktop/Research Assistant/aspirational_india_20140101_20140430_R.csv", clear
		merge m:1 state district using "/Users/ignaciogutierrez/Desktop/Research Assistant/V2_UPDATED_chest_exposure.dta", keepusing(chest_exposure)
		drop _merge
		clear all
		
		** save merged dataset
		use "/Users/ignaciogutierrez/Desktop/Research Assistant/V2_Jan2014_India.dta"
		file /Users/ignaciogutierrez/Desktop/Research Assistant/V2_Jan2014_India.dta saved


	* Create a panel ranked by household ID and interview day slot

		** first sort dataset by household ID, then sort household ID by interview day slot 
		use "/Users/ignaciogutierrez/Desktop/Research Assistant/V2_Jan2014_India.dta"
		gen double numdate = clock(day_slot, "MY")
		sort hh_id numdate
		drop numdate
		save "/Users/ignaciogutierrez/Desktop/Research Assistant/Panel2014_India.dta"
		clear all

********************************* THE END **************************************



*** DESCRIPTIVE STATISTICS, BASELINE TEST, AND IMPACT EVALUATION: PROGRESA MEXICO RCT ***

	* Set cd and upload dataset
		clear
		cd "/Users/ignaciogutierrez/Desktop/Impact Evaluation/PROGRESA RCT"
		
	* Individual-level data for 27,588 children ages 6-16 in either 1997 or 1998. Data covers 505 villages in evaluation sample of the PROGRESA cash transfer program's impact on school attendance and child work in poor rural Mexico
		use ps1.dta


	* Conduct descriptive portrait of school attendance and child work

		** within control villages, measure the fraction of children that attended school in 1997 separately for each age level 6 - 16
			preserve
				keep if age97>=6 & age97<=16
				tab age97 enroll97 if program == 0, row nofreq
			restore

					   |       enroll97
				 age97 |         0          1 |     Total
			-----------+----------------------+----------
					 6 |      0.58      99.42 |    100.00 
					 7 |      0.74      99.26 |    100.00 
					 8 |      0.89      99.11 |    100.00 
					 9 |      0.77      99.23 |    100.00 
					10 |      2.02      97.98 |    100.00 
					11 |      3.73      96.27 |    100.00 
					12 |     12.09      87.91 |    100.00 
					13 |     27.22      72.78 |    100.00 
					14 |     37.91      62.09 |    100.00 
					15 |     55.51      44.49 |    100.00 
					16 |     72.34      27.66 |    100.00 
			-----------+----------------------+----------
				 Total |     18.40      81.60 |    100.00 

		** within control villages, measure the fraction of children that worked prior to the 1997 separately for each age level 8 - 16
			preserve
				keep if age97>=8 & age97<=16
				tab age97 work97 if program == 0, row nofreq
			restore

					   |        work97
				 age97 |         0          1 |     Total
			-----------+----------------------+----------
					 8 |     98.42       1.58 |    100.00 
					 9 |     97.67       2.33 |    100.00 
					10 |     97.78       2.22 |    100.00 
					11 |     96.89       3.11 |    100.00 
					12 |     93.05       6.95 |    100.00 
					13 |     90.20       9.80 |    100.00 
					14 |     83.75      16.25 |    100.00 
					15 |     73.18      26.82 |    100.00 
					16 |     59.20      40.80 |    100.00 
			-----------+----------------------+----------
				 Total |     88.48      11.52 |    100.00 

	 
	* Conduct a baseline test for randomization

		preserve
		
		** calculate means and standard errors for three interest variables for group of treatment control villages, children ages 6 - 16 (collapse dataset)
			keep if age97>=6 & age97<=16

			collapse (mean) age97mean=age97 (sd) age97sd=age97 (count) age97count=age97 ///
			(mean) grade97mean=grade97 (sd) grade97sd=grade97 (count)  grade97count=grade97 ///
			(mean) enroll97mean=enroll97 (sd) enroll97sd=enroll97 (count) enroll97count=enroll97, by(program)
			
		** calculate standard errors of means from standard deviations
			gen age97se = age97sd / age97count^0.5
			gen grade97se = grade97sd / grade97count^0.5
			gen enroll97se = enroll97sd / enroll97count^0.5 
			
		** calculate difference in means for interest variables, standard error of difference, and construct 95% confidence interval w/ upper and lower bounds
			gen id=_n
			
			* age97 variable
			gen age97diff=age97mean[_n-1] - age97mean 
			gen age97diffse = (age97se^2+age97se[_n-1]^2)^0.5
			
			* construct confidence interval
			gen age97diffub = age97diff + 1.96*age97diffse
			gen age97difflb = age97diff - 1.96*age97diffse

			list age97diff age97diffse age97difflb age97diffub

			* grade97 variable
			gen grade97diff=grade97mean[_n-1] - grade97mean 
			gen grade97diffse = (grade97se^2+grade97se[_n-1]^2)^0.5
			
			* construct confidence interval
			gen grade97diffub = grade97diff + 1.96*grade97diffse
			gen grade97difflb = grade97diff - 1.96*grade97diffse

			list grade97diff grade97diffse grade97difflb grade97diffub
			
			* enroll97
			gen enroll97diff=enroll97mean[_n-1] - enroll97mean 
			gen enroll97diffse = (enroll97se^2+enroll97se[_n-1]^2)^0.5
			
			* construct confidence interval
			gen enroll97diffub = enroll97diff + 1.96*enroll97diffse
			gen enroll97difflb = enroll97diff - 1.96*enroll97diffse

			list enroll97diff enroll97diffse enroll97difflb enroll97diffub
			
		** conduct t-test for difference-in-means baseline balance test on interest variables and export to excel 
			gen Ttestage97= age97diff/age97diffse
			list Ttestage97 
			gen Ttestgrade97= grade97diff/grade97diffse
			list Ttestgrade97 
			gen Ttestenroll97= enroll97diff/enroll97diffse
			list Ttestenroll97 
			
		** export sheet to Excel	
			export excel using "RCT_Baseline_Test", sheet("Randomization_Table") replace firstrow(variables)
			
		restore


	* Evaluate the impact of the program on school attendance and/or child work for different age-level sub-groups

		** primary-school age children vs. secondary-school age children: generate dummy variable for primary-school 
			gen primary =1 if age98>=6 & age98<=11
			replace primary = 0 if age98>=12 & age98<=16
			drop if primary==.
			
		** conduct t-test for four null hypotheses
			* program had no effect on the school attendance rate of children of primary-school age-level (6-11)
				ttest enroll98 if primary==1, by(program) unequal
			
			* program had no effect on the fraction of children of primary school age who worked
				ttest work98 if primary==1, by(program) unequal
			
			* program had no effect on the school attendance rate of children of secondary-school age-level (12-16)
				ttest enroll98 if primary==0, by(program) unequal

			* program had no effect on the fraction of children of primary school age who worked
				ttest work98 if primary==0, by(program) unequal	

		** conduct t-test for null that the program had no effect on the likelihood of students finishing primary school and continuing onto secondary school 
			ttest continued98, by(program) unequal
	
		** conduct same evaluation as above, but sub-divide primary and secondary school groups by boys and girls
			* effect on school attendance and child work for primary-school age and males
				ttest enroll98 if primary==1 & male==1, by(program) unequal
				ttest work98 if primary==1 & male==1, by(program) unequal
				
			* effect on school attendance and child work for secondary-school age and males	
				ttest enroll98 if primary==0 & male==1, by(program) unequal
				ttest work98 if primary==0 & male==1, by(program) unequal
				
			* effect on school attendance and child work for primary-school age and females
				ttest enroll98 if primary==1 & male==0, by(program) unequal
				ttest work98 if primary==1 & male==0, by(program) unequal
				
			* effect on school attendance and child work for secondary-school age and females	
				ttest enroll98 if primary==0 & male==0, by(program) unequal
				ttest work98 if primary==0 & male==0, by(program) unequal
				
			* effect on continuing education for males and females
				ttest continued98 if male==1, by(program) unequal
				ttest continued98 if male==0, by(program) unequal
		
********************************* THE END **************************************



*** DATA VISUALIZATION: WORLD ECONOMIC OUTLOOK ***

	* Set cd and upload dataset
		clear all
		cd "/Users/ignaciogutierrez/Desktop/International Economic Policy/"
		import excel "/Users/ignaciogutierrez/Desktop/International Economic Policy/inputs_weo.xlsx", sheet("Processed data") firstrow clear


	* Compute cyclical components of Real GDP, Gov. Expenditures, and Value-Added Tax Rate for Argentina with HP filter ** 
	
		*** set time-series to year
		tsset Year
		
		*** compute cyclical components
		global vars RealGDP GovExp VATR

		*** transform the required variables in logs.
		foreach X in $vars {
		gen l_`X' = ln(`X')
		}
		
		*** compute HP-Filter with lambda 6.25
		foreach X in $vars{
		tsfilter hp cycle_`X' = l_`X', smooth(6.25) trend(trend_`X')
		}

		
	* Create data visualization plots 
	
		*** plot comparing data for log(Real GDP) and HP trend of log(Real GDP)
		tsline l_RealGDP trend_RealGDP
		
		*** plot comparing data for log(Gov. Expenditures) and HP trend of log(Gov. Expenditures)
		tsline l_GovExp trend_GovExp


	* Compute correlations between the cyclical components of Real GDP, Gov. Expenditures, and Value-Added Tax Rate

		*** export correlation as Word file
		asdocx pwcorr RGDP_Cycle VATR_Cycle GovExp_Cycle, save(Correls.docx) star(all)

		*** compute and export correlation before 2003 (the first year after the 1998-2002 Argentine great depression)
		asdocx pwcorr cycle_rgdp cycle_tax_rate cycle_gov_exp if Year < 2003, save(Correls.docx) star(all) append 

		*** compute and export correlation after 2003 (the first year after the 1998-2002 Argentine great depression)
		asdocx pwcorr cycle_rgdp cycle_tax_rate cycle_gov_exp if Year >= 2003, save(Correls.docx) star(all) append 

	
********************************* THE END **************************************

	

*** GRAVITY MODEL REGRESSION ***

	* Set cd and upload dataset
		clear
		cd "/Users/ignaciogutierrez/Desktop/Applied Econometrics/Gravity Model"
		
	* WTO panel dataset of all bilateral and multilateral regional trade agreements between 1986 and 2006
		use WTO_agreements.dta


	* Data Wrangling 
	
		* analysis considers panel data with 4 year intervals (1986, 1990, ..., 2006)
			keep if year == 1986 | year == 1990 | year == 1994 | year == 1998 | year == 2002 | year == 2006 
		
		* create dependent variable: logarithm of nominal trade flows between importer and exporter
			generate ln_trade = ln(trade)
			
		* create key independent variables: logarithm of bilateral distance between importer and exporter		
			generate ln_DIST = ln(DIST)
			
		* independent variable: economic output as a value for exports, by exporting country, by year 
			bysort exporter year: egen Y = sum(trade)
				generate ln_Y = ln(Y)
		* independent variable: expenditures as a value for imports, by importing country, by year  
			bysort importer year: egen E = sum(trade)
				generate ln_E = ln(E)
		
		
	* OLS excluding Multilateral Resistance Terms
	
		* Estimate the gravity model with control variables and pair ID for exporter-importer combinations; ln_DIST is var. of interest
		regress ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E if exporter != importer, cluster(pair_id) 

		* Store results
		estimates store ols

		* Perform RESET Test
		predict fit, xb
			generate fit2 = fit^2
		regress ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E fit2 if exporter != importer, cluster(pair_id)
			test fit2 = 0
			drop fit*
	

	* OLS controlling for Multilateral Resistance Terms with Remoteness Indexes
		
		* Create the remoteness indexes on the exporter side, defined as the logarithms of expenditure-weighted averages of bilateral distance:
		
			* variable for total expenditures for each year measured (same for all exporters)
			bysort exporter year: egen TotEj = total(E)
		
			* remoteness index
			bysort exporter year: egen REM_EXP = total(DIST / (E / TotEj))
			gen ln_REM_EXP = ln(REM_EXP)
				
		* Create the remoteness indexes on the importer side defined as the logarithms of output-weighted averages of bilateral distance:	
		
			* variable for total output for each year measured (same for all importers)
			bysort importer year: egen TotYi = total(Y)
		
			* remoteness index
			bysort importer year: egen REM_IMP = total(DIST / (Y / TotYi))
			gen ln_REM_IMP = ln(REM_IMP)

		* Estimate the gravity model and store estimates; ln_DIST is the var. of interest
			regress ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E ln_REM_EXP ln_REM_IMP if exporter != importer, cluster(pair_id) 
				estimates store rmtns

		* Perform the RESET test 
			predict fit, xb
				generate fit2 = fit^2
			regress ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E REM_EXP REM_IMP fit2 if exporter != importer, cluster(pair_id) 
				test fit2 = 0
				drop fit*


	* OLS controlling for Multilateral Resistance with Fixed Effects 

		* Create exporter-time fixed effects to control for factors constant across an exporter but variant over time
			egen exp_time = group(exporter year)
				quietly tabulate exp_time, gen(EXPORTER_TIME_FE)

		* Create importer-time fixed effects to control for factors constant across an importer but variant over time 
			egen imp_time = group(importer year)
				quietly tabulate imp_time, gen(IMPORTER_TIME_FE)

		* Estimate the gravity model with fixed effects (reghdfe) and store estimates; ln_DIST is the var. of interest
			ssc install reghdfe
			reghdfe ln_trade ln_DIST CNTG LANG CLNY if exporter != importer, absorb(exp_time imp_time) cluster(pair_id)
			estimates store fes

		* Perform the RESET test
			predict fit, xb
				generate fit2 = fit^2
			reghdfe ln_trade ln_DIST CNTG LANG CLNY fit2 if exporter != importer, absorb(exp_time imp_time) cluster(pair_id)
				test fit2 = 0
				drop fit*
			
			
	* FTA Effects: Israel-US 1985 Free Trade Agreement: measuring trade creating or trade diverting effects	

		* dummy variable = 1 when both countries in Free Trade Agreement 	
		gen FTA1 = 0 
		replace FTA1 =1 if ((year>1986) & inlist(exporter,  "USA", "ISR") & inlist(importer,  "USA", "ISR")) 

		* dummy variable = 1 when exporter in Free Trade Agreement 
		gen FTA2 = 0 
		replace FTA2 =1 if ((year>1986) & inlist(exporter,  "USA", "ISR") & !inlist(importer,  "USA", "ISR")) 

		* dummy variable = 1 when importer in Free Trade Agreement 
		gen FTA3 = 0 
		replace FTA3 =1 if ((year>1986) & !inlist(exporter,  "USA", "ISR") & inlist(importer,  "USA", "ISR")) 

		* Estimate the gravity model with FTA dummy variables (coefficient on dummies signify trade creation/diversion)
		regress ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E FTA1 FTA2 FTA3 if exporter != importer, cluster(pair_id) 
		clear all
	
	
********************************* THE END **************************************





