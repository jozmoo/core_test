/*
 Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file 
\anchor core_rest_get_rule_set

   \brief   Retrieve the Rule set(s) registered in SAS Risk Cirrus Objects

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
   \param [out] outds Name of the output table that contains the rule sets information (Default: cycles)
   \param [out] outVarToken Name of the output macro variable which will contain the access token (Default: accessToken)
   \param [out] outSuccess Name of the output macro variable that indicates if the request was successful (&outSuccess = 1) or not (&outSuccess = 0). (Default: httpSuccess)
   \param [out] outResponseStatus Name of the output macro variable containing the HTTP response header status: i.e. HTTP/1.1 200 OK. (Default: responseStatus)

   \details
   This macro sends a GET request to <b><i>\<host\>:\<port\>/riskCirrusObjects/objects/&solution./ruleSets</i></b> and collects the results in the output table. \n
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

   2) Send a Http GET request and parse the JSON response into the output table WORK.rule_set
   \code
      %let accessToken =;
      %core_rest_get_rule_set(host = <host>
                                , port = <port>
                                , username = <userid>
                                , password = <pwd>
                                , outds = rule_set
                                , outVarToken = accessToken
                                , outSuccess = httpSuccess
                                , outResponseStatus = responseStatus
                                );
      %put &=accessToken;
      %put &=httpSuccess;
      %put &=responseStatus;
   \endcode

   <b>Sample output:</b>

   | LOOKUP_KEY | key     | OPERATOR | AGGR_GROUP_BY_VARS | RULE_DESC              | PRIMARY_KEY               | LOOKUP_DATA | RULE_DETAILS | PARENTHESIS | RULE_REPORTING_LEV1  | RULE_ID     | LOOKUP_TABLE | RULE_COMPONENT | RULE_NAME              | RULE_TYPE        | RULE_REPORTING_LEV2 | AGGR_VAR_NM | RULE_WEIGHT | ruleSetKey | ruleSetType     | COLUMN_NM              | AGGR_EXPRESSION_TXT | RULE_REPORTING_LEV3 | AGGREGATED_RULE_FLG | MESSAGE_TXT                                              |
   |------------|---------|----------|--------------------|------------------------|---------------------------|-------------|--------------|-------------|----------------------|-------------|--------------|----------------|------------------------|------------------|---------------------|-------------|-------------|------------|-----------------|------------------------|---------------------|---------------------|---------------------|----------------------------------------------------------|
   |            | #000001 |          |                    | Check Missing Currency | ENTITY_ID INSTID INSTTYPE |             |              |             | Completeness         | PTF_RULE_01 |              | CONDITION      | Check Missing Currency | MISSING          | Currency            |             | 1           | 10000      | BusinessRuleSet | CURRENCY               |                     | Missing             |                     | CURRENCY cannot be missing.                              |
   |            | #000002 |          |                    | Check Currency Length  | ENTITY_ID INSTID INSTTYPE |             | 3            |             | Accuracy & Integrity | PTF_RULE_02 |              | CONDITION      | Check Currency Length  | NOT_FIXED_LENGTH | Currency            |             | 1           | 10000      | BusinessRuleSet | CURRENCY               |                     | Fixed Length        |                     | CURRENCY is not a 3-character variable.                  |
   |            | #000003 |          |                    | Check Collateral Flag  | ENTITY_ID INSTID INSTTYPE |             | "Y", "N"     |             | Accuracy & Integrity | PTF_RULE_03 |              | CONDITION      | Check Collateral Flag  | NOT_LIST         | Counterparty Status |             | 1           | 10000      | BusinessRuleSet | COLLATERAL_SUPPORT_FLG |                     | Not In List         |                     | COLLATERAL_SUPPORT_FLG must be set to either "Y" or "N". |

   \ingroup rgfRestUtils

   \author  SAS Institute Inc.
   \date    2018
*/
%macro core_rest_get_rule_set(host =
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
                                , outds = rule_set
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
   %let requestUrl = &host:&port./&server./objects/&solution./ruleSets;

   %if(%sysevalf(%superq(key) ne, boolean)) %then
      /* Request the specified resource by the key */
      %let requestUrl = &requestUrl./&key.;
   %else
      /* Add filters (if any) */
      %let requestUrl = &requestUrl.?&filter.;

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
                     , parser = sas.risk.irm.rgf_rest_parser.rmcRestRuleSetData
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
