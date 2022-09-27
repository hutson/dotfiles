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

--[[
	Backups

	These options manage settings associated with how backups are handled by Vim.
--]]

-- Turn off backups for files that are being edited by Neovim.
vim.opt.backup = false -- Do not keep a backup of a file after overwriting the file.
vim.opt.swapfile = false -- No temporary swap files.

--[[
	Tab and Indents

	These options manage settings associated with tabs and automatically indenting new lines.
--]]

-- Number of spaces Vim should use to visually represent a TAB character when encountered within a file.
vim.opt.tabstop = 2

-- Number of spaces Vim should use when autoindenting a new line of text, or when using the `<<` and `>>` operations (Such as pressing > or < while text is selected to change the indentation of the text). Also used by `cindent` when that option is enabled.
vim.opt.shiftwidth = 2

-- Number of spaces Vim should insert when TAB is pressed, and the number of spaces Vim should remove when the <backspace> is pressed. This allows for a single backspace to go back this many white space characters.
vim.opt.softtabstop = 2

-- Copy the structure of the existing lines indent when autoindenting a new line.
vim.opt.copyindent = true

-- Enable special display options to show tabs and end-of-line characters within a non-GUI window. Tabs are represented using '>-' and a sequence of '-'s that will fill out to match the proper width of a tab. End-of-line is represented by a dollar sign '$'. Displaying tabs as '>-' and end-of-lines as '$'. Trailing white space is represented by '~'. Must be toggled by a mapping to ':set list!'.
vim.opt.listchars = 'tab:>-,eol:$,trail:~,extends:>,precedes:<'

--[[
	Folding

	These options manage settings associated with folding portions of code into condensed forms, leaving only an outline of the code visible. Folding is a form of collapsing of function definitions, class definitions, sections, etc. When a portion of code is collapsed only a header associated with that section is left visible along with a line indicating statistics associated with the collapsed code; such as the number of collapsed lines, etc. The terms 'folded' and 'collapsed' within this file are used interchangeably with one another.
--]]

-- Use tree-sitter to determine how source code or content should be folded.
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr   = 'nvim_treesitter#foldexpr()'

-- Show 4 levels of nested content before automatically folding. 4 levels is usually good enough to find the section we are interested in before needing to expand that section, without being overwhelmed with all the content a file might contain.
vim.opt.foldlevel = 4

--[[
	Tree-sitter

	Enable and configure the AST-aware tree-sitter for syntax highlighting and folding.
--]]

require'nvim-treesitter.configs'.setup {
	-- A list of language parsers that should be installed and enabled to provide syntax highlighting.
	ensure_installed = { 'bash', 'cooklang', 'css', 'dockerfile', 'go', 'hcl', 'help', 'html', 'javascript', 'json', 'lua', 'markdown', 'python', 'regex', 'toml', 'vim', 'yaml', 'zig' },

	-- Install parsers asynchornously so as not to block the user from working with the current buffer. (Only applies to `ensure_installed`.)
	sync_install = false,

	highlight = {
		-- Enable syntax highlighting using tree-sitter.
		enable = true,

		-- Setting this to `true` will run `syntax` and `tree-sitter` at the same time.
		-- Using this option may slow down neovim while it's attempting to run two syntax highlighers and may cause duplicate highlights.
		additional_vim_regex_highlighting = false,
	},
}

--[[
	Language Server

	Setup and configuration for language servers.
--]]

-- The following key mapping is taken from https://github.com/neovim/nvim-lspconfig#suggested-configuration

-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
vim.api.nvim_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
	-- Enable completion triggered by <c-x><c-o>
	vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
	vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { 'gopls', 'terraformls' }
for _, lsp in pairs(servers) do
	require('lspconfig')[lsp].setup {
		on_attach = on_attach,
		flags = {
			-- This will be the default in neovim 0.7+
			debounce_text_changes = 150,
		}
	}
end

--[[
	Vim Explorer


	These options configure Vim's built-in file system explorer so that it behaves in a manner that meets user expectations. This includes showing files in a tree view so that entire projects can be seen at once.
--]]

-- Will cause files selected in the Explorer window to be opened in the most recently used buffer window (Causing the previous buffer to be pushed into the background).
vim.g.netrw_browse_split = 4

-- List files and directories in the Explorer window using the tree listing style.
vim.g.netrw_liststyle = 3
