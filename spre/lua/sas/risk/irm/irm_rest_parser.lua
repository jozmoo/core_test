--[[
/* Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA */

/*!
\file

\brief   Module provides JSON parsing functionality for interacting with the IRM REST API

\details
   The following functions are available:
   - parseJSONFile(<filename or fileref>): Parse a JSON file and returns a Lua table.
   - irmRestPlain(<filename or fileref>, output): Parse a JSON file and returns an output SAS table (Assumes a plain/flat JSON structure)

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
json.strictTypes = true

local M = {}
-- declare function
local readFile
local parseJSONFile
local irmRestPlain

rowCount = function(ds)
   local dsid = sas.open(ds)
   local cnt = sas.nobs(dsid)
   sas.close(dsid)
   return cnt
end

getJsonString = function(filename)
   -- Create a temporary table by reading the input file 1024 characters at the time
   local tmpDs = "__tmpJSON__"
   sas.set_quiet(true)
   sas.submit[[
      data @tmpDs@;
         infile @filename@ recfm = F lrecl = 1024 length = len;
         length str $1024.;
         input str $varying1024. len;
      run;
   ]]

   -- Load data set
   local data = sas.load_ds(tmpDs)
   -- Load content of each row into a new table
   local rows = {}
   for i = 1, rowCount("__tmpJSON__") do
      -- Make sure blanks are not truncated if they happen to be at the character position 1024
      rows[i] = data[i].str..string.rep(' ', 1024 - #data[i].str)
   end

   -- Cleanup
   sas.submit[[
      proc datasets library = work nolist nodetails;
         delete @tmpDs@;
      quit;
   ]]
   sas.set_quiet(false)
   -- Concatenate the table to get a full JSON string
   local str = table.concat(rows)
   return str
end;


parseJSONFile = function(filename)
   --local jsonString = readFile(filename)
   local jsonString = getJsonString(filename)
   local jsonTable, pos, err
   jsonTable = nil
   if jsonString ~= "" then
      jsonTable, pos, err = json:decode(jsonString)
   else
      print("WARNING: Input filename is empty!")
   end
   return jsonTable
end
M.parseJSONFile = parseJSONFile


processBoolean = function(tbl)
   for i, t in pairs(tbl) do
      if type(t) == "table" then
         tbl[i] = processBoolean(t)
      elseif type(t) == "boolean" then
         if t then
            tbl[i] = "true"
         else
            tbl[i] = "false"
         end
      end
   end
   return tbl
end;
M.processBoolean = processBoolean


function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

getItem = function(obj, item)
   local levels = item:split('.')
   local value = obj
   for i, level in pairs(levels) do
      if (type(value) == "table") then
         value = value[level]
      else
        value = nil
      end
   end
   if value ~= nil and type(value) ~= "table" then
      local temp = value
      value = {}
      value[levels[#levels]] = temp
   end
   return value
end

restLinks = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      if jsonTable.links ~= nil then
         sas.write_ds(jsonTable.links, output)
      end
   end
end;
M.restLinks = restLinks


irmRestPlain = function(filename, output, item, defaultLength)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      -- Check if we have to retrieve a specific item from the json object
      if item ~= nil then
         -- Retrieve the specified item
         jsonTable = getItem(jsonTable, item)
         -- Throw an error if the item could not be found
         if jsonTable == nil then
            sas.submit([[%put ERROR: Could not find JSON object matching the query: @item@;]])
         end
      end
      -- Need to check again in case the item search returned nil
      if jsonTable ~= nil then
         vars = {}
         jsonTable = processBoolean(jsonTable)
         if #jsonTable == 0 then
            jsonTable = {jsonTable}
         end
         
         -- Loop through all rows
         for i, row in ipairs(jsonTable) do
            -- Loop through all columns
            for key, value in pairs(row) do
               -- Convert into a flat string if the attribute is a table
               if type(value) == "table" then
                  row[key] = json:encode(value)
               end
               
               -- Check if the defaultLength has been specified
               if defaultLength ~= nil then
                  -- Check if this is a numeric column
                  if type(row[key]) == "number" then
                     varType = "N"
                     varLen = 8
                  else -- This is a character column
                     varType = "C"
                     -- Set the specified default lenght (unless the value of the column is larger)
                     varLen = math.max(string.len(row[key]), defaultLength)
                  end
                  -- Add the column definition to the vars array
                  vars[key] = {type = varType, length = varLen}
               end
            end
         end
         
         if defaultLength ~= nil then
            -- Set the vars definition
            jsonTable.vars = vars
         end
         
         sas.write_ds(jsonTable, output)
      end
   end
end;

M.irmRestPlain = irmRestPlain


irmRestInstanceInfo = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   local result = {}
   if jsonTable ~= nil then
      -- Loop through the rows
      for i, row in pairs(jsonTable) do
         local configCount = 0

         -- check if there are multiple FA Ids associated with this jobflow
         if row.federatedAreaIds ~= nil then
            local faIds = ""
            -- Convert the array into a space separated list of values
            for k, faId in pairs(row.federatedAreaIds) do
               if k > 1 then
                  faIds = faIds .. " "
               end
               faIds = faIds .. faId
            end
            row.federatedAreaIds = faIds
         end

         -- check if there are multiple configuration sets associated with this jobflow
         if row.configurationSetIds ~= nil then
            -- Loop through all configuration set ids and create a new row for each config set
            for k, configSetId in pairs(row.configurationSetIds) do
               configCount = configCount + 1
               -- Copy the content of this row to a new variable (excluding the array configurationSetIds)
               local newRow = {}
               for k, v in pairs(row) do
                  if k ~= "configurationSetIds" then
                     newRow[k] = v
                  end
               end
               newRow.ConfigurationSetId = configSetId
               table.insert(result, newRow)
            end
         end

         -- If there are no configuration sets specified then set a default value
         if configCount == 0 then
            row.configurationSetIds = "*"
            table.insert(result, row)
         end
      end
      result = processBoolean(result)
      sas.write_ds(result, output)
   end
end;

M.irmRestInstanceInfo = irmRestInstanceInfo



irmRestEntities = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      -- flatten the role sub-table to the same level as the entity list table
      for i, t in pairs(jsonTable) do
         for k, v in pairs(t.role) do
            t["role_"..k] = v
         end
         t.role = nil
      end;
      sas.write_ds(jsonTable, output)
   end
end;

M.irmRestEntities = irmRestEntities

irmRestInstances = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then

      for i, t in pairs(jsonTable) do
         -- Remove the results and id fields
         t.results = nil
         t.id = nil
         -- Set the publish related info
         if t.publishInfo ~= nil then
            t.published = true
            t.publishedBy = t.publishInfo.createdBy
            t.publishInfo = nil
         else
            t.published = false
            t.publishedBy = ""
            t.publishComments = ""
            t.publishTimestamp = ""
         end
         t.statusDesc = setJobStatus(t.status)
      end;
      jsonTable = processBoolean(jsonTable)
      sas.write_ds(jsonTable, output)
   end
end;
M.irmRestInstances = irmRestInstances

setJobStatus = function(status)
   res = "N/A"
   if status == 0 then
      res = "Not Run"
   elseif status == 2 then
      res = "Running"
   elseif status == 3 then
      res = "Error"
   elseif status == 4 then
      res = "Successful"
   elseif status == 5 then
      res = "Canceled"
   elseif status == 6 then
      res = "Published"
   elseif status == 7 then
      res = "Out Of Date"
   elseif status == 8 then
      res = "Publishing"
   elseif status == 10 then
      res = "Canceling"
   elseif status == 12 then
      res = "Publish Error"
   end
   return res
end

irmRestJobStatus = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      result = {}

      -- Process jobflow status
      row = {}
      row.key = jsonTable.key
      row.type = "JOBFLOW"
      row.status_code = jsonTable.jobFlowStatus
      row.status = setJobStatus(jsonTable.jobFlowStatus)
      table.insert(result, row)

      -- Process subflow status
      for k, v in pairs(jsonTable.subFlowsStatus) do
         row = {}
         row.key = k
         row.type = "SUBFLOW"
         row.status_code = v
         row.status = setJobStatus(v)
         table.insert(result, row)
      end;

      -- Process task status
      for k, v in pairs(jsonTable.tasksStatus) do
         row = {}
         row.key = k
         row.type = "TASK"
         row.status_code = v
         row.status = setJobStatus(v)
         table.insert(result, row)
      end;
      sas.write_ds(result, output)
   end
end;
M.irmRestJobStatus = irmRestJobStatus


strScan = function (str, pos, pattern, plain)
   local outResults = {}
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find(str, pattern, theStart, plain)
   local tokenCnt = 0
   while theSplitStart do
      table.insert(outResults, string.sub(str, theStart, theSplitStart-1))
      tokenCnt = tokenCnt + 1
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find(str, pattern, theStart, plain)
   end
   table.insert(outResults, string.sub(str, theStart))
   tokenCnt = tokenCnt + 1

   if pos > 0 then
      return outResults[pos]
   elseif pos < 0 then
      return outResults[tokenCnt + pos + 1]
   else
      return outResults
   end
end


getObjectProperties = function(tbl, additionalProperties, subsetList, renameList)
   local res = {}
   for i, t in pairs(tbl) do
      -- Create new row
      local row = {}
      -- Attach the initial properties (assumption is that these properties have different name than those contained in the tbl object)
      for k, v in pairs(additionalProperties) do
         row[k] = v
      end
      -- Get all properties defined in the tbl object (current row)
      for k, v in pairs(t) do
         -- Keep only the properties that are specified in the subsetList
         if(subsetList[k] or subsetList[k] == nil) then
            if(renameList[k]) then
               row[renameList[k]] = v
            else
               row[k] = v
            end
         end
      end
      -- convert boolean to string
      row = processBoolean(row)
      -- Append this row to the result
      table.insert(res, row)
   end
   return res
end


irmRestTableMap = function(filename, output, webDavBasePath, topInstanceKey)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      local result = {}
      -- Rename the following properties in the output table
      local renameList = {key = "dataKey", name = "objectName", baseName = "tableName"}
      -- Discard the following properties from the output table
      local subsetList = {id = false, sourceId = false, sourceTask = false}
      local columnList = {modified = "string"
                           , readOnly = "string"
                           , jobFlowDefinitionFile = "string"
                           , webDavNodePath = "string"
                           , dataKey = "number"
                           , nodeName = "string"
                           , collection = "string"
                           , url = "string"
                           , result = "string"
                           , webDavFullPath = "string"
                           , processKey = "number"
                           , topInstanceKey = "number"
                           , categoryId = "string"
                           , baseDate = "string"
                           , webDavLibPath = "string"
                           , entityId = "string"
                           , owner = "string"
                           , fileName = "string"
                           , nodeType = "string"
                           , subflowKey = "number"
                           , libname = "string"
                           , version = "number"
                           , nodeKey = "number"
                           , tableName = "string"
                           , extension = "string"
                           , objectName = "string"
                           , partition = "string"
                           , federatedAreaId = "string"
                           , modifiedBy = "string"
                           , modifiedNotes = "string"
                           , modifiedTimestamp = "string"
                           , modifiedVersion = "number"
                           , dataObjectRole = "string"
                          }
      -- Process subflow instances
      for i, t in pairs(jsonTable.subFlowInstances) do
         local properties = {}
         if(not jsonTable.subFlow) then
            -- This is the root jobflow. Construct the base WebDAV path to the subflow folder
            properties.webDavNodePath = table.concat({jsonTable.baseDate
                                                  , jsonTable.configSetId
                                                  , jsonTable.entityId
                                                  , jsonTable.entityRoleId
                                                  , jsonTable.categoryId
                                                  , (string.gsub(jsonTable.jobFlowDefinitionFile, ".bpmn$", ""))
                                                  , jsonTable.name
                                                  , (string.gsub(strScan(t.path, -1, "/", true), ".bpmn$", ""))
                                                  }
                                                  , "/")
         else
            -- This is a subflow. The starting point is passed as a parameter by the call to the REST API
            properties.webDavNodePath = webDavBasePath .. "/" .. (string.gsub(strScan(t.path, -1, "/", true), ".bpmn$", ""))
         end
         properties.topInstanceKey = topInstanceKey
         properties.entityId = jsonTable.entityId
         properties.baseDate = jsonTable.baseDate
         properties.owner = jsonTable.createdBy
         properties.categoryId = jsonTable.categoryId
         properties.jobFlowDefinitionFile = jsonTable.jobFlowDefinitionFile

         properties.subflowKey = t.instanceKey
         properties.nodeKey = t.key
         properties.nodeName = t.name
         properties.nodeType = "SUBFLOW"
         -- Loop through all inputs
         local inputData = getObjectProperties(t.inputData, properties, subsetList, renameList)
         for idx, row in pairs(inputData) do
            row.dataObjectRole = "INPUT"
            row.webDavLibPath = table.concat({properties.webDavNodePath, row.libname}, "/")
            row.webDavFullPath = table.concat({properties.webDavNodePath, row.libname, row.fileName}, "/")
            if row.modifiedInfo then
               row.modifiedBy = row.modifiedInfo.createdBy
               row.modifiedNotes = row.modifiedInfo.notes
               row.modifiedVersion = row.modifiedInfo.version
            end
            row.modifiedInfo = nil
            table.insert(result, row)
         end
         -- Loop through all outputs
         local outputData = getObjectProperties(t.outputData, properties, subsetList, renameList)
         for idx, row in pairs(outputData) do
            row.dataObjectRole = "OUTPUT"
            row.webDavLibPath = table.concat({properties.webDavNodePath, row.libname}, "/")
            row.webDavFullPath = table.concat({properties.webDavNodePath, row.libname, row.fileName}, "/")
            table.insert(result, row)
         end
         -- Make sure this subflow object is included in the output table even if it does not have any input/output data object
         if (#inputData == 0 and #outputData == 0) then
            table.insert(result, properties)
         end
      end;

      -- Process task objects
      for i, t in pairs(jsonTable.tasks) do
         local properties = {}
         if(not jsonTable.subFlow) then
            -- This is the root jobflow. Construct the base WebDAV path to the task folder
            properties.webDavNodePath = table.concat({jsonTable.baseDate
                                                  , jsonTable.configSetId
                                                  , jsonTable.entityId
                                                  , jsonTable.entityRoleId
                                                  , jsonTable.categoryId
                                                  , (string.gsub(jsonTable.jobFlowDefinitionFile, ".bpmn$", ""))
                                                  , jsonTable.name
                                                  , t.name
                                                  }
                                                  , "/")
         else
            -- This is a subflow. The starting point is passed as a parameter by the call to the REST API
            properties.webDavNodePath = webDavBasePath .. "/" .. t.name
         end
         properties.topInstanceKey = topInstanceKey
         properties.entityId = jsonTable.entityId
         properties.baseDate = jsonTable.baseDate
         properties.owner = jsonTable.createdBy
         properties.categoryId = jsonTable.categoryId
         properties.jobFlowDefinitionFile = jsonTable.jobFlowDefinitionFile

         -- Make sure this property is defined in case of the task -> will result to missing column
         properties.subflowKey = -1/0
         properties.nodeKey = t.key
         properties.nodeName = t.name
         properties.nodeType = "TASK"
         -- Loop through all inputs
         local inputData = getObjectProperties(t.inputData, properties, subsetList, renameList)
         for idx, row in pairs(inputData) do
            row.dataObjectRole = "INPUT"
            row.webDavLibPath = table.concat({properties.webDavNodePath, row.libname}, "/")
            row.webDavFullPath = table.concat({properties.webDavNodePath, row.libname, row.fileName}, "/")
            if row.modifiedInfo then
               row.modifiedBy = row.modifiedInfo.createdBy
               row.modifiedNotes = row.modifiedInfo.notes
               row.modifiedVersion = row.modifiedInfo.version
            end
            row.modifiedInfo = nil
            table.insert(result, row)
         end
         -- Loop through all outputs
         local outputData = getObjectProperties(t.outputData, properties, subsetList, renameList)
         for idx, row in pairs(outputData) do
            row.dataObjectRole = "OUTPUT"
            row.webDavLibPath = table.concat({properties.webDavNodePath, row.libname}, "/")
            row.webDavFullPath = table.concat({properties.webDavNodePath, row.libname, row.fileName}, "/")
            table.insert(result, row)
         end
      end;

      -- Make sure that all columns are defined
      if(#result) then
         for k, v in pairs(columnList) do
            if(result[1][k] == nil) then
               if(v == "string") then
                  result[1][k] = ""
               else
                  result[1][k] = -1/0
               end
            end
         end
      end
      sas.write_ds(result, output)
   end
end
M.irmRestTableMap = irmRestTableMap

irmRestManageInstance = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      -- Get rid of unwanted properties
      jsonTable.results = nil
      jsonTable.id = nil
      jsonTable.details = nil
      jsonTable.links = nil
      if jsonTable.publishInfo ~= nil then
         jsonTable.published = true
         jsonTable.publishedBy = jsonTable.publishInfo.createdBy
         jsonTable.publishInfo = nil
      else
         jsonTable.published = false
         jsonTable.publishedBy = ""
         jsonTable.publishComments = ""
         jsonTable.publishTimestamp = ""
      end
      jsonTable = processBoolean(jsonTable)
      sas.write_ds({jsonTable}, output)
   end
end
M.irmRestManageInstance = irmRestManageInstance

irmRestMessages = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      local result = {}
      -- Loop through all rows
      for i, row in pairs(jsonTable) do
         row.id = nil
         table.insert(result, row)
      end;
      sas.write_ds(result, output)
   end
end
M.irmRestMessages = irmRestMessages

irmRestGetInstanceParams = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      -- Rename the following properties in the output table
      local result = {
         vars = {
            -- These attributes are mapped from jsonTable.items.model
            key = {type = "N"}
            , name = {type = "C", length = 200}
            , federatedAreaId = {type = "C", length = 50}
            , processKey = {type = "N"}
            , libname = {type = "C", length = 10}
            , rawPath = {type = "C", length = 200}
            , baseName = {type = "C", length = 100}
            , extension = {type = "C", length = 20}
            , path = {type = "C", length = 2048}
            , fileName = {type = "C", length = 500}
            -- These attributes are mapped from jsonTable.items.links
            , uri = {type = "C", length = 1024}
            , href = {type = "C", length = 1024}
         }
      }
      -- Loop through all rows
      for i, row in pairs(jsonTable.items) do
         -- Create empty record
         local record = {}
         -- Map all attributes of for the current row
         for k, v in pairs(result.vars) do
            if row.model[k] ~= nil then
               -- Attributes mapped from jsonTable.items.model
               record[k] = row.model[k]
            else
               -- Loop through all Link items
               for j, link in ipairs(row.links) do
                  -- Look for the Get method
                  if link.method == "GET" then
                     -- Attributes mapped from jsonTable.items.links
                     record[k] = link[k]
                  end
               end
            end
         end
         -- Get the table name (Strip the extension)
         record.table_name = record.name.gsub(string.upper(record.name), '.SAS7BDAT$', '')
         table.insert(result, record)
      end;
      -- Set length for table_name column
      result.vars.table_name = {type = "C", length = 50}

      -- Write result
      sas.write_ds(result, output)
   end
end
M.irmRestGetInstanceParams = irmRestGetInstanceParams


irmRestGetInstanceParamDetails = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   if jsonTable ~= nil then
      -- Rename the following properties in the output table
      local result = {
         vars = {
            name = {type = "C"}
            , table_name = {type = "C", length = 50}
            , config_name = {type = "C", length = 32}
            , config_value = {type = "C", length = 32000}
            , config_value_desc = {type = "C", length = 32000}
            , data_type = {type = "C", length = 10}
         }
      }

      -- Get the object name (including the extension)
      local obj_name = string.upper(jsonTable.model.name)
      -- Get the table name (Strip the extension)
      local tbl_name = obj_name.gsub(obj_name, '.SAS7BDAT$', '')

      -- Loop through all rows
      if jsonTable.model.parameters ~= nil then
         for i, row in pairs(jsonTable.model.parameters) do
            -- Get the required attributes
            local record = {
                    name = obj_name
                  , table_name = tbl_name
                  , config_name = row.name
                  , config_value = row.value
                  , config_value_desc = row.description
                  , data_type = row.type
               }
            table.insert(result, record)
         end;
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
end
M.irmRestGetInstanceParamDetails = irmRestGetInstanceParamDetails


-- Data Export
irmRestExportData = function(filename, output)
   local jsonTable = parseJSONFile(filename)
   local result = {}
   if jsonTable ~= nil then
   
      -- Get the rows
      result = jsonTable.data.rows
      
      local vars = {}
      -- Loop through all the columns to define the output table structure
      for i, var in pairs(jsonTable.meta.rows) do
         local vType = "N"
         if var.TYPE == 2 then
            vType = "C"
         end
         vars[var.NAME] = {type = vType, length = var.LENGTH, label = var.LABEL, format = var.FORMAT}
      end
      -- Set the output table structure
      result.vars = vars
      
      if #result == 0 then
         -- Make sure there is at least one record
         result[1] = {__tmp__ = ""}
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
M.irmRestExportData = irmRestExportData


return M
