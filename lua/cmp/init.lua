local care_cmp = {}

function care_cmp.register_source(name, cmp_source)
    cmp_source.name = "cmp_" .. name
    cmp_source.display_name = name .. " (cmp)"
    if not cmp_source.is_available then
        cmp_source.is_available = function()
            return true
        end
    end
    local old_complete = cmp_source.complete
    cmp_source.complete = function(completion_context, callback)
        local cursor = vim.api.nvim_win_get_cursor(0)
        local cursor_line = vim.api.nvim_get_current_line()
        local cmp_context = {
            option = { reason = completion_context.completion_context.triggerKind == 1 and "manual" or "auto" },
            filetype = vim.api.nvim_get_option_value("filetype", {
                buf = 0,
            }),
            time = vim.uv.now(),
            bufnr = vim.api.nvim_get_current_buf(),
            cursor_line = cursor_line,
            cursor = {
                row = cursor[1],
                col = cursor[2] - 1,
                line = cursor[1] - 1,
                character = cursor[2] - 1,
            },
            get_reason = function(self)
                return self.option.reason
            end,
            cursor_before_line = string.sub(cursor_line, 1, cursor[2] - 2),
            cursor_after_line = string.sub(cursor_line, cursor[2] - 1),
        }
        local TODO = 3
        old_complete(cmp_source, {
            context = cmp_context,
            offset = TODO,
            completion_context = completion_context.completion_context,
            option = {},
            ---@diagnostic disable-next-line: redundant-parameter
        }, function(response)
            if not response then
                callback({})
                return
            end
            if response.isIncomplete ~= nil then
                callback(response.items or {}, response.isIncomplete == true)
                return
            end
            callback(response.items or response)
        end)
    end
    local old_is_available = cmp_source.is_available
    if old_is_available then
        cmp_source.is_available = function(self)
            old_is_available(self)
        end
    end
    local old_get_keyword_pattern = cmp_source.get_keyword_pattern
    if old_get_keyword_pattern then
        cmp_source.get_keyword_pattern = function(self)
            return old_get_keyword_pattern(self, { option = {} })
        end
    end
    local old_execute = cmp_source.execute
    if old_execute then
        cmp_source.execute = function(self, entry)
            old_execute(self, entry.completion_item, function() end)
        end
    end
    require("care.sources").register_source(vim.deepcopy(cmp_source))
end

care_cmp.lsp = {}
care_cmp.lsp.CompletionItemKind = {
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Class = 7,
    Interface = 8,
    Module = 9,
    Property = 10,
    Unit = 11,
    Value = 12,
    Enum = 13,
    Keyword = 14,
    Snippet = 15,
    Color = 16,
    File = 17,
    Reference = 18,
    Folder = 19,
    EnumMember = 20,
    Constant = 21,
    Struct = 22,
    Event = 23,
    Operator = 24,
    TypeParameter = 25,
}

care_cmp.lsp.MarkupKind = { PlainText = "plaintext", Markdown = "markdown" }

care_cmp.ContextReason = {
    Auto = "auto",
    Manual = "manual",
    TriggerOnly = "triggerOnly",
    None = "none",
}

return care_cmp
