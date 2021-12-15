/*
 Copyright (C) 2020 SAS Institute Inc. Cary, NC, USA
*/

/*!
\file 
\anchor core_check_macrovars_nonempty
\brief   Check if macro variables are defined

\param [in] varnames space-separated list of variable names
\param [out] outBadVars name of the macro variable to hold a list of the variables that were not defined.

\details
Takes a sapce-separated list of macro variable names and if any of them are empty or undefined lists them in outBadVars, a space-separated list.

\author  SAS Institute Inc.
\date    2020
*/
%macro core_check_macrovars_nonempty(varnames=, outBadVars=badVars);
   %local 
      i
      var
      varOK
      temp
   ;
   %let &outBadVars. = ;
   %do i=1 %to %sysfunc(countw(&varnames.,%str( )));
      %let varOK = true;
      %let var = %scan(&varnames.,&i.,%str( ));
      %if not %symexist(&var.) %then %do;
         %let varOK = false;
      %end;
      %else %do;
         %let temp = &&&var.;
         %if %sysevalf(%superq(temp)=,boolean) %then %do;
            %let varOK = false;
         %end;
      %end;
      %if %sysevalf(&varOK. eq false, boolean) %then %do;
         %let &outBadVars. = &&&outBadVars. &var.;
      %end;
   %end;
%mend core_check_macrovars_nonempty;