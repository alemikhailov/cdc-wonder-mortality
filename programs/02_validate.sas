options notes source;

/*****************************************************************************
* Program:     02_validate.sas
* Project:     CDC WONDER Heart Disease Mortality Disparities Analysis
* Purpose:     Validate the cleaned dataset for completeness, consistency,
*              and data quality before analysis.
* Input:       WORK.MORTALITY_CLEAN (from 01_import.sas)
* Output:      Validation findings printed to RESULTS
* Author:      Aleksandr Mikhailov
* Date:        September 2026
*****************************************************************************/

/*==========================================================================
  CHECK 1: Record count — expected vs actual
  With 6 races x 2 sexes x 4 regions x 5 years = 240 possible cells.
  Any shortfall indicates suppressed or missing strata.
==========================================================================*/

title "Validation Check 1: Record count vs expected";
proc sql;
    select count(*) as Actual_Records,
           240 as Expected_Records,
           240 - count(*) as Missing_Strata
    from mortality_clean;
quit;

/*==========================================================================
  CHECK 2: Duplicate records
  Each combination of Region + Race + Sex + Year should appear once.
==========================================================================*/

title "Validation Check 2: Duplicate check (should return 0 rows)";
proc sql;
    select Census_Region_Code, Race_Code, Sex_Code, Year, 
           count(*) as N
    from mortality_clean
    group by Census_Region_Code, Race_Code, Sex_Code, Year
    having count(*) > 1;
quit;

/*==========================================================================
  CHECK 3: Missing values in required fields
==========================================================================*/

title "Validation Check 3: Missing values in key variables";
proc sql;
    select 
        sum(missing(Census_Region)) as Miss_Region,
        sum(missing(Race))          as Miss_Race,
        sum(missing(Sex))           as Miss_Sex,
        sum(missing(Year))          as Miss_Year,
        sum(missing(Deaths))        as Miss_Deaths,
        sum(missing(Population))    as Miss_Population,
        sum(missing(Crude_Rate))    as Miss_Rate
    from mortality_clean;
quit;

/*==========================================================================
  CHECK 4: Value range checks
  - Deaths should be >= 0
  - Population should be > 0
  - Crude Rate should be > 0
  - Year should be within expected range
  - Rate_LCL should be <= Crude_Rate <= Rate_UCL
==========================================================================*/

title "Validation Check 4a: Records with invalid death counts (< 0)";
proc sql;
    select * from mortality_clean where Deaths < 0;
quit;

title "Validation Check 4b: Records with invalid population (<= 0)";
proc sql;
    select * from mortality_clean where Population <= 0;
quit;

title "Validation Check 4c: Records with year outside expected range";
proc sql;
    select * from mortality_clean where Year not in (2020, 2021, 2022, 2023, 2024);
quit;

title "Validation Check 4d: Records where CI bounds are inconsistent";
proc sql;
    select Census_Region, Race, Sex, Year, 
           Rate_LCL, Crude_Rate, Rate_UCL
    from mortality_clean
    where Rate_LCL > Crude_Rate 
       or Crude_Rate > Rate_UCL;
quit;

/*==========================================================================
  CHECK 5: Cross-tabulation completeness
  Show which Race x Sex x Region combinations have fewer than 5 years.
  These are the strata where CDC suppressed data.
==========================================================================*/

title "Validation Check 5: Incomplete strata (fewer than 5 years)";
proc sql;
    select Census_Region, Race, Sex, 
           count(*) as Years_Present,
           5 - count(*) as Years_Missing
    from mortality_clean
    group by Census_Region, Race, Sex
    having count(*) < 5
    order by Years_Missing desc;
quit;

/*==========================================================================
  CHECK 6: Computed rate verification
  Recalculate crude rate as (Deaths / Population) * 100000 and compare
  to the CDC-provided rate. Flag records where difference > 0.5.
==========================================================================*/

title "Validation Check 6: Rate recalculation discrepancies (diff > 0.5)";
proc sql;
    select Census_Region, Race, Sex, Year,
           Deaths, Population,
           Crude_Rate as CDC_Rate,
           (Deaths / Population) * 100000 as Calc_Rate format=8.1,
           Crude_Rate - ((Deaths / Population) * 100000) as Difference format=8.2
    from mortality_clean
    where abs(Crude_Rate - ((Deaths / Population) * 100000)) > 0.5;
quit;

/*==========================================================================
  SUMMARY: Validation findings
==========================================================================*/

title "Validation Summary";
proc sql;
    select 
        count(*) as Total_Records,
        sum(case when missing(Deaths) then 1 else 0 end) as Missing_Deaths,
        sum(case when missing(Population) then 1 else 0 end) as Missing_Pop,
        sum(case when Deaths < 0 then 1 else 0 end) as Negative_Deaths,
        sum(case when Population <= 0 then 1 else 0 end) as Invalid_Pop,
        min(Year) as Min_Year,
        max(Year) as Max_Year
    from mortality_clean;
quit;

title;