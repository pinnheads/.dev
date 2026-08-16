-- Load all Omarchy colorscheme plugins lazily so any theme picked via
-- `omarchy theme set` has a matching plugin available. None of these are
-- actually applied here -- omarchy-theme-sync.lua picks the active one.
--
-- `lazy = true` only defers *loading*; lazy.nvim still clones every listed
-- repo on `:Lazy sync` regardless of that flag. On a machine without
-- Omarchy these would never be selected, so skip registering them entirely
-- -- keeps this config portable to plain Arch/other systems without
-- wasting installs on plugins nothing will ever pick.
if
	vim.fn.isdirectory(vim.fn.expand("~/.config/omarchy")) ~= 1
	and vim.fn.isdirectory(vim.fn.expand("~/.local/state/omarchy")) ~= 1
then
	return {}
end

return {
	{ "ribru17/bamboo.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/aether.nvim", branch = "v3", name = "aether", lazy = true, priority = 1000 },
	{ "bjarneo/ethereal.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/hackerman.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/vantablack.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/white.nvim", lazy = true, priority = 1000 },
	{ "catppuccin/nvim", name = "catppuccin", lazy = true, priority = 1000 },
	{ "neanias/everforest-nvim", lazy = true, priority = 1000 },
	{ "kepano/flexoki-neovim", lazy = true, priority = 1000 },
	{ "ellisonleao/gruvbox.nvim", lazy = true, priority = 1000 },
	{ "rebelot/kanagawa.nvim", lazy = true, priority = 1000 },
	{ "tahayvr/matteblack.nvim", lazy = true, priority = 1000 },
	{ "gthelding/monokai-pro.nvim", lazy = true, priority = 1000 },
	{ "EdenEast/nightfox.nvim", lazy = true, priority = 1000 },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true, priority = 1000 },
	{ "ficcdaf/ashen.nvim", lazy = true, priority = 1000 },
	{ "folke/tokyonight.nvim", lazy = true, priority = 1000 },
	{ "OldJobobo/miasma.nvim", lazy = true, priority = 1000 },
	{ "OldJobobo/retro-82.nvim", lazy = true, priority = 1000 },
	{ "omacom-io/lumon.nvim", lazy = true, priority = 1000 },
}
