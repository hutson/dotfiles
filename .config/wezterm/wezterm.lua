local wezterm = require 'wezterm'

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- The default font size, 12pt as of writing, is too large
-- relative to other text on the screen while using the
-- default font used by WezTerm.
config.font_size = 10

-- Prefer a more traditional square tab style in the terminal.
config.use_fancy_tab_bar = false

config.window_background_opacity = 0.70
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
wezterm.on('update-status', function(window)
	local tab = window:active_tab()
	local panes = tab:panes()
	local alt_screen_active = false

	for i = 1, #panes, 1 do
		local pane = panes[i]
		if pane:is_alt_screen_active() then
			alt_screen_active = true
			break
		end
	end

	if alt_screen_active then
		window:set_config_overrides({
			window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
		})
	else
		window:set_config_overrides({
			window_padding = default_padding,
		})
	end

	local color_scheme = window:effective_config().resolved_palette
	window:set_right_status(wezterm.format({
		{ Background = { Color = color_scheme.background } },
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
	{
		key = 'r',
		mods = 'LEADER',
		action = wezterm.action.ActivateKeyTable {
			name = 'resize_panes',
			one_shot = false,
			timeout_milliseconds = 500,
		}
	},

	{
		key = 'w',
		mods = 'LEADER',
		action = wezterm.action.CloseCurrentTab { confirm = false },
	},

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
