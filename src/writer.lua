#!/usr/bin/env tarantool
------------
-- Output Writer
-- ...
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2021
------------

local l = require('lulpeg')

l.locale(l)

local alpha = l.alpha
local digit = l.digit

local function short(ou, ...)
    local arg = {...}
    local mssg = ou.short
    for i,v in ipairs(arg) do
        print(i)
        print(v)
        --result = result + v
    end
    --print(output.short)
    --print(output.expanded)
end

local function expanded(ou, ...)
    local arg = {...}

end


-- match on alphas followed by digits (eg. abc123) and capture each
pattern = l.C (alpha^1) * l.C (digit^1)

function f (a, b)
  return b .. a
end -- f

pattern = lpeg.Cs((pattern / f + 1)^0)

print (pattern:match ("I am testing abc123 and def567"))

local writer = {}
writer.short = short
writer.expanded = expanded

return writer