/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_get_data_def

   \brief   Retrieve the Data Definition(s) registered in SAS Risk Cirrus Objects

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
   \param [in] filter Filters to apply on the GET request when no value for key is specified. Example: request GET /dataDefinitions?name=DataDefinition1|DataDefinition2&riskTypeCd=CREDIT
   \param [in] start Specify the starting point of the records to get. Start indicate the starting index of the subset. Start SHOULD be a zero-based index. The default start SHOULD be 0. Applicable only when filter is used.
   \param [in] limit Limit controls the maximum number of items to get from the start position (Default = 1000). Applicable only when filter is used.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table that contains the allocation schemes (Default: allocation_details)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a GET request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/&solution./dataDefinitions</i></b> and collects the results in the output table. \n
   See \link core_rest_request.sas \endlink for details about how to send GET requests and parse the response.


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

   2) Send a Http GET request and parse the JSON response into the output table WORK.data_definitions
   \code
      %let accessToken =;
      %core_rest_get_data_def(host = <host>
                                , port = <port>
                                , username = <userid>
                                , password = <pwd>
                                , outds = data_definitions
                                , outds_columns = data_definitions_columns
                                , outVarToken = accessToken
                                , outSuccess = httpSuccess
                                , outResponseStatus = responseStatus
                                );
      %put &=accessToken;
      %put &=httpSuccess;
      %put &=responseStatus;
   \endcode

   <b>Sample output:</b>

   |description                  | libref | sourceSystemCd | metaLibraryNm                      | createdDttm              | objectLinks | schemaVersion  | version | engine | dataType | dimensionalPoints | schemaName          | creator | businessCategoryCd | objectId | schemaTypeCd | changeReason | columnInfo                                    | key   | itemsCount | riskTypeCd | dataCategoryCd | name                 | updater |
   |-----------------------------|--------|----------------|------------------------------------|--------------------------|-------------|----------------|---------|--------|----------|-------------------|---------------------|---------|--------------------|----------|--------------|--------------|-----------------------------------------------|-------|------------|------------|----------------|----------------------|---------|
   | Portfolio schema definition | RMCDR  | RMC            | SAS Risk Cirrus Core Core Data Repository | 2019-03-13T19:53:14.449Z |             | rqsst.v09.2019 | 1       | META   |          |                   | st_credit_portfolio | 10000   | ST                 | 10005    | FLAT         | Initial Save | JSON representation of the column definitions | 10005 | 1          | CREDIT     | PORTFOLIO      | Portfolio Definition | 10000   |


   \ingroup rgfRestUtils

   \author  SAS Institute Inc.
   \date    2018
*/
%macro core_rest_get_data_def(host =
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
                                , key =
                                , filter =
                                , start =
                                , limit = 1000
                                , outds = data_definitions
                                , outds_columns = data_definitions_columns
                                , outds_aggregation_config = aggregation_config
                                , outVarToken = accessToken
                                , outSuccess = httpSuccess
                                , outResponseStatus = responseStatus
                                , debug = false
                                , logOptions =
                                , restartLUA = Y
                                , clearCache = Y
                                );

   %local requestUrl;

   /* Set the required log options */
   %if(%length(&logOptions.)) %then
      options &logOptions.;
   ;

   /* Get the current value of mlogic and symbolgen options */
   %local oldLogOptions;
   %let oldLogOptions = %sysfunc(getoption(mlogic)) %sysfunc(getoption(symbolgen));

   %if(%length(&port.) = 0) %then
      %let port = 443;

   /* Set the base Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./dataDefinitions;

   %if(%sysevalf(%superq(key) ne, boolean)) %then
      /* Request the specified resource by the key */
      %let requestUrl = &requestUrl./&key.;
   %else %do;
      /* Add filters (if any) */
      %let requestUrl = &requestUrl.?&filter.;

      /* Set Start and Limit options */
      %if(%sysevalf(%superq(start) ne, boolean)) %then
         %let requestUrl = &requestUrl.%str(&)start=&start.;
      %if(%sysevalf(%superq(limit) ne, boolean)) %then
         %let requestUrl = &requestUrl.%str(&)limit=&limit.;
   %end;

   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   /* Send the REST request */
   %core_rest_request(url = &requestUrl.
                     , method = GET
                     , logonHost = &logonHost.
                     , logonPort = &logonPort.
                     , username = &username.
                     , password = &password.
                     , headerOut = __hout_
                     , authMethod = &authMethod.
                     , client_id = &client_id.
                     , client_secret = &client_secret.
                     , parser = sas.risk.irm.rgf_rest_parser.rmcRestDataDefinition
                     , outds = &outds.
                     , arg1 = &outds_columns.
                     , arg2 = &outds_aggregation_config.
                     , outVarToken = &outVarToken.
                     , outSuccess = &outSuccess.
                     , outResponseStatus = &outResponseStatus.
                     , debug = &debug.
                     , logOptions = &oldLogOptions.
                     , restartLUA = &restartLUA.
                     , clearCache = &clearCache.
                     );

%mend;
