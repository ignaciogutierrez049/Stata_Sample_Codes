
*** Busara Ghana Savings RCT Sample Code ***



** SUMMARY: This sample code assesses the impact of a savings lockbox and financial education program on the saving behavior (saving amount in Ghanaian cedi) and attitude of students from different regions in Ghana. Children in Ghana schools were randomly assigned to receive the savings lockbox treatment (lockbox) or the financial education treatment (Fin_ed). Randomization was done at the school level. Schools in the lockbox group were given a metal padlocked savings box which was used to safeguard children's deposits in each classroom. Students who were in the Fin_ed schools were treated with sessions on the importance of money, savings and spending, and personal finances. Data on savings and saving behavior was collected at baseline and endline based on self-reported answers to an in-person questionnaire.



** SECTION A: SETTING UP AND HANDLING DATA

	* set up folder structure and create relative file paths	
		clear all
		cd "/Users/ignaciogutierrez/Desktop/Busara Test/"
			
			
	* import data and save as dta: 
		import delimited "data/raw_data/student_data_2023.csv", clear
		save "data/raw_data/student_data.dta", replace	
		
		clear
		
		import delimited "data/raw_data/school_data_2023.csv"
		save "data/raw_data/school_data.dta", replace
	
	
	* merge data files:			
		use "data/raw_data/school_data"
		merge 1:m schid using "data/raw_data/student_data.dta"	
		
	
	* drop unmatched observations (34 observations dropped)
		drop if _merge != 3
		drop _merge
		
	
	* save merged dataset: 
		save "data/processed_data/ghana_savings_merged_data.dta", replace
		

		
** SECTION B: DATA CLEANING

	* create unique ID variable 
		clear
		use "data/processed_data/ghana_savings_merged_data"
		
		gen schid_str = string(schid)
		gen std_number_stri = string(student_number_school)
		gen unique_id_str = schid_str + std_number_stri
		gen unique_id = real(unique_id_str)
		order unique_id
		sort unique_id
		drop schid_str std_number_stri unique_id_str

		
	* inspect date and time vars
		
		** tab day, month, year, hour, minute variables
			tab survdd 
			tab survmo
			tab survyy
			tab survhhst
			tab survminst
			
			
		** recode numeric data with faulty day and/or time values as missing
			local vars survdd survmo survyy survhhst survminst saveamt end_saveamt saving_attitude_index end_saving_attitude_index student_number_school take_up
				foreach var of local vars {
					replace `var' = . if survdd < 1,
					replace `var' = . if survmo > 12,
					replace `var' = . if survyy < 2010,
					replace `var' = . if survminst > 59 
				}				
			
	
	* generate date and time variables and combine
		gen date = mdy(survmo, survdd, survyy)	
		format date %tdNN/DD/CCYY		
		
		gen time = hms(survhhst, survminst, 0)
		format time %tcHH:MM

		gen timestamp = dhms(date, hh(time), mm(time), ss(time))
		format timestamp %tcNN/DD/CCYY_HH:MM
		
		drop date time
		
		
	* additional data cleaning: recode "-999" values in savings data as missing 
		foreach var of varlist(saveamt - end_saving_attitude_index) {
			replace `var' = . if `var' == -999
		}
		
		
	* save dataset
		save "data/processed_data/ghana_savings_clean_data.dta", replace 
		
		
		
** SECTION C: DESCRIBE AND VISUALIZE DATA

	* average value of savings at baseline
		clear
		use "data/processed_data/ghana_savings_clean_data"
		summarize saveamt 
		* result = 4.42
		
		
	* men in control group 
		count if gender == "Male" & take_up == 0
		* result = 567
		
		
	* balance test:
		pwmean saveamt, over(samp)  mcompare(tukey) effects
		pwmean saving_attitude_index, over(samp)  mcompare(tukey) effects
		
		* part a: 
** First, we would have to code the gender variable into a dummy, with '1' for Female and '0' for Male. Then, we would use the p-score of our pairwise comparison test to compare the proportion of women between the lockbox treatment group and the control group. A statistically significant p-score (below 0.05) would indicate a different proportion of women.   		
		
		* part b:
** Based on the results of the balance test, we cannot determine whether the treatment arms are balanced across regions, since we do not have a reference variable in our data which matches each treatment arm with each of the three regions in Ghana. This variable would allow us to run a balance test similar to the one conducted above, comparing relevant covariates across treatment arms in each of Ghana's regions rather than across the country as a whole.  
		
		* part c:
** The results of my balance test do not pose a problem for identification, since they disaggregate the descriptive statistics for each relevant covariate by each treatment arm (both treatments and control) and compare each of these individually. This allows us to detect statistically significant differences in baseline characteristics between individual groups (i.e., lockbox treatment group vs. control group), helping us determine whether randomization was conducted effectively for each group.  
		
	
	* graph of savings distribution at baseline by gender
		
		* recode gender variable to correct for spacing data entry errors and replace original gender variable
			gen gender_new = "Male"
			replace gender_new = "Female" if regexm(gender, "Female")
			replace gender_new = "-999" if regexm(gender, "-999")
			drop if schid == 145
			drop gender
			rename gender_new gender
			order gender, before(saveamt)
			save "data/processed_data/ghana_savings_clean_data", replace
			
		* graph histogram for males
			preserve
			keep if gender == "Male"
			quietly: summarize saveamt
			local mean_saving = r(mean)
			histogram saveamt, frequency ///
			fcolor(%50) ///
			xlabel(0(50)400) ///
			xtick(0(25)400) ///
			xtitle("Savings Amount") ///
			title("Distribution of Baseline Savings for Males") ///
			xline(`mean_saving', lpattern(dash) lcolor(red)) ///
			text(2000 59 "Mean Savings Amount", color(red))
			graph save "Graph" "graphs/basesavings_male.gph", replace			
			restore
			
		* graph histogram for females	
			preserve
			keep if gender == "Female"
			quietly: summarize saveamt
			local mean_saving = r(mean)
			histogram saveamt, frequency ///
			fcolor(%50) ///
			xlabel(0(50)400) ///
			xtick(0(25)400) ///
			xtitle("Savings Amount") ///
			title("Distribution of Baseline Savings for Females") ///
			xline(`mean_saving', lpattern(dash) lcolor(red)) ///
			text(2000 59 "Mean Savings Amount", color(red))
			graph save "Graph" "graphs/basesavings_female.gph", replace
			restore
			
			
		* part a. 
** For both males and females, the distribution of savings at baseline is quite similar, with a high concentration of savings between 0 and 10, and a much lower concentration approaching roughly 75. Some outlier values exceeding 100 for both groups also exist. In general, it appears more males save slightly higher values than females between roughly 25 and 150, but not enough to significantly differentiate their savings distribution. 
		
	
	
** SECTION D: ANALYZING DATA AND OUTPUTTING RESULTS

	* effect of treatment on amount saved 
		set cformat %9.2f
		reg end_saveamt take_up
		
		* Students subjected to the treatment save 3.46 more cedi than students who not subjected to the treatment 
		
		
	* effect of the treatments on saving amount and saving attitude
		
		* create dummies for separate treatments 
			gen lockbox = 1 if samp == 1
			replace lockbox = 0 if samp != 1
			gen fin_ed = 1 if samp == 2
			replace fin_ed = 0 if samp != 2
			save "data/processed_data/ghana_savings_clean_data", replace
		
		* run regressions and store results
			reg end_saveamt lockbox
			reg end_saving_attitude_index lockbox
			reg end_saveamt fin_ed
			reg end_saving_attitude_index fin_ed
			
		* part a: create table of results and export to Word
			ssc install estout
			ssc install ftools
			ssc install tabout
			
			label variable end_saveamt "End Savings"
			label variable end_saving_attitude_index "Sav. Attitude"
			label variable fin_ed "Financial Education"
			label variable lockbox "Savings Lockbox"
			
			eststo clear
			eststo: reg end_saveamt lockbox
			eststo: reg end_saving_attitude_index lockbox
			eststo: reg end_saveamt fin_ed
			eststo: reg end_saving_attitude_index fin_ed
			
			esttab using "output/busara_table.txt", replace se no t ///
			stats(N r2 p,fmt(%9.0f %9.3f %9.3f) labels("Observations" "R-Squared" "F-statistic" "Prob > F")) ///
			starlevels(* 0.10 ** 0.05 *** 0.01) ///
			label ///
			title("Effect of Treatments on Savings") ///
			addnotes ("Notes: savings amount in Ghanaian cedi (GHS); savings attitude index assumes numeric" /// 
			"value between 6 and -6, subject to outlier effects")
			
		* part b: 
			set cformat %9.3f
			reg end_saving_attitude_index fin_ed
			
			* The standard error of the effect of fin_ed on the saving attitude of students in Ghana is 18.688

		
	* estimation of actual treatment uptake on savings (use contaminated RCT method with treatment variables as IVs for the endogenous variable "take_up")
		use "data/processed_data/ghana_savings_clean_data"
		ivregress 2sls end_saveamt (take_up = fin_ed lockbox)
		ivregress 2sls end_saveamt (take_up = fin_ed)
		ivregress 2sls end_saveamt (take_up = lockbox)

		

** SECTION E: INTERPRETING RESULTS		

	* regression results 

** For the regression from Section D Question 1, the number of observations (3,881) in the regression encompasses the majority of observations from the questionnaire, posing no major complications for the estimation of results. The estimate for this regression was statistically significant at the 1% significance level, wherein receiving either of the treatments predicted an increase in the endline saving amount of 3.46 GHD. 

** For the regressions from Section D Question 2, the number of observations (3,881) was the same across each individual regression, again posing no complications for the estimation of results across treatments or dependent variables. Based on our estimated regressions, neither the savings lockbox treatment nor the financial education treatment produced statistically significant effects on the endline savings attitude index for Ghanaian schoolchildren. On the other hand, both treatments produced statistically significant results for the endline savings amount. In the case of the lockbox, endline savings were predicted to increase by 11.55 GHD if a child was assigned to the lockbox savings treatment, significant at the 1% level. In the case of the financial education program, endline savings were predicted to decrease by 6.45 GHD if a child was assigned to the financial education treatment, significant at the 1% level.   

** For the regression from Section D Question 3, the number of observations (3,881) is the same across both IV regressions and the number is high enough to pose no complications around the reliability of the sample (law of large numbers). Using the lockbox treatment as an instrument for the treatment take up, a student whom actually receives the treatment is predicted to increase endline savings by 32 GHD, with statistical significance at the 1% level. Using the financial education treatment as an instrument, a student whom actually receives the treatment is predicted to decrease endline savings by 15.55 GHD, with statistical significance at the 1% level.       


	* assumptions for Section D, Question 3
	
** For the effect of the IV regression on the treated to be unbiased, we must assume both instrumental relevance and exclusion restriction. Instrumental relevance implies that the instruments (in this case the treatment dummies "lockbox" and "fin_ed") are correlated with the endogenous variable "take_up". This ensures that the instruments can explain a significant portion of the variation in "take_up". Exclusion restriction implies that the instruments (lockbox and fin_ed) must only affect the endline savings amount (saveamt) through its effect on "take_up". The instruments cannot have a direct effect on "saveamt" that is unrelated to "take_up", otherwise the IV estimate will be biased.   
	
	
	* mechanisms/behaviors explaining effects of the treatment on endline savings 
	
** For the lockbox treatment, the resultant increase in savings could be due to the uniformity of the treatment across schools. Every school was given a metal padlocked savings box within to store the children's deposits, and this ensured, tangible measure of security likely inspired the same level of confidence for every student who received the treatment, resulting in increased savings. On the other hand, the financial education treatment is much more prone to variation in the quality of the sessions teaching the importance of money, saving, and spending, and inspiring behavioral changes through educational instruction is not likely to have a uniform effect across students or schools. Furthermore, certain elements of Ghanaian culture may dissuade students from listening to non-family members on ways to save and spend their money, breeding distrust among students who may then become more likely to do the opposite of what the financial education sessions instruct them to do. 

** To test my hypothesis, I would address the effect of each treatment separately. For the savings lockbox, I would implement the treatment in schools within districts with poor economic indicators around factors like earnings, consumption, saving, and investment. Since the lockbox produced such highly positive effects across a randomized sample of schools, some of which were likely in poorer regions of Ghana, I would be interested in assessing whether the tangible confidence produced by a padlocked savings box results in increased savings in regions where this outcome is least likely. For the financial education program, I would run the same RCT in a different African country, ideally in a different region like East Africa, to determine whether the negative results of the treatment are due to a country-wide cultural phenomenon against financial workshops in schools. Moreover, I would ensure a standardized financial education curriculum to try to minimize variation in the quality of the sessions across schools, thereby producing the same uniform behavioral/psychological effect on students as the metal padlocked savings box.     



***************************** END OF SAMPLE CODE *******************************
		
		
		