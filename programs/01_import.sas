options notes source;

/*****************************************************************************
* Program:     01_import.sas
* Project:     CDC WONDER Heart Disease Mortality Disparities Analysis
* Purpose:     Import raw CDC WONDER export, clean variables, apply
*              exclusions, and create an analysis-ready dataset.
* Input:       heart_disease_mortality_raw.tsv (tab-delimited CDC WONDER export)
* Output:      WORK.MORTALITY_RAW  — imported data before exclusions
*              WORK.MORTALITY_CLEAN — analysis-ready dataset
* Author:      Aleksandr Mikhailov
* Date:        September 2026
*****************************************************************************/

%let datapath = /home/u63064984/heart_disease_mortality_raw.tsv;

data mortality_raw;
    infile "&datapath" 
        delimiter='09'x
        missover
        dsd
        lrecl=2000
        firstobs=2;

    length 
        Notes              $10
        Census_Region      $50
        Census_Region_Code $10
        Race               $50
        Race_Code          $10
        Sex                $10
        Sex_Code           $5
        Year_Char          $10
        Year_Code_Char     $10
        Deaths_Char        $15
        Population_Char    $15
        Crude_Rate_Char    $15
        Rate_LCL_Char      $15
        Rate_UCL_Char      $15;

    input 
        Notes $
        Census_Region $
        Census_Region_Code $
        Race $
        Race_Code $
        Sex $
        Sex_Code $
        Year_Char $
        Year_Code_Char $
        Deaths_Char $
        Population_Char $
        Crude_Rate_Char $
        Rate_LCL_Char $
        Rate_UCL_Char $;
run;

title "Step 2: Raw import check";
proc sql;
    select count(*) as Raw_Record_Count from mortality_raw;
quit;

proc print data=mortality_raw(obs=20) noobs;
run;

data mortality_clean;
    set mortality_raw;

    Year       = input(strip(Year_Char), ?? best12.);
    Year_Code  = input(strip(Year_Code_Char), ?? best12.);
    Deaths     = input(strip(Deaths_Char), ?? best12.);
    Population = input(strip(Population_Char), ?? best12.);
    Crude_Rate = input(strip(Crude_Rate_Char), ?? best12.);
    Rate_LCL   = input(strip(Rate_LCL_Char), ?? best12.);
    Rate_UCL   = input(strip(Rate_UCL_Char), ?? best12.);

    if Notes = "Total" then delete;
    if missing(Year) then delete;

    if Population > 0 then Log_Pop = log(Population);

    drop Notes Year_Char Year_Code_Char Deaths_Char Population_Char 
         Crude_Rate_Char Rate_LCL_Char Rate_UCL_Char;

    label 
        Census_Region      = "US Census Region"
        Census_Region_Code = "Census Region Code"
        Race               = "Race/Ethnicity (Single Race 6)"
        Race_Code          = "Race Code"
        Sex                = "Sex"
        Sex_Code           = "Sex Code"
        Year               = "Calendar Year"
        Year_Code          = "Year Code"
        Deaths             = "Number of Deaths"
        Population         = "Population Denominator"
        Crude_Rate         = "Crude Death Rate per 100,000"
        Rate_LCL           = "Crude Rate Lower 95% CI"
        Rate_UCL           = "Crude Rate Upper 95% CI"
        Log_Pop            = "Log(Population) for Poisson Offset";

    format Population comma15.0 Deaths comma10.0 
           Crude_Rate Rate_LCL Rate_UCL 8.1;
run;

title "Step 4a: Cleaned dataset summary";
proc sql;
    select count(*) as Clean_Record_Count,
           count(distinct Year) as N_Years,
           count(distinct Race) as N_Races,
           count(distinct Sex) as N_Sexes,
           count(distinct Census_Region) as N_Regions
    from mortality_clean;
quit;

title "Step 4b: Year distribution";
proc freq data=mortality_clean;
    tables Year / nocum;
run;

title "Step 4c: Race distribution";
proc freq data=mortality_clean;
    tables Race / nocum;
run;

title "Step 4d: Sex distribution";
proc freq data=mortality_clean;
    tables Sex / nocum;
run;

title "Step 4e: First 20 cleaned observations";
proc print data=mortality_clean(obs=20) noobs label;
    var Census_Region Race Sex Year Deaths Population Crude_Rate;
run;

title "Step 4f: Missing values check";
proc means data=mortality_clean n nmiss min max;