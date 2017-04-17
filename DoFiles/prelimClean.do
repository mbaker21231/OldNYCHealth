/* Preliminary data cleaning and analysis */

/* Just change to the directory that we need */

	cd C:\Users\mbaker\Desktop\Sarah
	use 190313Mod.dta,clear
	
/* Some basic data cleaning and renaming to get things to work */
	
	replace areainacres=subinstr(areainacres,",","",.)
	destring areainacres, replace
	rename areainacres area
	
	replace populationbycensus=subinstr(populationbycensus,",","",.)
	destring populationbycensus, replace
	rename populationbycensus pop
	
	rename deathsofchildrenunder5years childdeaths
	replace childdeaths=subinstr(childdeaths,",","",.)
	destring childdeaths, replace

	replace allcauses=subinstr(allcauses,",","",.)
	destring allcauses, replace
	
	gen deathpop =allcauses/pop*1000
	gen death5pop=childdeaths/pop*1000

	rename numberofpersonstotheacre popdens
	
	replace diarrhealdiseases=subinstr(diarrhealdiseases,",","",.)
	destring diarrhealdiseases, replace
	
	gen diarpop=diarrhealdiseases/pop*100
	
/* Generate a ward-level id variable */	
	
	gen wardborough=wards+borough
	egen id=group(wardborough)
	
/* Set up the variables for panel data */
	
	xtset id year

/* Generate a set of dummy variables for each year */

	tab year, gen(yd)
	
/* Let's generate a variable for lower manhattan */

	gen lowerMH=0
	replace lowerMH=1 if borough=="MA" & (wards=="First" | wards=="Second" | wards=="Third" | /// 
		wards=="Fourth" | wards=="Fifth" | wards=="Sixth" | wards=="Seventh" | wards=="Eighth" ///
		| wards=="Ninth" | wards=="Tenth" | wards=="Eleventh" | wards=="Twelfth" | wards=="Thirteenth" | ///
		wards=="Fourteenth" | wards=="Fifteenth" | wards=="Sixteenth" | wards=="Seventeenth" | wards=="Eighteenth")

/* Some estimators - let's look at the yearly trends and how they look */
/* Fixed effects - a dummy for each ward */

	xtreg deathpop yd2-yd11, fe
	
	bysort id: gen weight=popdens[1]
	xtreg deathpop yd2-yd11 [pw=weight], fe		/* Interesting... */
	xtreg deathpop yd2-yd11 if lowerMH, fe
	xtreg death5pop yd2-yd11 if borough=="MA", fe
	
/* Interesting - we see that starting in about yd8, which corresponds to 1910, the death rate starts falling */

	xtreg death5pop yd2-yd11, fe
	xtreg death5pop yd2-yd11 [pw=weight], fe
	xtreg death5pop yd2-yd11 if lowerMH, fe
	xtreg death5pop yd2-yd11 if borough=="MA", fe
	
	
/* What sorts of diseases had the biggest changes? */
	
	xtreg diarpop yd2-yd11, fe

/* how about some graphs? */

	preserve
	collapse (mean) deathpop (mean) death5pop, by(borough year)
	egen bnum=group(borough)
	xtline deathpop, i(bnum) t(year)
	xtline death5pop, i(bnum) t(year)
	restore
	
/* What if we remove the fixed effects and do this? */

	tab id, gen(iddum)
	reg death5pop iddum*
	predict fe, xb
	gen err=death5pop-fe
	xtline err, i(id) t(year) overlay legend(off)
	xtline death5pop, i(id) t(year)
	

