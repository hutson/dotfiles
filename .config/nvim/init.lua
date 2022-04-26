--[[
	Vim Configuration

	This script provides useful Vim configuration settings.
--]]

--[[
	General Features

	These options enable several useful baseline features for improving Vim functionality.
--]]

-- Use Unix as the standard file type when saving a buffer back to file. This will cause Unix line terminators, \n, to be used for deliminating a file's newlines.
vim.opt.fileformat = 'unix'

-- Disable modeline support within Vim. Modeline support within Vim has constantly introduced security vulnerabilities into the Vim editor. By disabling this feature any chance of a future vulnerability interfering with the use of Vim, or the operating system on which it runs, is mitigated. As for functionality, modelines are configuration lines contained within text files that instruct Vim how to behave when reading those files into a buffer.
vim.opt.modeline = false -- Turn off modeline parsing altogether.

-- Set the default language to use for spell checking. `spelllang` is a comma separated list of word lists. Word lists are of the form LANGUAGE_REGION. The LANGUAGE segment may include a specification, such as `-rare` to indicate rare words in that language.
vim.opt.spelllang = 'en_us'

-- Automatically save the contents of the buffer to file whenever the `:make` command is invoked, which is used by plugins such as Go for their `GoBuild`, etc. functions.
vim.opt.autowrite = true

-- TODO: Convert remaining Vimscript to Lua.
vim.cmd('source ~/.config/nvim/script.vim')

--[[
	User Interface

	These options alter the graphical layout and visual color of the interface, and alter how file contents are rendered.
--]]

-- Enable better command-line completion.
vim.opt.wildmenu = true -- Enables a menu at the bottom of the window.
vim.opt.wildmode = 'list:longest,full' -- Allows the completion of commands on the command line via the tab button.

-- Ignore certain backup and compiled files based on file extensions when using tab completion.
vim.opt.wildignore = '*.swp,*.bak,*.tmp,*~,.zip,*.7z,*.gzip,*.gz,*.jpg,*.png,*.gif,*.avi,*.mov,*.mpeg'

-- Try not to split words across multiple lines when a line wraps.
vim.opt.linebreak = true

-- Use case insensitive search, except when using capital letters.
vim.opt.ignorecase =true -- Case insensitive search.
vim.opt.smartcase = true -- Enable case-sensitive search when the search phrase contains capital letters.

-- Allows moving left when at the beginning of a line, or right when at the end of the line. When the end of the line has been reached, the cursor will progress to the next line, either up or down, depending on the direction of movement. < and > are left and right arrow keys, respectively, in normal and visual modes, and [ and ] are arrow keys, respectively, in insert mode.
vim.opt.whichwrap = '<,>,h,l,[,]'

-- Instead of failing a command because of unsaved changes raise a dialogue asking if you wish to save changed files.
vim.opt.confirm = true

-- Enable use of the mouse for all Vim modes: Normal, Insert, Visual, and Command-line.
vim.opt.mouse = 'a'

-- Use abbreviations when posting status messages to the command output line (The line right beneth Vim's statusline). Shortening command output may help avoid the 'press <Enter>' prompt that appears when the output is longer than the available space in the command output section. Furthermore, we append the 't' option to 'shortmess' so that if abbreviations are insufficient to keep output within the confines of the command output section, then content will be truncated as necessary; beginning at the start of the message.
vim.opt.shortmess = 'at'

-- Display line numbers on the left with a column width of 4.
vim.opt.number = true

-- A buffer becomes hidden, not destroyed, when it's abandoned.
vim.opt.hidden = true

-- Don't redraw while executing macros, thereby improving performance.
vim.opt.lazyredraw = true

-- Show matching brackets when text indicator is over them.
vim.opt.showmatch = true

-- Disable error bells.
vim.opt.errorbells = false
vim.opt.visualbell = false

-- Start scrolling when we're 3 lines from the bottom of the current window.
vim.opt.scrolloff = 3

-- Enable the highlighting of the row on which the cursor resides, along with highlighting the row's row number.
vim.opt.cursorline = true

-- Instruct Vim to offer corrections in a pop-up on right-click of the mouse.
vim.opt.mousemodel = 'popup'

-- Configure Vim's formatting options used by Vim to automatically for a line of text. Formatting not applied when 'paste' is enabled.
-- Options:
-- j - Where it makes sense, remove a comment leader when joining lines.
-- l - Do not break existing long lines when entering insert mode.
-- n - Recognize numbered lists and automatically continue the correct level of indention onto the next line.
-- o - Automatically insert the current comment leader after after entering 'o' or 'O' in Normal mode.
-- q - Allow formatting of comments using `gq`.
-- r - Automatically insert the current comment leader after pressing <ENTER> in Insert mode.
vim.opt.formatoptions = 'jlnoqr'
