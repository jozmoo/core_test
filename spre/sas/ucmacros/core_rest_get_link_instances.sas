/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_get_link_instances
   \brief   Retrieve the Link Instance(s) registered in SAS Risk Cirrus Objects

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
   \param [in] key Instance key of the Cirrus object that is fetched with this REST request. If no Key is specified, the records are fetched using filter parameters.
   \param [in] filter Filters to apply on the GET request when no value for key is specified.
   \param [in] start Specify the starting point of the records to get. Start indicate the starting index of the subset. Start SHOULD be a zero-based index. The default start SHOULD be 0. Applicable only when filter is used.
   \param [in] limit Limit controls the maximum number of items to get from the start position (Default = 1000). Applicable only when filter is used.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table that contains the master risk scenarios (Default: master_risk_scenario)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a GET request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/&solution./linkInstances</i></b> and collects the results in the output table. \n
   See \link core_rest_request.sas \endlink for details about how to send GET requests and parse the response.

   <b>Example:</b>

   1) Set up the environment (set SASAUTOS and required LUA libraries)
   \code
      %let source_path = <Path to the root folder of the Federated Content Area (root folder, excluding the Federated Content folder)>;
      %let fa_id = <Name of the Federated Area Content folder>;
      %include "&source_path./&fa_id./source/sas/ucmacros/irm_setup.sas";
      %irm_setup(source_path = &source_path.
                , fa_id = &fa_id.
                );
   \endcode

   2) Send a Http GET request and parse the JSON response into the output table WORK.link_instances
   \code
      %let accessToken =;
      %core_rest_get_link_instances(host = <host>
                                       , port = <port>
                                       , username = <userid>
                                       , password = <pwd>
                                       , outds = link_instances
                                       , outVarToken = accessToken
                                       , outSuccess = httpSuccess
                                       , outResponseStatus = responseStatus
                                       );
      %put &=accessToken;
      %put &=httpSuccess;
      %put &=responseStatus;
   \endcode

   <b>Sample output:</b>

   | sourceSystemCd | linkInstanceId    | businessObject1 | isDisabled | businesscollectionNameNm1 | businessObject2 | lastModifiedDttm         | businesscollectionNameNm2 | itemsCount | linkType | creator | modifiedDttm             | key   |
   |----------------|-------------------|-----------------|------------|-----------------------|-----------------|--------------------------|-----------------------|------------|----------|---------|--------------------------|-------|
   | RMC            | 10105_10000_10000 | 10000           | FALSE      | customObject225       | 10000           | 2019-11-13T17:41:43.957Z | customObject214       | 8          | 10105    | 10000   | 2019-11-13T17:41:43.957Z | 10000 |
   | RMC            | 10105_10000_10001 | 10000           | FALSE      | customObject225       | 10001           | 2019-11-13T17:41:43.965Z | customObject214       | 8          | 10105    | 10000   | 2019-11-13T17:41:43.965Z | 10001 |
   | RMC            | 10021_10005_10042 | 10005           | FALSE      | customObject220       | 10042           | 2019-11-14T20:03:21.177Z | customObject209       | 8          | 10021    | 10000   | 2019-11-14T20:03:21.177Z | 10016 |

   \ingroup rgfRestUtils

   \author  SAS Institute Inc.
   \date    2018
*/
%macro core_rest_get_link_instances(host =
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
                                     , collectionName =
                                     , collectionObjectKey =
                                     , objectFilter =
                                     , linkType =
                                     , linkTypeKey =
                                     , linkInstanceFilter =
                                     , logSeverity = WARNING
                                     , start =
                                     , limit = 1000
                                     , outds = link_instances
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
      object_key
      linkType_key
   ;

   /* Set the required log options */
   %if(%length(&logOptions.)) %then
      options &logOptions.;
   ;

   /* Get the current value of mlogic and symbolgen options */
   %local oldLogOptions;
   %let oldLogOptions = %sysfunc(getoption(mlogic)) %sysfunc(getoption(symbolgen));

   %if(%length(&port.) = 0) %then
      %let port = 443;
   
   %if(%length(&limit.) = 0) %then
      %let limit = 1000;
      
   %if %sysevalf(%superq(collectionName) eq, boolean) %then %do;
      %put ERROR: The collectionName parameter must be specified;
      %return;
   %end;
   
   /* Retrieve the object key if the objectFilter parameter has been specified */
   %if %sysevalf(%superq(objectFilter) ne, boolean) %then %do;
   
      %let requestUrl = &host:&port./&server./objects/&solution./&collectionName.?&objectFilter.;
      filename resp temp;
      
      /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
      option nomlogic nosymbolgen;
      /* Send the REST request */
      %core_rest_request(url = &requestUrl.
                        , method = GET
                        , logonHost = &logonHost.
                        , logonPort = &logonPort.
                        , username = &username.
                        , password = &password.
                        , authMethod = &authMethod
                        , client_id = &client_id.
                        , client_secret = &client_secret.
                        , fout = resp
                        , parser =
                        , outVarToken = &outVarToken.
                        , outSuccess = &outSuccess.
                        , outResponseStatus = &outResponseStatus.
                        , debug = &debug.
                        , logOptions = &oldLogOptions.
                        , restartLUA = &restartLUA.
                        , clearCache = &clearCache.
                        );
                        
      /* Exit in case of errors */
      %if(not &&&outSuccess..) %then
         %return;
         
      libname resp_lib json fileref=resp noalldata nrm;
      
      %let num_keys=0;
      data _null_;
         set resp_lib.items end=last;
         call symputx("object_key", key, "L");
         if last then call symputx("num_keys", _N_, "L"); 
      run;
      
      %if %upcase(&debug) ne TRUE %then %do;
         libname resp_lib;
      %end;
      
      /*Exit if no object instances met the objectFilter*/  
      %if "&object_key"="." %then %do;
         %put ERROR: No instances were found for object type "&collectionName" with filter "&objectFilter.";
         %return;
      %end;
      
      /*Exit if 2 or more object instances met the objectFilter*/      
      %if &num_keys. ne 1 %then %do;
         %put ERROR: More than 1 instance was found for object type "&collectionName" with filter "&objectFilter.";
         %return;
      %end;
      
   %end; /* %if %sysevalf(%superq(objectFilter) ne, boolean) */
   %else %if %sysevalf(%superq(collectionObjectKey) ne, boolean) %then %do;
      %let object_key=&collectionObjectKey.;
   %end;
   %else %do;
      %put ERROR: Either the collectionObjectKey or objectFilter parameter must be provided;
      %return;
   %end;
   

   /* Retrieve the linkType key if the linkType parameter has been specified */
   %if %sysevalf(%superq(linkType) ne, boolean) %then %do;
   
      %if %sysevalf(%superq(logSeverity) =, boolean) %then
         %let logSeverity = WARNING;
      %else
         %let logSeverity = %upcase(&logSeverity.);
      
      /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
      option nomlogic nosymbolgen;
      /* Send the REST request */
      %core_rest_get_link_types(host = &host
                                   , solution = &solution.
                                   , port = &port.
                                   , logonHost = &logonHost.
                                   , logonPort = &logonPort.
                                   , username = &username.
                                   , password = &password.
                                   , authMethod = &authMethod.
                                   , client_id = &client_id.
                                   , client_secret = &client_secret.
                                   , filter = objectId=&linkType.
                                   , outds = _tmp_link_type_
                                   , outVarToken = &outVarToken.
                                   , outSuccess = &outSuccess.
                                   , outResponseStatus = &outResponseStatus.
                                   , debug = &debug.
                                   , logOptions = &oldLogOptions.
                                   , restartLUA = &restartLUA.
                                   , clearCache = &clearCache.
                                   );

      /* Exit in case of errors */
      %if(not &&&outSuccess.. or not %rsk_dsexist(_tmp_link_type_)) %then
         %return;

      /* Check if we found the link types */
      %if(%rsk_attrn(_tmp_link_type_, nobs) = 0) %then %do;
         %put ERROR: Could not find LinkType objects of type &linkType..;
         %return;
      %end;
      %else %do;
         /* Get the linkType key */
         data _null_;
            set _tmp_link_type_;
            call symputx("linkType_key", key, "L");
         run;
      %end;
      
   %end; /* %if %sysevalf(%superq(linkType) ne, boolean) */
   %else %if %sysevalf(%superq(linkTypeKey) ne, boolean) %then %do;
      %let linkType_key=&linkTypeKey.;
   %end;
   %else %do;
      %put ERROR: Either the linkTypeKey or linkType parameter must be provided;
      %return;
   %end;

   /* Set the base Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./linkInstances;
   %let requestUrl = &host:&port./&server./objects/&solution./&collectionName./&object_key./linkInstances/&linkType_key.;
   
   /*add start/limit and linkInstanceFilter filters*/
   %let requestUrl=&requestUrl.?limit=&limit.;
   %if(%sysevalf(%superq(start) ne, boolean)) %then
      %let requestUrl = &requestUrl.%str(&)start=&start.;
   %if(%sysevalf(%superq(linkInstanceFilter) ne, boolean)) %then
      %let requestUrl = &requestUrl.%str(&)&linkInstanceFilter.;

   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   /* Send the REST request */
   %core_rest_request(url = &requestUrl.
                     , method = GET
                     , logonHost = &logonHost.
                     , logonPort = &logonPort.
                     , username = &username.
                     , password = &password.
                     , authMethod = &authMethod.
                     , client_id = &client_id.
                     , client_secret = &client_secret.
                     , parser = sas.risk.irm.rgf_rest_parser.rgfRestLinkInstances
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