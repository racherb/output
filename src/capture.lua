#!/usr/bin/env tarantool
------------
-- Output Capture
-- Capture data and variables from output
-- ...
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2021
------------

local popen = require('popen')
local fiber = require('fiber')
local l = require('lulpeg')

local popen_new = popen.new
local popen_opts = popen.opts
local sleep = fiber.sleep

local P = l.P          -- match a String literally
local R = l.R          -- match anything in a Range
local S = l.S          -- match anything in a Set
local V = l.V
local C = l.C
local Cg = l.Cg
local Ct = l.Ct
local Cs = l.Cs

local match = l.match  -- match a pattern against a string

local any = P(1)

local number = C(
           P('-')^-1 *
           R('09')^0 *
           (
               P('.') *
               R('09')^0
           )^-1 ) / tonumber

--TODO: Completar caracteres de texto libre
local free_text = (R'!~' + P' ')
local string_value = free_text^1 + (P'"' * (free_text - P'"')^1 * P'"') + (P"'" * (free_text - P"'" )^1 * P"'")
local numeric_value = R'09' --TODO: Generalizar numeros

local grammar = {
    "hashtag_line",          -- Initial rule
    hashtag     = (C(V"HASHTAG" *  V"hashtag_name") * (V"WSPACE" + V"COLON" + V"WSPACE") * C(V"hashtag_value")) +
                   C(V"HASHTAG" *  V"hashtag_name"),
    hashtag_list   = V"hashtag" + V"WSPACE"^0 + V"hashtag"^0,
    hashtag_name   = (R'az' + R'AZ' + R'09' + S'_!@$%&()[]{}+-*/')^1,
    hashtag_value  = numeric_value^1 + string_value,
    hashtag_line = V"hashtag_list" * V"hashtag",

    printusascii = R"!~"^-60,

    BLANKS = S(" \t\n")^0,

    HASHTAG     = P("#"),
    COLON       = P(":"),
    ALPHA       = R("AZ","az"),
    LOWER       = R("az"),
    UPPER       = R("AZ"),
    BIT         = S"01",
    CHAR        = R"\1\127",
    CR          = P"\r",
    LF          = P"\n",
    CRLF        = P"\r\n",
    CTL         = R"\0\31" + P"\127",
    DIGIT       = R"09",
    NZERO_DIGIT = R"19",
    DOUQUOTE    = P'"',
    TAB         = P"\t",
    SPACE       = P" ",
    WSPACE      = S" \t"
}

local parser = P(grammar)
-- ans = Ct(parser):match('#CteSinCto:"123"')}

local capture = {}

local function submit (what)

    local ph, err = popen_new(
        {what..' >&2'},
        {
            stdin = popen_opts.PIPE,
            stdout = popen_opts.PIPE,
            stderr = popen_opts.PIPE,
            shell = true,
            group_signal = true,
            setsid = true,
        }
    )
    if ph == nil then return nil, err end

    return ph

end

local function read(ph, save)
    local res, err
        res, err = ph:read({stderr = true}):rstrip()
        if res==nil then
            ph:close()
            return nil, err
        end
        if save and res and res ~= '' then
            local cmd = {'echo "', tostring(res), '" >> ', save}
            os.execute(table.concat(cmd))
        end
    return res
end

local function kill(ph)
    if ph then
        local ans, err = ph:kill()
        return ans, err
    end
end

local function output_capture(ph, interval, tofile)

    local _interval = interval or 1
    while (ph.status.state == 'alive')
    do
        local output, err  = read(ph, tofile)
        if output and output  ~= '' then
            print(output)
        end
        sleep(_interval)
    end
end



capture.submit = submit
capture.read = read
capture.kill = kill
capture.output = output_capture

return capture