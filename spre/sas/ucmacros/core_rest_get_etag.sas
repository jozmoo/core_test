/*
 Copyright (C) 2020 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_get_etag
   \brief   Retrieve the ETag for an Cirrus Object Instance

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
   \param [in] authMethod: Authentication method (accepted values: BEARER). (Default: BEARER).
   \param [in] client_id The client id registered with the Viya authentication server. If blank, the internal SAS client id is used (only if GRANT_TYPE = password).
   \param [in] client_secret The secret associated with the client id.   \param [in] collectionName The name of the collection the object belongs to. e.g. ruleSets, cycles, analysisRuns, etc.
   \param [in] key Instance key of the Cirrus object that is fetched with this REST request.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outEtag Name of the macro variable to hold the eTag for the object
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a GET request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/&solution./&collectionName/&key.</i></b> and retireves the ETag for the returned object. 



   \author  SAS Institute Inc.
   \date    2020
*/
%macro core_rest_get_etag(host =
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
                              , key =
                              , outEtag = 
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
      requiredInputs
      badInputs
      ;
      
   /* Set the required log options */
   %if(%length(&logOptions.)) %then
      options &logOptions.;
   ;

   /* Check inputs */
   %let requiredInputs = host collectionName outEtag key;
   %let badInputs = ;
   %core_check_macrovars_nonempty(varnames=&requiredInputs., outBadVars=badInputs);
   %if %sysevalf(&badInputs. ne %str(), boolean) %then %do;
      %put ERROR: The following variables were not defined but are required by core_rest_get_etag: &badInputs.;
      %return;
   %end;
   
   %if(%length(&port.) = 0) %then
      %let port = 443;

   /* Set the request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./&collectionName./&key.;

   filename _OutHdr temp;
   /* Send the REST request */
   %core_rest_request(url = &requestUrl.
                     , method = GET
                     , logonHost = &logonHost.
                     , logonPort = &logonPort.
                     , username = %superq(username)
                     , password = %superq(password)
                     , authMethod = &authMethod.
                     , client_id = &client_id.
                     , client_secret = &client_secret.
                     , headerOut = _OutHdr
                     , outVarToken = &outVarToken.
                     , outSuccess = &outSuccess.
                     , outResponseStatus = &outResponseStatus.
                     , parser = sas.risk.irm.rgf_rest_parser.rgfRestObjectInfo
                     , debug = &debug.
                     , logOptions = &logOptions.
                     , restartLUA = &restartLUA.
                     , clearCache = &clearCache.
                     );
   /* let the caller macro decide what to do if the call fails */
   %if &&&outSuccess. eq 1 %then %do;
      data _null_;
         length Header $ 50 Value $ 200;
          infile _OutHdr dlm=':';
          input Header $ Value $;
          if Header = 'ETag';
          call symputx("&outEtag.", Value);
      run;
   %end;
   filename _OutHdr clear;
%mend;
