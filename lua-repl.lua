local options = {
    persist_history = false,
    history_path = '~~state/lua_history.txt',
}

require 'mp.options'.read_options(options)

-- These are global to make them available in the REPL.
utils = require 'mp.utils'
input = require 'mp.input'

mp.add_key_binding('Ctrl+r', 'lua-repl', function ()
    input.get({
        prompt = 'Evaluate Lua:',
        keep_open = true,
        history_path = options.persist_history and mp.command_native({"expand-path", options.history_path}) or nil,
        opened = function ()
            -- Show messages logged with print() without switching to the regular console.
            mp.enable_messages('terminal-default')
        end,
        complete = function (code)
            local last_identifier = code:match('[%w_%.]*$')
            if last_identifier == nil then
                return
            end

            local prefix_table = _G
            for prefix in last_identifier:gmatch('([%w_]+)%.') do
                prefix_table = prefix_table[prefix]

                if type(prefix_table) ~= 'table' then
                    return
                end
            end

            local candidates = {}
            for key, value in pairs(prefix_table) do
                local suffix = ''
                if type(value) == 'function' then
                    suffix = '('
                elseif type(value) == 'table' then
                    suffix = '.'
                end
                candidates[#candidates+1] = key .. suffix
            end

            return candidates, code:find('[%w_]*$'), nil
        end,
        submit = function (code)
            -- Auto insert return before single lines, without breaking
            -- assignments, loops and conditionals. Unfortunately, this breaks
            -- multiple statements on the same line like 'print("foo") print("bar")'
            if code:find('[;\n]') == nil and
               code:find('^%s*return%s') == nil and
               -- Don't insert return before assigments, but insert it before
               -- tables with indexes like {['foo'] = 'bar'}.
               (code:find('[^=]=[^=]') == nil or code:find('^%s*{.*[^=]=[^=]')) and
               code:find('^%s*if%s') == nil and
               code:find('^%s*for%s') == nil and
               code:find('^%s*while%s') == nil and
               code:find('^%s*repeat%s') == nil then
                code = 'return ' .. code
            end

            local result, error = load(code)
            if result == nil then
                input.log_error(error)
                return
            end

            result = {pcall(result)}
            if result[1] == false then
                input.log_error(result[2])
                return
            end

            -- When result[2] is nil and result[3] is not #result is 1, so
            -- determine the real length.
            local length = 0
            for index, _ in pairs(result) do
                if index > length then
                    length = index
                end
            end
            -- Or use table.maxn(result), but it was removed in Lua 5.3.

            if length == 2 then
                input.log(utils.to_string(result[2]))
            elseif length > 2 then
                local result_string = ''
                for i = 2, length do
                    result_string = result_string .. utils.to_string(result[i])
                                    .. (i < length and '    ' or '')
                end
                input.log(result_string)
            end
        end,
        closed = function ()
            mp.enable_messages('no')
        end,
    })
end)

mp.register_event('log-message', function (e)
    if e.prefix == mp.get_script_name() then
        input.log('[' .. e.level .. '] ' .. e.text:gsub('\n$', ''))
    end
end)
