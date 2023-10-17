---
*** WORLD BANK STATA SAMPLE CODE ***
---


* SUMMARY:

*** This sample code analyzes a randomized control trial performed in India to increase voter turnout, with an emphasis on female participation,

*** for a 2010 election in India. The RCT was conducted in 27 towns, with roughly half of the polling booths in each town randomly selected for

*** treatment. The outcomes of interest were total turnout (the number of votes cast at each polling booth) and female turnout (the number of 

*** votes cast by women at each polling booth). Data was also collected on the number of registered voters at each polling booth, disaggregated

*** by gender, but for some polling booths this data could not be obtained, so data entry operations entered "-999" whenever they were missing 

*** data. 



* SECTION 1: Data Cleaning 
	
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
		
		
	* Verify that 'registered_total' and 'turnout_total' values equal their same values disaggregated by gender
		assert (registered_total == registered_male + registered_female)
		assert (turnout_total == turnout_female + turnout_male)

			* Dummy variables to identify contradictions to the verification expression for 'registered_total' and 'turnout_total'
				egen contradiction1 = rowtotal(registered_female registered_male)
				gen indicator1 = 1 if contradiction1 == registered_total
				replace indicator1 = 0 if contradiction1 != registered_total
				list indicator1 if indicator1 == 0

				egen contradiction2 = rowtotal(turnout_female turnout_male)
				gen indicator2 = 1 if contradiction2 == turnout_total
				replace indicator2 = 0 if contradiction2 != turnout_total
				list indicator2 if indicator2 == 0
				
				drop contradiction1
				drop indicator1
				drop contradiction2
				drop indicator2
			
		
	* Create polling booth ID variable, ranking polling booths by turnout (1 = highest turnout, 2 = second highest turnout...)
		egen index = group(town_id)
		egen poll_booth = rank(turnout_total), by(index)
		drop index
	
	
	* Create unique dummy variable for each value of the town ID number (= 1 for every observation for that particular town, = 0 otherwise)
		levelsof town_id, local(unique)
		foreach lev of local unique {
			generate town_id_`lev' = 0
			replace town_id_`lev' = 1 if town_id == `lev'
		}
		
		save "/Users/ignaciogutierrez/Desktop/World Bank Assessment/World Bank Test Data"
			
		
	* Merge town names into dataset from supplementary Excel file and sort by town ID number
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
		
	
	* Label values for the treatment variable
		label define polling_booth 1 "Treatment Polling Booth" 0 "Control Polling Booth"
		label values treatment polling_booth  
		tabulate treatment
		
		save "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Final_Data"

		
		
* SECTION 2: Regressions and Results Table

	* Import data and install packages
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
	
	
	* Create regression table and export to excel (include mean turnout from control group as a reference)
		esttab, addnotes("Mean of total_turnout from control group = 461.254")
		esttab using regression_results.csv, replace addnotes("Mean of total_turnout from control group = 461.254")
		
	
	
* SECTION 3: Data Visualization
	
	* Import clean dataset
		use "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Final_Data.dta"
	
	* Generate bar graph showing difference in female turnout between treatment and control polling booths  
		graph hbar (count) turnout_female, over(treatment) ///
		title("Intervention Effects on Female Election Turnout") ///
		ytitle("Total Female Turnout")
	
	* Save graph
		graph save "Graph" "/Users/ignaciogutierrez/Desktop/World Bank Assessment/Graph.gph"
	

	
* CONCLUSION: 


*** Regression Analysis: based on the results of the regression analysis, the treatment increased total election turnout in the polling booth 
*** where it was implemented with a 5% statistical significance level. When we control for the total number of registered voters at each booth, 
*** as well as impose town-level fixed effects to control for inherent differences across towns, the results are the same. The average total 
*** election turnout for the control polling booths was roughly 461, whereas the total election turnout in the treatment polling booths increased
*** by roughly 7 voters for the first regression and roughly 8 voters for the second regression, which included a control variable and town-fixed
*** effects. 


*** Data Visualization: based on the results of our bar graph, total female turnout in the treatment polling booths did not surpass female 
*** turnout in the control polling booths. This suggests that while the treatment might have increased total voter turnout in the polling booths 
*** where it was implemented, it may have failed to elevate total female turnout in those same booths, likely still targeting males as the 
*** primary voter base. 


********************************** END OF CODE *********************************



----
*** PROGRESA MEXICO RCT SAMPLE CODE ***
----

	
* SUMMARY: 

*** PROGRESA is a program of the Mexican government to reduce poverty, improve health, and increase educational attainment in the country, 
*** initially in rural areas and now in urban areas as well. In a sample of 506 villages, the phase-in was randomly assigned: 320 villages (the 
*** "treatment" villages) got the program in May 1998, and 186 villages (the "control" villages) did not get the program until December 2000. 
*** First, this evaluation will run descriptive statistics for variables of interest in the study. Second, this evaluation will run a balance 
*** test for randomization of the treatment. Third, this evaluation will assess the quantitative impact of the program by subgroups, followed by 
*** a conclusion either supporting or rejecting the effectiveness of this policy initiative. 



* SECTION 1: Descriptive Statistics of Schooling Attendance and Child Work Variables

	* Set cd and upload dataset: individual-level data for 27,588 children ages 6-16 in either 1997 or 1998
		clear
		cd "/Users/ignaciogutierrez/Desktop/Impact Evaluation/PROGRESA RCT"
		use ps1.dta
		
		
	* Measure fraction of children that attended school in 1997 for each age level 6 - 16 in control villages
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

				 
	* Measure fraction of children that worked prior to 1997 for each age level 8 - 16 in control villages
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


* SECTION 2: Manual Baseline Test for Randomization

		preserve
		
		* Calculate means and standard errors for age, grade, and school enrollment in 1997 for all treatment and control villages (children 6 - 16)
			keep if age97>=6 & age97<=16

			collapse (mean) age97mean=age97 (sd) age97sd=age97 (count) age97count=age97 ///
			(mean) grade97mean=grade97 (sd) grade97sd=grade97 (count)  grade97count=grade97 ///
			(mean) enroll97mean=enroll97 (sd) enroll97sd=enroll97 (count) enroll97count=enroll97, by(program)
			
		* Calculate standard errors of means from standard deviations
			gen age97se = age97sd / age97count^0.5
			gen grade97se = grade97sd / grade97count^0.5
			gen enroll97se = enroll97sd / enroll97count^0.5 
			
		* Calculate diff. in means, standard error of diff, and 95% confidence interval w/ upper and lower bounds for age, grade, and school enrollment in 1997
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
			
			
		* Conduct t-test for difference-in-means balance test on age, grade, and school enrollment in 1997 and export to excel 
			gen Ttestage97= age97diff/age97diffse
			list Ttestage97 
			gen Ttestgrade97= grade97diff/grade97diffse
			list Ttestgrade97 
			gen Ttestenroll97= enroll97diff/enroll97diffse
			list Ttestenroll97 
			
			
		* Export sheet to Excel	
			export excel using "RCT_Baseline_Test", sheet("Randomization_Table") replace firstrow(variables)
			
		restore


* SECTION 3: Impact Evaluation of PROGRESA on School Attendance & Child Work Across Age/Gender Sub-Groups in 1998 (year in which treatment villages received the program)

	* Primary-school age children vs. secondary-school age children: generate dummy variable for primary school age-level
		gen primary =1 if age98>=6 & age98<=11
		replace primary = 0 if age98>=12 & age98<=16
		drop if primary==.
		
			
	* Conduct t-test for four null hypotheses

		* program had no effect on the school attendance rate of children of primary school age-level (6-11)
			ttest enroll98 if primary==1, by(program) unequal
			
		* program had no effect on the fraction of children of primary school age who worked
			ttest work98 if primary==1, by(program) unequal
			
		* program had no effect on the school attendance rate of children of secondary school age-level (12-16)
			ttest enroll98 if primary==0, by(program) unequal

		* program had no effect on the fraction of children of secondary school age who worked
			ttest work98 if primary==0, by(program) unequal	
			

	* Conduct t-test for null that program had no effect on the chance of students finishing primary school and continuing onto secondary school 
		ttest continued98, by(program) unequal
	
	
	* Conduct same evaluation as both sets of T-tests above, but sub-divide primary and secondary school groups by boys and girls
			
		* effect on school attendance and child work for primary school age-level and males
			ttest enroll98 if primary==1 & male==1, by(program) unequal
			ttest work98 if primary==1 & male==1, by(program) unequal
				
		* effect on school attendance and child work for secondary school age-level and males	
			ttest enroll98 if primary==0 & male==1, by(program) unequal
			ttest work98 if primary==0 & male==1, by(program) unequal
				
		* effect on school attendance and child work for primary school age-level and females
			ttest enroll98 if primary==1 & male==0, by(program) unequal
			ttest work98 if primary==1 & male==0, by(program) unequal
				
		* effect on school attendance and child work for secondary school age-level and females	
			ttest enroll98 if primary==0 & male==0, by(program) unequal
			ttest work98 if primary==0 & male==0, by(program) unequal
				
		* effect on continuing education (from primary to secondary school) for males and females
			ttest continued98 if male==1, by(program) unequal
			ttest continued98 if male==0, by(program) unequal
		
		
		
* OUTCOME: 


*** The results of the evaluation show the statistical significance of the three desired outcome variables (continued98, enroll98, work98) for 
*** specific sub-groups of the population, which includes gender and primary vs secondary school placement based on age. Assuming a 95% 
*** confidence interval, the program appears to have had the largest effect on the following sub-groups:
	* Entire sample population for children who completed primary school in 1997 and continued onto secondary school 
	* Children of secondary school age enrolling in school in 1998
	* Males of secondary school age enrolling in school in 1998
	* Females of secondary school age enrolling in school in 1998
	
*** The effect of the program appears to have been the smallest for the following subgroups of the population: 
	* Females in primary school enrolling in school in 1998
	* Children of secondary school age having worked in the week before the 1998 survey
	* Males of primary school age having worked in the week before the 1998 survey
	* Females of secondary school age having worked in the week before the 1998 survey

*** The variables which appear to have been most affected are enroll98 and continued98, as they show statistically significant results for almost
*** all their respective sub-groups (assuming a 95% confidence interval). The variable work98 appears to have been least affected, with only one 
*** subgroup showing statistically significant results at the 5% significance level.

*** I attribute these findings to inherent differences between the measured outcome variables. The variable continued98 is likely to display 
*** statistically significant results, since children who finished primary school in 1997 are of the critical age (12) in which their school 
*** enrollments begin to drop and increasing numbers of them begin working. As such, the cash transfer program targets them at a significant 
*** juncture of their lives, allowing them to continue onto secondary school rather than drop out of school and work. For the enroll98 variable, 
*** a similar logic applies. The subgroups with the most significant (and thereby successful) results were those of secondary school age, 
*** regardless of gender. The program had the most success in boosting school enrollment rates because this is the age range in which children 
*** are more prone to drop out of school. Lastly, the variable work98 shows the least significant results, perhaps because the program dissuaded 
*** children across several households from working as they no longer needed the additional income. These results may coincide with the increased
*** enrollment rates across the secondary school age group. The only statistically significant results showed that the program increased females 
*** of primary school age who worked leading up to the 1998 survey. This may be due to the outsize presence of extremely poor households who 
*** prioritized sending their male kids to school but still required their female children to work. 

	
	
* Conclusion: 


*** Based on the evidence, the PROGRESA policy initiative appears to have a tangibly positive impact on poverty outcomes across poor rural 
*** villages in Mexico. The results show the program triggered legitimate increases in school enrollments for children and enabled more of them 
*** to attend secondary school. Furthermore, the program did not generally lead to increases in the number of children who worked. The cash 
*** transfer worked as intended, supplementing household incomes and allowing children to attend more school rather than drop out and work to 
*** support their families. I recommend that the program emphasizes targeting children of secondary-school age (12 to 16 years of age) since 
*** these show the greatest propensity to drop out of school and work. Furthermore, the results are not quite as statistically significant for 
*** children of primary school age (6 to 11 years of age).
		
		
******************************* END OF CODE ************************************



 


