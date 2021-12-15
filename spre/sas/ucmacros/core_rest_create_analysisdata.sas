/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_create_analysisdata

   \brief   Create an instance of Analysis Data Object in SAS Risk Cirrus Objects

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
   \param [in] description Description of the instance of the Cirrus object that is created with this REST request
   \param [in] base_date Value of the Base Date field of the instance of the Cirrus object that is created with this REST request
   \param [in] status_cd Value of the Status field of the instance of the Cirrus object that is created with this REST request. (Default: Draft)
   \param [in] visibility_cd Value of the Private or Shared field of the instance of the Cirrus object that is created with this REST request. (Default: Private)
   \param [in] bep_target_var Value of the BEP Target Variable field of the instance of the Cirrus object that is created with this REST request
   \param [in] results_category Value of the Results Category field of the instance of the Cirrus object that is created with this REST request.  Valid values are defined in the resultsCategoryCd NamedList.
   \param [in] dimensional_point_rk (Optional) Value of the single Classification point of the instance of the Cirrus object that is created with this REST request. Ignored if dimensional_points is specified.
   \param [in] relationship_flg Value of the Show Relationships field of the instance of the Cirrus object that is created with this REST request. (Default: Private)
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [in] dimensional_points (Optional) List of dimensional point rk values to use for the dimensional area of the output object.  Formatted as a comma-separated list of integers: e.g. [10000, 10001, 100002].  If not provided, the dimensional points will be pulled from &analysis_run_id if possible.
   \param [out] outds Name of the output table (Default: analysis_data)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a POST request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/analysisData</i></b> and creates an instance in Cirrus Analysis Data object \n
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

   2) Send a Http GET request and parse the JSON response into the output table WORK.analysis_data
   \code
      %let accessToken =;
      %core_rest_create_analysisdata(host = <host>
                                    , port = <port>
                                    , username = <userid>
                                    , password = <pwd>
                                    , outds = analysis_data
                                    , outVarToken = accessToken
                                    , outSuccess = httpSuccess
                                    , outResponseStatus = responseStatus
                                    );
      %put &=accessToken;
      %put &=httpSuccess;
      %put &=responseStatus;
   \endcode

   <b>Sample output:</b>


   \ingroup rgfRestUtils

   \author  SAS Institute Inc.
   \date    2018
*/
%macro core_rest_create_analysisdata(host =
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
                                  , base_date =
                                  , status_cd = Draft
                                  /*, visibility_cd = Private*/
                                  , results_category =
                                  /*, dimensional_point_rk =*/
                                  , dimensional_points = 
                                  , outds = analysis_data
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
      analysisDataBody
      baseDateAttr
      dimensionalPoints
      solution_created_in
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

   /* Process Base_Date parameter (if available) */
   %if(%sysevalf(%superq(base_date) ne, boolean)) %then %do;
      /* Check that the base_date parameter has the format yyyy-mm-ddZ */
      %if(not %sysfunc(prxmatch(/^\d{4}-\d{2}-\d{2}$/, %superq(base_date)))) %then %do;
         %put NOTE: parameter base_date = &base_date. is not in the expected format yyyy-mm-dd.;
         /* Strip the quotes (in case the date is in format "DDMMMYYYY"d or 'DDMMMYYYY'd */
         %let base_date = %sysfunc(prxchange(s/("(\w+)"d)|('(\w+)'d)/$2$4/i, -1, %superq(base_date)));
         /* Attempt to parse the date string and convert it into yyyy-mm-dd format */
         %let base_date = %sysfunc(inputn(&base_date., anydtdte.), yymmddd10.);
         %if(not %sysfunc(prxmatch(/\d{4}-\d{2}-\d{2}/, %superq(base_date)))) %then %do;
            %put ERROR: failed to parse the date parameter.;
            %return;
         %end;
      %end;

      %let baseDateAttr = , "baseDate": "&base_date.Z";
   %end;
      
 

   /* ************************************************************************************** */
   /* Create the analysis data instance                                                      */
   /* ************************************************************************************** */

   %if(%sysevalf(%superq(dimensional_points) ne, boolean)) %then
      %let dimensionalPoints = , "classification": "default": [&dimensional_points.];

   /*%if(%sysevalf(%superq(solution_created_in) ne, boolean)) %then
      %let solutionCreatedIn = , "solutionCreatedIn": "&solution_created_in.";*/

   /* Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./analysisData;

   %if(%sysevalf(%superq(results_category) ne, boolean)) %then
      %let results_category = , "resultsCategoryCd": "&results_category.";


   /* Request body */
   %let analysisDataBody =
      {"name": "&name."
       , "description": "&description."
       , "changeReason": "batch change by core_rest_create_analysisdata"
       , "customFields": {
            "statusCd": "%upcase(&status_cd.)"
            /*, "visibilityStatusCd": "&visibility_cd."*/
            &results_category.
            &baseDateAttr.
            /*&solutionCreatedIn.*/
         }
       &dimensionalPoints.
      }
   ;
   %put qwerty;
   %put &=analysisDataBody.;

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
                     , body = %bquote(&analysisDataBody.)
                     , contentType = application/json
                     , parser = sas.risk.irm.rgf_rest_parser.rmcRestAnalysisData
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
