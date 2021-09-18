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

local popen_new = popen.new
local popen_opts = popen.opts
local sleep = fiber.sleep

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