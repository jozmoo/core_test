--[[
/* Copyright (C) 2015 SAS Institute Inc. Cary, NC, USA */

/*!
\file    irm.lua

\brief   This function is to provide a product specific mapping of message keys to message files,
         used by the sas_msg.get_message() function.

\ingroup commonAnalytics

 \param[in] msgKey               message key

\author  SAS Institute Inc.

\date    2015

\details The rmb module is considered a singleton object, so we don't instantiate ant objects of this type
         (if you have the module you have the object)
         and all of its methods and instance data are at the module level.


*/

]]

local stringutils = require 'sas.risk.utils.stringutils'
local sas_msg = require 'sas.risk.utils.sas_msg'

function _G.get_message_file(msgKey)

   local msgFile = nil;
   if msgKey then
      msgKey = msgKey:lower()
      if stringutils.starts_with(msgKey, "irm_")  then
         msgFile = "SASHELP.irmcalcmsg"
      elseif stringutils.starts_with(msgKey, "rsk_") then
         msgFile = "SASHELP.irmutilmsg"
     end
   end
   return msgFile

end

function _G.get_message_string(msgKey, s1, s2, s3, s4, s5, s6, s7)

    return sas_msg.get_message(msgKey, s1, s2, s3, s4, s5, s6, s7)

end


return M
