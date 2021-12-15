%macro core_json_escape(field =, outfield =, isText = N);
   %local result;

   %if %sysevalf(%superq(isText) =, boolean) %then
      %let isText = N;
   %else
      %let isText = %upcase(&isText.);
      
   %if(&isText. = Y) %then %do;
      %let result = %sysfunc(prxchange(s/([\\""])/\\$1/i, -1, %superq(field)));
      %let result = %sysfunc(prxchange(s/\r/\\r/i, -1, %superq(result)));
      %let result = %sysfunc(prxchange(s/\n/\\n/i, -1, %superq(result)));
      %let result = %sysfunc(prxchange(s/\t/\\t/i, -1, %superq(result)));
   %end;
   %else %do;
      %if %sysevalf(%superq(outfield) =, boolean) %then
         %let outfield = &field.;
         
      %if(&outfield. ne &field.) %then
         &outfield. = &field.;
      ;
      
      if(not missing(&field.)) then do;
         &outfield. = prxchange('s/([\\""])/\\$1/i', -1, &field.);
         &outfield. = prxchange('s/\r/\\r/i', -1, &outfield.);
         &outfield. = prxchange('s/\n/\\n/i', -1, &outfield.);
         &outfield. = prxchange('s/\t/\\t/i', -1, &outfield.);
      end;
   %end;
   
   %if(&isText. = Y) %then &result.;
%mend;
