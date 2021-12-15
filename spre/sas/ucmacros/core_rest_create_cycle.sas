 /*
  Copyright (C) 2019 SAS Institute Inc. Cary, NC, USA
 */

 /**
    \file 
\anchor core_rest_create_cycle

   \brief   Create an instance of Cycle Object in SAS Risk Cirrus Objects

   \param [in] host Host url, including the protocol
   \param [in] server Name of the Web Application Server that provides the REST service (Default: riskCirrusObjects)
   \param [in] solution Solution identifier (Source system code) for Cirrus Core content packages (Default: currently blank)
   \param [in] perspective Perspective identifier for Cirrus content packages (Default: <null>)
   \param [in] port Server port (Default: 443)
   \param [in] logonHost (Optional) Host/IP of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app host/ip is the same as the host/ip in the url parameter 
   \param [in] logonPort (Optional) Port of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app port is the same as the port in the url parameter
   \param [in] username Username credentials
   \param [in] password Password credentials: it can be plain text or SAS-Encoded (it will be masked during execution).
   \param [in] authMethod: Authentication method (accepted values: BEARER). (Default: BEARER).
   \param [in] client_id The client id registered with the Viya authentication server. If blank, the internal SAS client id is used (only if GRANT_TYPE = password).
   \param [in] client_secret The secret associated with the client id.
   \param [in] cycleId Unique identifier string for the cycle object
   \param [in] name (Optional, default value is Cycle Created by Macro) Name of the instance of the Cirrus object that is created with this REST request
   \param [in] description (Optional, default value depends on solution) Description of the instance of the Cirrus object that is created with this REST request
   \param [in] base_date (Optional, default value depends on solution) Value of the Base Date field of the instance of the Cirrus object that is created with this REST request
   \param [in] coreVersionNm (Optional, default value depends on solution) Value of the Cirrus Core Version field of the instance of the Cirrus object that is created with this REST request
   \param [in] versionNm (Optional, default value depends on solution) Version of the product running the analysis cycle
   \param [in] entityId (Optional, default value depends on solution) Entity whose data is used for the calculations
   \param [in] initialRunFlg (Optional, does not apply to all Cirrus Solutions, default value depends on solution) <i>true</i> if user is linking cycle to previous analysis data, <i>false</i> if not
   \param [in] cycleStartDt (Optional) The start date of the cycle.  Specify with this format: YYYY-MM-DDZ:  e.g. 2021-12-01Z
   \param [in] cycleEndDt (Optional) The end date of the cycle.  Specify with this format: YYYY-MM-DDZ:  e.g. 2021-12-31Z
   \param [in] objectLinks Allows user to link cycle to workflow templates, analysis data, etc. when applicable
   \param [in] dimensional_points (Optional) List of dimensional point rk values to use for the dimensional area of the output object.  Formatted as a comma-separated list of integers: e.g. [10000, 10001, 100002].
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [in] FuncCurrency (Optional, default value depends on solution) Value of the functional currency
   \param [out] outds Name of the output table (Default: cycle_info)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)


    \details
    This macro sends a POST request to <b><i><host>:<port>/riskCirrusObjects/objects/cycles</i></b> and creates an instance in Cirrus Cycle object \n
    \n
    See \link core_rest_get_request.sas \endlink for details about how to send POST requests and parse the response.


    <b>Example:</b>

   1) Set up the environment (set SASAUTOS and required LUA libraries).  Assumes the spre folder is under /core_core_code
   \code
      %let core_root_path=/core_core_code;
      option insert = (
         SASAUTOS = (
            "&core_root_path./spre/sas/ucmacros"
            )
         );
      filename LUAPATH ("&core_root_path./spre/lua");
   \endcode

    2) Send a Http GET request and parse the JSON response into the output table WORK.result
    \code
      %let accessToken =;
      %core_rest_create_cycle(host = <host>
                           , server = riskCirrusObjects
                           , solution =
                           , perspective = cecl
                           , port = <port>
                           , username = <username>
                           , password = <password>
                           , authMethod = bearer
                           , client_id =
                           , client_secret =
                           , cycleId = cycle1
                           , name = cycle from macro
                           , description = cycle from macro desc
                           , versionNm = cecl.2019.07
                           , baseDt = 2018-12-31
                           , entityId = SASBank_2
                           , initialRunFlg = true
                           , objectLinks = %bquote({"linkTypeId": "wfTemplate_cycle", "businessObject1": 10000})
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

%macro core_rest_create_cycle(host =
                     , server = riskCirrusObjects
                     , solution =
                     /*, perspective =*/
                     , port = 443
                     , logonHost =
                     , logonPort =
                     , username =
                     , password =
                     , authMethod = bearer
                     , client_id =
                     , client_secret =
                     , name = Cycle Created by Macro
                     , outds = cycle_info
                     , cycleId =
                     , description =
                     , versionNm =
                     , baseDt =
                     , coreVersionNm =
                     , entityId =
                     , initialRunFlg =
                     , cycleStartDt =
                     , cycleEndDt =
                     , FuncCurrency = 
                     , statusCd =
                     , objectLinks =
                     , dimensional_points = 
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
      requestUrlUI
   ;

   /* Check if the cycle already exists */
   %if %sysevalf(%superq(cycleId) ne, boolean) %then %do;
      %let &outVarToken. =;
      %let httpSuccess = 0;
      %let responseStatus =;
      %core_rest_get_cycle(filter = filter=eq(objectId,%22&cycleId.%22)
                              , host = &host.
                              , solution = &solution.
                              , port = &port.
                              , logonHost = &logonHost.
                              , logonPort = &logonPort.
                              , username = &username.
                              , password = &password.
                              , outds = existing_cycles
                              , outVarToken = &outVarToken.
                              , outSuccess = httpSuccess
                              , outResponseStatus = responseStatus
                              );
      /* Error and exit if the cycle already exists */
      %if(%rsk_attrn(existing_cycles, NLOBS) gt 0) %then %do;
         %put ERROR: Cycle already exists with ID &cycleId.. Aborting execution..;
         %abort cancel;
      %end;
   %end;
   
   /* If the dimensional_points parameter is empty but perspective exists, get the corresponding dim point */
   /*%if(%sysevalf(%superq(dimensional_points) eq,boolean) and %sysevalf(%superq(perspective) ne, boolean)) %then %do;
      %let dim_points=;
      %irmc_get_dim_point_from_groovy(query_type = emptyLocationWithPerspectiveNodes
                                    , perspective_id = &perspective.
                                    , outVar = dim_points
                                    , host = &host.
                                    , solution = &solution.
                                    , port = &port.
                                    , username = &username.
                                    , password = &password.
                                    , outVarToken = &outVarToken.
                                    , outSuccess = httpSuccess
                                    , outResponseStatus = responseStatus
                                    );
      %let dimensional_points =&dim_points.;
   %end;*/

   filename cycle1 temp;
   data _null_;
      file cycle1;
      put "{""name"": ""&name.""";
      put "  , ""description"": ""&description.""";
      put "  , ""changeReason"": ""batch change by core_rest_create_cycle""";
      %if(%sysevalf(%superq(dimensional_points) ne, boolean)) %then %do;
         put "  , ""classification"": ""default"": [&dimensional_points.]";
      %end;
      %if(%sysevalf(%superq(cycleId) ne, boolean)) %then %do;
         put "  , ""objectId"": ""&cycleId.""";
      %end;
      put "  , ""customFields"": {";
        /*%if(%sysevalf(%superq(perspective) ne, boolean)) %then %do;
           put "        ""solutionCreatedIn"": ""%upcase(&perspective.)"",";
        %end;*/
        %if(%sysevalf(%superq(initialRunFlg) ne, boolean)) %then %do;
           put "     ""initialRunFlg"": &initialRunFlg.,";
        %end;
        %if(%sysevalf(%superq(cycleStartDt) ne, boolean)) %then %do;
           put "     ""cycleStartDt"": ""&cycleStartDt."",";
        %end;
        %if(%sysevalf(%superq(cycleEndDt) ne, boolean)) %then %do;
           put "     ""cycleEndDt"": ""&cycleEndDt."",";
        %end;
        %if(%sysevalf(%superq(entityId) ne, boolean)) %then %do;
           put "     ""entityId"": ""&entityId."",";
        %end;
         %if( %sysevalf(%superq(FuncCurrency) ne ., boolean) and %sysevalf(%superq(FuncCurrency) ne, boolean) ) %then %do;
            put "     ""funcCurrency"": ""&FuncCurrency."",";
         %end;
         %if(%sysevalf(%superq(statusCd) ne, boolean)) %then %do;
           put "        ""statusCd"": ""%upcase(&statusCd.)"",";
         %end;
        put "     ""versionNm"": ""&versionNm."", ""baseDt"": ""&baseDt."", ""coreVersionNm"": ""&coreVersionNm.""}}";
   run;

   %let requestUrl = &host.:&port./&server./objects/&solution./cycles;

   %core_rest_request(url = &requestUrl.
            , method = POST
            , logonHost = &logonHost.
            , logonPort = &logonPort.
            , username = &username.
            , password = &password.
            , headerIn = Accept:application/json
            , body = cycle1
            , parser = sas.risk.irm.rgf_rest_parser.rmcRestCycle
            , outds = &outds.
            , headerOut =
            , outVarToken = &outVarToken.
            , outSuccess = &outSuccess.
            , outResponseStatus = &outResponseStatus.
            , debug = &debug.
            , logOptions = &logOptions.
            , restartLUA = &restartLUA.
            , clearCache = &clearCache.
            );

   %if &httpSuccess ne 1 %then %do;
      %put ERROR: Execution stopped due to errors. Cycle was not created correctly.;
      %abort cancel;
   %end;

   %if %upcase(&debug) ne TRUE %then %do;
      filename cycle1;
   %end;
   
   /* Get cycle key */
   data _null_;
      set &outds.;
      call symputx('key', key);
   run;

   /* objectLinks */
   %if(%sysevalf(%superq(objectLinks) ne, boolean)) %then %do;
      filename objLinks temp;
      data _null_;
         length _temp $ 32000;
         file objLinks;
         _temp = symget('objectLinks');
         put _temp;
      run;

      libname objLinks json fileref=objLinks noalldata nrm;
      
      data _null_;
         length businessObject1 businessObject2 $64;
         set objLinks.root end=last;
         call symputx(catt("linkTypeId_", _n_), linkTypeId, "L");
         call symputx(catt("business_object1_", _n_), coalescec(businessObject1, "&key."), "L");
         call symputx(catt("business_object2_", _n_), coalescec(businessObject2, "&key."), "L");
         if last then call symputx("num_links", _n_, "L");
      run;
         
      %do i = 1 %to &num_links.;

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
                                        , collectionName = cycles
                                        , collectionObjectKey = &key.
                                        , business_object1 = &&&business_object1_&i..
                                        , business_object2 = &&&business_object2_&i..
                                        , link_type = &&&linkTypeId_&i..
                                        , outds = objectLink&i.
                                        , outVarToken = &outVarToken.
                                        , outSuccess = &outSuccess.
                                        , outResponseStatus = &outResponseStatus.
                                        , debug = &debug.
                                        , logOptions = &logOptions.
                                        , restartLUA = &restartLUA.
                                        , clearCache = &clearCache.
                );

         %if &httpSuccess ne 1 %then %do;
            %put ERROR: Execution stopped due to errors.;
            %abort cancel;
         %end;
      %end;
      
      %if %upcase(&debug) ne TRUE %then %do;
         filename objLinks;
         libname objLinks;
      %end;

   %end; /* end objectLinks */

%mend;