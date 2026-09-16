options notes source;

/*****************************************************************************
* Program:     03_analysis.sas
* Project:     CDC WONDER Heart Disease Mortality Disparities Analysis
* Purpose:     Produce descriptive tables, statistical models, and
*              visualizations for heart disease mortality disparities
*              by race, sex, and region (2020-2024).
* Input:       WORK.MORTALITY_CLEAN (from 01_import.sas)
* Output:      Tables, figures, and model results to RESULTS
* Author:      Aleksandr Mikhailov
* Date:        September 2026
*****************************************************************************/

/*==========================================================================
  TABLE 1: Overall mortality rates by race and sex
  This is the main descriptive summary — the kind of Table 1 you see
  in every clinical or epidemiological report.
==========================================================================*/

title "Table 1: Heart Disease Mortality Rate per 100,000 by Race and Sex (2020-2024)";
proc tabulate data=mortality_clean format=8.1;
    class Race Sex;
    var Crude_Rate Deaths Population;
    table Race=' ' all='Overall',
          Sex=' ' * (Crude_Rate=' '*mean=' '  Deaths=' '*sum=' '*f=comma10.0)
          all='Both Sexes' * (Crude_Rate=' '*mean=' '  Deaths=' '*sum=' '*f=comma10.0)
          / box='Race/Ethnicity';
run;

/*==========================================================================
  TABLE 2: Mortality rates by region and race
==========================================================================*/

title "Table 2: Mean Heart Disease Mortality Rate by Region and Race (2020-2024)";
proc tabulate data=mortality_clean format=8.1;
    class Census_Region Race;
    var Crude_Rate;
    table Census_Region=' ' all='National',
          Race=' '*Crude_Rate=' '*mean=' '
          / box='Region';
run;

/*==========================================================================
  TABLE 3: Year-over-year trends by race
==========================================================================*/

title "Table 3: Heart Disease Mortality Rate by Race and Year";
proc tabulate data=mortality_clean format=8.1;
    class Race Year;
    var Crude_Rate;
    table Race=' ' all='Overall',
          Year=' '*Crude_Rate=' '*mean=' '
          / box='Race/Ethnicity';
run;

/*==========================================================================
  FIGURE 1: Bar chart of mean mortality rate by race and sex
==========================================================================*/

title "Figure 1: Mean Heart Disease Mortality Rate by Race and Sex (2020-2024)";
proc sgplot data=mortality_clean;
    vbar Race / response=Crude_Rate stat=mean group=Sex 
         groupdisplay=cluster dataskin=crisp;
    xaxis label="Race/Ethnicity" discreteorder=data;
    yaxis label="Mean Crude Rate per 100,000" grid;
    keylegend / title="Sex" location=inside position=topright;
run;

/*==========================================================================
  FIGURE 2: Trend lines by race over time
==========================================================================*/

proc sort data=mortality_clean out=trend_data;
    by Race Year;
run;

proc means data=trend_data noprint nway;
    class Race Year;
    var Crude_Rate;
    output out=race_year_means(drop=_type_ _freq_) mean=Mean_Rate;
run;

title "Figure 2: Heart Disease Mortality Trends by Race (2020-2024)";
proc sgplot data=race_year_means;
    series x=Year y=Mean_Rate / group=Race lineattrs=(thickness=2)
           markers markerattrs=(size=8);
    xaxis label="Year" integer;
    yaxis label="Mean Crude Rate per 100,000" grid;
    keylegend / title="Race/Ethnicity" location=outside position=bottom;
run;

/*==========================================================================
  FIGURE 3: Regional comparison panel
==========================================================================*/

title "Figure 3: Heart Disease Mortality by Region and Race (2020-2024)";
proc sgpanel data=mortality_clean;
    panelby Census_Region / columns=2 rows=2 uniscale=row;
    vbar Race / response=Crude_Rate stat=mean dataskin=crisp;
    rowaxis label="Mean Crude Rate per 100,000" grid;
    colaxis label=" " discreteorder=data fitpolicy=rotate;
run;

/*==========================================================================
  MODEL 1: Poisson regression — rate ratios by race
  Reference group: White (largest population, standard comparator)
  Offset: log(Population) to model rates rather than counts
==========================================================================*/

title "Model 1: Poisson Regression — Heart Disease Mortality Rate Ratios by Race";
proc genmod data=mortality_clean;
    class Race(ref="White") Sex(ref="Female") Census_Region / param=ref;
    model Deaths = Race Sex Census_Region Year
        / dist=poisson link=log offset=Log_Pop type3;
        estimate 'AIAN vs White'         Race 1 0 0 0 0 -1 / exp;
    estimate 'Asian vs White'        Race 0 1 0 0 0 -1 / exp;
    estimate 'Black vs White'        Race 0 0 1 0 0 -1 / exp;
    estimate 'Multiracial vs White'  Race 0 0 0 1 0 -1 / exp;
    estimate 'NHOPI vs White'        Race 0 0 0 0 1 -1 / exp;
    estimate 'Male vs Female'        Sex  1 -1            / exp;
run;

/*==========================================================================
  MODEL 2: Poisson regression with Race x Sex interaction
  Tests whether racial disparities differ between men and women.
==========================================================================*/

title "Model 2: Poisson Regression with Race x Sex Interaction";
proc genmod data=mortality_clean;
    class Race(ref="White") Sex(ref="Female") Census_Region / param=ref;
    model Deaths = Race Sex Race*Sex Census_Region Year
        / dist=poisson link=log offset=Log_Pop type3;
run;

title;

proc freq data=mortality_clean;
    tables Race / nocum nopercent;
run;