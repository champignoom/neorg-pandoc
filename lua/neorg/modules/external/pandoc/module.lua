local neorg = require("neorg.core")
local lib, log, modules, utils = neorg.lib, neorg.log, neorg.modules, neorg.utils

local module = modules.create("external.pandoc", {})

module.setup = function()
    return {
        success = true,
        requires = {
            "core.neorgcmd",
            "core.integrations.treesitter",
        },
    }
end

module.private = {
}

local function get_metadata_node(buf)
    local languagetree = vim.treesitter.get_parser(buf, "norg")
    if not languagetree then
        return
    end

    for _, tree in pairs(languagetree:children()) do
        if tree:lang() == "norg_meta" then
            local tree = tree:parse()[1]
            return tree and tree:root()
        end
    end
end

local function get_metadata(buf)
    local meta_root = get_metadata_node(buf)
    if not meta_root then
        return
    end

    local query = utils.ts_parse_query(
        "norg_meta",
        [[
        (pair
        (key) @key
        (value) @value)
        ]]
    )

    local key
    local data = {}
    for id, node in query:iter_captures(meta_root, buf) do
        local capture = query.captures[id]
        local range = module.required["core.integrations.treesitter"].get_node_range(node)
        local lines = vim.api.nvim_buf_get_text(buf, range.row_start, range.column_start, range.row_end, range.column_end, {})

        if capture == "key" then
            assert(key == nil)
            assert(#lines == 1)
            key = lines[1]
        else
            assert(#lines <=1 or lines[1] == "[" and lines[#lines] == "]")
            table.remove(lines, #lines)
            table.remove(lines, 1)
            data[key] = lines
            key = nil
        end
    end

    return data
end

local function handle_event(event)
    local metadata = get_metadata(event.buffer)
    local pandoc_args = metadata and metadata['pandoc-args'] or {}
    local this_dir = debug.getinfo(1).source:match("@?(.*/)")
    local plugin_dir = this_dir .. '../../../../../'

    if metadata and metadata['pandoc-ignore-metadata'] then
        pandoc_args[#pandoc_args+1] = '--lua-filter'
        pandoc_args[#pandoc_args+1] = plugin_dir .. 'filter/ignore_metadata.lua'
    end

    local input_file = event.filehead .. '/' .. event.filename
    local output_file = event.content[1]
    local cmd = vim.tbl_flatten{ 'pandoc', '--from', plugin_dir .. 'init.lua', '-o', output_file, pandoc_args, input_file, '2>&1'}
    local f = io.popen(table.concat(cmd, ' '))
    local output = f:read("*all")
    f:close()
    if output and #output > 0 then
        log.warn(output)
    else
        print('pandoc finished')
    end
end


module.on_event = function(event)
    if event.type ~= "core.neorgcmd.events.external.pandoc" then
        return
    end

    if vim.bo[event.buffer].ft ~= "norg" then
        log.warn("not a norg file")
        return
    end

    handle_event(event)
end

module.load = function()
    modules.await("core.neorgcmd", function(neorgcmd)
        neorgcmd.add_commands_from_table({
            ["pandoc"] = {
                name = "external.pandoc",
                args = 1,
                condition = "norg",
            },
        })
    end)
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["external.pandoc"] = true,
    },
}

return module
