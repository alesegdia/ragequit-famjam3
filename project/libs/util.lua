
local json = require(LIBRARYPATH.."dkjson")

local util = {

	--local f,err = io.open(path,"r")
	--if not f then return print(err) end
	--f:close()
  json2table = function( path )
	local contents,size = love.filesystem.read(path)
	local tbl = json.decode(contents) --f:read("*all"))
	return tbl
  end,

  table2json = function( path, tbl )
	local f,err = io.open(path, "w+")
	if not f then return print(err) end
	f:write(json.encode(tbl))
	f:close()
	return true
  end,

  sign = function( n )
	if n < 0 then return -1 else return 1 end
  end,

  -- thanks to mniip on #lua@freenode.net
  ircparse = function( s )
	local command, source
	if s:sub(1, 1) == ":" then
	  source, command = s:match"^:([^ ]*)(.*)"
	else
	  command = " " .. s
	end
	local t = {}
	local n = 1
	for pos, word in command:gmatch" ()([^ ]*)" do
	  if word:sub(1, 1) == ":" then
		t[n] = command:sub(pos + 1)
		break
	  end
	  t[n] = word
	  n = n + 1
	end
	t[0] = source
	return t
  end

}

return util
