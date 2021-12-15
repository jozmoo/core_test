/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_create_ruleset

   \brief   Create an instance of a Rule Set Object in SAS Risk Cirrus Objects

   \param [in] host Host url, including the protocol
   \param [in] server Name of the Web Application Server that provides the REST service (Default: riskCirrusObjects)
   \param [in] solution Solution identifier (Source system code) for Cirrus Core content packages (Default: currently blank)
   \param [in] port Server port (Default: 443)
   \param [in] logonHost (Optional) Host/IP of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app host/ip is the same as the host/ip in the url parameter 
   \param [in] logonPort (Optional) Port of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app port is the same as the port in the url parameter
   \param [in] username Username credentials
   \param [in] password Password credentials: it can be plain text or SAS-Encoded (it will be masked during execution).
   \param [in] authMethod: Authentication method (accepted values: BEARER). (Default: BEARER).
   \param [in] client_id The client id registered with the Viya authentication server. If blank, the internal SAS client id is used (only if GRANT_TYPE = password).
   \param [in] client_secret The secret associated with the client id.
   \param [in] name Name of the instance of the Cirrus object that is created with this REST request
   \param [in] description Description of the instance of the Cirrus object that is created with this REST request
   \param [in] ds_in Name of the input data set that contains the rules
   \param [in] ruleset_type Type of rule set (AllocationRuleSet, BusinessRuleSet, QFactorRuleSet or ClassificationRuleSet). (Default: BusinessRuleSet)
   \param [in] ruleset_category Rule set category (DQ, STAGE, ADJ, OTHER). (Default: OTHER)
   \param [in] dimensional_points (Optional) List of dimensional point rk values to use for the dimensional area of the output object.  Formatted as a comma-separated list of integers: e.g. [10000, 10001, 100002].  If not provided, the dimensional points will be pulled from &analysis_run_id if possible.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table that contains the link_instance information (Default: link_instance)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
     This macro sends a POST request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/ruleSets</i></b> and creates an instance in Cirrus Rule Set object \n
   See \link core_rest_request.sas \endlink for details about how to send POST requests and parse the response.
   \n

   <b>Example:</b>

   1) Set up the environment (set SASAUTOS and required LUA libraries)
   \code
      %let source_path = <Path to the root folder of the Federated Content Area (root folder, excluding the Federated Content folder)>;
      %let fa_id = <Name of the Federated Area Content folder>;
      %include "&source_path./&fa_id./source/sas/ucmacros/core_setup.sas";
      %core_setup(source_path = &source_path.
                , fa_id = &fa_id.
                );
   \endcode

   2) Send a Http GET request and parse the JSON response into the output table WORK.ruleSetInfo
   \code
      %let accessToken =;
      %core_rest_create_ruleset(host = <host>
                                   , port = <port>
                                   , username = <userid>
                                   , password = <pwd>
                                   , outds = ruleSetInfo
                                   , outVarToken = accessToken
                                   , outSuccess = httpSuccess
                                   , outResponseStatus = responseStatus
                                   );
      %put &=accessToken;
      %put &=httpSuccess;
      %put &=responseStatus;
   \endcode

   \ingroup rgfRestUtils

   \author  SAS Institute Inc.
   \date    2018
*/
%macro core_rest_create_ruleset(host =
                                   , server = riskCirrusObjects
                                   , solution =
                                   , port = 443
                                   , logonHost =
                                   , logonPort =
                                   , username =
                                   , password =
                                   , authMethod = bearer
                                   , client_id =
                                   , client_secret =
                                   , name =
                                   , description =
                                   , ds_in =
                                   , ruleset_type = BusinessRuleSet
                                   , ruleset_category = OTHER
                                   , dimensional_points = 
                                   , outds = ruleSetInfo
                                   , outVarToken = accessToken
                                   , outSuccess = httpSuccess
                                   , outResponseStatus = responseStatus
                                   , debug = false
                                   , logOptions =
                                   , restartLUA = Y
                                   , clearCache = Y
                                   );

   %local
      auxOpDim1_key
      solution_created_in
      requestUrl
      ruleSetBody
      var_attrib
      varlist
      current_var
      rule_data
      upcase_varlist
      nrows
      i
   ;

   /* Initialize outputs */
   %let &outVarToken. =;
   %let &outSuccess. = 0;
   %let &outResponseStatus. =;

   /* Set the required log options */
   %if(%length(&logOptions.)) %then
      options &logOptions.;
   ;

   /* Get the current value of mlogic and symbolgen options */
   %local oldLogOptions;
   %let oldLogOptions = %sysfunc(getoption(mlogic)) %sysfunc(getoption(symbolgen));

   %if(%length(&port.) = 0) %then
      %let port = 443;

   /* ************************************************************************************** */
   /* Get the location and Solution Created In                                               */
   /* ************************************************************************************** */

   /* If the dimensional points parameter is not empty, pull the solution created in from the dim points */
   %if(%sysevalf(%superq(dimensional_points) ne, boolean)) %then %do;
      /* The solution created in should be the same across all points - only look at the first point */
      %let dim_point_1 = %sysfunc(prxchange(s/\s*\[(\d+).*/$1/,1,%superq(dimensional_points)));

      /* Get the dim point info for this dimensional point */
      %let &outSuccess. = 0;
      %core_rest_get_dim_point( key = &dim_point_1.
                                    , host = &host.
                                    , solution = &solution.
                                    , port = &port.
                                    , username = &username.
                                    , password = &password.
                                    , authMethod = &authMethod.
                                    , client_id = &client_id.
                                    , client_secret = &client_secret.
                                    , outds = dim_points
                                    , outVarToken = &outVarToken.
                                    , outSuccess = &outSuccess.
                                    , outResponseStatus = &outResponseStatus.
                                    );

      /* Check for errors */
      %if(not &&&outSuccess. or not %rsk_dsexist(dim_points)) %then %do;
         %put ERROR: Unable to get the dimensional point;
         %return;
      %end;

      /* Get the dimesion node key for auxOpDim1 (SolutionCreatedIn) */
      data _null_;
         set dim_points;
         call symputx("auxOpDim1_key", auxOpDim1, "L");
      run;

      /* Get auxOpDim1 value from dim point info */
      %let &outSuccess. = 0;
      %core_rest_get_aux_op_dim( key = &auxOpDim1_key.
                                    , host = &host.
                                    , solution = &solution.
                                    , port = &port.
                                    , username = &username.
                                    , password = &password.
                                    , authMethod = &authMethod.
                                    , client_id = &client_id.
                                    , client_secret = &client_secret.
                                    , outds = aux_op_dim
                                    , outVarToken = &outVarToken.
                                    , outSuccess = &outSuccess.
                                    , outResponseStatus = &outResponseStatus.
                                    );

      /* Check for errors */
      %if(not &&&outSuccess. or not %rsk_dsexist(aux_op_dim)) %then %do;
         %put ERROR: Unable to get the auxOpDim1 key;
         %return;
      %end;

      /* Get the dimesion node id - this is the solutionCreatedIn */
      data _null_;
         set aux_op_dim;
         call symputx("solution_created_in", auxOpDim1Id, "L");
      run;
   %end;
   /* Else if the analysis run id exists then pull SolutionCreatedIn from analysis run */
   %else %if %symexist(analysis_run_id) %then %do;
      %if(%sysevalf(%superq(analysis_run_id) ne, boolean)) %then %do;
         /* Get the analysis run info to pull SolutionCreatedIn */
         %let &outSuccess. = 0;
         %core_rest_get_analysis_run( host = &host.
                                      , solution = &solution.
                                      , port = &port.
                                      , logonHost = &logonHost.
                                      , logonPort = &logonPort.
                                      , username = &username.
                                      , password = &password.
                                      , authMethod = &authMethod.
                                      , client_id = &client_id.
                                      , client_secret = &client_secret.
                                      , key = &analysis_run_id.
                                      , outds = analysis_run
                                      , outVarToken = &outVarToken.
                                      , outSuccess = &outSuccess.
                                      , outResponseStatus = &outResponseStatus.
                                      );

         /* Check for errors */
         %if(not &&&outSuccess. or not %rsk_dsexist(analysis_run)) %then %do;
            %put ERROR: Unable to get the analysis run information;
            %return;
         %end;

        %let dimensional_points=;
        data _null_;
            set analysis_run;
            if not missing(dimensionalPoints) then
               call symputx("dimensional_points", dimensionalPoints, "L");
            if not missing(SolutionCreatedIn) then
               call symputx("solution_created_in", solutionCreatedIn, "L");
        run;
        /* Get the dimensional point and update the Solutions Shared With */
        %let accessToken =;
        %let new_dim_points=;
        %irmc_get_dim_point_from_groovy(query_type = emptyLocationWithPerspectiveNodes
                                      , dimensional_points = %quote(&dimensional_points.)
                                      , perspective_id = &solution_created_in.
                                      , outVar = new_dim_points
                                      , host = &host.
                                      , solution = &solution.
                                      , port = &port.
                                      , username = &username.
                                      , password = &password.
                                      );
        %let dimensional_points = &new_dim_points.;
      %end;
   %end;
   /* Otherwise, set solution created in to missing */
   %else %do;
      %let solution_created_in=;
   %end;

   /* ************************************************************************************** */
   /* Create the Rule Set                                                                    */
   /* ************************************************************************************** */

   /* Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./ruleSets;

   %if(%sysevalf(%superq(ruleset_type) = BusinessRuleSet, boolean)) %then %do;
      %let var_attrib =
         PRIMARY_KEY             length = $10000.
         RULE_ID                 length = $100.
         RULE_NAME               length = $100.
         RULE_DESC               length = $100.
         RULE_COMPONENT          length = $32.
         OPERATOR                length = $10.
         PARENTHESIS             length = $3.
         COLUMN_NM               length = $32.
         RULE_TYPE               length = $100.
         RULE_DETAILS            length = $4000.
         MESSAGE_TXT             length = $4096.
         AGGR_VAR_NM             length = $32.
         AGGR_EXPRESSION_TXT     length = $10000.
         AGGR_GROUP_BY_VARS      length = $10000.
         AGGREGATED_RULE_FLG     length = $3.
         RULE_REPORTING_LEV1     length = $1024.
         RULE_REPORTING_LEV2     length = $1024.
         RULE_REPORTING_LEV3     length = $1024.
         RULE_WEIGHT             length = 8.
      ;
      %let lookup_var_attrib =
         LOOKUP_TABLE            length = $1000.
         LOOKUP_KEY              length = $10000.
         LOOKUP_DATA             length = $10000.
      ;
      %let upcase_varlist =
         RULE_COMPONENT
         OPERATOR
         RULE_TYPE
         AGGREGATED_RULE_FLG
      ;
   %end;
   %else %if(%sysevalf(%superq(ruleset_type) = AllocationRuleSet, boolean)) %then %do;
      %let var_attrib =
         ADJUSTMENT_VALUE           length = 8.
         MEASURE_VAR_NM             length = $32.
         ADJUSTMENT_TYPE            length = $32.
         ALLOCATION_METHOD          length = $32.
         AGGREGATION_METHOD         length = $32.
         WEIGHT_VAR_NM              length = $32.
         WEIGHTED_AGGREGATION_FLG   length = $3.
      ;
      %let lookup_var_attrib =;
      %let upcase_varlist =
         ADJUSTMENT_TYPE
         ALLOCATION_METHOD
         AGGREGATION_METHOD
         WEIGHTED_AGGREGATION_FLG
      ;
   %end;
   %else %do;
      %put ERROR: Value for parameter RULESET_TYPE = &ruleset_type. is invalid. Expected values are: BusinessRuleSet or AllocationRuleSet (case sensitive);
      %return;
   %end;

   /* Get the number of rows from the input dataset */
   %let nrows = %rsk_attrn(&ds_in., nlobs);

   %let varlist = %sysfunc(prxchange(s/\s*length\s*=\s*\$?\d+\.?\s*/ /i, -1, &var_attrib.));
   %let lookup_varlist = %sysfunc(prxchange(s/\s*length\s*=\s*\$?\d+\.?\s*/ /i, -1, &lookup_var_attrib.));

   filename _tmpin temp;
   data _null_;
      attrib
         key length = $32.
         &var_attrib.
         &lookup_var_attrib.
         ruleData length = $32000.
         current_ruleData length = $32000.
      ;
      file _tmpin recfm=N;
      retain
         ruleData
         rx
         lookup_rx
      ;
      set &ds_in. end = last;

      if _N_ = 1 then do;
         rx = prxparse('s/[""]/\\\\\\"/i');
         lookup_rx = prxparse('s/[""]/\\"/i');

         put "{""name"": ""&name.""";
         put "  , ""description"": ""&description.""";
         %if(%sysevalf(%superq(dimensional_points) ne, boolean)) %then %do;
            put "  , ""dimensionalPoints"": &dimensional_points.";
         %end;
         put "  , ""customFields"": {";
         put "        ""ruleSetType"": ""&ruleset_type.""";
         %if %sysevalf(%superq(ruleset_category) ne, boolean) %then
            put "        ,""ruleSetCategoryCd"": ""&ruleset_category.""";
         ;
         %if(%sysevalf(%superq(solution_created_in) ne, boolean)) %then %do;
            put "       , ""solutionCreatedIn"": ""&solution_created_in.""";
         %end;
         put "        ,""ruleData"": ""{";
         put "             \""start\"": 0";
         put "             ,\""limit\"": &nrows.";
         put "             ,\""count\"": &nrows.";
         put "             ,\""items\"": [";
      end;

      array chars{*} key %sysfunc(prxchange(s/\b(rule_weight|adjustment_value)\b//i, -1, &varlist.));
      array lookup_chars{*} &lookup_varlist.;

      /* Set record key */
      key = cats("#", put(_N_, z6.));

      /* Make sure that dropdown columns are specified with uppercase values */
      %do i = 1 %to %sysfunc(countw(&upcase_varlist., %str( )));
         %scan(&upcase_varlist., &i., %str( )) = upcase(%scan(&upcase_varlist., &i., %str( )));
      %end;
      /* Process character variables */
      do i = 1 to dim(chars);
         current_ruleData = catx(",", current_ruleData
                                 , cats('\"', vname(chars[i]), '\":\"',  prxchange(rx, -1, chars[i]), '\"')
                                 );
      end;

      do i = 1 to dim(lookup_chars);
         if missing(lookup_chars[i]) then 
            current_ruleData = catx(",", current_ruleData
                                    , cats('\"', vname(lookup_chars[i]), '\":\"\"')
                                    );
         else
            current_ruleData = catx(",", current_ruleData
                                    , cats('\"', vname(lookup_chars[i]), '\":',  prxchange(lookup_rx, -1, lookup_chars[i]))
                                    );
         end;

      /* Process numeric variable */
      current_ruleData = catx(",", current_ruleData
                              %if(&ruleset_type. = BusinessRuleSet) %then
                                 , cats('\"RULE_WEIGHT\":', rule_weight);
                              %else
                                 , cats('\"ADJUSTMENT_VALUE\":', adjustment_value);
                              );

      if _N_ = 1 then put "{" current_ruleData "}";
      else put ", {" current_ruleData "}";

      /* ruleData = catx(",", ruleData, current_ruleData); */
      if last then do;
         put "  ]}""}";  /* end "items" list in "ruleData" */
         put "}";
         /* call symputx("rule_data", ruleData, "L"); */
      end;
   run;

   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   /* Send the REST request */
   %let &outSuccess. = 0;
   %core_rest_request(url = &requestUrl.
                     , method = POST
                     , logonHost = &logonHost.
                     , logonPort = &logonPort.
                     , username = &username.
                     , password = &password.
                     , authMethod = &authMethod.
                     , client_id = &client_id.
                     , client_secret = &client_secret.
                     , headerIn = Accept:application/json
                     , body = _tmpin
                     , contentType = application/json
                     , parser = sas.risk.irm.rgf_rest_parser.rmcRestRuleSetData
                     , outds = &outds.
                     , outVarToken = &outVarToken.
                     , outSuccess = &outSuccess.
                     , outResponseStatus = &outResponseStatus.
                     , debug = &debug.
                     , logOptions = &oldLogOptions.
                     , restartLUA = &restartLUA.
                     , clearCache = &clearCache.
                     );

%mend;
