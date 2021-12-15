/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file

   \brief   Deletes a link instance between two objects of the SAS Risk Cirrus Objects

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
   \param [in] linkInstanceKeys Space separated list of linkInstance keys to delete.
   \param [in] linkType Alternative method for searching the linkInstance objects to delete. Used if linkInstanceKeys parameter is blank.
   \param [in] filter optional filter condition to further subset the list of linkInstance objects to delete. Used if linkInstanceKeys parameter is blank.
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table that contains the link_instance information (Default: link_instance)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a DELETE request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/linkInstances</i></b> and deletes a link instance in Cirrus  \n
   See \link core_rest_request.sas \endlink for details about how to send DELETE requests and parse the response.
   \n
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

   2) Delete all linkInstances of type dataDef_analysisData_rptmart where the dataDefinition (businessObject1) is the object with key = 10000
   \code
      %let accessToken =;
      %core_rest_delete_link_insts(host = <host>
                                     , port = <port>
                                     , username = <userid>
                                     , password = <pwd>
                                     , linkType = dataDef_analysisData_rptmart
                                     , filter = businessObject1=10000
                                     , outds = deleted_link_instances
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
   \date    2020
*/
%macro core_rest_delete_link_insts(host =
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
                                     , linkInstanceKeys =
                                     , linkType =
                                     , linkInstanceFilter = 
                                     , outds = updated_link_instances
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
      quoted_link_instance_keys
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

   %if %sysevalf(%superq(collectionName) eq, boolean) %then %do;
      %put ERROR: The collectionName parameter must be specified;
      %return;
   %end;
   
   %if %sysevalf(%superq(collectionObjectKey) eq, boolean) %then %do;
      %put ERROR: The collectionObjectKey parameter must be specified;
      %return;
   %end;
   
   /* Retrieve the link instance keys if parameter linkInstanceKeys has not been specified */
   %if %sysevalf(%superq(linkInstanceKeys) =, boolean) %then %do;
   
      %if %sysevalf(%superq(linkType) =, boolean) %then %do;
         %put ERROR: Input parameter linkType is required when parameter linkInstanceKeys is blank.;
         %return;
      %end;

      /* ****************************************** */
      /* Get the Linkinstances of the given type    */
      /* ****************************************** */

      /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
      option nomlogic nosymbolgen;
      /* Send the REST request */
      %core_rest_get_link_instances(host = &host
                                       , solution = &solution.
                                       , port = &port.
                                       , logonHost = &logonHost.
                                       , logonPort = &logonPort.
                                       , username = &username.
                                       , password = &password.
                                       , authMethod = &authMethod.
                                       , client_id = &client_id.
                                       , client_secret = &client_secret.
                                       , collectionName = &collectionName.
                                       , collectionObjectKey = &collectionObjectKey.
                                       , linkType = &linkType.
                                       , logSeverity = ERROR
                                       , linkInstanceFilter = &linkInstanceFilter.
                                       , outds = _tmp_link_instances_
                                       , outVarToken = &outVarToken.
                                       , outSuccess = &outSuccess.
                                       , outResponseStatus = &outResponseStatus.
                                       , debug = &debug.
                                       , logOptions = &oldLogOptions.
                                       , restartLUA = &restartLUA.
                                       , clearCache = &clearCache.
                                       );

      /* Exit in case of errors */
      %if(not &&&outSuccess.. or not %rsk_dsexist(_tmp_link_instances_)) %then
         %return;
      
      data _null_;
         length link_instance_keys $ 32000;
         set _tmp_link_instances_ end=last;
         retain link_instance_keys "";
         link_instance_keys=catt(link_instance_keys, ' "', key, '"');
         if last then call symputx("quoted_link_instance_keys", link_instance_keys, "L");
      run;

   %end; /* %if %sysevalf(%superq(link_instance_key) =, boolean) */
   %else %do;
      %let quoted_link_instance_keys=%sysfunc(prxchange(s/([\w+-]+)/"$1" /i, -1, %bquote(&linkInstanceKeys.)));
   %end;


   /* ********************************************************************** */
   /*  Get all of the object instance's current link instances and eTag      */
   /* ********************************************************************** */

   /* Set the request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./&collectionName./&collectionObjectKey.;
   filename _hout_ temp;
   filename _fout_ temp;
   
   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   
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
                     , headerOut = _hout_
                     , fout = _fout_
                     , parser = 
                     , outVarToken = &outVarToken.
                     , outSuccess = &outSuccess.
                     , outResponseStatus = &outResponseStatus.
                     , debug = &debug.
                     , logOptions = &logOptions.
                     , restartLUA = &restartLUA.
                     , clearCache = &clearCache.
                     );
  
   /* Exit in case of errors */
   %if(not &&&outSuccess..) %then
      %return;
      
   /* Get the object instance's eTag from the response header - needed for PUT/PATCH requests to riskCirrusObjects */
   %let etag =;
   data _null_;
       length Header $ 50 Value $ 200;
       infile _hout_ dlm=':';
       input Header $ Value $;
       if Header = 'ETag';
       call symputx("etag", Value);
   run;
   
   
   /* ************************************************************************************** */
   /*  Build the request header and body                                                     */
   /* ************************************************************************************** */
   /* Build header for the PATCH request*/
   filename _hin_ temp;
   data _null_;
       file _hin_;
       put 'Accept: application/json';
       put 'If-Match: "' &etag. '"';
   run;
   
   /* Build request body for the PATCH request */
   libname resp_lib json fileref=_fout_ noalldata nrm ordinalcount=NONE;
   filename _body_ temp;
   
   %if (not %rsk_dsexist(resp_lib.objectlinks)) %then %do;
      %put WARNING: No link instances were found for &collectionName. object (key=&collectionObjectKey.);
      %return;
   %end;
   
   data outds;
   
      set resp_lib.objectlinks (where=(key not in (&quoted_link_instance_keys.))) end=last;
      
      file _body_;
      if _n_=1 then do;
         put "{";
         put "   ""changeReason"": ""Batch change by macro core_rest_delete_link_insts.sas"",";
         put "   ""objectLinks"": [";
      end;

      /* Add in all link instances except for those we're deleting */
      put "      {";
         put "         ""key"": """ key $CHAR. """,";
         put "         ""creationTimeStamp"": """ creationTimeStamp $CHAR. """,";
         put "         ""modifiedTimeStamp"": """ modifiedTimeStamp $CHAR. """,";
         put "         ""createdBy"": """ createdBy $CHAR. """,";
         put "         ""modifiedBy"": """ modifiedBy $CHAR. """,";
         put "         ""sourceSystemCd"": """ sourceSystemCd $CHAR. """,";
         put "         ""objectId"": """ objectId $CHAR. """,";
         put "         ""linkType"": """ linkType $CHAR. """,";
         put "         ""businessObject1"": """ businessObject1 $CHAR. """,";
         put "         ""businessObject2"": """ businessObject2 $CHAR. """";
      
      if not last then do;
         put "      },";
      end;
      else do;
         put "      }";
         put "   ]";
         put "}";
      end;
      
   run;
   
   /* Clear references if we're not debugging */
   %if %upcase(&debug) ne TRUE %then %do;
      filename _hout_;
      filename _fout_;
      libname resp_lib;
   %end;
  
  
   /* ************************************************************************************ */
   /*  Recreate the link instances for the object, with the deleted link instances removed */
   /* ************************************************************************************ */

   /* Set the Request URL */
   %let requestUrl = &host:&port./&server./objects/&solution./&collectionName./&collectionObjectKey.;

   /* Temporary disable mlogic and symbolgen options to avoid printing of userid/pwd to the log */
   option nomlogic nosymbolgen;
   /* Send the REST request */
   %core_rest_request(url = &requestUrl.
                     , method = PATCH
                     , logonHost = &logonHost.
                     , logonPort = &logonPort.
                     , username = &username.
                     , password = &password.
                     , authMethod = &authMethod.
                     , client_id = &client_id.
                     , client_secret = &client_secret.
                     , headerIn = _hin_
                     , body = _body_
                     , contentType = application/json
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
                     
      /* Exit in case of errors */
   %if(not &&&outSuccess..) %then %do;
      %return;
   %end;
   %else %do;
      data &outds.;
         length objectKey $ 64; 
         set outds;
         objectKey="&collectionObjectKey.";
      run;
   %end;
      
      
%mend;
