--[[
/* Copyright (C) 2018 SAS Institute Inc. Cary, NC, USA */

/*!
\file

\brief   Module provides JSON parsing functionality for interacting with the SAS Viya Model Manager REST API

\details
   The following functions are available:
   - vmmRestPlain Parse a simple (one level) JSON structure
   - ...

\section ..

   Returns the list of scenarios defined in SAS Risk Scenario Manager <br>

   <b>Syntax:</b> <i>(\<filename¦fileref\>, output)</i>

   <b>Sample JSON input structure: </b>
   \code

   \endcode

   <b>Sample Output: </b>


\ingroup commonAnalytics

\author  SAS Institute Inc.

\date    2018

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

M.vmmRestPlain = json_utils.jsonRestPlain

-----------------------------------------------------------------------------------------
-- General VMM parsing functions
-----------------------------------------------------------------------------------------

-- Process VMM item attributes
vmmProcessAttr = function(item, func)

   -- Initialize output row
   local row = {}

   for attrName, attrValue in pairs(item) do
     if(type(attrValue) == "table") then
        -- Convert table into plain string
        row[attrName] = json:encode(attrValue)
     else
        row[attrName] = attrValue
     end
   end

   -- Use custom function if provided
   if(func ~= nil) then
      row = func(item, row)
   end

   -- Return the processed row
   return row
end


-- General wrapper for REST calls
vmmProcessItems = function(schema, jsonTable, output, func)
   -- Declare output table structure (copy from the input schema)
   local result = schema

   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then
         result = {}
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
         -- Check if this is a collection of items
         if jsonTable.items ~= nil then
            -- Loop through the items
            for i, row in pairs(jsonTable.items) do
               row.itemsCount = jsonTable.count
               -- Add record to the output table
               table.insert(result, vmmProcessAttr(row, func))
            end
            -- Process boolean attributes
            result = json_utils.processBoolean(result)
         else
            -- Check if this is a single item
            if jsonTable.id ~= nil then
               jsonTable.itemsCount = 1
               -- Add record to the output table
               table.insert(result, vmmProcessAttr(jsonTable, func))
               -- Process boolean attributes
               result = json_utils.processBoolean(result)
            end
         end
      end

      --print(table.tostring(result))

      if output ~= nil then
         if #result == 0 then
            -- Make sure there is at least one record
            result[1] = {id = -1}
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

   return result

end
-----------------------------------------------------------------------------------------
-- VMM output schema definition functions
-----------------------------------------------------------------------------------------

-- Attributes of the VMM Scenario object
vmmModelAttr = function()
  -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
           id                 = {type = "C", length = 100}
         , projectId          = {type = "C", length = 100}
         , projectVersionId   = {type = "C", length = 100}
         , folderId           = {type = "C", length = 100}
         , indirectFolderId   = {type = "C", length = 100}
         , repositoryId       = {type = "C", length = 100}
         , externalModelId    = {type = "C", length = 100}
         , name               = {type = "C", length = 512}
         , description        = {type = "C", length = 512}
         , projectName        = {type = "C", length = 512}
         , projectVersionName = {type = "C", length = 512}
         , projectVersionNum  = {type = "C", length = 512}
         , algorithm          = {type = "C", length = 512}
         , modeler            = {type = "C", length = 100}
         , role               = {type = "C", length = 100}
         , scoreCodeType      = {type = "C", length = 100}         
         , targetEvent        = {type = "C", length = 100}
         , targetLevel        = {type = "C", length = 100}
         , targetVariable     = {type = "C", length = 100}
         , eventProbVar       = {type = "C", length = 100}
         , tool               = {type = "C", length = 100}
         , toolVersion        = {type = "C", length = 100}
         , trainCodeType      = {type = "C", length = 100}
         , modelVersionName   = {type = "C", length = 100}
         , createdBy          = {type = "C", length = 100}
         , modifiedBy         = {type = "C", length = 100}
         , creationTimeStamp  = {type = "C", length = 32}
         , modifiedTimeStamp  = {type = "C", length = 32}
         , publishTimeStamp   = {type = "C", length = 32}
         , suggestedChampion  = {type = "C", length = 10}
         , candidateChampion  = {type = "C", length = 10}
         , immutable          = {type = "C", length = 10}
         , retrainable        = {type = "C", length = 10}
         , trainTable         = {type = "C", length = 2048}
         , externalUrl        = {type = "C", length = 2048}
         , location           = {type = "C", length = 2048}
         , tags               = {type = "C", length = 32000}
         , globalTags         = {type = "C", length = 32000}
         , itemsCount         = {type = "N"}
         -- , inputVariables     = {type = "C", length = 32000}
         -- , outputVariables    = {type = "C", length = 32000}
         -- , modelVersions      = {type = "C", length = 32000}
        }
   }
   -- Special variable name "function" must be specified using the array syntax to avoid compiling errors
   result.vars["function"]    = {type = "C", length = 512}

   -- Return table structure
   return result
end


-----------------------------------------------------------------------------------------
-- VMM parser functions
-----------------------------------------------------------------------------------------

-----------------------------
-- Model
-----------------------------

-- Parser for rest/Scenario
vmmRestModel = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define Model Attributes
   local schema = vmmModelAttr()
   -- Process all items
   vmmProcessItems(schema, jsonTable, output)
end
M.vmmRestModel = vmmRestModel


return M