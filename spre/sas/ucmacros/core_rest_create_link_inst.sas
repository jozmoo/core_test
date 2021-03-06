/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_create_link_inst

   \brief   Create a link instance between two objects of the SAS Risk Cirrus Objects

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
   \param [in] link_instance_id A unique Id value for the link instance. suggested design - LinkType Id ||_ ||Object 1 rk ||_|| Object 2 rk
   \param [in] link_type Link Type to used for linking the two objects
   \param [in] business_object1 Key of business object 1 to use in the link instance
   \param [in] business_object2 Key of business object 2 to use in the link instance
   \param [in] debug True/False. If True, debugging informations are printed to the log (Default: false)
   \param [in] logOptions Logging options (i.e. mprint mlogic symbolgen ...)
   \param [in] restartLUA. Flag (Y/N). Resets the state of Lua code submission for a SAS session if set to Y (Default: Y)
   \param [in] clearCache Flag (Y/N). Controls whether the connection cache is cleared across multiple proc http calls. (Default: Y)
   \param [out] outds Name of the output table that contains the link_instance information (Default: link_instance)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a POST request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/linkInstances</i></b> and creates a link instance in Cirrus  \n
   See \link core_rest_request.sas \endlink for details about how to send POST requests and parse the response.
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

   2) Send a Http GET request and parse the JSON response into the output table WORK.link_instance
   \code
      %let accessToken =;
      %core_rest_create_link_inst(host = <host>
                                     , port = <port>
                                     , username = <userid>
                                     , password = <pwd>
                                     , link_instance_id = analysisRun_model_B1_B2
                                     , link_type = analysisRun_model
                                     , business_object1 = B1
                                     , business_object2 = B2
                                     , outds = link_instance
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
%macro core_rest_create_link_inst(host =
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
                                  , business_object1 =
                                  , business_object2 =
                                  , link_instance_id =
                                  , link_type =
                                  , linkSourceSystemCd = RCC
                                  , outds = link_instance
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
      linkInstanceBody
      link_type_key
      linkInstanceId
      businessObject1
      businessObject2
      add_existing_links_flag
      link_already_exists_flag
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

   /* ************************************************************************************** */
   /* Get the LinkType key                                                                   */
   /* ************************************************************************************** */

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
                                , filter = objectId=&link_type.
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

   /* Get the linkType key */
   data _null_;
      set _tmp_link_type_;
      call symputx("link_type_key", key, "L");
   run;

   /* Create a unique (enough) linkInstanceId */
   %if(%sysevalf(%superq(linkInstanceId) =, boolean)) %then
      %let linkInstanceId = %sysfunc(uuidgen());
   %else
      %let linkInstanceId = &link_instance_id.;


   /* ******************************************************************************** */
   /*  Get all of the object instance's current link instances (of any link type)      */
   /* ******************************************************************************** */

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
   
   %let add_existing_links_flag=0;
   %if %rsk_dsexist(resp_lib.objectlinks) %then
      %let add_existing_links_flag=1;
   
   %let businessObject1=%sysfunc(coalescec(&business_object1., &collectionObjectKey.));
   %let businessObject2=%sysfunc(coalescec(&business_object2., &collectionObjectKey.));
   
   %let link_already_exists_flag=0;
   data _null_;
   
      %if &add_existing_links_flag. %then %do;
      
         set resp_lib.objectlinks end=last;
         
         if linkType="&link_type_key." and businessObject1="&businessObject1." and businessObject2="&businessObject2." then do;
            call symput("link_already_exists_flag", 1);
            stop;
         end;
         
      %end;

      file _body_;
      if _n_=1 then do;
         put "{";
         put "   ""changeReason"": ""Batch change by macro core_rest_create_link_inst.sas"",";
         put "   ""objectLinks"": [";
      end;

      /* Add the link instances that already existed for the object (if any) */
      %if &add_existing_links_flag. %then %do;
         
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
         put "      },";
         
      %end;
      
      /* Add the new link instance */
      if last or not &add_existing_links_flag. then do;
         put "      {";
         %if(%sysevalf(%superq(linkSourceSystemCd) ne, boolean)) %then %do;
            put "         ""sourceSystemCd"": ""%upcase(&linkSourceSystemCd.)"",";
         %end;
         put "         ""objectId"": ""&linkInstanceId."",";
         put "         ""linkType"": ""&link_type_key."",";
         put "         ""businessObject1"": ""&businessObject1."",";
         put "         ""businessObject2"": ""&businessObject2.""";
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
   
   /* If the link instance already exists then exit */
   %if &link_already_exists_flag. %then %do;
      %put NOTE: For object &collectionObjectKey., a link instance already exists with link type &link_type, business object 1 key &businessObject1., and business object 2 key &businessObject2..;
      %return;
   %end;
   
   
   /* ************************************************************************************** */
   /*  Create the link instance                                                              */
   /* ************************************************************************************** */

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

%mend;
