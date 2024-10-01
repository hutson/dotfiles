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
config.scrollback_lines = 10000

-- Set my LEADER key to be something familiar.
config.leader = {
	key = 'a',
	mods = 'CTRL',
	timeout_milliseconds = 500,
}

-- Create a powerline line tab bar with regularly updated segments
-- containing information relavent to the current terminal environment.
local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
wezterm.on('update-status', function(window)
	local color_scheme = window:effective_config().resolved_palette
	local background = color_scheme.background
	local foreground = color_scheme.foreground
	window:set_right_status(wezterm.format({
		{ Background = { Color = 'none' } },
		{ Foreground = { Color = background } },
		{ Text = SOLID_LEFT_ARROW },
		{ Background = { Color = background } },
		{ Foreground = { Color = 'Green' } },
		{ Text = ' ' .. wezterm.hostname() .. ' ' },
	}))
end)

local function resize_pane(key, direction)
	return {
		key = key,
		action = wezterm.action.AdjustPaneSize { direction, 6 }
	}
end

config.key_tables = {
	resize_panes = {
		resize_pane('DownArrow', 'Down'),
		resize_pane('UpArrow', 'Up'),
		resize_pane('LeftArrow', 'Left'),
		resize_pane('RightArrow', 'Right'),
	},
}

config.keys = {
	-- Allow resizing split panes using arrow keys.
	{
		key = 'r',
		mods = 'LEADER',
		action = wezterm.action.ActivateKeyTable {
			name = 'resize_panes',
			one_shot = false,
			timeout_milliseconds = 500,
		}
	},

	-- Close tab with same hotkey as used in a browser.
	{
		key = 'w',
		mods = 'CTRL',
		action = wezterm.action.CloseCurrentTab{ confirm = false },
	},

	-- Split horizonal.
  {
    key = 'h',
    mods = 'LEADER',
    action = wezterm.action.SplitPane {
      direction = 'Down',
      size = { Percent = 50 },
    },
  },
}

return config
