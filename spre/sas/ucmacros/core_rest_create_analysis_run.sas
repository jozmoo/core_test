 /*
  Copyright (C) 2019 SAS Institute Inc. Cary, NC, USA
 */

 /**
    \file 
\anchor core_rest_create_analysis_run

    \brief   Create an instance of Analysis Run Object in SAS Risk Cirrus Objects

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
   \param [in] name (Optional, default value is "Analysis run for model <Model id> on <Current datetime>") Name of the instance of the Cirrus object that is created with this REST request
   \param [in] description (Optional, default value is pulled from the Model's description) Description of the instance of the Cirrus object that is created with this REST request
   \param [in] productionRun (Optional, default value is false) true if this run is a production run for the cycle, false otherwise
   \param [in] statusCd (Optional, default value is CREATED) status of the Analysis Run instance (typically this will be left as the default and the status will be updated upon execution)
   \param [in] cycleId Unique identifier string for the cycle object to link to the analysis run
   \param [in] modelId Unique identifier string for the model obejct to link to the analysis run
   \param [in] modelParameters Json-formatted string of model parameters for the analysis run
   \param [in] cycleTaskName The string value to assign to the cycleTaskName field (Default: Ad hoc run)
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table (Default: analysis_run_info)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

    \details
    This macro sends a POST request to <b><i><host>:<port>/riskCirrusObjects/objects/analysisRuns</i></b> and creates an instance in Cirrus Analysis Run object \n
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

    2) Send a Http GET request and parse the JSON response into the output table WORK.result
    \code
      %let accessToken =;
      %core_rest_create_analysis_run(host = <host>
                                       , server = riskCirrusObjects
                                       , solution =
                                       , port = <port>
                                       , username = <username>
                                       , password = <password>
                                       , name = Sample Analysis Run
                                       , description = Sample analysis run created by core_rest_create_analysis_run
                                       , productionRun = false
                                       , cycleId = RMC-2018.12
                                       , modelId = RMC-003-DataQuality
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

%macro core_rest_create_analysis_run(host =
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
                               , productionRun = false
                               , statusCd = CREATED
                               , cycleId =
                               , modelId = 
                               , modelParameters = 
                               , cycleTaskName = Ad hoc run
                               , outds = analysis_run_info
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
      curr_date
      curr_time
      cycle_key
      cycle_dim_points
      cycle_perspective
      model_key
      model_status
      analysis_run_key
      source_system_cd
   ;

   /* Set the required log options */
   %if(%length(&logOptions.)) %then
      options &logOptions.;
   ;

   /* Get the current value of mlogic and symbolgen options */
   %local oldLogOptions;
   %let oldLogOptions = %sysfunc(getoption(mlogic)) %sysfunc(getoption(symbolgen));

   %let source_system_cd = %sysfunc(coalescec(%upcase(&solution.), RCC));
   
   /* Get the request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./analysisRuns;
   %let requestMethod = POST;

   /* Get the current date and current time */
   %let curr_date = %sysfunc(date(), yymmddn8.);
   %let curr_date = %substr(&curr_date., 1, 4)-%substr(&curr_date., 5, 2)-%substr(&curr_date., 7, 2);
   %let curr_time = %sysfunc(time(), time.);

   /* Retrieve the cycle information */
   %let httpSuccess=;
   %core_rest_get_cycle(host = &host.
                           , solution = &solution.
                           , port = &port.
                           , logonHost = &logonHost.
                           , logonPort = &logonPort.
                           , username = &username.
                           , password = &password.
                           , authMethod = &authMethod.
                           , client_id = &client_id.
                           , client_secret = &client_secret.
                           , filter = %bquote(filter=eq(objectId,%27&cycleId.%27))
                           , outds = cycle_info
                           , outVarToken = &outVarToken.
                           , outSuccess = httpSuccess
                           , outResponseStatus = responseStatus
                           );
   /* Exit in case of errors */
   %if(not &httpSuccess. or not %rsk_dsexist(cycle_info)) %then %do;
      %put ERROR: Could not retrieve cycle information for cycleId &cycleId.;
      %abort cancel;
   %end;

   /* Get the required information from the cycle details */
   data _null_;
      set cycle_info;
      call symputx("cycle_key", key, "L");
      call symputx("cycle_dim_points", classification, "L");
      /*call symputx("cycle_perspective", solutionCreatedIn, "L");*/
   run;
   
   /* Get the dimensional points for the analysis run (same as cycle but reset Solutions Shared With to equal Solution Created In) */
   %let dim_points=%quote(&cycle_dim_points.);
   /*%let dim_points=;
   %irmc_get_dim_point_from_groovy(query_type = sameLocationReplaceSolutionsSharedWith
                                    , dimensional_points = %quote(&cycle_dim_points.)
                                    , perspective_id = &cycle_perspective.
                                    , outVar = dim_points
                                    , host = &host.
                                    , solution = &solution.
                                    , port = &port.
                                    , username = &username.
                                    , password = &password.
                                    );*/

   /* Retrieve the model information */
   %let httpSuccess=;
   %core_rest_get_model(host = &host.
                           , solution = &solution.
                           , port = &port.
                           , logonHost = &logonHost.
                           , logonPort = &logonPort.
                           , username = &username.
                           , password = &password.
                           , authMethod = &authMethod.
                           , client_id = &client_id.
                           , client_secret = &client_secret.
                           , filter = %bquote(filter=eq(objectId,%27&modelId.%27)%nrstr(&)fields=key,statusCd)
                           , outds = model_info
                           , outVarToken = &outVarToken.
                           , outSuccess = httpSuccess
                           , outResponseStatus = responseStatus
                           );
   /* Exit in case of errors */
   %if(not &httpSuccess. or not %rsk_dsexist(model_info)) %then %do;
      %put ERROR: Could not retrieve model information for modelId &modelId.;
      %abort cancel;
   %end;

   /* Get the required information from the model details */
   data _null_;
      set model_info;
      call symputx("model_key", key, "L");
      call symputx("model_status", statusCd, "L");
   run;

   /* If production run flag is true but model status is not Production, then error */
   %if(&model_status. ne PROD and &productionRun = true) %then %do;
      %put ERROR: Cannot create a Production analysis run for model &modelId. which does not have Production status.;
      %abort cancel;
   %end;

   /* If name or description is empty, set to the default */
   %if (%sysevalf(%superq(name) eq, boolean)) %then
      %let name = Analysis run for model &modelId. on &curr_date. &curr_time.;
   %if (%sysevalf(%superq(description) eq, boolean)) %then
      %let description = Created from batch execution script;

   /* Build analysisRun JSON body */
   filename _tmpBody temp;
   data _null_;
      file _tmpBody recfm=N;
      if _N_ = 1 then do;
         rx = prxparse('s/[""]/\\\\\\"/i');
         
         put "{""sourceSystemCd"": ""&source_system_cd.""";
         put "  , ""name"": ""&name.""";
         put "  , ""description"": ""&description.""";
         put "  , ""changeReason"": ""batch change by core_rest_create_analysis_run""";
         %if(%sysevalf(%superq(dim_points) ne, boolean)) %then %do;
            put "  , ""classification"": ""default"": [&dim_points.]";
         %end;
         /* Custom fields */
         put "  , ""customFields"": {";
         put "        ""statusCd"": ""&statusCd.""";
         put "       , ""prodRunFlg"": &productionRun.";
         /*put "       , ""solutionCreatedIn"": ""&cycle_perspective.""";*/
         put "       , ""cycleTaskName"": ""&cycleTaskName.""";
         put "       , ""modelParameters"": ""&modelParameters.""";
         put "}"; /* customFields */
         put "}"; /* JSON body */
      end;
   run;

   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   /* Send the REST request */
   %core_rest_request(url = &requestUrl.
                     , method = &requestMethod.
                     , logonHost = &logonHost.
                     , logonPort = &logonPort.
                     , username = &username.
                     , password = &password.
                     , authMethod = &authMethod.
                     , client_id = &client_id.
                     , client_secret = &client_secret.
                     , headerIn = Accept:application/json
                     , body = _tmpBody
                     , contentType = application/json
                     , parser = sas.risk.irm.rgf_rest_parser.rmcRestAnalysisRun
                     , outds = &outds.
                     , outVarToken = &outVarToken.
                     , outSuccess = &outSuccess.
                     , outResponseStatus = &outResponseStatus.
                     , debug = &debug.
                     , logOptions = &oldLogOptions.
                     , restartLUA = &restartLUA.
                     , clearCache = &clearCache.
                     );

   /* Get the analysis run key */
   data _null_;
      set &outds.;
      call symputx("analysis_run_key", key, "L");
   run;

   /* Create the cycle link instance */
   %core_rest_create_link_inst(host = &host.
                                  , port = &port.
                                  , logonHost = &logonHost.
                                  , logonPort = &logonPort.
                                  , solution = &solution.
                                  , username = &username.
                                  , password = &password.
                                  , authMethod = &authMethod.
                                  , client_id = &client_id.
                                  , client_secret = &client_secret.
                                  , collectionName = analysisRuns
                                  , collectionObjectKey = &analysis_run_key.
                                  , business_object2 = &cycle_key.
                                  , link_type = analysisRun_cycle
                                  , outds = analysis_run_cycle_link
                                  , outVarToken = &outVarToken.
                                  , outSuccess = &outSuccess.
                                  , outResponseStatus = &outResponseStatus.
                                  );

   /* Create the model link instance */
   %core_rest_create_link_inst(host = &host.
                                  , port = &port.
                                  , logonHost = &logonHost.
                                  , logonPort = &logonPort.
                                  , solution = &solution.
                                  , username = &username.
                                  , password = &password.
                                  , authMethod = &authMethod.
                                  , client_id = &client_id.
                                  , client_secret = &client_secret.
                                  , collectionName = analysisRuns
                                  , collectionObjectKey = &analysis_run_key.
                                  , business_object2 = &model_key.
                                  , link_type = analysisRun_model
                                  , outds = analysis_run_model_link
                                  , outVarToken = &outVarToken.
                                  , outSuccess = &outSuccess.
                                  , outResponseStatus = &outResponseStatus.
                                  );

%mend;