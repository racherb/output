#!/usr/bin/env tarantool
------------
-- Output Language
-- Output language definition
-- ...
-- @module watcher
-- @author hernandez, raciel
-- @license MIT
-- @copyright Raciel Hernández 2021
------------

local l = require('lpeg')

local P = l.P          -- match a String literally
local R = l.R          -- match anything in a Range
local S = l.S          -- match anything in a Set
local V = l.V
local C = l.C
local Cg = l.Cg
local Ct = l.Ct
local Cs = l.Cs
local I = l.Cp()

local match = l.match  -- match a pattern against a string

local dot = P"."
local sign = (P"+" + P"-")
local zero = P"0"
local one = P"1"

local eol = P"\n\r" + P"\r\n" + P"\n" + P"\r" --End of line

local function maybe(p)
    return p^0
end

--Any
local any = P(1)
local asci = R'!~'

--Any to white space
local towsp = P" "^0 * (P(1) - P" ")^1

local int = sign^-1 * R('09')^0
local nat = R('19') * R('09')^0
local float = R('09')^0 *P('.') * R('09')^1
local word = (R"AZ" + R"az")^0
local spaces = P" "^1
local sentence = (any - dot)^1
local paragraph = (any - eol)^1

local num = sign^-1 *
    R('09')^0 *
    (
        P('.') *
        R('09')^0
    )^-1

--IP4 Dot-Decimal Notation
local odf = (P"100" + (P"1" * R"09" * R"09") + (P"2" * R"05" * R"05")) + (P"10" + (R"19" * R"09")) + R"09"
local ip4 = odf * dot * odf * dot * odf * dot * odf --IP4 addrees in decimal format

return {
    any = any,
    asci = asci,
    int = int,
    nat = nat,
    num = num,
    float = float,
    ip4 = ip4,
    zeros = zero^1,
    ones = one^1,
    towsp = towsp,
    word = word,
    spaces = spaces,
    sentence = sentence,
    paragraph = paragraph
}
