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
local patt = require('patterns')

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
local dash = P"-"
local colon = P":"
local comma = P","
local hashtag = P"#"
local virgulilla = P"~"
local ucase = R"AZ"
local lcase = R"az"
local digit = R"09"
local nonzero = R"19"
local alpha = ucase + lcase
local alphanum = alpha + digit
local underscore = P"_"

local obraket = P"["
local cbraket = P"]"
local oparent = P("(")
local cparent = P(")")
local obrace = P"{"
local cbrace = P"}"
local oanglebrack = P"<"
local canglebrack = P">"

local eol = P"\n\r" + P"\r\n" + P"\n" + P"\r" --End of line

local bit = S"01"
local char = R"\1\127"
local cr = P"\r"        --carriage return
local lf = P"\n"        --new line
local tab = P"\t"       --horizontal tab
local crlf = cr + lf    --carriage return & new line

local quote = P"'"      --single quote
local dquote = P'"'     --double quote
local space = P" "      --blank space
local wsp = S" \t\v"    --White space

local valuename = (R'!~' - P"'" - P'"')^1
local sentenc_wq = (R'!~' + P' ' - P"'" + wsp + eol)^1
local sentenc_wdq = (R'!~' + P' ' - P'"' + wsp + eol)^1
local free_text = (R'!~' + wsp + eol)^1
local text_wht = (R'!~' + wsp + eol -P"#")^1

local number = patt.num

local function maybe(p)
    return p^0
end

local function anywhere (p)
    return P{ p + 1 * V(1) }
end

-- extract_quote('(',')'):match '(and more)'
-- ans: "and more"
-- extract_quote('[[',']]'):match '[[long string]]'
-- "long string"
local function extract_quote(openp, endp)
    openp = P(openp)
    endp = endp and P(endp) or openp
    local upto_endp = (1 - endp)^1
    return openp * C(upto_endp) * endp
end

local ht_grammar = {
    "HASHTAG",
    HASHTAG = Ct(
                 maybe(text_wht) * C(hashtag * V"HTNAME") *
                 maybe(wsp^0 * colon * maybe(wsp) * C(V"HTVALUE")) *
                 maybe(text_wht)
                ) * V("HASHTAG")^-1,
    HTNAME  = (alphanum + S'_!@$&')^1,    --hashtag name
    STRVAL  = (valuename) + (dquote * sentenc_wdq * dquote) + (quote * sentenc_wq * quote),
    NUMVAL  = number,
    HTVALUE = (V"STRVAL" + V"NUMVAL"),  --hashtag value
}

local ht_parser = P(ht_grammar)
--Ct(ht_parser):match('#fff:12 #vvv:"ab vb cd #sd \t bn"')

local block = P"block" + "b"
local record = P"record" + "r"
local text = P"text" + "t"
local pattern = P"pattern" + "p"
local loc = P"loc" + "l"
local name_var = alpha * (alphanum + underscore)^-19  --name variable or class name len max=20 chars
local loc_ops = (P"from" + P"to" + P"move" + P"not")
local loc_ref = (P"Block" + P"Record" + P"Text" + P"Location" + P"Lines" + P"Sentences" + P"Words" + "Chars" + P"End")
local name_or_index = (name_var + digit^1)
local sign = (P"+" + P"-")
local int = digit^1
local txt_wvirg = (R'!~' + wsp - P"~")^1

local grammar = {
    "EXPR",

    EXPR = (V"BLOCK" + V"RECORD" + V"PATTERN" + V"TEXT" + V"JSON" + V"LOC") +
           (V"SCHEMA" + V"ITEMREC"),

    BLOCK = Ct(
               maybe(wsp) * C(block) * maybe(colon * C(name_var)) * maybe(wsp) *
               obrace * maybe(wsp) *
               maybe(eol) * maybe(wsp) *
               Ct(V"SCHEMA")^1 * maybe(wsp) *
               maybe(eol) * maybe(wsp) * cbrace *
               maybe(wsp^1 * C(V("LOC")^0)) * maybe(wsp)
            ),

    SCHEMA = Ct(  maybe(wsp) *
                C(V"PATTERN" + V"TEXT" + V"RECORD" + V"BLOCK" + V"JSON") *
                (maybe(wsp) * maybe(comma) * maybe(wsp))
             ) * V("SCHEMA")^-1,

    RECORD = Ct(
               maybe(wsp) * C(record) * maybe(colon * C(name_var)) * maybe(wsp) *
               obrace * maybe(wsp) *
               maybe(eol) * maybe(wsp) *
               (V"ITEMREC")^1 * maybe(wsp) *
               maybe(eol) * maybe(wsp) * cbrace *
               maybe(wsp^1 * C(V("LOC")^0)) * maybe(wsp)
             ),

    ITEMREC = Ct( maybe(wsp) *
                C(V"PATTERN" + V"TEXT" + V"BLOCK" + V"JSON") *
                (maybe(wsp) * maybe(comma) * maybe(wsp))
            ) * V("ITEMREC")^-1,

    TEXT = Ct(maybe(wsp) * C(text) *
           maybe(colon * C(name_var)) * wsp^1 *
           virgulilla * C(txt_wvirg) * virgulilla *
           maybe(V"LOC") * maybe(wsp)),

    PATTERN = Ct(
        maybe(wsp) * C(pattern) *
        maybe(colon * C(name_var)) * maybe(wsp) *
        virgulilla * C(txt_wvirg) * virgulilla
    ),

    LOC = maybe(wsp) * C(loc) *
          maybe(colon * C(name_var)) * wsp^1 *
          (loc_ops * wsp^1 * V"LOCSPEC")^1,

    LOCSPEC = Ct(
                 maybe(wsp) * loc_ref * maybe(wsp) *
                 maybe(name_or_index) * maybe(wsp) *
                 (maybe(sign) * int)
                ) * V"LOCSPEC"^-1,

    EXTRACT = P'extract',
    IGNORE = P'ignore',
    JSON = C(P'json'),
    CSV = C(P'csv'),
    VARIABLE = P'var', --extrae un valor unico
    ARRAY = P'array', --genera un arreglo de valores
}

local parser = P(grammar)
--parser:match('b:BLKA {p:OK ~64 bytes from $(server) $(ip): icmp_seq=$(seq) ttl=$(ttl) time=$(time) $(um)~}')

local word = patt.word
local sentence = patt.sentence
local paragraph = patt.paragraph
local asci = patt.asci

local sandbox_env = {}

sandbox_env['P']          = P
sandbox_env['R']          = R
sandbox_env['S']          = S
sandbox_env['C']          = C
sandbox_env['maybe']      = maybe
sandbox_env['any']        = patt.any^1
sandbox_env['lower']      = lcase^1
sandbox_env['upper']      = lcase^1
sandbox_env['alpha']      = alpha^1
sandbox_env['alphanum']   = alphanum^1
sandbox_env['hostname']   = patt.hostname
sandbox_env['ip4']        = patt.ip4
sandbox_env['num']        = number
sandbox_env['nat']        = patt.nat
sandbox_env['int']        = patt.int
sandbox_env['float']      = patt.float
sandbox_env['zeros']      = patt.zeros
sandbox_env['ones']       = patt.ones
sandbox_env['towsp']      = patt.to
sandbox_env['word']       = word
sandbox_env['sentence']   = sentence
sandbox_env['paragraph']  = paragraph
sandbox_env['spaces']     = patt.spaces
--sandbox_env['inc']        = inc
--sandbox_env['seq']        = seq

local function split (str, sep)
    sep = P(sep)
    local elem = C((1 - sep)^0)
    local p = Ct(elem * (sep * elem)^0)   --make a table capture
    return match(p, str)
end

--Split to first n items
local function split_n (str, sep, nitems)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    local n = 0
    for _str in string.gmatch(str, "([^"..sep.."]+)") do
            t[#t+1] = _str
            n = n + 1
            if n >= nitems then
                return t
            end
    end
    return t
end

local function capture(str_patt, mb)
    print(str_patt)
    if sandbox_env[str_patt] or l.type(str_patt)=='pattern' then
        if arg then
            if mb==true then
                return 'C(maybe('..str_patt..'))'
            else
                return 'C('..str_patt..')'
            end
        else
            if mb==true then
                return 'C(maybe('..str_patt..'))'
            else
                return 'C('..str_patt..')'
            end
        end
    else
        return 'C(P"'..str_patt..'")'
    end
end

local function noncapture(str_patt, mb)
    if sandbox_env[str_patt] or l.type(str_patt)=='pattern' then
        if arg then
            if mb==true then
                return ('maybe('..str_patt..')')
            else
                return str_patt
            end
        else
            if mb==true then
                return 'maybe('..str_patt..')'
            else
                return str_patt
            end
        end
    else
        return 'C(P"'..str_patt..'")'
    end
end

local function literal(str_patt)
    return 'P"'..str_patt..'"'
end

local function nchars(n)
    local _n = n
    if type(n)=='string' then
        _n = tonumber(n)
    end
    return asci^-_n
end
sandbox_env['nchars'] = nchars

local function n_items(ptt, brek, n)
    local _brek = P(brek)
    local _ptt = (ptt - _brek)^1
    return (_ptt * maybe(_brek))^-n
end

local function nwords(n)
    local _n = n
    if type(n)=='string' then
        _n = tonumber(n)
    end
    return (wsp^0 * word)^-_n
end
sandbox_env['nwords'] = nwords

local function nsentences(n)
    local _n = n
    if type(n)=='string' then
        _n = tonumber(n)
    end
    return (sentence * dot)^-_n
end
sandbox_env['nsentences'] = nsentences

local function nparagraphs(n)
    local _n = n
    if type(n)=='string' then
        _n = tonumber(n)
    end
    return (paragraph * eol)^-_n
end
sandbox_env['nparagraphs'] = nparagraphs

--Clear all 'empty' values from table
local function clear_args(tbl)
    local t = {}
    for i=1,#tbl do
        if tbl[i] ~= '' then
            t[#t+1] = tbl[i]
        end
    end
    return t
end

-- String to pattern
--aj=loadstring('return C(P"hostname") * C(P"jj")')
local function tolpeg(str)
    local lpeg_patt = {}
    local vars = {}
    local parts = split(str, '${')
    for i=1,#parts do
        if parts[i] and parts[i] ~= '' then
            --extract pattern
            local user_intros = split_n(parts[i], '}', 2)
            local prefix = user_intros[1]
            local cont = user_intros[2]
            if not cont then cont = '' end
            if prefix:match(':') then --has pattern definition?
                local vartype = split(prefix, ':')
                local var_name = vartype[1] --variable name
                local is_maybe = false
                if var_name:sub(1,1)=='.' then
                    is_maybe = true
                    var_name = var_name:sub(2, -1)
                end

                local pat = vartype[2]          --pattern values
                local or_lst = split(pat, '|')  --split or pattern options
                local or_tbl = {}

                for j=1,#or_lst do
                    local pat_j = or_lst[j]
                    local func  = pat_j         --for pattern function
                    local parm                  --list params for func
                    if pat_j:find(' ') then
                        local funpart = split(pat_j, ' ')
                        local funp = clear_args(funpart)
                        func = funp[1]
                        table.remove(funp, 1)
                        if #funp~=0 then
                            parm = '('..table.concat(funp, ',')..')'
                        else
                            parm = ''
                        end
                        pat_j = func..parm
                    end

                    local lpeg_bloq
                    if not (sandbox_env[func] or l.type(func)=='pattern') then
                        lpeg_bloq = 'P"'..pat_j..'"'
                    else
                        lpeg_bloq = pat_j
                    end

                    or_tbl[#or_tbl+1] = lpeg_bloq
                end

                local or_pat = table.concat(or_tbl, ' + ')

                if var_name and var_name ~= '' then
                    lpeg_patt[#lpeg_patt+1] = 'C('..or_pat..')' --capture(or_pat, is_maybe)
                    vars[#vars+1] = var_name
                else
                    lpeg_patt[#lpeg_patt+1] = or_pat --, is_maybe)
                end
                lpeg_patt[#lpeg_patt+1] = literal(cont)
            else
                lpeg_patt[#lpeg_patt+1] = literal(prefix)
                if cont ~= '' then
                    lpeg_patt[#lpeg_patt+1] = literal(cont)
                end
            end
        end
    end

    --Resume lpeg pattern
    local str_patt = 'return '..'P('..table.concat(lpeg_patt, ' * ')..')'
    local the_patt = load(str_patt)
    setfenv(the_patt, sandbox_env)

    return {
        patt = the_patt(),
        tree = lpeg_patt,
        vars = vars
    }
end

--t=o.tolpeg('${bits:nat} bytes from ${ip:ip4}: icmp_seq=${seq:nat} ttl=${ttl:nat} time=${time:float} ${um:ms}')
--a=Ct(t.patt):match('64 bytes from 8.8.8.8: icmp_seq=1 ttl=121 time=28.7 ms')

return {
    split = split,
    split_n = split_n,
    tolpeg = tolpeg,
    parser = parser,
    n_items = n_items
}