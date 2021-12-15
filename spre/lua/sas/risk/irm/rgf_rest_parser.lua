--[[
/* Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA */

/*!
\file

\brief   Module provides JSON parsing functionality for interacting with the SAS Risk Cirrus Core Objects REST API

\details
   The following functions are available:
   - rgfRestPlain Parse a simple (one level) JSON structure
   - ...

\section ..

   Returns the list of workgroups defined in SAS Model Implementation Platform <br>

   <b>Syntax:</b> <i>(\<filename¦fileref\>, output)</i>

   <b>Sample JSON input structure: </b>
   \code

   \endcode

   <b>Sample Output: </b>


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

M.rgfRestPlain = json_utils.irmRestPlain

-- Clone a lua table recursively
clone = function(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[clone(k, s)] = clone(v, s) end
  return res
end

-- Converts tabs to spaces
function detab(text, tab_width)
   tab_width = tab_width or 3
   local function rep(match)
      local spaces = tab_width - match:len() % tab_width
      return match .. string.rep(" ", spaces)
   end
   text = text:gsub("([^\n]-)\t", rep)
   return text
end


-----------------------------------------------------------------------------------------
-- General Core parsing functions
-----------------------------------------------------------------------------------------

-- Return standard Core Object attributes
rgfObjectAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "C"}
         , objectId = {type = "C"}
         , sourceSystemCd = {type = "C"}
         , name = {type = "C"}
         , description = {type = "C"}
         , creationTimeStamp = {type = "C"}
         , modifiedTimeStamp = {type = "C"}
         , createdBy = {type = "C"}
         , modifiedBy = {type = "C"}
         , classification = {type = "C", length = 32000}
         , itemsCount = {type = "N"}
         , changeReason = {type = "C"}
         , objectLinks = {type = "C", length = 32000}
         --, , version = {type = "C"}
         --, solutionCreatedIn = {type = "C", length = 32}
      }
   }

   -- Return table structure
   return result
end

-- Return standard Core Attachment structure
rgfAttachmentAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "N"}
         , objectId = {type = "C"}
         , createdDttm = {type = "C"}
         , name = {type = "C"}
         , version = {type = "N"}
         , description = {type = "C"}
         , creator = {type = "N"}
         , updater = {type = "N"}
         , sourceSystemCd = {type = "C"}
         , changeReason = {type = "C"}
         , groupNo = {type = "N"}
         , urlTxt = {type = "C"}
         , contentType = {type = "C"}
         , typeCd = {type = "C"}
         , versionNumber = {type = "N"}
         , changeMessage = {type = "C"}
         , fileExtension = {type = "C"}
         , fileSize = {type = "N"}
         , revisionCd = {type = "C"}
         , modifiedDttm = {type = "C"}
         , fileName = {type = "C"}
      }
   }

   -- Return table structure
   return result

end

-- Return Core User Attributes
rgfUserAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "N"}
         , displayNm = {type = "C"}
         , confidentialityCd = {type = "N"}
         , userId = {type = "C"}
         , activeFlg = {type = "C"}
         , version = {type = "N"}
         , itemsCount = {type = "N"}
      }
   }

   -- Return table structure
   return result
end

-- Return Core LinkTypes Attributes
rgfLinkTypesAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "C"}
         , objectId = {type = "C"}
         , sourceSystemCd = {type = "C"}
         , side1Type = {type = "C"}
         , side1ObjectTypeKey = {type = "C"}
         , side2Type = {type = "C"}
         , side2ObjectTypeKey = {type = "C"}
         , itemsCount = {type = "N"}
      }
   }

   -- Return table structure
   return result
end


-- Return standard Core LinkInstances structure
rgfLinkInstancesAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "C"}
         , objectId = {type = "C"}
         , sourceSystemCd = {type = "C"}
         , businessObjectTypeNm1 = {type = "C"}
         , businessObjectTypeNm2 = {type = "C"}
         , linkType = {type = "C"}
         , businessObject1 = {type = "C"}
         , businessObject2 = {type = "C"}
         , createdBy = {type = "C"}
         , modifiedBy = {type = "C"}
         , creationTimeStamp = {type = "C"}
         , modifiedTimeStamp = {type = "C"}
         , itemsCount = {type = "N"}
      }
   }

   -- Return table structure
   return result
end

-- Return standard Regulatory Reporting Framework Instance structure
rgfInstancesAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "N"}
         , statusCd = {type = "C"}
         , taxonomyCd = {type = "C"}
         , selModuleCd = {type = "C"}
         , contextRefDt = {type = "C"}
         , lastUpdatedStr = {type = "C"}
         , objectLinks = {type = "C", length = 32000}
         , createdDttm = {type = "C"}
         , objectId = {type = "N"}
         , updater = {type = "N"}
         , sourceSystemCd = {type = "C"}
         , name = {type = "C"}
         , creator = {type = "C"}
         , version = {type = "N"}
      }
   }

   -- Return table structure
   return result
end


-- Return standard Regulatory Reporting Framework Instance Attachment structure
rgfInstanceAttachmentAttr = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   schema.vars.urlTxt = {type = "C"}
   schema.vars.contentType = {type = "C"}
   schema.vars.typeCd = {type = "C"}
   schema.vars.versionNumber = {type = "N"}
   schema.vars.changeMessage = {type = "C"}
   schema.vars.fileExtension = {type = "C"}
   schema.vars.fileSize = {type = "N"}
   schema.vars.revisionCd = {type = "C"}
   schema.vars.fileName = {type = "C"}

   -- Return schema
   return schema
end


-- Return standard Core ManagementOrg structure
rgfManagementOrgAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "N"}
         , selectable = {type = "C"}
         , leaf = {type = "C"}
         , managementOrgId = {type = "C"}
         , organizationNm = {type = "C"}
         , consolidationMethodCd = {type = "N"}
         , levelNo = {type = "N"}
         , sourceSystemCd = {type = "C"}
         , activeFromDttm = {type = "C"}
         , activeToDttm = {type = "C"}
         , organizationNm_lev1 = {type = "C"}
         , organizationNm_lev2 = {type = "C"}
         , organizationNm_lev3 = {type = "C"}
         , organizationNm_lev4 = {type = "C"}
         , organizationNm_lev5 = {type = "C"}
         , organizationNm_lev6 = {type = "C"}
         , organizationNm_lev7 = {type = "C"}
         , organizationNm_lev8 = {type = "C"}
         , organizationNm_lev9 = {type = "C"}
         , organizationNm_lev10 = {type = "C"}
      }
   }

   -- Return table structure
   return result
end


-- Attributes of the Core auxOpDim1 structure
rgfAuxOpDim1Attr = function()
  -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "N"}
         , auxOpDim1Nm = {type = "C"}
         , auxOpDim1Id = {type = "C"}
         , auxOpDim1Desc = {type = "C"}
         , sourceSystemCd = {type = "C"}
         , activeFromDttm = {type = "C"}
         , activeToDttm = {type = "C"}
         , leaf = {type = "C"}
         , levelNo = {type = "N"}
         , selectable = {type = "C"}
      }
   }

   -- Return table structure
   return result
end

-- Attributes of the Core auxOrgDim1 structure
rgfAuxOrgDim1Attr = function()
  -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "N"}
         , auxOrgDim1Nm = {type = "C"}
         , auxOrgDim1Id = {type = "C"}
         , auxOrgDim1Desc = {type = "C"}
         , sourceSystemCd = {type = "C"}
         , activeFromDttm = {type = "C"}
         , activeToDttm = {type = "C"}
         , leaf = {type = "C"}
         , levelNo = {type = "N"}
         , selectable = {type = "C"}
      }
   }

   -- Return table structure
   return result
end

-- Return standard Core dimensional points attributes
rgfDimPointAttr = function()
   -- Declare table structure
   local result = {
      vars = {
         -- Standard fields
         key = {type = "N"}
         , version = {type = "N"}
         , sourceSystemCd = {type = "C"}
         , dimPointRk = {type = "N"}
         , dimPointId = {type = "C"}
         , businessLine = {type = "N"}
         , costCenter = {type = "N"}
         , geography = {type = "N"}
         , legalOrg = {type = "N"}
         , managementOrg = {type = "N"}
         , auxOrgDim1 = {type = "N"}
         , process = {type = "N"}
         , product = {type = "N"}
         , project = {type = "N"}
         , resource = {type = "N"}
         , objective = {type = "N"}
         , auxOpDim1 = {type = "N"}
         , riskCategory = {type = "N"}
         , cause = {type = "N"}
         , nfiType = {type = "N"}
         , auxRiskDim1 = {type = "N"}
         , control = {type = "N"}
         , auxRmgDim1 = {type = "N"}
         , baselBusinessLine = {type = "N"}
         , baselRiskCategory = {type = "N"}
         , standardProcess = {type = "N"}
         , auxRptDim1 = {type = "N"}
         , financialStatementItem = {type = "N"}
      }
   }

   -- Return table structure
   return result
end


-- Process Core item attributes
rgfProcessAttr = function(item, func)

   -- Initialize output row
   local row = {}

   for attrName, attrValue in pairs(item) do
      -- Process customFields (if available)
      if(attrName == "customFields") then
         -- Loop through all customFields
         for key, value in pairs(attrValue) do
            if(type(value) == "table") then
               -- Convert table into plain string
               row[key] = json:encode(value)
            else
               row[key] = value
            end
         end
      else -- Process all other attributes
         if(type(attrValue) == "table") then
            -- Convert table into plain string
            row[attrName] = json:encode(attrValue)
         else
            row[attrName] = attrValue
         end

         -- Parse linked Objects
         --[[
         if(attrName == "objectLinks") then
            -- Loop through all linkInstances
            for i, linkInstance in ipairs(attrValue) do
               local businessObject1 = linkInstance.businessObject1
               local businessObject2 = linkInstance.businessObject2
               -- loop through all links, look for the url of businessObject1 and businessObject2
               for j, link in ipairs(linkInstance.links) do
                  if (link.rel == "businessObject1" or link.rel == "businessObject2") then
                     -- Extract the object type from the uri: /<contentId>/<objectType>/<objectId>
                     local objType = string.gsub(link.uri, "/%w+/(%w+)/%d+", "%1")
                     row[objType.."Key"] = linkInstance[link.rel]
                  end
               end;
            end
         end
         ]]--

         -- Parse Dimensional Points (grab only the first)
         if(attrName == "dimensionalPoints" and #attrValue > 0) then
            row.dimensionalPoint = attrValue[1]
         end

      end

   end

   -- Use custom function if provided
   if(func ~= nil) then
      row = func(item, row)
   end

   -- Return the processed row
   return row
end

-- General wrapper for REST calls of type objects/<solution>/<CustomObject>
rgfProcessItems = function(schema, jsonTable, output, func)
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
               -- Process current row
               local processedRecord = rgfProcessAttr(row, func)
               -- Check if the above call returned a single record or multiple records
               if #processedRecord > 0 then
                  -- It's a table with multiple records: Loop through all records
                  for j = 1, #processedRecord do
                     -- Insert current record to the result
                     table.insert(result, processedRecord[j])
                  end
               else
                  -- It's a single record: add it to the output table
                  table.insert(result, processedRecord)
               end
            end
            -- Process boolean attributes
            result = json_utils.processBoolean(result)
         else
            -- Check if this is a single item
            if jsonTable.key ~= nil then

               -- Process current row
               local processedRecord = rgfProcessAttr(jsonTable, func)
               -- Check if the above call returned a single record or multiple records
               if #processedRecord > 0 then
                  -- It's a table with multiple records: Loop through all records
                  for j = 1, #processedRecord do
                     processedRecord[j].itemsCount = 1
                     -- Insert current record to the result
                     table.insert(result, processedRecord[j])
                  end
               else
                  processedRecord.itemsCount = 1
                  -- It's a single record: add it to the output table
                  table.insert(result, processedRecord)
               end

               -- Process boolean attributes
               result = json_utils.processBoolean(result)
            end
         end
      end
      
      if output ~= nil then
         if #result == 0 then
            -- Make sure there is at least one record
            result[1] = {key = -1}
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
-- Core parser functions
-----------------------------------------------------------------------------------------


-----------------------------
-- Users
-----------------------------

-- Parser for objects/<solution>/Users
rgfRestUsers = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define LinkTypes Attributes
   local schema = rgfUserAttr()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestUsers = rgfRestUsers


-----------------------------
-- linkTypes
-----------------------------

-- Parser for objects/<solution>/linkTypes
rgfRestLinkTypes = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define LinkTypes Attributes
   local schema = rgfLinkTypesAttr()
   
   -- Local function for expanding the side1 and side2 keys
   local linkSideFunc = function(item, row)
      row=item
      row["side1Type"]=item.side1.type
      row["side1ObjectTypeKey"]=item.side1.typeKey
      row["side2Type"]=item.side2.type
      row["side2ObjectTypeKey"]=item.side2.typeKey
      return row
   end
   
   -- Process all items
   rgfProcessItems(schema, jsonTable, output, linkSideFunc)
   
end
M.rgfRestLinkTypes = rgfRestLinkTypes


-----------------------------
-- linkInstances
-----------------------------

-- Parser for objects/<solution>/<objectType>/<objectKey>/linkInstances/<linkTypeKey>
rgfRestLinkInstances = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define LinkTypes Attributes
   local schema = rgfLinkInstancesAttr()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestLinkInstances = rgfRestLinkInstances

-----------------------------
-- Regulatory Reporting Framework Instance
-----------------------------

-- Parser for objects/<solution>/linkInstances
rgfRestInstances = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define LinkTypes Attributes
   local schema = rgfInstancesAttr()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestInstances = rgfRestInstances


-----------------------------
-- Regulatory Reporting Framework Instance Attachment
-----------------------------

-- Parser for objects/<solution>/linkInstances
rgfRestInstanceAttachment = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define LinkTypes Attributes
   local schema = rgfInstanceAttachmentAttr()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestInstanceAttachment = rgfRestInstanceAttachment


-----------------------------
-- managementOrg
-----------------------------
rgfRestManagementOrg = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define managementOrg Attributes
   local schema = rgfManagementOrgAttr()

   -- Local function for expanding the Management Org Path attribute
   local mgmtOrgPathFunc = function(item, row)
      local i
      for i = 1, item.levelNo do
         row["organizationNm_lev" .. i] = item.path[i]
      end
      return row
   end

   -- Process all items
   rgfProcessItems(schema, jsonTable, output, mgmtOrgPathFunc)
end
M.rgfRestManagementOrg = rgfRestManagementOrg

---------------------------------
-- auxOpDim1 (SolutionCreatedIn)
---------------------------------
rgfRestAuxOpDim1 = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define attributes
   local schema = rgfAuxOpDim1Attr()

   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestAuxOpDim1 = rgfRestAuxOpDim1

------------------------------------
-- auxOrgDim1 (SolutionsSharedWith)
------------------------------------
rgfRestAuxOrgDim1 = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define attributes
   local schema = rgfAuxOrgDim1Attr()

   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestAuxOrgDim1 = rgfRestAuxOrgDim1

-----------------------------------------------------------------------------------------
-- Core Schemas
-----------------------------------------------------------------------------------------

-- Attributes of the Core dataDefinition custom object
rmcSchemaDataDefinition = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the dataDefinition object
   schema.vars.libref = {type = "C"}
   schema.vars.metaLibraryNm = {type = "C"}
   schema.vars.engine = {type = "C"}
   schema.vars.schemaName = {type = "C"}
   schema.vars.schemaVersion = {type = "C"}
   schema.vars.schemaTypeCd = {type = "C"}
   schema.vars.dataCategoryCd = {type = "C"}
   schema.vars.dataSubCategoryCd = {type = "C"}
   schema.vars.businessCategoryCd = {type = "C"}
   schema.vars.riskTypeCd = {type = "C"}
   schema.vars.dataType = {type = "C"}
   schema.vars.reportmartGroupId = {type = "C"}
   schema.vars.martLibraryNm = {type = "C"}
   schema.vars.martTableNm = {type = "C"}
   schema.vars.rlsTableNm = {type = "C"}
   schema.vars.lasrLibraryNm = {type = "C"}
   schema.vars.lasrMetaFolder = {type = "C"}
   schema.vars.casLibraryNm = {type = "C"}
   schema.vars.martAggregationEnabled = {type = "C"}
   schema.vars.martConditionalAggregation = {type = "C", length = 32000}
   schema.vars.martFilter = {type = "C", length = 32000}

   -- Return schema
   return schema
end

-- Attributes of the Core analysisData custom object
rmcSchemaAnalysisData = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the analysisData object
   schema.vars.baseDate = {type = "C"}
   schema.vars.statusCd = {type = "C"}
   schema.vars.visibilityStatusCd = {type = "C"}
   schema.vars.resultsCategoryCd = {type = "C"}
   schema.vars.updatedDttm = {type = "C"}
   schema.vars.showRelationships = {type = "C"}
   schema.vars.cyclesKey = {type = "N"}
   schema.vars.dataDefinitionsKey = {type = "N"}
   schema.vars.dimensionalPoint = {type = "N"}

   -- Return schema
   return schema
end

-- Attributes of the Core segments custom object
rmcSchemaSegments = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the segments object
   schema.vars.segmentVariables = {type = "C", length = 1024}

   -- Return schema
   return schema
end

-- Attributes of the Core allocationScheme custom object
rmcSchemaAllocationScheme = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the allocationScheme object
   schema.vars.strategyMethod = {type = "C"}
   schema.vars.modelParameters = {type = "C", length = 32000}
   schema.vars.synthInstAllocation = {type = "C", length = 32000}
   schema.vars.segmentationVarList = {type = "C", length = 2048}
   schema.vars.segmentationVars = {type = "C", length = 32000}

   -- LinkedObjects
   schema.vars.analysisDataKey = {type = "N"}
   schema.vars.segmentsKey = {type = "N"}
   schema.vars.modelsKey = {type = "N"}

   -- Return schema
   return schema
end

-- Attributes of the Core businessEvolution custom object
rmcSchemaBusinessEvolution = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the BusinessEvolution object
   schema.vars.bepShortName = {type = "C", length = 12}
   schema.vars.interval = {type = "C", length = 32}
   schema.vars.intervalCount = {type = "N"}
   schema.vars.allocationFlg = {type = "C", length = 3}
   schema.vars.allocationSchemeKey = {type = "N"}
   schema.vars.planningDataKey = {type = "C", length = 2048}
   schema.vars.segmentationVarList = {type = "C", length = 2048}
   schema.vars.segmentationVars = {type = "C", length = 32000}
   schema.vars.modelKey = {type = "N"}
   schema.vars.modelRunKey = {type = "N"}
   schema.vars.modelParams = {type = "C", length = 32000}
   schema.vars.targetVariable = {type = "C", length = 256}
   schema.vars.accountID = {type = "C", length = 256}
   schema.vars.bepVarsInfo = {type = "C", length = 32000}
   schema.vars.fundSrcVars = {type = "C", length = 1024}
   schema.vars.dataDefSchemaName = {type = "C", length = 1024}
   schema.vars.dataDefSchemaVersion = {type = "C", length = 1024}

   -- Return schema
   return schema
end

-- Attributes of the Core Cycle custom object
rmcSchemaCycle = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the analysisData object
   schema.vars.statusCd = {type = "C"}
   schema.vars.cycleStartDt = {type = "C"}
   schema.vars.cycleEndDt = {type = "C"}
   schema.vars.baseDt = {type = "C"}
   schema.vars.versionNm = {type = "C"}
   schema.vars.coreVersionNm = {type = "C"}
   schema.vars.entityId = {type = "C"}
   schema.vars.initialRunFlg = {type = "C"}
   schema.vars.FuncCurrency = {type = "C"}

   -- Return schema
   return schema
end

-- Attributes of the Core analysisRun custom object
rmcSchemaAnalysisRun = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the analysisData object
   schema.vars.statusCd = {type = "C"}
   schema.vars.initStatusCd = {type = "C"}
   schema.vars.versionCd = {type = "C"}
   schema.vars.cycleTaskName = {type = "C", length = 400}
   schema.vars.modelParameters = {type = "C", length = 32000}
   schema.vars.showRelationships = {type = "C"}
   schema.vars.executionDt = {type = "C"}
   schema.vars.executionDttm = {type = "C"}
   schema.vars.prodRunFlg = {type = "C"}
   schema.vars.cyclesKey = {type = "N"}
   schema.vars.sasCode = {type = "C", length = 32000}
   schema.vars.sasParams = {type = "C", length = 32000}
   schema.vars.dimensionalPoint = {type = "N"}

   -- Return schema
   return schema
end

-- Attributes of the Core analysisRun custom object
rmcSchemaModelRun = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the analysisData object
   schema.vars.statusCd = {type = "C"}
   schema.vars.initStatusCd = {type = "C"}
   schema.vars.executionDt = {type = "C"}
   schema.vars.executionDttm = {type = "C"}
   schema.vars.cycleTaskName = {type = "C", length = 400}
   schema.vars.sasCode = {type = "C", length = 32000}
   schema.vars.sasPreCode = {type = "C", length = 32000}
   schema.vars.sasPostCode = {type = "C", length = 32000}
   schema.vars.mipPreCode = {type = "C", length = 32000}
   schema.vars.mipPostCode = {type = "C", length = 32000}
   schema.vars.modelParameters = {type = "C", length = 32000}
   schema.vars.sasParams = {type = "C", length = 32000}
   schema.vars.dimensionalPoint = {type = "N"}

   -- Return schema
   return schema
end


-- Attributes of the Core model custom object
rmcSchemaModel = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the analysisData object
   schema.vars.statusCd = {type = "C"}
   schema.vars.businessCatCd = {type = "C"}
   schema.vars.typeCd = {type = "C"}
   schema.vars.subTypeCd = {type = "C"}
   schema.vars.versionId = {type = "C"}
   schema.vars.engineCd = {type = "C"}
   schema.vars.runTypeCd = {type = "C"}
   schema.vars.parameters = {type = "C", length = 32000}
   schema.vars.codeEditor = {type = "C", length = 32000}
   schema.vars.preCodeEditor = {type = "C", length = 32000}
   schema.vars.postCodeEditor = {type = "C", length = 32000}
   schema.vars.preCodeFlg = {type = "C"}
   schema.vars.postCodeFlg = {type = "C"}
   schema.vars.scenWeightFlg = {type = "C"}

   -- Return schema
   return schema
end

-- Attributes of the Core script object
rmcSchemaScript = function()
   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the analysisData object
   schema.vars.statusCd = {type = "C"}
   schema.vars.typeCd = {type = "C"}
   schema.vars.engineCd = {type = "C"}
   schema.vars.parameters = {type = "C", length = 32000}
   schema.vars.codeEditor = {type = "C", length = 32000}
   schema.vars.independentRunFlg = {type = "C"}
   schema.vars.rolesForIndependentRun = {type = "C", length = 32000}

   -- Return schema
   return schema
end


-- Attributes of the Core MasterRiskScenario custom object
rmcSchemaMasterRiskScenario = function(details_flg)

   -- Process details_flg parameter
   details_flg = details_flg or "N"
   details_flg = string.upper(details_flg)

   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the MasterRiskScenario object
   schema.vars.defaultWeight = {type = "N"}
   schema.vars.multiForecastFlg = {type = "C"}
   schema.vars.mrsShortName = {type = "C", length = 12}

   if details_flg == "Y" then
      -- Add details about each scenario associated with this master risk scenario
      schema.vars.scenarioId = {type = "C"}
      schema.vars.scenarioName = {type = "C"}
      schema.vars.scenarioVersion = {type = "N"}
      schema.vars.deprecated = {type = "C"}
      schema.vars.modifiedBy = {type = "C"}
      schema.vars.modifiedByName = {type = "C"}
      schema.vars.modifiedTimeStamp = {type = "C"}
      schema.vars.label = {type = "C"}
      schema.vars.creationTimeStamp = {type = "C"}
      schema.vars.sourceId = {type = "C"}
      schema.vars.baselineId = {type = "C"}
      schema.vars.readOnly = {type = "C"}
      schema.vars.createdByName = {type = "C"}
      schema.vars.createdBy = {type = "C"}
      schema.vars.periodType = {type = "C"}
      schema.vars.workGroup = {type = "C"}
      schema.vars.forecastTime = {type = "N"}
   else
      schema.vars.riskScenarioData = {type = "C", length = 32000}
   end

   -- Return schema
   return schema
end



-- Attributes of the Core Data Map custom object
rmcSchemaDataMap = function(details_flg)

   -- Define Standard Core Attributes
   local schema

   -- Set default value if nil
   details_flg = details_flg or "N"

   if(details_flg == "N") then
      schema = rgfObjectAttr()

      -- Add Custom Fields for the DataMap object
      schema.vars.mapType = {type = "C"}
      --schema.vars.mappingInfo = {type = "C", length = 32000}
   else
      schema = {vars = {}}
      schema.vars.dataMapKey = {type = "N"}
      schema.vars.dataMapName = {type = "C"}
      schema.vars.map_type = {type = "C"}
      schema.vars.rowKey = {type = "N"}
      schema.vars.source_var_name = {type = "C"}
      schema.vars.target_var_name = {type = "C"}
      schema.vars.expression_txt = {type = "C", length = 10000}
      schema.vars.mapping_desc = {type = "C", length = 1024}
      schema.vars.target_var_type = {type = "C"}
      schema.vars.target_var_length = {type = "N"}
      schema.vars.target_var_label = {type = "C"}
      schema.vars.target_var_fmt = {type = "C"}
      schema.vars.filterExpression = {type = "C", length = 32000}
      schema.vars.filterAssignment = {type = "C", length = 32000}
   end
   -- Return schema
   return schema
end

-- Attributes of the Core Workflow Template custom object
-- Valid types for the schema_type argument are "info", "model_mapping", "task_details", "review_activities"
rmcSchemaWfTemplate = function(schema_type)

   -- Define Standard Core Attributes
   local schema

   -- Set default value if nil
   schema_type = schema_type or "info"
   schema_type = string.lower(schema_type)

   -- If schema type is info, return the basic object info and custom fields
   if(schema_type == "info") then
      schema = rgfObjectAttr()
      schema.vars.wfTemplateNm = {type = "C"}
      schema.vars.wfTag = {type = "C", length = 64}
      schema.vars.fileNm = {type = "C"}
   -- If schema type is model_mapping, return the model mapping
   elseif (schema_type == "model_mapping") then
      schema = {vars = {}}
      schema.vars.activity = {type = "C", length = 1024}
      schema.vars.modelSscId = {type = "C", length = 1024}
   -- If schema type is task_details, return the task details
   elseif (schema_type == "task_details") then
      schema = {vars = {}}
      schema.vars.activity = {type = "C", length = 1024}
      schema.vars.duration = {type = "C", length = 1024}
      schema.vars.taskKey = {type = "C", length = 1024}
      schema.vars.role = {type = "C", length = 1024}
      schema.vars.statusCd = {type = "C", length = 64}
      schema.vars.subStatusCdField = {type = "C", length = 64}
      schema.vars.subStatusCdValue = {type = "C", length = 64}
   -- If schema type is review_activities, return the review activities
   elseif (schema_type == "review_activities") then
      schema = {vars = {}}
      schema.vars.linkHref = {type = "C", length = 32000}
      schema.vars.linkOrder = {type = "N"}
      schema.vars.linkText = {type = "C", length = 1024}
      schema.vars.taskName = {type = "C", length = 1024}
   end
   -- Return schema
   return schema
end


-- Attributes of the Core AttributionAnalysis custom object
rmcSchemaAttributionAnalysis = function(details_flg)

   -- Process details_flg parameter
   details_flg = details_flg or "N"
   details_flg = string.upper(details_flg)

   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add standard Core custom fields
   schema.vars.solutionCreatedIn = {type = "C"}

   if details_flg == "Y" then
      -- Add details about each scenario associated with this master risk scenario
      schema.vars.attributionGroupNo = {type = "N"}
      schema.vars.attributionGroupName = {type = "C", length = 100}
      schema.vars.attributeName = {type = "C", length = 100}
      schema.vars.attributionType = {type = "C", length = 100}
      schema.vars.attributionVars = {type = "C", length = 32000}
      schema.vars.Members = {type = "C", length = 100}
      schema.vars.Description = {type = "C", length = 256}
   else
      schema.vars.attFactors = {type = "C", length = 32000}
      schema.vars.outputVars = {type = "C", length = 32000}
   end

   schema.vars.transferFromLabel = {type = "C", length = 100}
   schema.vars.transferToLabel = {type = "C", length = 100}

   -- Return schema
   return schema
end



-- Attributes of the Core Shortcuts custom object
rmcSchemaShortcut = function()

   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the analysisData object
   schema.vars.orderNo = {type = "N"}
   schema.vars.id = {type = "C"}
   schema.vars.name = {type = "C"}
   schema.vars.url = {type = "C"}
   schema.vars.selected = {type = "C"}
   schema.vars.version = {type = "N"}

   -- Return schema
   return schema
end



-- Attributes of the Core Members custom object
rmcSchemaMember = function()

   -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the Member object
   schema.vars.statusCd = {type = "C"}
   schema.vars.version = {type = "N"}
   schema.vars.memberCd = {type = "C"}
   schema.vars.memberInternalCd = {type = "C"}
   schema.vars.memberAttributes = {type = "C", length = 32000}
   schema.vars.memberAttributeNames = {type = "C", length = 1024}
   schema.vars.accountType = {type = "C", length = 16}
   schema.vars.functionalCurrencyCd = {type = "C", length = 3}
   schema.vars.reportingCurrencyCd = {type = "C", length = 3}
   schema.vars.validFrom = {type = "C"}
   schema.vars.validTo = {type = "C"}

   -- Return schema
   return schema
end



-- Attributes of the Core Hierarchy custom object
rmcSchemaHierarchy = function(details_flg)

  -- Define Standard Core Attributes
   local schema = rgfObjectAttr()

   -- Add Custom Fields for the Hierarchy object
   schema.vars.statusCd = {type = "C"}
   schema.vars.version = {type = "N"}
   schema.vars.dimension = {type = "C"}
   schema.vars.hierarchyCd = {type = "C", length = 36}
   schema.vars.hierarchyInternalCd = {type = "C"}
   schema.vars.validFrom = {type = "C"}
   schema.vars.validTo = {type = "C"}
   schema.vars.workflowTemplate = {type = "C", length = 300}
   schema.vars.members = {type = "C", length = 32000}

   -- Return schema
   return schema
end


-----------------------------------------------------------------------------------------
-- Core parser functions
-----------------------------------------------------------------------------------------

-----------------------------
-- Object Basic Information
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/dataDefinitions
rgfRestObjectInfo = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rgfObjectAttr()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestObjectInfo = rgfRestObjectInfo

-----------------------------
-- Attachments
-----------------------------

-- Parser for objects/<solution>/attachments/<object_uri>/<object_key>
rgfRestAttachment = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define LinkTypes Attributes
   local schema = rgfAttachmentAttr()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestAttachment = rgfRestAttachment

-----------------------------
-- Dimensional Points
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/dimensionalPoints
rgfRestDimPoints = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rgfDimPointAttr()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rgfRestDimPoints = rgfRestDimPoints

-----------------------------
-- dataDefinition
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/dataDefinitions
rmcRestDataDefinition = function(filename, outputSummary, outputColInfo, outputAggregationConfig)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaDataDefinition()
   -- Process all items
   local result = rgfProcessItems(schema, jsonTable, outputSummary)

   -- Process columnInfo field
   if outputColInfo ~= nil then
      local columnInfoTable = {vars = {}}
      columnInfoTable.vars.dataDefKey = result.vars.key
      columnInfoTable.vars.dataDefName = result.vars.name
      columnInfoTable.vars.key = {type = "C"}
      columnInfoTable.vars.name = {type = "C"}
      columnInfoTable.vars.config_readOnly = {type = "C"}
      columnInfoTable.vars.label = {type = "C"}
      columnInfoTable.vars.type = {type = "C"}
      columnInfoTable.vars.size = {type = "N"}
      columnInfoTable.vars.format = {type = "C"}
      columnInfoTable.vars.informat = {type = "C"}
      columnInfoTable.vars.primary_key_flg = {type = "C"}
      columnInfoTable.vars.partition_flg = {type = "C"}
      columnInfoTable.vars.filterable = {type = "C"}
      columnInfoTable.vars.classification = {type = "C"}
      columnInfoTable.vars.attributable = {type = "C"}
      columnInfoTable.vars.mandatory_segmentation = {type = "C"}
      columnInfoTable.vars.projection = {type = "C"}
      columnInfoTable.vars.fx_var = {type = "C"}

      -- Loop through all data definitions
      for i, row in ipairs(result) do
         if(row.columnInfo ~= nil) then
            -- row.columnInfo is a JSON table stored as a string: need to decode it
            local cols = json:decode(row.columnInfo)
            -- Loop through all columnInfo
            for j, item in ipairs(cols.items) do
               local col = {}
               col.dataDefKey = row.key
               col.dataDefName = row.name
               -- Loop through all attributes of the column
               for attrName, attrValue in pairs(item) do
                  if type(attrValue) == "table" then
                     -- It is a complex parameter. Need to encode it
                     col[attrName] = json:encode(attrValue)
                  else
                     col[attrName] = attrValue
                  end
               end
               table.insert(columnInfoTable, col)
            end
         end
      end
      if #columnInfoTable == 0 then
         -- Make sure there is at least one record
         columnInfoTable[1] = {dataDefKey = -1}
         -- Write table
         sas.write_ds(columnInfoTable, outputColInfo)
         -- Now remove the empty record
         sas.submit([[data @outputColInfo@; set @outputColInfo@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(columnInfoTable, outputColInfo)
      end
   end -- if outputColInfo ~= nil

   -- Process martAggregationConfig field
   if outputAggregationConfig ~= nil then
      local aggregationConfigTable = {vars = {}}
      aggregationConfigTable.vars.dataDefKey = result.vars.key
      aggregationConfigTable.vars.dataDefName = result.vars.name
      aggregationConfigTable.vars.var_name = {type = "C"}
      aggregationConfigTable.vars.var_scope = {type = "C"}
      aggregationConfigTable.vars.weight_var = {type = "C"}
      aggregationConfigTable.vars.alias = {type = "C"}

      -- Loop through all data definitions
      for i, row in ipairs(result) do
         if(row.martAggregationConfig ~= nil) then
            -- row.martAggregationConfig is a JSON table stored as a string: need to decode it
            local cols = json:decode(row.martAggregationConfig)
            -- Loop through all columnInfo
            for j, item in ipairs(cols.items) do
               local col = {}
               col.dataDefKey = row.key
               col.dataDefName = row.name
               -- Loop through all attributes of the column
               for attrName, attrValue in pairs(item) do
                  if type(attrValue) == "table" then
                     -- It is a complex parameter. Need to encode it
                     col[attrName] = json:encode(attrValue)
                  else
                     col[attrName] = attrValue
                  end
               end
               table.insert(aggregationConfigTable, col)
            end
         end
      end
      if #aggregationConfigTable == 0 then
         -- Make sure there is at least one record
         aggregationConfigTable[1] = {dataDefKey = -1}
         -- Write table
         sas.write_ds(aggregationConfigTable, outputAggregationConfig)
         -- Now remove the empty record
         sas.submit([[data @outputAggregationConfig@; set @outputAggregationConfig@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(aggregationConfigTable, outputAggregationConfig)
      end
   end -- if outputAggregationConfig ~= nil

end
M.rmcRestDataDefinition = rmcRestDataDefinition


-----------------------------
-- analysisData
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/AnalysisData
rmcRestAnalysisData = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaAnalysisData()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rmcRestAnalysisData = rmcRestAnalysisData

-----------------------------
-- Segmentation scheme
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/AnalysisData
rmcRestSegmentationScheme = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaSegments()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rmcRestSegmentationScheme = rmcRestSegmentationScheme

-----------------------------
-- businessEvolution
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/BusinessEvolution
rmcRestBusinessEvolution = function(filename, outputSummary, outputEvolution)

   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)

   -- If allocationFlg is false for a row, may have multiple planning data. Create a row for each.
   -- Note that modelRunKey will be the same for each row as there is only one model
   local modItems = {}
   local hasAllocationEntries = false;
   local hasBSPEntries = false;

   local items = jsonTable.items or {jsonTable};
   for i,item in ipairs(items) do
      if(not item.customFields.allocationFlg) then
         hasBSPEntries = true;
         if(item.customFields.planDataSegsAndTargets and item.customFields.planDataSegsAndTargets ~= "") then
            local planDataTbl = json:decode(item.customFields.planDataSegsAndTargets)
            local targetVariable = {};
            local accountID = {};
            local planningDataKey = {};
            local dataDefSchemaName = {};
            local dataDefSchemaVersion = {};
            local fundSrcVars = {};
            local fields = item.customFields;
            local bepDetails = json:decode(fields.BEPDetails);

            --Find an entry with data (i.e. not projModelDetails) and get unique schema name / versions from there
            for _,v in pairs(bepDetails) do
               if(v.bepData) then
                  for _,data in ipairs(v.planData) do
                     table.insert(dataDefSchemaName,data.schemaName);
                     table.insert(dataDefSchemaVersion,data.schemaVersion);
                  end
                  break
               end
            end

            --Grab the target variable, account ID, and planning data key for this row
            for p,plan in ipairs(planDataTbl.items) do
               table.insert(targetVariable,plan.target);
               table.insert(accountID,plan.accountID);
               table.insert(planningDataKey,plan.planData.key);
            end

            --Get Model information
            local projModelDetails = bepDetails.projModelDetails;
            if projModelDetails then
               fields.modelKey = projModelDetails.modelKey;
               fields.modelRunKey = projModelDetails.modelRunKey;
            end

            --Get funding source vars
            local bepVars = json:decode(fields.bepVarsInfo)
            for _,var in ipairs(bepVars.targets) do
               if(var.type == 'fundingSources') then
                  table.insert(fundSrcVars,var.value .. "_source")
               end
            end

            fields.targetVariable=json:encode(targetVariable):gsub("[%[%]\"]","");
            fields.accountID=json:encode(accountID):gsub("[%[%]\"]","");
            fields.planningDataKey=json:encode(planningDataKey):gsub("[%[%]\"]","");
            fields.dataDefSchemaName=json:encode(dataDefSchemaName):gsub("[%[%]\"]","");
            fields.dataDefSchemaVersion=json:encode(dataDefSchemaVersion):gsub("[%[%]\"]","");
            fields.fundSrcVars=json:encode(fundSrcVars):gsub("[%[%]\"]","");

            table.insert(modItems,item);
         end
      else
         hasAllocationEntries = true;
         item.customFields.targetVariable = item.customFields.lastSelectedTargetVariable;
         item.customFields.planDataSegsAndTargets = '{"count":0,"items":[]}';
         local thisBepDetails = json:decode(item.customFields.BEPDetails);
         item.customFields.modelKey = thisBepDetails[item.customFields.lastSelectedTargetVariable].modelKey;
         item.customFields.modelRunKey = thisBepDetails[item.customFields.lastSelectedTargetVariable].modelRunKey;
         table.insert(modItems,item);
      end
   end
   jsonTable.items = modItems;

   -- Define businessEvolution Attributes
   local schema = rmcSchemaBusinessEvolution()

   -- Local function for extracting the list of segmentation variables
   local getSegmentationVars = function(item, row)
      local i, var

      -- Convert allocationFlg from boolean to Y/N
      -- segmentationVars not present when allocationFlg is false
      local segmentationVars = {}
      row.segmentationVarList = ""
      if(item.customFields.allocationFlg == true) then
         row.allocationFlg = "Y"
         if(item.customFields.segmentationVars) then
            segmentationVars = json:decode(item.customFields.segmentationVars)
            for i, var in ipairs(segmentationVars) do
               row.segmentationVarList = row.segmentationVarList .. " " .. var.name
            end
         end
         row.segmentationVarList = sas.strip(row.segmentationVarList)
      else
         row.allocationFlg = "N"
      end

      return row
   end

   -- Process main table (one record per BEP)
   local result = rgfProcessItems(schema, jsonTable, outputSummary, getSegmentationVars)
   if #result == 0 or (#result == 1 and result[1].key<0) then
      result = {vars = result.vars}
   end

   -- Process the Evolution details (if required)
   if outputEvolution ~= nil then
      local evolutionDetails = {vars = {}}
      -- Declare fixed columns the detail table
      evolutionDetails.vars.bepKey = schema.vars.key
      evolutionDetails.vars.bepName = schema.vars.name
      evolutionDetails.vars.bepShortName = schema.vars.bepShortName
      evolutionDetails.vars.planningDataKey = schema.vars.planningDataKey
      evolutionDetails.vars.interval = schema.vars.interval
      evolutionDetails.vars.modelKey = {type = "N"}
      evolutionDetails.vars.modelRunKey = {type = "N"}
      evolutionDetails.vars.targetVarName = {type = "C", length = "32"}
      evolutionDetails.vars.activationHorizon = {type = "N"}
      evolutionDetails.vars.absoluteValue = {type = "N"}
      evolutionDetails.vars.allocationFlg = {type = "C", length = "8"}
      if(hasAllocationEntries) then
         -- Segmentation variables might be different across multiple BEPs. The resulting table will contain all segmentation variables
         evolutionDetails.vars.changeType = {type = "C", length = "32"}
         evolutionDetails.vars.relativeValue = {type = "N"}
         evolutionDetails.vars.relativePct = {type = "N", format = "percent8.2"}
      end
      if(hasBSPEntries) then
         local varFormats = {}
         varFormats.number = {type = "N"}
         varFormats.percent = {type = "N", format = "percent8.2"}
         varFormats.dropdown = {type = "C", length = "256"}
         varFormats.string = {type = "C", length = "32000"}
         varFormats.fundingSrc = {type = "C", length = "512"}
         varFormats.allocPct = {type = "N"}
         varFormats.string = {type = "C", length = "32000"}
         varFormats.default = {type = "C", length = "32000"}
         -- Go through the variables and add them to the output
         for _,row in ipairs(result) do
            if(row.allocationFlg == "N" and sas.strip(row.bepVarsInfo) ~= "") then
               evolutionDetails.vars.varFamily = {type = "C", length = "256"}
               evolutionDetails.vars.accountID = {type = "C", length = "256"}
               local bepVars = json:decode(row.bepVarsInfo)
               for _,var in ipairs(bepVars.targets) do
                  if(var.type == 'fundingSources') then
                     evolutionDetails.vars[var.value .. "_source"] = {type = "C", length = "256"}
                     evolutionDetails.vars[var.value .. "_percent"] = {type = "N"}
                  else
                     evolutionDetails.vars[var.value] =  varFormats[var.type] or varFormats.default
                  end
               end
            end
         end
      end

      --First, get one row per planning data. Since BEP may have multiple planning data, will get possibly multiple rows per BEP
      local newResult={};
      for i,row in ipairs(result) do
         local planData = json:decode(row.planDataSegsAndTargets);
         if planData.count > 0 then
            for d,data in ipairs(planData.items) do
               local newRow = clone(row)
               newRow.targetVariable = sas.scan(row.targetVariable,d,",")
               newRow.accountID = sas.scan(row.accountID,d,",")
               newRow.planningDataKey = sas.scan(row.planningDataKey,d,",")
               newRow.dataDefSchemaName = sas.scan(row.dataDefSchemaName,d,",")
               newRow.dataDefSchemaVersion = sas.scan(row.dataDefSchemaVersion,d,",")
               if type(newRow.BEPDetails) == 'string' then
                  newRow.BEPDetails = json:decode(newRow.BEPDetails)
               end
               for k,v in pairs(newRow.BEPDetails) do
                  if v.planData then
                     v.planData = v.planData[d]
                  end
                  if v.bepData then
                     v.bepData = v.bepData[d]
                  end
               end
               newRow.BEPDetails = json:encode(newRow.BEPDetails)
               table.insert(newResult,newRow)
            end
         else
            table.insert(newResult,row)
         end
      end

      -- Loop through all Business Evolution Plans
      for i, row in ipairs(newResult) do

         -- Process the BEPDetails (if available) associated with the current BEP
         if row.BEPDetails ~= nil then
            -- row.BEPDetails is a JSON table stored as a string: need to decode it
            local bepDetails = json:decode(row.BEPDetails)

            local keysWithBEPData = {}
            -- Allocation case
            local segmentationVars
            if row.allocationFlg == "Y" then
               -- row.targetVariables is a JSON array stored as a string: need to decode it
               keysWithBEPData = json:decode(row.targetVariables)

               -- row.segmentationVars is a JSON table stored as a string: need to decode it
               segmentationVars = json:decode(row.segmentationVars)

               -- Declare the dynamic columns of the detail table
               for m, var in ipairs(segmentationVars) do
                  local varType = "N"
                  if var.type == "Char" then
                     varType = "C"
                  end
                  evolutionDetails.vars[var.name] = {type = varType, length = var.size}
               end
            else
               local families = (json:decode(row.bepVarsInfo)).families
               keysWithBEPData = {}
               for _,k in pairs(families) do
                  table.insert(keysWithBEPData,k.value)
               end
            end

            -- Loop through all target variables
            for _, keyVar in ipairs(keysWithBEPData) do
               -- Extract the details of the current target variable
               local item = bepDetails[keyVar]
               -- Get the bepData for this target variable
               local bepData = item.bepData
               local planData = item.planData or {schemaName="",schemaVersion=""}

               -- Loop through all records of the BEP spreadsheet component
               for k, data in pairs(bepData.items) do
                  local rowDetail = {}

                  --Add in planning data's data definition schema info
                  if(item.planData) then
                     rowDetail.dataDefSchemaName = planData.schemaName
                     rowDetail.dataDefSchemaVersion = planData.schemaVersion
                  end

                  rowDetail.bepKey = row.key
                  rowDetail.bepName = row.name
                  rowDetail.bepShortName = row.bepShortName
                  rowDetail.planningDataKey = row.planningDataKey
                  rowDetail.modelKey = row.modelKey
                  rowDetail.modelRunKey = row.modelRunKey
                  rowDetail.allocationFlg = row.allocationFlg

                  rowDetail.interval = row.interval
                  rowDetail.activationHorizon = 0

                  if row.allocationFlg == "Y" then
                     -- Get the segments
                     for m, var in ipairs(segmentationVars) do
                        rowDetail[var.name] = data[var.name]
                     end
                     rowDetail.changeType = data.changeType
                     rowDetail.targetVarName = keyVar
                     rowDetail.absoluteValue = data[keyVar]
                  else
                     rowDetail.varFamily = keyVar
                     rowDetail.targetVarName = row.targetVariable
                     rowDetail.absoluteValue = data[row.targetVariable]
                     rowDetail.accountID = data[row.accountID]
                  end

                  -- Insert the baseline value (horizon = 0)
                  table.insert(evolutionDetails, rowDetail)

                  local absoluteValue = rowDetail.absoluteValue

                  -- Loop through all forecast horizons
                  for h = 1, row.intervalCount do
                     -- Clone the record (copy by value) so we can modify it
                     rowDetail = clone(rowDetail)
                     -- Set the horizon
                     rowDetail.activationHorizon = h

                     if row.allocationFlg == "Y" then
                        if rowDetail.changeType == "rel_add" then
                           -- Column period_<h> contains growth rates
                           rowDetail.relativePct = data["period_"..h]
                           if absoluteValue ~= nil and rowDetail.relativePct ~= nil then
                              rowDetail.relativeValue = absoluteValue * rowDetail.relativePct
                              absoluteValue = absoluteValue * (1 + rowDetail.relativePct)
                              rowDetail.absoluteValue = absoluteValue
                           else
                              absoluteValue = nil
                              rowDetail.absoluteValue = nil
                              rowDetail.relativeValue = nil
                           end
                        else -- Abs-Add
                           -- Column period_<h> contains values to be added
                           rowDetail.relativeValue = data["period_"..h]
                           if absoluteValue ~= nil and rowDetail.relativeValue ~= nil then
                              rowDetail.relativePct = rowDetail.relativeValue / absoluteValue
                              absoluteValue = absoluteValue + rowDetail.relativeValue
                              rowDetail.absoluteValue = absoluteValue
                           else
                              absoluteValue = nil
                              rowDetail.absoluteValue = nil
                              rowDetail.relativePct = nil
                           end
                        end
                        table.insert(evolutionDetails, rowDetail)
                     else -- Non allocation case
                        rowDetail.absoluteValue = nil
                        local bepVars = json:decode(row.bepVarsInfo)
                        local fundSrcVars = {}
                        for _,var in ipairs(bepVars.targets) do
                           if(var.periodic) then
                              rowDetail[var.value] = data[var.value.."_period_"..h]
                           else
                              rowDetail[var.value] = data[var.value]
                           end
                           --If the value is an empty string, set it to nil so that the SAS dataset has the appropriate missing value
                           if(type(rowDetail[var.value]) == 'string') then
                              if(rowDetail[var.value]:gsub("%s+", "") == "") then
                                 rowDetail[var.value] = nil
                              end
                           end
                           if(var.type == "fundingSources") then
                              table.insert(fundSrcVars,var.value);
                           end
                        end
                        -- If we have funding source cells, want one row per funding source. Note that a given row
                        -- could have multiple funding source columns. So if there are 2, say sourceA and sourceB and sourceA
                        -- has 2 sources for a row and sourceB has 4 sources for the same row, we want to make 6 rows for that specific row.
                        local fundSrcCount = 0;
                        if #fundSrcVars > 0 then
                           for _,sourceVar in ipairs(fundSrcVars) do
                              local fsTable = data[sourceVar]
                              if type(fsTable) == 'table' and fsTable then
                                for _,source in ipairs(fsTable) do
                                   local newRowDetail = clone(rowDetail)
                                   fundSrcCount=fundSrcCount+1;
                                   newRowDetail[sourceVar.."_source"]=source.accountID;
                                   newRowDetail[sourceVar.."_percent"]=source.fundPercent;
                                   table.insert(evolutionDetails, newRowDetail)
                                end
                              end
                           end
                        end
                        if fundSrcCount == 0 then
                           table.insert(evolutionDetails, rowDetail)
                        end
                     end

                  end -- Loop through all forecast horizons

               end -- Loop through all records of the BEP spreadsheet component

            end -- Loop through all bepDetails items (one item for each target variable)

         end -- if row.BEPDetails ~= nil

      end -- Loop through all Business Evolution Plans

      -- Write output evolution details table
      if #evolutionDetails == 0 then
         -- Make sure there is at least one record
         evolutionDetails[1] = {key = -1}
         -- Write table
         sas.write_ds(evolutionDetails, outputEvolution)
         -- Now remove the empty record
         sas.submit([[data @outputEvolution@; set @outputEvolution@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(evolutionDetails, outputEvolution)
      end

   end -- if outputEvolution ~= nil
end
M.rmcRestBusinessEvolution = rmcRestBusinessEvolution


-----------------------------
-- allocationScheme
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/AllocationScheme
rmcRestAllocationScheme = function(filename, outputSummary, outputAllocation)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)

   -- Define dataDefinition Attributes
   local schema = rmcSchemaAllocationScheme()

   -- Local function for extracting the list of segmentation variables
   local getSegmentationVars = function(item, row)
      local i, var
      local segmentationVars = json:decode(item.customFields.segmentationVars)
      row.segmentationVarList = ""
      for i, var in ipairs(segmentationVars) do
         row.segmentationVarList = row.segmentationVarList .. " " .. var.name
      end
      row.segmentationVarList = sas.strip(row.segmentationVarList)
      return row
   end

   -- Create the main table dataset
   local result = rgfProcessItems(schema, jsonTable, outputSummary, getSegmentationVars)

   -- Process allocation details (if required)
   if outputAllocation ~= nil then

      local outAlloc = {vars = {}}
      outAlloc.vars.allocationSchemekey = schema.vars.key
      outAlloc.vars.tableId = {type = "N"}
      outAlloc.vars.InstId = {type = "C"}
      outAlloc.vars.Allocation = {type = "N", format = "percent8.2"}

      -- Loop through all allocation schemes
      for i, row in ipairs(result) do
         -- Process only Allocation Schemes based on template data
         if(row.strategyMethod == "SYNTH_INST" and row.synthInstAllocation ~= nil) then

            -- Parse the segmentationVars JSON object
            local segmentationVars = json:decode(row.segmentationVars)

            -- Declare the dynamic columns of the detail table
            for m, var in ipairs(segmentationVars) do
               local varType = "N"
               if var.type == "Char" then
                  varType = "C"
               end
               outAlloc.vars[var.name] = {type = varType, length = var.size}
            end


            -- Parse the Allocation table
            local synthInstAllocation = json:decode(row.synthInstAllocation)
            -- Loop through all records of the allocation table
            for j, alloc in ipairs(synthInstAllocation.items) do
               local allocDetails = {}
               -- Extract relevant fields
               allocDetails.allocationSchemekey = row.key
               allocDetails.tableId = alloc.table_id
               allocDetails.InstId = alloc.INSTID
               -- Get the segments
               for m, var in ipairs(segmentationVars) do
                  allocDetails[var.name] = alloc[var.name]
               end
               allocDetails.Allocation = alloc._alloc_
               -- Insert record to output table
               table.insert(outAlloc, allocDetails)
            end

         end -- if(row.strategyMethod == "SYNTH_INST" and row.synthInstAllocation ~= nil)

      end -- Loop through all allocation schemes

      if #outAlloc == 0 then
         -- Make sure there is at least one record
         outAlloc[1] = {key = -1}
         -- Write table
         sas.write_ds(outAlloc, outputAllocation)
         -- Now remove the empty record
         sas.submit([[data @outputAllocation@; set @outputAllocation@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(outAlloc, outputAllocation)
      end

   end -- if outputAllocation ~= nil

end
M.rmcRestAllocationScheme = rmcRestAllocationScheme

-----------------------------
-- Cycle
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/cycles
rmcRestCycle = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define cycle Attributes
   local schema = rmcSchemaCycle()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rmcRestCycle = rmcRestCycle

-----------------------------
-- RuleSetData
-----------------------------
rmcRestRuleSetData = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   local result = {}

   if jsonTable ~= nil then
      -- Check for errors
      if jsonTable.errorCode ~= nil then
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
         local jsonTableItem
         if jsonTable.items ~= nil then
            -- Process only the first item
            jsonTableItem = jsonTable.items[1]
         else
            jsonTableItem = jsonTable
         end

         local ruleSetType = jsonTableItem.customFields.ruleSetType

         -- Set output table structure
         result.vars = {}
         result.vars.ruleSetKey = {type = "N"}
         result.vars.ruleSetType = {type = "C"}
         if ruleSetType == 'BusinessRuleSet' then
            result.vars.primary_key = {type = "C", length = 10000}
            result.vars.key = {type = "C", length = 40}
            result.vars.target_table = {type = "C", length = 40}
            result.vars.rule_id  = {type = "C", length = 100}
            result.vars.rule_name = {type = "C", length = 100}
            result.vars.rule_desc = {type = "C", length = 100}
            result.vars.rule_component = {type = "C", length = 32}
            result.vars.operator = {type = "C", length = 32}
            result.vars.parenthesis = {type = "C", length = 3}
            result.vars.column_nm = {type = "C", length = 32}
            result.vars.rule_type = {type = "C", length = 100}
            result.vars.rule_details = {type = "C", length = 4000}
            result.vars.message_txt = {type = "C", length = 4096}
            result.vars.lookup_table = {type = "C", length = 1024}
            result.vars.lookup_key = {type = "C", length = 10000}
            result.vars.lookup_data = {type = "C", length = 10000}
            result.vars.aggr_var_nm = {type = "C", length = 32}
            result.vars.aggr_expression_txt = {type = "C", length = 10000}
            result.vars.aggr_group_by_vars = {type = "C", length = 10000}
            result.vars.aggregated_rule_flg = {type = "C", length = 3}
            result.vars.rule_reporting_lev1 = {type = "C", length = 1024}
            result.vars.rule_reporting_lev2 = {type = "C", length = 1024}
            result.vars.rule_reporting_lev3 = {type = "C", length = 1024}
            result.vars.rule_weight = {type = "N"}
         elseif ruleSetType == 'ClassificationRuleSet' then
            result.vars.classification_field = {type = "C", length = 150}
            result.vars.classification_value = {type = "C", length = 150}
            result.vars.filter_exp = {type = "C", length = 10000}
         elseif ruleSetType == 'WhatIfAnalysisRuleSet' then
            result.vars.datadef = {type = "C", length = 150}
            result.vars.filter = {type = "C", length = 10000}
            result.vars.action = {type = "C", length = 10000}
            result.vars.objectId = {type = "C"}
            result.vars.name = {type = "C"}
            result.vars.description = {type = "C"}
         else
            result.vars.rule_id  = {type = "C", length = 32}
            result.vars.rule_desc = {type = "C", length = 4096}
            result.vars.record_id = {type = "C", length = 100}
            result.vars.adjustment_value = {type = "N"}
            result.vars.measure_var_nm = {type = "C", length = 150}
            result.vars.adjustment_type = {type = "C", length = 150}
            result.vars.allocation_method = {type = "C", length = 150}
            result.vars.aggregation_method = {type = "C", length = 32}
            result.vars.weight_var_nm = {type = "C", length = 150}
            result.vars.weighted_aggregation_flg = {type = "C", length = 3}
            result.vars.filter_exp = {type = "C", length = 10000}
         end

         -- Check if the ruleData property is set
         if jsonTableItem.customFields.ruleData ~= nil then
            -- Parse the embedded JSON string into a Lua table
            local ruleSetData = json:decode(jsonTableItem.customFields.ruleData)
            -- Process all records
            for i, row in ipairs(ruleSetData.items) do
               for item, value in pairs(row) do
                  -- Convert table values to string
                  if type(value) == "table" then
                     row[item] = json:encode(value)
                  end
                  -- Convert empty string to missing in case of numeric fields
                  if result.vars[item:lower()] ~= nil then
                     if result.vars[item:lower()].type == "N" and row[item] == "" then
                           row[item] = nil
                     end
                  end
               end
               row.ruleSetKey = jsonTableItem.key
               row.ruleSetType = ruleSetType
               row.objectId = jsonTableItem.objectId
               row.name = jsonTableItem.name
               row.description = jsonTableItem.description

               -- Add record to the output table
               table.insert(result, row)
            end
         end
      end

      if output ~= nil then
         if #result == 0 then
            -- Make sure there is at least one record
            result[1] = {ruleSetKey = -1}
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
end
M.rmcRestRuleSetData = rmcRestRuleSetData


-----------------------------
-- analysisRun
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/AnalysisRun
rmcRestAnalysisRun = function(filename, outputSummary, outputParms, foutCode)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaAnalysisRun()
   -- Process all items
   local result = rgfProcessItems(schema, jsonTable, outputSummary)

   if outputParms ~= nil then
      local outParmsTable = {vars = {}}
      outParmsTable.vars.analysisRunKey = result.vars.key
      outParmsTable.vars.analysisRunName = result.vars.name
      outParmsTable.vars.parameterName = {type = "C", length = 100}
      outParmsTable.vars.parameterValue = {type = "C", length = 32000}

      -- Loop through all analysisRuns
      for i, row in ipairs(result) do
         if(row.sasParams ~= nil) then
            -- row.sasParams is a JSON table stored as a string: need to decode it
            local params = json:decode(row.sasParams)
            -- Loop through all parameters
            for paramName, paramValue in pairs(params) do
               local param = {}
               param.analysisRunKey = row.key
               param.analysisRunName = row.name
               param.parameterName = paramName
               if type(paramValue) == "table" then
                  -- It is a complex parameter. Need to encode it
                  param.parameterValue = json:encode(paramValue)
               else
                  param.parameterValue = paramValue
               end
               table.insert(outParmsTable, param)
            end
         end
      end
      if #outParmsTable == 0 then
         -- Make sure there is at least one record
         outParmsTable[1] = {analysisRunKey = -1}
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
         -- Now remove the empty record
         sas.submit([[data @outputParms@; set @outputParms@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
      end
   end

   if foutCode ~= nil then
      if #result == 1  and result[1].sasCode ~= nil then
         -- Assign fileref
         local fileref = sasxx.new(foutCode)
         -- Open fileref for writing
         local f = fileref:open("wb")
         -- Write the code
         f:write(result[1].sasCode)
         -- Close file
         f:close()
         -- Deassign the fileref
         fileref:deassign()
      end
   end
end
M.rmcRestAnalysisRun = rmcRestAnalysisRun


-----------------------------
-- modelRun
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/modelRun
rmcRestModelRun = function(filename, outputSummary, outputParms, foutCode, foutPreCode, foutPostCode, foutMipPreCode, foutMipPostCode)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaModelRun()
   -- Process all items
   local result = rgfProcessItems(schema, jsonTable, outputSummary)

   if outputParms ~= nil then
      local outParmsTable = {vars = {}}
      outParmsTable.vars.modelRunKey = result.vars.key
      outParmsTable.vars.modelRunName = result.vars.name
      outParmsTable.vars.parameterName = {type = "C", length = 100}
      outParmsTable.vars.parameterValue = {type = "C", length = 32000}

      -- Loop through all modelRuns
      for i, row in ipairs(result) do
         if(row.sasParams ~= nil) then
            -- row.sasParams is a JSON table stored as a string: need to decode it
            local params = json:decode(row.sasParams)
            -- Loop through all parameters
            for paramName, paramValue in pairs(params) do
               local param = {}
               param.modelRunKey = row.key
               param.modelRunName = row.name
               param.parameterName = paramName
               if type(paramValue) == "table" then
                  -- It is a complex parameter. Need to encode it
                  param.parameterValue = json:encode(paramValue)
               else
                  param.parameterValue = paramValue
               end
               table.insert(outParmsTable, param)
            end
         end
      end
      if #outParmsTable == 0 then
         -- Make sure there is at least one record
         outParmsTable[1] = {modelRunKey = -1}
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
         -- Now remove the empty record
         sas.submit([[data @outputParms@; set @outputParms@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
      end
   end

   -- Build a list of filerefs to process
   local fref_list = {}
   fref_list[1] = {fref = foutCode, codeAttr = "sasCode"}
   fref_list[2] = {fref = foutPreCode, codeAttr = "sasPreCode"}
   fref_list[3] = {fref = foutPostCode, codeAttr = "sasPostCode"}
   fref_list[4] = {fref = foutMipPreCode, codeAttr = "mipPreCode"}
   fref_list[5] = {fref = foutMipPostCode, codeAttr = "mipPostCode"}
   -- Loop through the list
   for i, current in ipairs(fref_list) do
      if current.fref ~= nil then
         if #result == 1 and result[1][current.codeAttr] ~= nil then
            -- Assign fileref
            local fileref = sasxx.new(current.fref)
            -- Open fileref for writing
            local f = fileref:open("wb")
            -- Write the code (convert tabs to spaces)
            f:write(detab(result[1][current.codeAttr]))
            -- Close file
            f:close()
            -- Deassign the fileref
            fileref:deassign()
         end
      end
   end

end
M.rmcRestModelRun = rmcRestModelRun




-----------------------------
-- Model
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/model
rmcRestModel = function(filename, outputSummary, outputParms, foutCode, foutPreCode, foutPostCode, foutMipPreCode, foutMipPostCode)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define model Attributes
   local schema = rmcSchemaModel()
   -- Process all items
   local result = rgfProcessItems(schema, jsonTable, outputSummary)

   if outputParms ~= nil then
      local outParmsTable = {vars = {}}
      outParmsTable.vars.modelKey = result.vars.key
      outParmsTable.vars.modelName = result.vars.name
      outParmsTable.vars.key = {type = "C"}
      outParmsTable.vars.name = {type = "C"}
      outParmsTable.vars.label = {type = "C"}
      outParmsTable.vars.description = {type = "C"}
      outParmsTable.vars.config = {type = "C", length = 1000}
      outParmsTable.vars.type = {type = "C"}
      outParmsTable.vars.required_flg = {type = "C"}
      outParmsTable.vars.default_value = {type = "C"}

      -- Loop through all models
      for i, row in ipairs(result) do
         if(row.parameters ~= nil) then
            -- row.parameters is a JSON table stored as a string: need to decode it
            local params = json:decode(row.parameters)
            -- Loop through all parameters
            for j, item in ipairs(params.items) do
               local param = {}
               param.modelKey = row.key
               param.modelName = row.name
               -- Loop through all attributes of the parameter
               for attrName, attrValue in pairs(item) do
                  if type(attrValue) == "table" then
                     -- It is a complex parameter. Need to encode it
                     param[attrName] = json:encode(attrValue)
                  else
                     param[attrName] = attrValue
                  end
               end
               table.insert(outParmsTable, param)
            end
         end
      end
      if #outParmsTable == 0 then
         -- Make sure there is at least one record
         outParmsTable[1] = {modelKey = -1}
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
         -- Now remove the empty record
         sas.submit([[data @outputParms@; set @outputParms@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
      end
   end

   -- Build a list of filerefs to process
   local fref_list = {}
   fref_list[1] = {fref = foutCode, codeAttr = "codeEditor"}
   fref_list[2] = {fref = foutPreCode, codeAttr = "preCodeEditor"}
   fref_list[3] = {fref = foutPostCode, codeAttr = "postCodeEditor"}
   fref_list[4] = {fref = foutMipPreCode, codeAttr = "mipPreCodeEditor"}
   fref_list[5] = {fref = foutMipPostCode, codeAttr = "mipPostCodeEditor"}
   -- Loop through the list
   for i, current in ipairs(fref_list) do
      if current.fref ~= nil then
         if #result == 1 and result[1][current.codeAttr] ~= nil then
            -- Assign fileref
            local fileref = sasxx.new(current.fref)
            -- Open fileref for writing
            local f = fileref:open("wb")
            -- Write the code (convert tabs to spaces)
            f:write(detab(result[1][current.codeAttr]))
            -- Close file
            f:close()
            -- Deassign the fileref
            fileref:deassign()
         end
      end
   end

end
M.rmcRestModel = rmcRestModel


-- Parser for riskCirrusObjects/object/<contentId>/script
rmcRestScript = function(filename, outputSummary, outputParms, foutCode)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define script Attributes
   local schema = rmcSchemaScript()
   -- Process all items
   local result = rgfProcessItems(schema, jsonTable, outputSummary)

   if outputParms ~= nil then
      local outParmsTable = {vars = {}}
      outParmsTable.vars.scriptKey = result.vars.key
      outParmsTable.vars.scriptName = result.vars.name
      outParmsTable.vars.key = {type = "C"}
      outParmsTable.vars.name = {type = "C"}
      outParmsTable.vars.label = {type = "C"}
      outParmsTable.vars.description = {type = "C"}
      outParmsTable.vars.config = {type = "C", length = 1000}
      outParmsTable.vars.type = {type = "C"}
      outParmsTable.vars.required_flg = {type = "C"}
      outParmsTable.vars.default_value = {type = "C"}

      -- Loop through all scripts parameters
      for i, row in ipairs(result) do
         if(row.parameters ~= nil) then
            -- row.parameters is a JSON table stored as a string: need to decode it
            local params = json:decode(row.parameters)
            -- Loop through all parameters
            for j, item in ipairs(params.items) do
               local param = {}
               param.scriptKey = row.key
               param.scriptName = row.name
               -- Loop through all attributes of the parameter
               for attrName, attrValue in pairs(item) do
                  if type(attrValue) == "table" then
                     -- It is a complex parameter. Need to encode it
                     param[attrName] = json:encode(attrValue)
                  else
                     param[attrName] = attrValue
                  end
               end
               table.insert(outParmsTable, param)
            end
         end
      end
      if #outParmsTable == 0 then
         -- Make sure there is at least one record
         outParmsTable[1] = {modelKey = -1}
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
         -- Now remove the empty record
         sas.submit([[data @outputParms@; set @outputParms@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(outParmsTable, outputParms)
      end
   end

   -- Build a list of filerefs to process
   local fref_list = {}
   fref_list[1] = {fref = foutCode, codeAttr = "codeEditor"}
   -- Loop through the list
   for i, current in ipairs(fref_list) do
      if current.fref ~= nil then
         if #result == 1 and result[1][current.codeAttr] ~= nil then
            -- Assign fileref
            local fileref = sasxx.new(current.fref)
            -- Open fileref for writing
            local f = fileref:open("wb")
            -- Write the code (convert tabs to spaces)
            f:write(detab(result[1][current.codeAttr]))
            -- Close file
            f:close()
            -- Deassign the fileref
            fileref:deassign()
         end
      end
   end

end
M.rmcRestScript = rmcRestScript

-----------------------------
-- MasterRiskScenario
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/masterRiskScenarios
rmcRestMasterRiskScenario = function(filename, output, details_flg)

   -- Process details_flg parameter
   details_flg = details_flg or "N"
   details_flg = string.upper(details_flg)

   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)

   -- Define MasterRiskScenario Attributes
   local schema = rmcSchemaMasterRiskScenario(details_flg)

      -- Local function for expanding the Management Org Path attribute
   local expandScenarios = function(item, row)
      -- Get MasterRiskScenario Attributes (including details)
      local schema = rmcSchemaMasterRiskScenario("Y")

      local scenarios = {}

      -- Process the scenarios associated with the master risk scenario (if any)
      if row.riskScenarioData ~= nil then
         -- row.riskScenarioData is a JSON table stored as a string: need to decode it
         local scenarioData = json:decode(row.riskScenarioData)
         -- Loop through all scenarios
         for i, scenario in pairs(scenarioData.items) do
            -- Rename conflicting variables
            scenario.scenarioId = scenario.id
            scenario.scenarioName = scenario.name
            scenario.scenarioVersion = scenario.version
            -- Loop through all properties of the schema variable
            for var, options in pairs(schema.vars) do
               -- Copy the value of the property from row to scenario
               if row[var] ~= nil then
                  scenario[var] = row[var]
               end
            end
            -- Add current scenario to the result
            table.insert(scenarios, scenario)
         end
      end

      return scenarios
   end

   -- Process all Master Risk Scenarios items (details_flg == "Y" ? expandScenarios : nil)
   rgfProcessItems(schema, jsonTable, output, details_flg == "Y" and expandScenarios or nil)

end
M.rmcRestMasterRiskScenario = rmcRestMasterRiskScenario

-----------------------------
-- DataMap
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/dataMap
rmcRestDataMap = function(filename, outputSummary, outputDetails)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaDataMap()
   -- Process all items
   resultSummary = rgfProcessItems(schema, jsonTable, outputSummary)

   if outputDetails ~= nil then
      -- Get schema for the detail table
      local resultDetails = rmcSchemaDataMap("Y")
      -- Loop through all data maps
      for i, row in ipairs(resultSummary) do
         local mappingInfo = json:decode(row.mappingInfo)
         local nrows = #mappingInfo.items
         for j, mapRow in ipairs(mappingInfo.items) do
            mapRow.dataMapkey = row.key
            mapRow.dataMapName = row.name
            mapRow.map_type = row.mapType

            -- Check if there is a query filter expression
            if(mapRow.filter and mapRow.filter.filter and mapRow.filter.filter.children) then
               local filterExpression = ""
               local filterAssignment = ""
               for k, filterEntry in ipairs(mapRow.filter.filter.children) do
                  if filterExpression ~= "" then
                     filterExpression = filterExpression .. " " .. mapRow.filter.filter.type .. " "
                     filterAssignment = filterAssignment .. " "
                  end
                  local expression = filterEntry.name .. " " .. filterEntry.operator .. " " .. filterEntry.value
                  local assignment = filterEntry.name .. " = " .. filterEntry.value .. ";"
                  -- Append filter condition
                  filterExpression = filterExpression .. expression
                  -- Append filter assignment expression
                  filterAssignment = filterAssignment .. assignment
               end

               mapRow.filterExpression = filterExpression
               mapRow.filterAssignment = filterAssignment
               mapRow.filter = nil
            end

            -- Set object attributes
            if(type(mapRow.key) == "number") then
               mapRow.rowKey = mapRow.key
            else
               -- Assign a numeric key
               nrows = nrows + 1
               -- Add an offset of 10M to avoid conflicts with other keys
               mapRow.rowKey = 10000000 + nrows
            end
            mapRow.key = nil

            -- Set the target_var_length to nil if it has not a number (it happens when the spreadhseet cell is missing)
            if(type(mapRow.target_var_length) ~= "number") then
               mapRow.target_var_length = nil
            end

            -- Append record to output
            table.insert(resultDetails, mapRow)
         end
      end

      if #resultDetails == 0 then
         -- Make sure there is at least one record
         resultDetails[1] = {dataMapKey = -1}
         -- Write table
         sas.write_ds(resultDetails, outputDetails)
         -- Now remove the empty record
         sas.submit([[data @outputDetails@; set @outputDetails@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(resultDetails, outputDetails)
      end
   end

end
M.rmcRestDataMap = rmcRestDataMap

-----------------------------
-- Workflow Template
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/workflowTemplates
rmcRestWfTemplate = function(filename, outputSummary, outputModelMap, outputTaskDetails, outputReviewActivities)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define workflow template attributes
   local schema = rmcSchemaWfTemplate()
   -- Process all items
   resultSummary = rgfProcessItems(schema, jsonTable, outputSummary)

   -- Store the model mapping information from the workflow template
   if outputModelMap ~= nil then
      -- Get schema for the model mapping table
      local modelMapDetails = rmcSchemaWfTemplate("model_mapping")
      -- Loop through all workflow templates
      for i, row in ipairs(resultSummary) do
         if row.wfActivityModelMapping ~= nill then
            local wfActivityModelMapping = json:decode(row.wfActivityModelMapping)
            local nrows = #wfActivityModelMapping.items
            for j, activityRow in ipairs(wfActivityModelMapping.items) do
               -- Append record to output
               table.insert(modelMapDetails, activityRow)
            end
         end
      end

      if #modelMapDetails == 0 then
         -- Make sure there is at least one record
         modelMapDetails[1] = {wfTemplateKey = -1}
         -- Write table
         sas.write_ds(modelMapDetails, outputModelMap)
         -- Now remove the empty record
         sas.submit([[data @outputModelMap@; set @outputModelMap@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(modelMapDetails, outputModelMap)
      end
   end

   -- Store the task detail information from the workflow template
   if outputTaskDetails ~= nil then
      -- Get schema for the model mapping table
      local taskDetails = rmcSchemaWfTemplate("task_details")
      -- Loop through all workflow templates
      for i, row in ipairs(resultSummary) do
         if row.wfActivityDetails ~= nil then
            local wfActivityDetails = json:decode(row.wfActivityDetails)
            local nrows = #wfActivityDetails.items
            for j, taskDetailRow in ipairs(wfActivityDetails.items) do
               -- Append record to output
               table.insert(taskDetails, taskDetailRow)
            end
         end
      end

      if #taskDetails == 0 then
         -- Make sure there is at least one record
         taskDetails[1] = {wfTemplateKey = -1}
         -- Write table
         sas.write_ds(taskDetails, outputTaskDetails)
         -- Now remove the empty record
         sas.submit([[data @outputTaskDetails@; set @outputTaskDetails@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(taskDetails, outputTaskDetails)
      end
   end

   -- Store the review activities information from the workflow template
   if outputReviewActivities ~= nil then
      -- Get schema for the model mapping table
      local reviewActivityDetails = rmcSchemaWfTemplate("review_activities")
      -- Loop through all workflow templates
      for i, row in ipairs(resultSummary) do
         if row.reviewActivities ~= nil then
            local reviewActivities = json:decode(row.reviewActivities)
            local nrows = #reviewActivities.tasks
            for j, activityRow in ipairs(reviewActivities.tasks) do
               -- Append record to output
               table.insert(reviewActivityDetails, activityRow)
            end
         end
      end

      if #reviewActivityDetails == 0 then
         -- Make sure there is at least one record
         reviewActivityDetails[1] = {wfTemplateKey = -1}
         -- Write table
         sas.write_ds(reviewActivityDetails, outputReviewActivities)
         -- Now remove the empty record
         sas.submit([[data @outputReviewActivities@; set @outputReviewActivities@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(reviewActivityDetails, outputReviewActivities)
      end
   end

end
M.rmcRestWfTemplate = rmcRestWfTemplate

-----------------------------
-- Shortcut
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/shortcuts
rmcRestShortcut = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaShortcut()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
end
M.rmcRestShortcut = rmcRestShortcut


-----------------------------
-- Member
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/Member
rmcRestMember = function(filename, output)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaMember()
   -- Process all items
   rgfProcessItems(schema, jsonTable, output)
   -- Go through memberAttributes and add columns for each attribute and also put all names in memberAttributeNames as a comma-separated list
end
M.rmcRestMember = rmcRestMember


-----------------------------
-- Hierarchy
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/hierarchies
rmcRestHierarchy = function(filename, outputSummary, outputMemberInfo)
   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)
   -- Define dataDefinition Attributes
   local schema = rmcSchemaHierarchy()
   -- Process all items
   local result = rgfProcessItems(schema, jsonTable, outputSummary)

   if outputMemberInfo ~= nil then
      local memberInfoTable = {vars = {}}
      memberInfoTable.vars.hierarchyCd = result.vars.hierarchyCd
      memberInfoTable.vars.hierarchyVersion = result.vars.version
      memberInfoTable.vars.hierarchyDimension = result.vars.dimension
      memberInfoTable.vars.key = {type = "N"}
      memberInfoTable.vars.memberCd = {type = "C"}
      memberInfoTable.vars.version = {type = "N"}
      memberInfoTable.vars.name = {type = "C"}
      memberInfoTable.vars.parent = {type = "C"}
      memberInfoTable.vars.path = {type = "C", length = 32000}
      memberInfoTable.vars.level = {type = "N"}
      memberInfoTable.vars.level0 = {type = "C"}
      memberInfoTable.vars.level1 = {type = "C"}
      memberInfoTable.vars.level2 = {type = "C"}
      memberInfoTable.vars.level3 = {type = "C"}
      memberInfoTable.vars.level4 = {type = "C"}
      memberInfoTable.vars.level5 = {type = "C"}
      memberInfoTable.vars.level6 = {type = "C"}
      memberInfoTable.vars.level7 = {type = "C"}
      memberInfoTable.vars.level8 = {type = "C"}
      memberInfoTable.vars.level9 = {type = "C"}
      memberInfoTable.vars.level10 = {type = "C"}
      memberInfoTable.vars.level11 = {type = "C"}
      memberInfoTable.vars.level12 = {type = "C"}
      memberInfoTable.vars.level13 = {type = "C"}
      memberInfoTable.vars.level14 = {type = "C"}
      memberInfoTable.vars.level15 = {type = "C"}
      memberInfoTable.vars.level16 = {type = "C"}
      memberInfoTable.vars.level17 = {type = "C"}
      memberInfoTable.vars.level18 = {type = "C"}
      memberInfoTable.vars.level19 = {type = "C"}
      memberInfoTable.vars.level20 = {type = "C"}
      memberInfoTable.vars.level21 = {type = "C"}
      memberInfoTable.vars.level22 = {type = "C"}
      memberInfoTable.vars.level23 = {type = "C"}
      memberInfoTable.vars.level24 = {type = "C"}
      memberInfoTable.vars.level25 = {type = "C"}

      -- Loop through all hierarchies
      for i, row in ipairs(result) do
         if(row.members ~= nil) then
            -- row.members is a JSON table stored as a string: need to decode it
            local cols = json:decode(row.members)
            -- Loop through all members
            for j, item in ipairs(cols.items) do
               local member = {}
               member.hierarchyCd = row.hierarchyCd
               member.hierarchyVersion = row.version
               member.hierarchyDimension = row.dimension
               -- Loop through all attributes of the member
               for attrName, attrValue in pairs(item) do
                  if type(attrValue) == "table" then
                     -- It is a complex parameter. Need to encode it
                     member[attrName] = json:encode(attrValue)
                  else
                     member[attrName] = attrValue
                  end
                  if not memberInfoTable.vars[attrName] then
                     memberInfoTable.vars[attrName] = {type = "C", length = 1024}
                  end
               end
               table.insert(memberInfoTable, member)
            end
         end
      end
      if #memberInfoTable == 0 then
         -- Make sure there is at least one record
         memberInfoTable[1] = {hierarchyVersion = -1}
         -- Write table
         sas.write_ds(memberInfoTable, outputMemberInfo)
         -- Now remove the empty record
         sas.submit([[data @outputMemberInfo@; set @outputMemberInfo@(obs = 0); run;]])
      else
         -- Write table
         sas.write_ds(memberInfoTable, outputMemberInfo)
      end
   end

end
M.rmcRestHierarchy = rmcRestHierarchy


-----------------------------
-- attributionAnalysis
-----------------------------

-- Parser for riskCirrusObjects/object/<contentId>/attributionAnalysis
rmcRestAttributionAnalysis = function(filename, output, details_flg)

   -- Process details_flg parameter
   details_flg = details_flg or "N"
   details_flg = string.upper(details_flg)

   -- Parse JSON
   local jsonTable = json_utils.parseJSONFile(filename)

   -- Define AttributionAnalysis Attributes
   local schema = rmcSchemaAttributionAnalysis(details_flg)

      -- Local function for expanding the Management Org Path attribute
   local expandAttribution = function(item, row)

      -- Get AttributionAnalysis Attributes (including details)
      local schema = rmcSchemaAttributionAnalysis("Y")

      local attributionTable = {}
      local attributionVars = ""

      if row.outputVars ~= nil then
         -- row.outputVars is a JSON table stored as a string: need to decode it
         local outputVarsData = json:decode(row.outputVars)
         -- Loop through all attribution variables
         for i, outputVar in pairs(outputVarsData.items) do
            attributionVars = sas.catx(" ", attributionVars, outputVar.name)
         end
      end

      -- Process the attribution factors associated with the attribution analysis (if any)
      if row.attFactors ~= nil then
         -- row.attFactors is a JSON table stored as a string: need to decode it
         local attFactorsData = json:decode(row.attFactors)
         -- Loop through all attribution factors
         for i, attFactor in pairs(attFactorsData.items) do
            -- Loop through all properties of the schema variable
            for var, options in pairs(schema.vars) do
               -- Copy the value of the property from row to attFactor
               if row[var] ~= nil then
                  attFactor[var] = row[var]
               end
            end
            -- Set attribution variables
            attFactor.attributionVars = attributionVars
            -- Add current attFactor to the result
            table.insert(attributionTable, attFactor)
         end
      end

      return attributionTable
   end

   -- Process all Attribution Analysis items (details_flg == "Y" ? expandAttribution : nil)
   rgfProcessItems(schema, jsonTable, output, details_flg == "Y" and expandAttribution or nil)

end
M.rmcRestAttributionAnalysis = rmcRestAttributionAnalysis


return M
