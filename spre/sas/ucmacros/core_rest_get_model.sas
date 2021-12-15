/*
 Copyright (C) 2022 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_get_model

  \brief   Retrieve the Model(s) registered in SAS Risk Cirrus Objects

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
   \param [in] filter Filters to apply on the GET request when no value for key is specified. Example: request GET /models?name=Model1|Model2&engineCd=SAS
   \param [in] start Specify the starting point of the records to get. Start indicate the starting index of the subset. Start SHOULD be a zero-based index. The default start SHOULD be 0. Applicable only when filter is used.
   \param [in] limit Limit controls the maximum number of items to get from the start position (Default = 1000). Applicable only when filter is used.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table that contains the model info (Default: model_info)
   \param [out] outds_params Name of the output table that contains the model params (Default: model_params)
   \param [out] fout_code Fileref for the code in the code editor (Default: fcode)
   \param [out] fout_pre_code Fileref for the code in the Pre-code code editor (Default: fpre)
   \param [out] fout_post_code Fileref for the code in the post-code editor (Default: fpost)
   \param [out] outVarToken Name of the output macro variable which will contain the Access Token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a GET request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/&solution./models</i></b> and collects the results in the output tables. \n
   See \link core_rest_request.sas \endlink for details about how to send GET requests and parse the response.


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

   2) Send a Http GET request and parse the JSON response into the output table WORK.MODEL_INFO and WORK.MODEL_PARAMS
   \code
      %let accessToken =;
      %core_rest_get_model(host = <host>
                              , port = <port>
                              , username = <userid>
                              , password = <pwd>
                              , outds = model_info
                              , outds_params = model_params
                              , fout_code = fcode
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
   \date    2022
*/
%macro core_rest_get_model(host =
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
                              , outds = model_info
                              , outds_params = model_params
                              , fout_code = fcode
                              , fout_pre_code = fpre
                              , fout_post_code = fpost
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
      fref_list
      curr_fref
      default_fref_list
      curr_default_fref
      i
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

   /* Set the base Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./models;

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

   /* List of input fcode* parameters */
   %let fref_list = fout_code fout_pre_code fout_post_code;
   /* List of default fileref in case the provided ones are too long */
   %let default_fref_list = fcode fpre fpost;
   /* Process all fcode* parameters */
   %do i = 1 %to %sysfunc(countw(&fref_list., %str( )));
      /* Extract current parameter name */
      %let curr_fref = %scan(&fref_list., &i., %str( ));
      /* Extract current default fileref value */
      %let curr_default_fref = %scan(&default_fref_list., &i., %str( ));

      %if(%sysevalf(%superq(&curr_fref.) ne, boolean)) %then %do;
         /* Check if the provided value is a fileref */
         %if(%length(%superq(&curr_fref.)) <= 8) %then %do;
            %if(%sysfunc(fileref(&&&curr_fref..)) ne 0) %then %do;
               /* It is not a fileref. Will need to create a temporary file */
               filename &&&curr_fref.. temp;
            %end;
         %end;
         %else %do;
            /* Assuming it is a path. Assign a fileref */
            filename &curr_default_fref. "&&&curr_fref..";
            /* Check if the path exists */
            %if (not %sysfunc(fexist(&curr_default_fref.))) %then %do;
               /* The path does not exist, throw a warning */
               %put WARNING: the specified external file path "&&&curr_fref.." does not exist. A temporary fileref (&curr_default_fref.) will be assigned.;
               /* Assign temporary file */
               %let &curr_fref. = &curr_default_fref.;
               filename &&&curr_fref.. temp;
            %end;
         %end;
      %end;
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
                     , authMethod = &authMethod.
                     , parser = sas.risk.irm.rgf_rest_parser.rmcRestModel
                     , outds = &outds.
                     , arg1 = &outds_params.
                     , arg2 = &fout_code.
                     , arg3 = &fout_pre_code.
                     , arg4 = &fout_post_code.
                     , outVarToken = &outVarToken.
                     , outSuccess = &outSuccess.
                     , outResponseStatus = &outResponseStatus.
                     , debug = &debug.
                     , logOptions = &oldLogOptions.
                     , restartLUA = &restartLUA.
                     , clearCache = &clearCache.
                     );

%mend;
