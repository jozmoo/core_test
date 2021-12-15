--[[
  Takes a json formatted string and creates a multipart/form-data request body

  Looks for these macros:
     mp_status    - set to 1 at the begging of execution and then set to 0 at the very end.

     mp_body      - fileref or full path to file to write body to. If mp_body is 8 characters or less
                    and has no / \ or . characters, it is treated as a fileref

     mp_boundary  - Boundary to use in the request. If boundary is empty, a random boundary is
                    generated and written to th

     mp_content   - json formatted string with content.

                 This is an array, with each element containing a different form-data entry.
                 Each element in the array should have:

                    disposition: An array of key/value pairs.

                    type: character. e.g. text/plain,application/json,application/octet-stream

                    content: character or table. If character, then this is printed as-is to the output.
                             if it is a table, then the it must have an element called 'file' which
                             can contain either a filename or fileref. If file is 8 characters or less
                             and has no / \ . characters, it is treated asa fileref. Contents of file
                             are read and written binary into the output file.


                    %let content = [{
                                      "disposition":[
                                        {"key":"name","value":"file"},
                                        {"key":"filename","value":"test.txt"}
                                      ],
                                      "type":"application/octet-stream",
                                      "content":{"file":"_tmpin"}
                                    },{
                                      "disposition":[
                                        {"key":"name","value":"_charset_"}
                                      ],
                                      "type":"text/plain",
                                      "content":"UTF-8"
                                    }];
]]--

-- Initialize status to 1 (fail)
sas.symput('mp_status',1)
sas.print('%3zCreating Multipart Request Body with arguments: ')

-- Generates a random string of alpha-numeric characters
local function generateFormBoundary(size)
   size = size or 16
   local charset = {}
   local str = ""
   for i = 48,  57 do table.insert(charset, string.char(i)) end
   for i = 65,  90 do table.insert(charset, string.char(i)) end
   for i = 97, 122 do table.insert(charset, string.char(i)) end
   for i = 1, size do
      str = str..charset[math.random(#charset)]
   end
   return str
end

-- Load json and rest)utils modules
local json = require 'sas.risk.utils.json'
local utils = require 'sas.risk.utils.fileutils'

-- Read in and parse macro vars
local outFile = sas.symget("mp_body")
sas.print('%3z   MP_BODY: '..tostring(outFile))
local boundary = sas.symget("mp_boundary")
sas.print('%3z   MP_BOUNDARY: '..tostring(boundary))
if sas.strip(boundary)  == "" then
   boundary = '----WebKitFormBoundary'..generateFormBoundary()
   sas.symput('mp_boundary',boundary)
   sas.print('%3z   No boundary specified, macro variable MP_BOUNDARY will be set to: '..tostring(boundary))
end
sas.print('%3z   MP_CONTENT: '..tostring(sas.symget('mp_content')))
sas.print('%3z   parsing content as a json object ... ')


local content = json:decode(sas.symget('mp_content'))
if sas.getoption('symbolgen') or sas.getoption('mprint')  or sas.getoption('mlogic') then
   print('lua table content resolves to '..table.tostring(content))
end


local  body = ""
local  debugBody = ""
for _,cont in ipairs(content) do

   local newlines = ""
   local newlinesDebug = ""
   newlines = newlines.."--"..boundary.."\r\n"
   newlines = newlines..'Content-Disposition: form-data'
   for _,d in ipairs(cont.disposition) do
      newlines = newlines..'; '..d.key..'="'..d.value..'"'
   end
   newlines = newlines.."\r\n"
   newlines = newlines..'Content-Type: '..cont.type.."\r\n\r\n"
   if type(cont.content) == 'string' then
      newlines = newlines..cont.content..'\r\n'
      debugBody = debugBody..newlines
   else
      -- Read contents from a file. Check if file is a fileref or file path
      local file = cont.content.file
      local read
      if file:len() < 9 and file:gsub('[/\\.]','') == file then
         -- If file is 8 characters or less and has no slashes or periods, then treat it as a fileref
         read = utils.read_fileref
      else
         -- Otherwise treat it as a file path
         read = utils.read_file
      end
      local fileContents = read(cont.content.file)
      local droppedChars = {}; droppedChars[0] = ""; droppedChars[fileContents:len()-20] = "<"..tostring(fileContents:len()-20).." characters not shown>";
      debugBody = debugBody..newlines..fileContents:sub(1,math.min(20,fileContents:len()))..droppedChars[math.max(fileContents:len()-20,0)]..'\r\n'
      newlines = newlines..fileContents..'\r\n'
   end
   body = body..newlines

end

debugBody =debugBody.."--"..boundary..'--'
body = body.."--"..boundary..'--'

if sas.getoption('symbolgen') or sas.getoption('mprint')  or sas.getoption('mlogic') then
   print('Multipart body is (file contents cut off at 20 characters): ')
   -- If debugBody contains any hex characters, replace with spaces
   print(debugBody:gsub('[^(\x20-\x7E|\x0C|\x0A|\x0D)]', ' '))
end

-- Determine if we are writing to a file by path or fileref.
local write
outFile = sas.strip(outFile)
if outFile:len() < 9 and outFile:gsub('[/\\.]','') == outFile then
   -- If outFile is 8 characters or less and has no slashes or periods, then treat it as a fileref
   write = utils.write_fileref
else
   -- Otherwise treat it as a file path
   write = utils.write_file
end


write(outFile,body)


sas.symput('mp_status',0)