/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_del_analysis_data

   \brief   Delete Analysis Data instance from SAS Risk Cirrus Objects

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
   \param [in] key Instance key of the Analysis data object to delete.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a DELETE request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/&solution./analysisData</i></b> to delete the requested object. \n
   The status of the operation is returned in the macro variable specified through the input parameter outSuccess.

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

   2) Send a Http DELETE request and parse the JSON response into the output table WORK.analysis_data
   \code
      %let accessToken =;
      %core_rest_del_analysis_data(host = <host>
                                      , port = <port>
                                      , username = <userid>
                                      , password = <pwd>
                                      , key = <key>
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
%macro core_rest_del_analysis_data(host =
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

   %if(%sysevalf(%superq(key) eq, boolean)) %then %do;
      %put ERROR: Required input parameter KEY is missing. Skipping execution..;
      %return;
   %end;


   /* Set the base Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./analysisData/&key.;


   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   /* Send the REST request */
   %core_rest_request(url = &requestUrl.
                     , method = DELETE
                     , logonHost = &logonHost.
                     , logonPort = &logonPort.
                     , username = &username.
                     , password = &password.
                     , authMethod = &authMethod.
                     , client_id = &client_id.
                     , client_secret = &client_secret.
                     , parser =
                     , outVarToken = &outVarToken.
                     , outSuccess = &outSuccess.
                     , outResponseStatus = &outResponseStatus.
                     , debug = &debug.
                     , logOptions = &oldLogOptions.
                     , restartLUA = &restartLUA.
                     , clearCache = &clearCache.
                     );

%mend;
