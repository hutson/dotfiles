local wezterm = require 'wezterm'

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.font = wezterm.font('Hack Nerd Font')

if wezterm.gui and wezterm.gui.get_appearance():find("Dark") then
	config.color_scheme = 'carbonfox'
end

config.window_background_opacity = 0.95
config.macos_window_background_blur = 10

config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

config.scrollback_lines = 10000

return config
