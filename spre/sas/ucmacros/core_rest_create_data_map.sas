/*
 Copyright (C) 2019 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   
   \brief   Create an instance of Data Map Object in SAS Risk Cirrus Objects
   
   \param [in] host Host url, including the protocol
   \param [in] server Name of the Web Application Server that provides the REST service (Default: riskCirrusObjects)
   \param [in] port Server port (Default: 443)
   \param [in] logonHost (Optional) Host/IP of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app host/ip is the same as the host/ip in the url parameter 
   \param [in] logonPort (Optional) Port of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app port is the same as the port in the url parameter
   \param [in] username Username credentials
   \param [in] password Password credentials: it can be plain text or SAS-Encoded (it will be masked during execution). 
   \param [in] authMethod: Authentication method (accepted values: BEARER). (Default: BEARER).
   \param [in] client_id The client id registered with the Viya authentication server. If blank, the internal SAS client id is used (only if GRANT_TYPE = password).
   \param [in] client_secret The secret associated with the client id.
   \param [in] name Name of the instance of the Cirrus object that is created with this REST request
   \param [in] dimensional_points (Optional) List of dimensional point rk values to use for the dimensional area of the output object.  Formatted as a comma-separated list of integers: e.g. [10000, 10001, 100002].  If not provided, the dimensional points will be pulled from &analysis_run_id if possible.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table (Default: analysis_data)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)
   
   \details 
   This macro sends a POST request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/rmc/dataMaps</i></b> and creates an instance in Cirrus Data Map object \n
   \n
   See \link core_rest_get_request.sas \endlink for details about how to send POST requests and parse the response.
   
   
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

   2) Send a Http GET request and parse the JSON response into the output table WORK.data_map
   \code
      %let accessToken =;
      %core_rest_create_data_map(host = <host>
                  , server = riskCirrusObjects
                  , solution =
                  , port = <port>
                  , username = <userid>
                  , password = <password>
                  , name = data_map
                  , description = test
                  , data_def_tgt_filter = %nrstr(name=Portfolio Definition)
                  , data_def_src_filter = %nrstr(name=Entity Definition)
                  , outds = data_map
                  );
      %put &=accessToken;                            
      %put &=httpSuccess;                        
      %put &=responseStatus;
   \endcode
         
   <b>Sample output:</b>
   

   \ingroup rgfRestUtils
   
   \author  SAS Institute Inc.
   \date    2019
*/

%macro core_rest_create_data_map(host =
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
                     , mapType =
                     , data_def_src_key = 
                     , data_def_src_filter = 
                     , data_def_tgt_key =
                     , data_def_tgt_filter =
                     , ds_in_mapping_data =
                     , filter_vars =
                     , dimensional_points = 
                     , outds = dataMap
                     , outVarToken = accessToken
                     , outSuccess = httpSuccess
                     , outResponseStatus = responseStatus
                     , debug = false
                     , logOptions =
                     , restartLUA = Y
                     , clearCache = Y
                     );

   %local
      requestUrl
      curr_var
      auxOpDim1_key
      solution_created_in
      filter_txt_vars
      filter_num_vars
      dataMapKey
      rowCount
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

   /* Make sure input parameter outds is not blank */
   %if %sysevalf(%superq(outds) =, boolean) %then
      %let &outds. = _tmp_dataMap_out;
  
   /* Make sure input parameter mapType is not blank */
   %if %sysevalf(%superq(mapType) =, boolean) %then %do;
      %put ERROR: Input parameter mapType is required.;
      %return;
   %end;
      
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
         %put ERROR: Unable to get the key for auxOpDim1;
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
         %irmc_get_dim_point_from_groovy(query_type = sameLocationReplaceSolutionsSharedWith
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
   /* Retrieve Source/Target Data Definitions                                                */
   /* ************************************************************************************** */
   
   /* Process Source Data Definition */
   %if(&mapType. ne SUBLEDGER
       and (%sysevalf(%superq(data_def_src_key) ne, boolean)
            or %sysevalf(%superq(data_def_src_filter) ne, boolean)
            ) 
       ) %then %do;

      %let &outSuccess. = 0;
      /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
      option nomlogic nosymbolgen;
      %core_rest_get_data_def(host = &host.
                       , solution = &solution.
                       , port = &port.
                       , logonHost = &logonHost.
                       , logonPort = &logonPort.
                       , username = &username.
                       , password = &password.
                       , authMethod = &authMethod.
                       , client_id = &client_id.
                       , client_secret = &client_secret.
                       , key = &data_def_src_key.
                       , filter = &data_def_src_filter.
                       , outds = _tmp_src_dataDef_summary
                       , outds_columns = _tmp_src_dataDef_details
                       , outVarToken = &outVarToken.
                       , outSuccess = &outSuccess.
                       , outResponseStatus = &outResponseStatus.
                       , debug = &debug.
                       , logOptions = &oldLogOptions.
                       , restartLUA = &restartLUA.
                       , clearCache = &clearCache.
                       );

      /* Exit in case of errors */
      %if(not &&&outSuccess.. or not %rsk_dsexist(_tmp_src_dataDef_summary)) %then %do;
         %put ERROR: Unable to get the data definition information;
         %return;
      %end;
      
      /* Exit if there are no results */
      %if(%rsk_attrn(_tmp_src_dataDef_summary, nobs) = 0) %then %do;
         %let &outSuccess. = 0;
         %put ERROR: Could not find any Data Definition matching the condition: key = &data_def_src_key., filter = &data_def_src_filter.;
         %return;
      %end;
      
      /* Exit if there is more than one result */
      %if(%rsk_attrn(_tmp_src_dataDef_summary, nobs) > 1) %then %do;
         %let &outSuccess. = 0;
         %put ERROR: There is more than one Data Definition matching the condition: &data_def_src_filter..;
         %return;
      %end;
      
      /* Get the Data Definition Key if it was not previded as input */
      %if %sysevalf(%superq(data_def_src_key) =, boolean) %then %do;
         data _null_;
            set _tmp_src_dataDef_summary;
            call symputx('data_def_src_key', key, 'L');
         run;
      %end;
      
   %end; /* Process Source Data Definition */
   

   /* Process Target Data Definition */
   %if(%sysevalf(%superq(data_def_tgt_key) ne, boolean)
       or %sysevalf(%superq(data_def_tgt_filter) ne, boolean)
       ) %then %do;

      %let &outSuccess. = 0;
      /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
      option nomlogic nosymbolgen;
      %core_rest_get_data_def(host = &host.
                       , solution = &solution.
                       , port = &port.
                       , logonHost = &logonHost.
                       , logonPort = &logonPort.
                       , username = &username.
                       , password = &password.
                       , authMethod = &authMethod.
                       , client_id = &client_id.
                       , client_secret = &client_secret.
                       , key = &data_def_tgt_key.
                       , filter = &data_def_tgt_filter.
                       , outds = _tmp_tgt_dataDef_summary
                       , outds_columns = _tmp_tgt_dataDef_details
                       , outVarToken = &outVarToken.
                       , outSuccess = &outSuccess.
                       , outResponseStatus = &outResponseStatus.
                       , debug = &debug.
                       , logOptions = &oldLogOptions.
                       , restartLUA = &restartLUA.
                       , clearCache = &clearCache.
                       );

      /* Exit in case of errors */
      %if(not &&&outSuccess.. or not %rsk_dsexist(_tmp_tgt_dataDef_summary)) %then %do;
         %put ERROR: Unable to get the data definition information;
         %return;
      %end;
      
      /* Exit if there are no results */
      %if(%rsk_attrn(_tmp_tgt_dataDef_summary, nobs) = 0) %then %do;
         %put ERROR: Could not find any Data Definition matching the condition: key = &data_def_tgt_key., filter = &data_def_tgt_filter.;
         %let &outSuccess. = 0;
         %return;
      %end;
      
      /* Exit if there is more than one result */
      %if(%rsk_attrn(_tmp_tgt_dataDef_summary, nobs) > 1) %then %do;
         %put ERROR: There is more than one Data Definition matching the condition: &data_def_tgt_filter..;
         %let &outSuccess. = 0;
         %return;
      %end;
      
      /* Validate the results */
      %local dataSubCategoryCd;
      data _null_;
         set _tmp_tgt_dataDef_summary;
         call symputx('dataSubCategoryCd', dataSubCategoryCd, 'L');
         /* Get the Data Definition Key if i was not previded as input */
         %if %sysevalf(%superq(data_def_tgt_key) =, boolean) %then %do;
            call symputx('data_def_tgt_key', key, 'L');
         %end;
      run;
      
      /* Make sure the right type of Data Definition was selected if this is a DataMap of type Sublegder  */
      %if(&mapType. = SUBLEDGER and %sysevalf(%superq(dataSubCategoryCd) ne calcDetail, boolean)) %then %do;
         %put ERROR: A Target Data Definition having dataSubCategoryCd = calcDetail is required to create a DataMap of type Subledger.;
         %let &outSuccess. = 0;
         %return;
      %end;
      
   %end; /* Process Target Data Definition */


   /* ************************************************************************************** */
   /* Create the Data Map JSON body                                                          */
   /* ************************************************************************************** */
   
   /* Check if we have have a mapping table to process */
   %let rowCount = 0;
   %if %sysevalf(%superq(ds_in_mapping_data) ne, boolean) %then %do;
   
      /* Make sure the specified input table exists */
      %if(not %rsk_dsexist(&ds_in_mapping_data.)) %then %do;
         %put ERROR: Table &ds_in_mapping_data. does not exist.;
         %let &outSuccess. = 0;
         %return;         
      %end;
      
      %let rowCount = %rsk_attrn(&ds_in_mapping_data., nlobs);

   %end;
   
   filename dataMap temp;
   data _null_;
      length
         source_var_name      $40.
         target_var_name      $40.
         expression_txt       $10000.
         mapping_desc         $256.
         target_var_type      $40.
         target_var_length    8.
         target_var_label     $200.
         target_var_fmt       $40.
         _filter_var_name_    $40.
         _filter_var_value_   $4096.
         _key_                8.
      ;
      file dataMap recfm = N;
      put '{' '0A'x;
      put ' "name": "' "&name." '"' '0A'x;
      put ' , "description": "' "&description." '"' '0A'x;
      put "  , ""changeReason"": ""batch change by core_rest_create_data_map""";
      
      /* Dimensional Points */
      %if(%sysevalf(%superq(dimensional_points) ne, boolean)) %then %do;
         put "  , ""classification"": ""default"": [&dimensional_points.]";
      %end;
      
      /* Custom fields */
      put ' , "customFields": {' '0A'x;
      put '      "mapType": "' "&mapType." '"' '0A'x;
      
      %if %sysevalf(%superq(ds_in_mapping_data) ne, boolean) %then %do;
         put '      , "mappingInfo":"{\"limit\":' "&rowCount." ', \"count\":' "&rowCount." ', \"start\": 0, \"items\":[';
         
         %if %sysevalf(%superq(ds_in_mapping_data) ne, boolean) %then %do;
            i = 0;
            do until(eof);
               /* Initialize variables */
               call missing(source_var_name, target_var_name, expression_txt, mapping_desc, target_var_type, target_var_length, target_var_label, target_var_fmt, filter);
               /* Read mapping table */
               set &ds_in_mapping_data. end = eof;
               /* Escape JSON special characters: Need to escape twice! */
               %core_json_escape(field = expression_txt);
               %core_json_escape(field = expression_txt);
               %core_json_escape(field = mapping_desc);
               %core_json_escape(field = mapping_desc);
               %core_json_escape(field = target_var_label);
               %core_json_escape(field = target_var_label);

               source_var_name = cats('\"', source_var_name, '\"');
               target_var_name = cats('\"', target_var_name, '\"');
               expression_txt = cats('\"', expression_txt, '\"');
               mapping_desc = cats('\"', mapping_desc, '\"');
               
               i + 1;
               %if(&mapType. = SUBLEDGER and %rsk_varexist(&ds_in_mapping_data., formula_id)) %then
                  /* Use a custom generated key if FORMULA_ID is missing. Start at 1M to avoid conflicts with other records where formula_id is not missing. */
                  _key_ = coalesce(formula_id, 1000000 + i);
               %else
                  _key_ = i;
               ;
               
               if(i > 1) then
                  put ', ';
               put '{';
               put '\"key\": ' _key_;
               put ', \"source_var_name\": ' source_var_name;
               put ', \"target_var_name\": ' target_var_name; 
               put ', \"expression_txt\": ' expression_txt;
               put ', \"mapping_desc\": ' mapping_desc;
               if(not missing(target_var_type)) then do;
                  target_var_type = cats('\"', target_var_type, '\"');
                  put ', \"target_var_type\": ' target_var_type;
               end;
               if(not missing(target_var_length)) then
                  put ', \"target_var_length\": ' target_var_length;
               if(not missing(target_var_label)) then do;
                  target_var_label = cats('\"', target_var_label, '\"');
                  put ', \"target_var_label\": ' target_var_label;
               end;
               if(not missing(target_var_fmt)) then do;
                  target_var_fmt = cats('\"', target_var_fmt, '\"');
                  put ', \"target_var_fmt\": ' target_var_fmt;
               end;
               
               /* Process filter for the Query Builder (mapType = Subledger) */
               %if(&mapType. = SUBLEDGER) %then %do;
                  %if %sysevalf(%superq(filter_vars) ne, boolean) %then %do;
                  
                     /* Split the filter variables between character and numeric */
                     %do i = 1 %to %sysfunc(countw(&filter_vars., %str( )));
                        %let curr_var = %scan(&filter_vars., &i. %str( ));
                        %if(%core_get_vartype(&ds_in_mapping_data., &curr_var.) = C) %then
                           %let filter_txt_vars = &filter_txt_vars. &curr_var.;
                        %else
                           %let filter_num_vars = &filter_num_vars. &curr_var.;
                     %end;
                     
                     /* Determine if there is a need to aply any filter */
                     _add_dataMap_filter_flg_ = "N";
                     %if %sysevalf(%superq(filter_txt_vars) ne, boolean) %then %do;
                        array _filter_txt_vars_ {*} &filter_txt_vars.;
                        do j = 1 to dim(_filter_txt_vars_);
                           /* Add the filter if it is not a wildcard value ("ALL" or "A" in case of flag variables) */
                           if(not (_filter_txt_vars_[j] = "ALL" or (_filter_txt_vars_[j] = "A" and vlength(_filter_txt_vars_[j]) = 1))) then
                              _add_dataMap_filter_flg_ = "Y";
                           *putlog i= _filter_txt_vars_[i]= _add_dataMap_filter_flg_=;
                        end;
                     %end;
                     %if %sysevalf(%superq(filter_num_vars) ne, boolean) %then %do;
                        /* Numeric filters are always included (no wildcard available) */
                        _add_dataMap_filter_flg_ = "Y";
                        array _filter_num_vars_ {*} &filter_num_vars.;
                     %end;
                     
                     
                     if(_add_dataMap_filter_flg_ = "Y") then do;
                     
                        put ', \"filter\": {\"filter\": {';
                        put '\"type\": \"and\"';
                        put ', \"children\": [';
                        
                        /* Counter for the filters */
                        _filter_cnt_ = 0;
                        
                        /* Process Text filters */
                        %if %sysevalf(%superq(filter_txt_vars) ne, boolean) %then %do;
                           do j = 1 to dim(_filter_txt_vars_);
                              /* Add the filter if it is not a wildcard value ("ALL" or "A" in case of flag variables) */
                              if(not (_filter_txt_vars_[j] = "ALL" or (_filter_txt_vars_[j] = "A" and vlength(_filter_txt_vars_[j]) = 1))) then do;
                                 _filter_cnt_ = _filter_cnt_ + 1;
                                 
                                 /* Escape JSON special characters: must be done twice! */
                                 %core_json_escape(field = _filter_txt_vars_[j]);
                                 %core_json_escape(field = _filter_txt_vars_[j]);
                                 
                                 _filter_var_name_ = cats('\"', vname(_filter_txt_vars_[j]), '\"');
                                 _filter_var_value_ = cats('\"', "'", _filter_txt_vars_[j], "'", '\"');
                                 
                                 if (_filter_cnt_ > 1) then
                                    put ', ';
                                 put '{';
                                 put '\"name\": ' _filter_var_name_;
                                 put ', \"type\": \"string\"';
                                 put ', \"value\": ' _filter_var_value_;
                                 put ', \"operator\": \"eq\"';
                                 put '}';
                              end;
                           end;
                        %end;
                        
                        /* Process Numeric filters */
                        %if %sysevalf(%superq(filter_num_vars) ne, boolean) %then %do;
                           do j = 1 to dim(_filter_num_vars_);
                              _filter_cnt_ = _filter_cnt_ + 1;
                              _filter_var_name_ = cats('\"', vname(_filter_num_vars_[j]), '\"');

                              if (_filter_cnt_ > 1) then
                                 put ', ';
                              put '{';
                              put '\"name\": ' _filter_var_name_;
                              put ', \"type\": \"Num\"';
                              put ', \"value\": ';
                              if(missing(_filter_num_vars_[j])) then
                                 put 'null';
                              else
                                 put _filter_num_vars_[j];
                              put ', \"operator\": \"eq\"';
                              put '}';
                           end;
                        %end;
                        
                        put ']'; /* Close children */
                        put '}}'; /* close filter */
                     end;
                     else do;
                        /* Create empty filter */
                        put ', \"filter\": \"\"';
                     end;
                  %end;
                  %else %do;
                     /* Create empty filter */
                     put ', \"filter\": \"\"';
                  %end;
               %end;
                  
               put '}'; /* Close mappingInfo.item entry */
               
            end;
         
         %end;
         put ']}"' '0A'x; /* Close mappingInfo custom field */
      %end;
      
      /* Solution Created in */
      %if(%sysevalf(%superq(solution_created_in) ne, boolean)) %then %do;
         put '      , "solutionCreatedIn": "' "&solution_created_in." '"' '0A'x;
      %end;
      
      put '   }' '0A'x;
      put '}' '0A'x;
      stop;
   run;
   
   
   /* ************************************************************************************** */
   /* Create the Data Map                                                                    */
   /* ************************************************************************************** */
   
   /* Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./dataMaps;

   %let &outSuccess. = 0;
   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   /* Send the REST request */
   %core_rest_request(url = &requestUrl.
               , method = POST
               , logonHost = &logonHost.
               , logonPort = &logonPort.
               , username = &username.
               , password = &password.
               , authMethod = &authMethod.
               , client_id = &client_id.
               , client_secret = &client_secret.
               , headerIn = Accept: application/json;charset=utf-8
               , body = dataMap
               , contentType = application/json;charset=utf-8
               , parser =
               , printResponse = N
               , outds =
               , headerOut = maphout
               , outVarToken = &outVarToken.
               , outSuccess = &outSuccess.
               , outResponseStatus = &outResponseStatus.
               , debug = &debug.
               , logOptions = &oldLogOptions.
               , restartLUA = &restartLUA.
               , clearCache = &clearCache.
               );

   /* Exit in case of errors */
   %if(not &&&outSuccess..) %then %do;
      %put ERROR: Failed to create the data map. Rsponse was: &&&outResponseStatus.. ;
      %return;
   %end;

   filename dataMap clear;
  
   /* Get the Data Map key from the header response */
   data &outds.;
      length key $ 64;
      infile maphout;
      input;
      /* Look for the Location parameter */
      if (_infile_ =: "Location:") then do;
         /* Get the key of the created object from the Location url */
         key = scan(_infile_, -1, "/");
         if (not missing(key)) then do;
            call symputx('dataMapKey', key, 'L');
            output;
         end;
      end;
   run;
  
   /* Make sure we got a key */
   %if %sysevalf(%superq(dataMapKey) = , boolean) %then %do;
      %put ERROR: Could not retrieve the Data Map key from the response.;
      %return;
   %end;

   /* ************************************************************************************** */
   /* Create the Link Instances to the Source/Target Data Definition                         */
   /* ************************************************************************************** */
   
   %if %sysevalf(%superq(data_def_src_key) ne, boolean) %then %do;
   
      %let &outSuccess. = 0;
      /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
      option nomlogic nosymbolgen;   
      %core_rest_create_link_inst(host = &host.
                           , port = &port.
                           , logonHost = &logonHost.
                           , logonPort = &logonPort.
                           , username = &username.
                           , password = &password.
                           , authMethod = &authMethod.
                           , client_id = &client_id.
                           , client_secret = &client_secret.
                           , collectionName = dataMaps
                           , collectionObjectKey = &dataMapKey.
                           , link_type = dataMap_dataDefinition_src
                           , business_object2 = &data_def_src_key.
                           , outds = objectLinkTgt
                           , outVarToken = &outVarToken.
                           , outSuccess = &outSuccess.
                           , outResponseStatus = &outResponseStatus.
                           , debug = &debug.
                           , logOptions = &oldLogOptions.
                           , restartLUA = &restartLUA.
                           , clearCache = &clearCache.
                           );
      
      %if(not &&&outSuccess.) %then %do;
         %put ERROR: Could not create a Link Instance of type dataMap_dataDefinition_src;
         %return;
      %end;
   
   %end;
   
   %if %sysevalf(%superq(data_def_tgt_key) ne, boolean) %then %do;

      %let &outSuccess. = 0;
      /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
      option nomlogic nosymbolgen;   
      %core_rest_create_link_inst(host = &host.
                           , port = &port.
                           , logonHost = &logonHost.
                           , logonPort = &logonPort.
                           , username = &username.
                           , password = &password.
                           , authMethod = &authMethod.
                           , client_id = &client_id.
                           , client_secret = &client_secret.
                           , collectionName = dataMaps
                           , collectionObjectKey = &dataMapKey.
                           , link_type = dataMap_dataDefinition_tgt
                           , business_object2 = &data_def_tgt_key.
                           , outds = objectLinkTgt
                           , outVarToken = &outVarToken.
                           , outSuccess = &outSuccess.
                           , outResponseStatus = &outResponseStatus.
                           , debug = &debug.
                           , logOptions = &oldLogOptions.
                           , restartLUA = &restartLUA.
                           , clearCache = &clearCache.
                           );
      
      %if(not &&&outSuccess.) %then %do;
         %put ERROR: Could not create a Link Instance of type dataMap_dataDefinition_tgt;
         %return;
      %end;
      
   %end;
         
%mend;