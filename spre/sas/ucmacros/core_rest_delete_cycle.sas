/*
 Copyright (C) 2020 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
   \anchor core_rest_delete_cycle

   \brief Given a cycle key, this macro will delete the associated cycle

   \param [in] host Host url, including the protocol
   \param [in] port Server port (Default: 443)
   \param [in] logonHost (Optional) Host/IP of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app host/ip is the same as the host/ip in the url parameter 
   \param [in] logonPort (Optional) Port of the sas-logon-app service or ingress.  If blank, it is assumed that the sas-logon-app port is the same as the port in the url parameter
   \param [in] server Name of the Web Application Server that provides the REST service (Default: riskCirrusObjects)
   \param [in] solution Solution identifier (Source system code) for Cirrus Core content packages (Default: currently blank)
   \param [in] username Username credentials
   \param [in] password Password credentials: it can be plain text or SAS-Encoded (it will be masked during execution).
   \param [in] authMethod: Authentication method (accepted values: BEARER). (Default: BEARER).
   \param [in] client_id The client id registered with the Viya authentication server. If blank, the internal SAS client id is used (only if GRANT_TYPE = password).
   \param [in] client_secret The secret associated with the client id.
   \param [in] cycleKey The unique key of the cycle to be deleted
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outVarSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
     This macro uses \link core_rest_request.sas \endlink to delete the cycle.
   \n

   \author  SAS Institute Inc.
   \date    2021
*/

%macro core_rest_delete_cycle(host =
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
                              , cycleKey =
                              , debug = false
                              , logOptions =
                              , restartLUA = Y
                              , clearCache = Y
                              , outVarToken = accessToken
                              , outSuccess = httpSuccess
                              , outResponseStatus = responseStatus
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

   %if(%sysevalf(%superq(cycleKey) eq, boolean)) %then %do;
      %put ERROR: Required input parameter cycleKey is missing. Skipping execution..;
      %return;
   %end;

   /* Set the base Request URL */
   %let requestUrl = &host.:&port./&server./objects/&solution./cycles/&cycleKey;


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
                    , headerIn = Accept:application/json
                    , parser =
                    , outds = cycleOut
                    , outVarToken = &outVarToken.
                    , outSuccess = &outSuccess.
                    , outResponseStatus = &outResponseStatus.
                    , debug = &debug.
                    , logOptions = &logOptions.
                    , restartLUA = &restartLUA.
                    , clearCache = &clearCache.
                    );

%mend;