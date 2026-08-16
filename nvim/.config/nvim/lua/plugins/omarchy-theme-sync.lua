-- Keeps this config's colorscheme in sync with `omarchy theme set`.
--
-- Omarchy regenerates a lazy.nvim plugin-spec file at
-- ~/.local/state/omarchy/current/theme/neovim.lua every time the theme
-- changes, shaped like:
--   return {
--     { "<colorscheme-plugin>" },
--     { "LazyVim/LazyVim", opts = { colorscheme = "<name>" } },
--   }
-- The real omarchy-nvim config (LazyVim) symlinks straight to that file and
-- relies on lazy.nvim's change_detection to fire `User LazyReload`. This
-- config isn't LazyVim, so instead we watch the file ourselves with a libuv
-- fs_event and read it as plain data via dofile() -- the "LazyVim/LazyVim"
-- entry is just a data table here, never installed as a real plugin.
return {
	{
		name = "omarchy-theme-sync",
		dir = vim.fn.stdpath("config"),
		lazy = false,
		priority = 1000,
		config = function()
			local uv = vim.uv or vim.loop

			local theme_path = vim.iter({
				vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua"),
				vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua"),
			}):find(function(p) return vim.fn.filereadable(p) == 1 end)

			if not theme_path then
				return
			end

			local function find_colorscheme(spec)
				if type(spec) ~= "table" then
					return nil
				end
				for _, entry in ipairs(spec) do
					if type(entry) == "table" then
						local name = entry[1] or entry.name
						if type(name) == "string" and name:match("LazyVim") then
							if type(entry.opts) == "table" and type(entry.opts.colorscheme) == "string" then
								return entry.opts.colorscheme
							end
						end
					end
				end
				return nil
			end

			local function apply()
				local ok, spec = pcall(dofile, theme_path)
				if not ok then
					return
				end

				local name = find_colorscheme(spec)
				if not name or vim.g.colors_name == name then
					return
				end

				-- Puts a lazy-loaded colorscheme plugin on rtp before :colorscheme
				-- needs it; no-op if already loaded.
				pcall(function() require("lazy.core.loader").colorscheme(name) end)

				vim.cmd("highlight clear")
				if vim.fn.exists("syntax_on") == 1 then
					vim.cmd("syntax reset")
				end

				local applied = pcall(vim.cmd.colorscheme, name)
				if not applied then
					vim.notify(("omarchy-theme-sync: no colorscheme %q installed"):format(name), vim.log.levels.WARN)
					return
				end

				-- Lets statusline/treesitter/etc plugins that hook ColorScheme
				-- re-derive their highlights.
				vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
				vim.cmd("redraw!")
			end

			-- fs_event watches an inode; atomic writes (write-temp + rename) swap
			-- it out, so re-arm the watcher after every fire instead of trusting
			-- one handle to live forever.
			local handle
			local function watch()
				if handle then
					pcall(function()
						handle:stop()
						handle:close()
					end)
				end
				handle = uv.new_fs_event()
				handle:start(theme_path, {}, vim.schedule_wrap(function()
					vim.defer_fn(function()
						apply()
						watch()
					end, 150)
				end))
			end

			apply() -- sync immediately on startup
			watch()

			vim.api.nvim_create_user_command("OmarchyThemeSync", apply, {
				desc = "Re-apply the colorscheme from Omarchy's current theme",
			})
		end,
	},
}
