--[[
/* Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA */

/*!
\file

\brief   Module provides JSON parsing functionality for interacting with the SAS Model Implementation Platform REST API

\details
   The following functions are available:
   - mipRestPlain Parse a simple (one level) JSON structure
   - mipRestWorkgroups

\section mipRestWorkgroups

   Returns the list of workgroups defined in SAS Model Implementation Platform <br>

   <b>Syntax:</b> <i>(\<filename¦fileref\>, output)</i>

   <b>Sample JSON input structure: </b>
   \code
      {
         "userName": "sasdemo",
         "userDisplayName": "SAS Demo User",
         "currentWorkGroup": {
            "version": 1,
            "name": "Commercial",
            "displayName": "Commercial",
            "description": "",
            "systemUnit": false
         },
         "workGroups": [{
            "version": 1,
            "name": "data",
            "displayName": "Public",
            "systemUnit": true,
            "description": ""
         },
         {
            "version": 1,
            "name": "Commercial",
            "displayName": "Commercial",
            "description": "",
            "systemUnit": false
         },
         {
            "version": 1,
            "name": "Retail",
            "displayName": "Retail",
            "description": "",
            "systemUnit": false
         }],
         "links": [{
            "method": "GET",
            "rel": "self",
            "href": "http://rsslax07.unx.sas.com:7980/SASModelImplementationPlatform/rest/sessions/sasdemo",
            "uri": "/sessions/sasdemo",
            "type": "application/vnd.sas.modimp.session"
         },
         {
            "method": "PUT",
            "rel": "update",
            "href": "http://rsslax07.unx.sas.com:7980/SASModelImplementationPlatform/rest/sessions/sasdemo",
            "uri": "/sessions/sasdemo",
            "type": "application/vnd.sas.modimp.session"
         }]
   }
   \endcode

   <b>Sample Output: </b>

   | name       | displayName | version | description | systemUnit | currentWorkGroup | userName | userDisplayName |
   |------------|-------------|---------|-------------|------------|------------------|----------|-----------------|
   | data       | Public      | 1       |             | true       | false            | sasdemo  | SAS Demo User   |
   | Commercial | Commercial  | 1       |             | false      | true             | sasdemo  | SAS Demo User   |
   | Retail     | Retail      | 1       |             | false      | false            | sasdemo  | SAS Demo User   |


\section mipRestInstances

   Returns the list of run instances defined in SAS Model Implementation Platform <br>

   <b>Syntax:</b> <i>(\<filename¦fileref\>, output)</i>

   <b>Sample JSON input structure: </b>
   \code

   {
    "name": "runInstances",
    "accept": "application/vnd.sas.modimp.run+json application/json",
    "start": 0,
    "count": 12,
    "items": [
        {
            "version": 1,
            "name": "ECL_Retail_20171001_S99",
            "workGroupName": "Retail",
            "type": "runScenarios",
            "typeName": "Scenario Run",
            "portfolioDataName": "ptf_retail_20171001",
            "economicDataName": "SC_20171001_S99",
            "interval": "month",
            "intervalName": "Month",
            "horizon": 50,
            "cubeDescriptor": "ECL_Retail_20171001_S99",
            "sourceCubeDescriptor": "Cube_Retail_20171001_S99",
            "sourceCubeDeleted": false,
            "modelGroupMap": {
                "createdBy": "sasdemo",
                "modifiedBy": "sasdemo",
                "createdByName": "SAS Demo User",
                "modifiedByName": "SAS Demo User",
                "modelingSystem": {
                    "id": "19",
                    "name": "Retail_Hazard_Model",
                    "version": 1,
                    "label": "Retail_Hazard_Model (1)",
                    "entityVersion": "1"
                },
                "developer": "SAS Demo User",
                "version": 1,
                "name": "Retail_Hazard_Model_Map",
                "kind": "evaluation",
                "kindName": "Evaluation",
                "id": "33",
                "modifiedTimeStamp": "2017-10-23T13:50:31.720Z"
            },
            "numberSimulations": 15,
            "runAsOfDate": "2017-10-01",
            "genCodeOnly": false,
            "reSubmit": false,
            "debugOn": false,
            "registerScenarios": false,
            "swcName": "Model Imp Pltfrm Srv Cfg",
            "swcOutProperty": "root.dir",
            "runLocation": "Retail/output/run_instances/ECL_Retail_20171001_S99",
            "removeCubeEnabled": false,
            "createdBy": "sasdemo",
            "createdByName": "SAS Demo User",
            "numberNodes": "ALL",
            "numberThreads": 8,
            "outputCurrency": {
                "version": 1,
                "id": "USD",
                "label": "US Dollar"
            },
            "runTasks": [
                {
                    "sequence": 1,
                    "type": "codeGen",
                    "stepName": "Code Generation",
                    "state": "completed",
                    "stateName": "Completed",
                    "submittedTimeStamp": "2017-10-23T13:52:17.678Z",
                    "critical": true,
                    "completionTimeStamp": "2017-10-23T13:52:25.267Z"
                },
                {
                    "sequence": 2,
                    "type": "codeGenData",
                    "stepName": "Code Generation Data",
                    "state": "completed",
                    "stateName": "Completed",
                    "submittedTimeStamp": "2017-10-23T13:52:25.363Z",
                    "critical": true,
                    "completionTimeStamp": "2017-10-23T13:52:26.420Z"
                },
                {
                    "sequence": 3,
                    "type": "runExecution",
                    "stepName": "Run Execution",
                    "state": "completed",
                    "stateName": "Completed",
                    "progressName": "Completed [4 of 4]",
                    "submittedTimeStamp": "2017-10-23T13:52:29.862Z",
                    "critical": true,
                    "completionTimeStamp": "2017-10-23T13:52:42.770Z"
                }
            ],
            "modelingSystem": {
                "id": "19",
                "name": "Retail_Hazard_Model",
                "version": 1,
                "label": "Retail_Hazard_Model (1)",
                "entityVersion": "1"
            },
            "msaConfigPresent": false,
            "creationTimeStamp": "2017-10-23T13:52:17.673Z",
            "completedTimeStamp": "2017-10-23T13:52:42.770Z",
            "resultsTimeStamp": "2017-10-23T13:52:45.000Z",
            "id": "3114"
        },
     ],
    "limit": -1,
    "version": 2
   }


   \endcode

   <b>Sample Output: </b>

   | id   | version | name                          | type                | typeName           | sourceCubeDescriptor          | numberSimulations | reSubmit | numberThreads | runLocation                                               | horizon | removeCubeEnabled | cubeDescriptor                | workGroupName | runExecutionSubmittedDttm | completedTimeStamp       | modelGroupMapKindName | resultsTimeStamp         | numberNodes | sourceCubeDeleted | economicDataName     | codeGenState | codeGenDataCompletionDttm | debugOn | modelGroupMapName               | outputCurrency | codeGenSubmittedDttm     | codeGenDataSubmittedDttm | swcName                  | codeGenCompletionDttm    | runExecutionState | codeGenDataState | registerScenarios | msaConfigPresent | modelGroupMapId | createdBy | creationTimeStamp        | runAsOfDate | genCodeOnly | modelGroupMapKind | portfolioDataName           | interval | runExecutionCompletionDttm | createdByName | intervalName | swcOutProperty |
   |------|---------|-------------------------------|---------------------|--------------------|-------------------------------|-------------------|----------|---------------|-----------------------------------------------------------|---------|-------------------|-------------------------------|---------------|---------------------------|--------------------------|-----------------------|--------------------------|-------------|-------------------|----------------------|--------------|---------------------------|---------|---------------------------------|----------------|--------------------------|--------------------------|--------------------------|--------------------------|-------------------|------------------|-------------------|------------------|-----------------|-----------|--------------------------|-------------|-------------|-------------------|-----------------------------|----------|----------------------------|---------------|--------------|----------------|
   | 3114 | 1       | ECL_Retail_20171001_S99  | runScenarios        | Scenario Run       | Cube_Retail_20171001_S99 | 15                | FALSE    | 8             | Retail/output/run_instances/ECL_Retail_20171001_S99  | 50      | FALSE             | ECL_Retail_20171001_S99  | Retail        | 2017-10-23T13:52:29.862Z  | 2017-10-23T13:52:42.770Z | Evaluation            | 2017-10-23T13:52:45.000Z | ALL         | FALSE             | SC_20171001_S99 | completed    | 2017-10-23T13:52:26.420Z  | FALSE   | Retail_Hazard_Model_Map  | USD            | 2017-10-23T13:52:17.678Z | 2017-10-23T13:52:25.363Z | Model Imp Pltfrm Srv Cfg | 2017-10-23T13:52:25.267Z | completed         | completed        | FALSE             | FALSE            | 33              | sasdemo   | 2017-10-23T13:52:17.673Z | 2017-10-01  | FALSE       | evaluation        | ptf_retail_20171001    | month    | 2017-10-23T13:52:42.770Z   | SAS Demo User | Month        | root.dir       |

\ingroup commonAnalytics

\author  SAS Institute Inc.

\date    2015

*/

]]


local filesys = require 'sas.risk.utils.filesys'
local stringutils = require 'sas.risk.utils.stringutils'
local args = require 'sas.risk.utils.args'
local errors = require 'sas.risk.utils.errors'
local sas_msg = require 'sas.risk.utils.sas_msg'
local tableutils = require 'sas.risk.utils.tableutils'
local json = require 'sas.risk.utils.json'
local json_utils = require 'sas.risk.irm.irm_rest_parser'

json.strictTypes = true

local M = {}

M.mipRestPlain = json_utils.jsonRestPlain


mipRestWorkgroups = function(filename, output)
   local jsonTable = json_utils.parseJSONFile(filename)
   local result = {}
   local currentWorkGroup = ""
   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then
         result.vars = {};
         result.vars.errorCode = {type = "C"}
         result.vars.message = {type = "C"}
         result.vars.remediation = {type = "C"}
         result.vars.httpStatusCode = {type = "C"}

         local row = {}
         -- Grab Error details
         row.errorCode = jsonTable.errorCode
         row.message = jsonTable.message
         row.remediation = jsonTable.remediation
         row.httpStatusCode = jsonTable.httpStatusCode
         table.insert(result, row)
         -- Print error info to the log
         sas.print("%1z" .. row.message .. ". " .. row.remediation)
      else

         result.vars = {};
         result.vars.name = {type = "C"}
         result.vars.version = {type = "C"}
         result.vars.displayName = {type = "C"}
         result.vars.userName = {type = "C"}
         result.vars.userDisplayName = {type = "C"}
         result.vars.currentWorkGroup = {type = "C"}

         -- Get the current active workgroup
         if jsonTable.currentWorkGroup ~= nil then
            currentWorkGroup = jsonTable.currentWorkGroup.name
         end
         if jsonTable.workGroups ~= nil then
            -- Loop through the workgroups
            for i, row in pairs(jsonTable.workGroups) do

               -- Attach the userName and userDisplayName properties to the current row
               row.userName = jsonTable.userName
               row.userDisplayName = jsonTable.userDisplayName

               -- Determine if this is the current active workgroup
               row.currentWorkGroup = false
               if row.name == currentWorkGroup then
                  row.currentWorkGroup = true
               end

               -- Set the displayName to the value of the Name field in case it is missing.
               if row.displayName == "" then
                  row.displayName = row.name
               end

               -- Add workgroup record to the output table
               table.insert(result, row)
            end
            -- Process boolean attributes
            result = json_utils.processBoolean(result)
         end
      end
      -- Write result
      sas.write_ds(result, output)
   end
end
M.mipRestWorkgroups = mipRestWorkgroups


mipRestInstances = function(filename, output)
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Declare output table structure
   local result = {
      vars = {
         id = {type = "C"}
         , version = {type = "N"}
         , name = {type = "C"}
         , workGroupName = {type = "C"}
         , type = {type = "C"}
         , typeName = {type = "C"}
         , portfolioDataName = {type = "C"}
         , mitigationDataName = {type = "C"}
         , economicDataName = {type = "C"}
         , econSimulationDataName = {type = "C"}
         , interval = {type = "C"}
         , intervalName = {type = "C"}
         , horizon = {type = "N"}
         , cubeDescriptor = {type = "C"}
         , sourceCubeDescriptor = {type = "C"}
         , sourceCubeDeleted = {type = "C"}
         , mitigationMapId = {type = "C"}
         , mitigationMapName = {type = "C"}
         , modelGroupMapId = {type = "C"}
         , modelGroupMapName = {type = "C"}
         , modelGroupMapKind = {type = "C"}
         , modelGroupMapKindName = {type = "C"}
         , numberSimulations = {type = "N"}
         , runAsOfDate = {type = "C"}
         , genCodeOnly = {type = "C"}
         , reSubmit = {type = "C"}
         , debugOn = {type = "C"}
         , registerScenarios = {type = "C"}
         , swcName = {type = "C"}
         , swcOutProperty = {type = "C"}
         , runLocation = {type = "C"}
         , removeCubeEnabled = {type = "C"}
         , createdBy = {type = "C"}
         , createdByName = {type = "C"}
         , numberNodes = {type = "C"}
         , numberThreads = {type = "N"}
         , outputCurrency = {type = "C"}
         , msaConfigPresent = {type = "C"}
         , creationTimeStamp = {type = "C"}
         , completedTimeStamp = {type = "C"}
         , resultsTimeStamp = {type = "C"}
         , codeGenState = {type = "C"}
         , codeGenSubmittedDttm = {type = "C"}
         , codeGenCompletionDttm = {type = "C"}
         , codeGenDataState = {type = "C"}
         , codeGenDataSubmittedDttm = {type = "C"}
         , codeGenDataCompletionDttm = {type = "C"}
         , runExecutionState = {type = "C"}
         , runExecutionSubmittedDttm = {type = "C"}
         , runExecutionCompletionDttm = {type = "C"}
         , postExecProgramState = {type = "C"}
         , postExecProgramSubmittedDttm = {type = "C"}
         , postExecProgramCompletionDttm = {type = "C"}
      }
   }
   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then

         -- Set new structure for the error result table
         result.vars = {};
         result.vars.errorCode = {type = "C"}
         result.vars.message = {type = "C"}
         result.vars.remediation = {type = "C"}
         result.vars.httpStatusCode = {type = "C"}

         local row = {}
         -- Grab Error details
         row.errorCode = jsonTable.errorCode
         row.message = jsonTable.message
         row.remediation = jsonTable.remediation
         row.httpStatusCode = jsonTable.httpStatusCode
         table.insert(result, row)
         -- Print error info to the log
         sas.print("%1z" .. row.message .. ". " .. row.remediation)
      else

         local items
         if jsonTable.items ~= nil then
            items = jsonTable.items
         else
            items = {jsonTable}
         end

         -- Loop through the instances
         for i, row in pairs(items) do

            -- Copy relevant properties of the modelGroupMap object (if available)
            if row.modelGroupMap ~= nil then
               row.modelGroupMapId = row.modelGroupMap.id
               row.modelGroupMapName = row.modelGroupMap.name
               row.modelGroupMapKind = row.modelGroupMap.kind
               row.modelGroupMapKindName = row.modelGroupMap.kindName
               -- Get rid of the modelGroupMap object
               row.modelGroupMap = nil
            end

            -- Copy relevant properties of the mitigationMap object (if available)
            if row.mitigationMap ~= nil then
               row.mitigationMapId = row.mitigationMap.id
               row.mitigationMapName = row.mitigationMap.name
               -- Get rid of the mitigationMap object
               row.mitigationMap = nil
            end

            -- Get the result currency (if available)
            if row.outputCurrency ~= nil then
               row.outputCurrency = row.outputCurrency.id
            end

            -- Get instance execution status
            if row.runTasks ~= nil then
               for i, task in pairs(row.runTasks) do
                  if task.type == "codeGen" then
                     row.codeGenState = task.state
                     row.codeGenSubmittedDttm = task.submittedTimeStamp
                     row.codeGenCompletionDttm = task.completionTimeStamp
                  elseif task.type == "codeGenData" then
                     row.codeGenDataState = task.state
                     row.codeGenDataSubmittedDttm = task.submittedTimeStamp
                     row.codeGenDataCompletionDttm = task.completionTimeStamp
                  elseif task.type == "runExecution" then
                     row.runExecutionState = task.state
                     row.runExecutionSubmittedDttm = task.submittedTimeStamp
                     row.runExecutionCompletionDttm = task.completionTimeStamp
                  elseif task.type == "postExecProgram" then
                     row.postExecProgramState = task.state
                     row.postExecProgramSubmittedDttm = task.submittedTimeStamp
                     row.postExecProgramCompletionDttm = task.completionTimeStamp
                  else
                  end
               end
               -- Get rid of the runTasks object
               row.runTasks = nil
            end

            -- Remove unused objects
            row.results = nil
            row.links = nil

            -- Add workgroup record to the output table
            table.insert(result, row)
         end
         -- Process boolean attributes
         result = json_utils.processBoolean(result)
      end

      if #result == 0 then
         -- Make sure there is at least one record
         result[1] = {id = ""}
         -- Write table
         sas.write_ds(result, output)
         -- Now remove the empty record
         sas.submit([[data @output@; set @output@(obs = 0); run;]])
      else
         -- Write result
         sas.write_ds(result, output)
      end
   end
end
M.mipRestInstances = mipRestInstances

mipRestModelingSystems = function(filename, output)
   local jsonTable = json_utils.parseJSONFile(filename)

   -- Declare output table structure
   local result = {
      vars = {
         modelingSystemId                 = {type = "C"}
         , modelingSystemName             = {type = "C"}
         , modelingSystemVersion          = {type = "C"}
         , modelingSystemLabel            = {type = "C"}
         , loaded                         = {type = "C"}
         , sourceServerName               = {type = "C"}
         , sourceMipRelease               = {type = "C"}
         , createdBy                      = {type = "C"}
         , createdByName                  = {type = "C"}
         , exportedBy                     = {type = "C"}
         , exportedByName                 = {type = "C"}
         , exportTimeStamp                = {type = "C"}
         , sourceWorkGroupName            = {type = "C"}
         , mitigationMapId                = {type = "C"}
         , mitigationMapName              = {type = "C"}
         , modifiedTimeStamp              = {type = "C"}
         , modelGroupMapId                = {type = "C"}
         , modelGroupMapKind              = {type = "C"}
         , modelGroupMapKindName          = {type = "C"}
         , modelGroupMapName              = {type = "C"}
         , scoringModelGroupMapId         = {type = "C"}
         , scoringModelGroupMapKind       = {type = "C"}
         , scoringModelGroupMapKindName   = {type = "C"}
         , scoringModelGroupMapName       = {type = "C"}
         , preExecutionProgramName        = {type = "C"}
         , preExecutionProgramId          = {type = "C"}
         , postExecutionProgramName       = {type = "C"}
         , postExecutionProgramId         = {type = "C"}
         , postProcessMethods             = {type = "C", length = 32000}
         , computedMethods                = {type = "C", length = 32000}
      }
   }
   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then

         -- Set new structure for the error result table
         result.vars = {};
         result.vars.errorCode = {type = "C"}
         result.vars.message = {type = "C"}
         result.vars.remediation = {type = "C"}
         result.vars.httpStatusCode = {type = "C"}

         local row = {}
         -- Grab Error details
         row.errorCode = jsonTable.errorCode
         row.message = jsonTable.message
         row.remediation = jsonTable.remediation
         row.httpStatusCode = jsonTable.httpStatusCode
         table.insert(result, row)
         -- Print error info to the log
         sas.print("%1z" .. row.message .. ". " .. row.remediation)
      else
         if jsonTable.items ~= nil then
            -- Loop through the instances
            for i, row in pairs(jsonTable.items) do

               -- Rename fields
               row.modelingSystemId = row.id
               row.modelingSystemName = row.name
               row.modelingSystemVersion = row.entityVersion
               row.modelingSystemLabel = row.label

               -- Copy relevant properties of the modelGroupMap object (if available)
               if row.entities ~= nil then
                  -- Copy relevant properties of the modelGroupMap object (if available)
                  if row.entities.modelGroupMap ~= nil then
                     row.modelGroupMapId = row.entities.modelGroupMap.id
                     row.modelGroupMapName = row.entities.modelGroupMap.name
                     row.modelGroupMapKind = row.entities.modelGroupMap.kind
                     row.modelGroupMapKindName = row.entities.modelGroupMap.kindName
                  end
                  -- Copy relevant properties of the mitigationMap object (if available)
                  if row.entities.mitigationMap ~= nil then
                     row.mitigationMapId = row.entities.mitigationMap.id
                     row.mitigationMapName = row.entities.mitigationMap.name
                  end
                  -- Copy relevant properties of the scoringModelGroupMap object (if available)
                  if row.entities.scoringModelGroupMap ~= nil then
                     row.scoringModelGroupMapId = row.entities.scoringModelGroupMap.id
                     row.scoringModelGroupMapName = row.entities.scoringModelGroupMap.name
                     row.scoringModelGroupMapKind = row.entities.scoringModelGroupMap.kind
                     row.scoringModelGroupMapKindName = row.entities.scoringModelGroupMap.kindName
                  end
                  -- Get preExecutionProgram info (if available)
                  if row.entities.preExecutionProgram ~= nil then
                     row.preExecutionProgramId = row.entities.preExecutionProgram.id
                     row.preExecutionProgramName = row.entities.preExecutionProgram.name
                  end
                  -- Get postExecutionProgram info (if available)
                  if row.entities.postExecutionProgram ~= nil then
                     row.postExecutionProgramId = row.entities.postExecutionProgram.id
                     row.postExecutionProgramName = row.entities.postExecutionProgram.name
                  end
                  -- Get postProcessMethods (if available)
                  if row.entities.postProcessMethods ~= nil then
                     row.postProcessMethods = ""
                     for j, postProcessMethod in pairs(row.entities.postProcessMethods) do
                        if row.postProcessMethods ~= "" then
                           row.postProcessMethods = row.postProcessMethods .. ", "
                        end
                        row.postProcessMethods = row.postProcessMethods .. '{'
                        row.postProcessMethods = row.postProcessMethods ..   '"id": "' .. postProcessMethod.id .. '"'
                        row.postProcessMethods = row.postProcessMethods ..   ',  "name": "' .. postProcessMethod.name .. '"'
                        row.postProcessMethods = row.postProcessMethods ..   ', "sequence": ' .. postProcessMethod.sequence
                        row.postProcessMethods = row.postProcessMethods .. '}'
                     end
                  end
                  -- Get computedMethods (if available)
                  if row.entities.computedMethods ~= nil then
                     row.computedMethods = ""
                     for j, computedMethod in pairs(row.entities.computedMethods) do
                        if row.computedMethods ~= "" then
                           row.computedMethods = row.computedMethods .. ", "
                        end
                        row.computedMethods = row.computedMethods .. '{'
                        row.computedMethods = row.computedMethods ..   '"id": "' .. computedMethod.id .. '"'
                        row.computedMethods = row.computedMethods ..   ', "name": "' .. computedMethod.name .. '"'
                        row.computedMethods = row.computedMethods ..   ', "sequence": ' .. computedMethod.sequence
                        row.computedMethods = row.computedMethods ..   ', "modelingSystem": {'
                        row.computedMethods = row.computedMethods ..          '"id": "' .. computedMethod.modelingSystem.id .. '"'
                        row.computedMethods = row.computedMethods ..          ', "name": "' .. computedMethod.modelingSystem.name .. '"'
                        row.computedMethods = row.computedMethods ..          ', "entityVersion": "' .. computedMethod.modelingSystem.entityVersion .. '"'
                        row.computedMethods = row.computedMethods ..      '}'
                        row.computedMethods = row.computedMethods .. '}'
                     end
                  end
               end

               -- Add workgroup record to the output table
               table.insert(result, row)
            end
            -- Process boolean attributes
            result = json_utils.processBoolean(result)
         end
      end

      if #result == 0 then
         -- Make sure there is at least one record
         result[1] = {id = ""}
         -- Write table
         sas.write_ds(result, output)
         -- Now remove the empty record
         sas.submit([[data @output@; set @output@(obs = 0); run;]])
      else
         -- Write result
         sas.write_ds(result, output)
      end
   end

end;
M.mipRestModelingSystems = mipRestModelingSystems




mipRestExecutionProgram = function(filename, output)
   local jsonTable = json_utils.parseJSONFile(filename)

   -- Declare output table structure
   local result = {
      vars = {
         name              = {type = "C"}
         , description     = {type = "C"}
         , type            = {type = "C"}
         , code            = {type = "C", length = 32000}
         , createdBy       = {type = "C"}
         , createdByName   = {type = "C"}
         , modifiedBy      = {type = "C"}
         , modifiedByName  = {type = "C"}
      }
   }
   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then

         -- Set new structure for the error result table
         result.vars = {};
         result.vars.errorCode = {type = "C"}
         result.vars.message = {type = "C"}
         result.vars.remediation = {type = "C"}
         result.vars.httpStatusCode = {type = "C"}

         local row = {}
         -- Grab Error details
         row.errorCode = jsonTable.errorCode
         row.message = jsonTable.message
         row.remediation = jsonTable.remediation
         row.httpStatusCode = jsonTable.httpStatusCode
         table.insert(result, row)
         -- Print error info to the log
         sas.print("%1z" .. row.message .. ". " .. row.remediation)
      else
         local row = {}
         row.name = jsonTable.name
         row.description = jsonTable.description
         row.type = jsonTable.type
         row.code = jsonTable.code
         row.createdBy = jsonTable.createdBy
         row.createdByName = jsonTable.createdByName
         row.modifiedBy = jsonTable.modifiedBy
         row.modifiedByName = jsonTable.modifiedByName
         table.insert(result, row)
      end

      if #result == 0 then
         -- Make sure there is at least one record
         result[1] = {name = ""}
         -- Write table
         sas.write_ds(result, output)
         -- Now remove the empty record
         sas.submit([[data @output@; set @output@(obs = 0); run;]])
      else
         -- Write result
         sas.write_ds(result, output)
      end
   end

end;
M.mipRestExecutionProgram = mipRestExecutionProgram



mipRestImportModelingSystem = function(filename, output)
   local jsonTable = json_utils.parseJSONFile(filename)

   -- Declare output table structure
   local result = {
      vars = {
         logFilename          = {type = "C"}
         , validationName     = {type = "C"}
         , validationType     = {type = "C"}
         , dataType           = {type = "C"}
         , dataTypeName       = {type = "C"}
         , identifier         = {type = "C"}
         , validationMessage  = {type = "C"}
      }
   }
   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then

         -- Set new structure for the error result table
         result.vars = {};
         result.vars.errorCode = {type = "C"}
         result.vars.message = {type = "C"}
         result.vars.remediation = {type = "C"}
         result.vars.httpStatusCode = {type = "C"}

         local row = {}
         -- Grab Error details
         row.errorCode = jsonTable.errorCode
         row.message = jsonTable.message
         row.remediation = jsonTable.remediation
         row.httpStatusCode = jsonTable.httpStatusCode
         table.insert(result, row)
         -- Print error info to the log
         sas.print("%1z" .. row.message .. ". " .. row.remediation)
      else
         if jsonTable.items ~= nil then
            for i, item in ipairs(jsonTable.items) do
               for j, validationItem in ipairs(item.validationItems) do
                  for k, dataItem in ipairs(validationItem.dataItems) do
                     local row = {}
                     row.logFilename = jsonTable.logFilename
                     row.validationName = item.validationName
                     row.validationType = item.validationType
                     row.dataType = validationItem.dataType
                     row.dataTypeName = validationItem.dataTypeName
                     row.identifier = dataItem.identifier
                     row.validationMessage = dataItem.validationMessage
                     table.insert(result, row)
                  end
               end
            end
         end
      end

      if #result == 0 then
         -- Make sure there is at least one record
         result[1] = {name = ""}
         -- Write table
         sas.write_ds(result, output)
         -- Now remove the empty record
         sas.submit([[data @output@; set @output@(obs = 0); run;]])
      else
         -- Write result
         sas.write_ds(result, output)
      end
   end

end;
M.mipRestImportModelingSystem = mipRestImportModelingSystem



mipRestDeleteInstances = function(filename, output)
   local jsonTable = json_utils.parseJSONFile(filename)

   -- Declare output table structure
   local result = {
      vars = {
         id = {type = "C"}
         , deleteType = {type = "C"}
         , deletedFlg = {type = "C"}
      }
   }
   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then

         -- Set new structure for the error result table
         result.vars = {};
         result.vars.errorCode = {type = "C"}
         result.vars.message = {type = "C"}
         result.vars.remediation = {type = "C"}
         result.vars.httpStatusCode = {type = "C"}

         local row = {}
         -- Grab Error details
         row.errorCode = jsonTable.errorCode
         row.message = jsonTable.message
         row.remediation = jsonTable.remediation
         row.httpStatusCode = jsonTable.httpStatusCode
         table.insert(result, row)
         -- Print error info to the log
         sas.print("%1z" .. row.message .. ". " .. row.remediation)
      else
         for id, item in pairs(jsonTable) do
            local row = {}
            row.id = id
            row.deleteType = "RunInstance"
            if(next(item) == nil) then
               row.deletedFlg = "Y"
            else
               row.deletedFlg = "N"
            end
            table.insert(result, row)
         end
      end

      if #result == 0 then
         -- Make sure there is at least one record
         result[1] = {id = ""}
         -- Write table
         sas.write_ds(result, output)
         -- Now remove the empty record
         sas.submit([[data @output@; set @output@(obs = 0); run;]])
      else
         -- Write result
         sas.write_ds(result, output)
      end
   end

end;
M.mipRestDeleteInstances = mipRestDeleteInstances



return M