-- Keeps this config's colorscheme in sync with `omarchy theme set`.
--
-- Omarchy writes a lazy.nvim plugin-spec file at
-- ~/.local/state/omarchy/current/theme/neovim.lua every time the theme
-- changes, shaped like:
--   return {
--     { "<colorscheme-plugin>", name = "...", opts = { ... } },
--     { "LazyVim/LazyVim", opts = { colorscheme = "<name>" } },
--   }
-- Many themes (every one without a hand-written neovim.lua) share the same
-- plugin and colorscheme name -- "aether" -- and differ ONLY in that plugin's
-- `opts.colors`. So syncing just the colorscheme name is not enough: the
-- plugin's setup() must be re-run with the theme's opts every time.
--
-- The real omarchy-nvim config (LazyVim) symlinks that file into its plugins
-- dir and relies on lazy.nvim's change_detection. This config isn't LazyVim,
-- so we read the file as plain data via dofile() and watch for changes
-- ourselves. The "LazyVim/LazyVim" entry is just data here, never installed.
local state_dir = vim.fn.expand("~/.local/state/omarchy/current")
local theme_file = state_dir .. "/theme/neovim.lua"

local function read_file(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end
	local content = fd:read("*a")
	fd:close()
	return content
end

-- Splits the spec into the colorscheme name and the colorscheme plugin entry.
local function parse_spec(spec)
	if type(spec) ~= "table" then
		return nil
	end
	local colorscheme, plugin_spec
	for _, entry in ipairs(spec) do
		if type(entry) == "table" then
			local id = entry[1] or entry.name
			if type(id) == "string" and id:match("LazyVim") then
				if type(entry.opts) == "table" then
					colorscheme = entry.opts.colorscheme
				end
			elseif type(id) == "string" then
				plugin_spec = entry
			end
		end
	end
	return colorscheme, plugin_spec
end

-- Finds the matching plugin registered in all-themes.lua. The spec may name
-- it by `name` or by repo ("owner/repo"), and the repo owner can differ from
-- ours (e.g. omacom/aether.nvim vs bjarneo/aether.nvim), so match loosely.
local function find_plugin(plugin_spec)
	local plugins = require("lazy.core.config").plugins
	if plugin_spec.name and plugins[plugin_spec.name] then
		return plugins[plugin_spec.name]
	end
	local repo = plugin_spec[1] and plugin_spec[1]:match("[^/]+$")
	if repo and plugins[repo] then
		return plugins[repo]
	end
	return nil
end

-- Re-runs the colorscheme plugin's setup() with the theme's opts, after
-- dropping its cached Lua modules so palettes computed from the previous
-- opts don't survive.
local function setup_plugin(plugin, opts)
	require("lazy").load({ plugins = { plugin.name } })

	local lua_dir = plugin.dir .. "/lua"
	if vim.fn.isdirectory(lua_dir) == 1 then
		require("lazy.core.util").walkmods(lua_dir, function(modname)
			package.loaded[modname] = nil
		end)
	end

	if type(opts) ~= "table" then
		return
	end

	local ok_main, main = pcall(require("lazy.core.loader").get_main, plugin)
	if not ok_main or not main then
		return
	end
	local ok_mod, mod = pcall(require, main)
	if ok_mod and type(mod) == "table" and type(mod.setup) == "function" then
		local ok_setup, err = pcall(mod.setup, opts)
		if not ok_setup then
			vim.notify(("omarchy-theme-sync: %s.setup() failed: %s"):format(main, err), vim.log.levels.WARN)
		end
	end
end

local last_content

local function apply(force)
	local content = read_file(theme_file)
	if not content or (content == last_content and not force) then
		return
	end

	local ok, spec = pcall(dofile, theme_file)
	if not ok then
		return
	end
	last_content = content

	local colorscheme, plugin_spec = parse_spec(spec)
	if not colorscheme then
		return
	end

	if plugin_spec then
		local plugin = find_plugin(plugin_spec)
		if plugin then
			setup_plugin(plugin, plugin_spec.opts)
		end
	end

	vim.cmd("highlight clear")
	if vim.fn.exists("syntax_on") == 1 then
		vim.cmd("syntax reset")
	end
	-- Let light themes flip this themselves.
	vim.o.background = "dark"

	-- colorscheme fires the ColorScheme autocmd itself, which lets
	-- statusline/treesitter/etc plugins re-derive their highlights.
	local applied = pcall(vim.cmd.colorscheme, colorscheme)
	if not applied then
		vim.notify(("omarchy-theme-sync: no colorscheme %q installed"):format(colorscheme), vim.log.levels.WARN)
		return
	end
	vim.cmd("redraw!")
end

return {
	{
		name = "omarchy-theme-sync",
		dir = vim.fn.stdpath("config"),
		lazy = false,
		priority = 1000,
		cond = function()
			return vim.fn.isdirectory(state_dir) == 1
		end,
		config = function()
			local uv = vim.uv or vim.loop

			apply(true) -- sync immediately on startup

			-- `omarchy theme set` does `rm -rf current/theme && mv next-theme
			-- current/theme`, so a watch on the file itself dies with the old
			-- directory. Watch the stable parent instead, debounce the burst of
			-- events a switch produces, and only re-apply when neovim.lua's
			-- content actually changed.
			local timer = uv.new_timer()
			local handle = uv.new_fs_event()
			handle:start(state_dir, {}, function()
				timer:stop()
				timer:start(200, 0, vim.schedule_wrap(function()
					apply(false)
				end))
			end)

			vim.api.nvim_create_user_command("OmarchyThemeSync", function()
				apply(true)
			end, { desc = "Re-apply the colorscheme from Omarchy's current theme" })
		end,
	},
}
