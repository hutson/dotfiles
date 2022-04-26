" Create a directory if it doesn't already exist.
function! EnsureDirectoryExists(directory)
	" Take the given directory, trim white space, and then expand the path using any path wildcards; such as ~ for example. Also, the second argument to expand(...) instructs expand to ignore Vim's suffixes and wildignore options..
	let l:path = expand(substitute(a:directory, '\s\+', '', 'g'), 1)

	" Ensure the expanded path is non-empty. An empty l:path may be caused if path expansion in previous step fails. For that reason we should return the original directory in hopes that it's useful for debugging.
	if empty(l:path)
		echoerr "EnsureDirectoryExists(): Invalid path: " . a:directory
		return 0
	endif

	" Ensure the path does not already exist (Because what's the point of creating a directory that already exists.).
	if !isdirectory(l:path)
		" Ensure `mkdir` exists on the system or otherwise we can't create the directory automatically.
		if exists('*mkdir')
			call mkdir(l:path,'p')
			echomsg "Created directory: " . l:path
		else
			echoerr "Please create directory: " . l:path
		endif
	endif

	return isdirectory(l:path)
endfunction

"====================================================
" Setup vim-plug Plugin
"
" Setup the vim-plug plugin so that it's aware of external plugins we're interested in incorporating into our Vim instance. vim-plug will manage those plugins by pulling in updates and placing them in the appropriate Vim directory.

" Note: Plugins MUST be listed before any configuration steps involving these plugins can take place.
"====================================================

" We must ensure that the `autoload` directory exists within our `~/.vim` directory for the installation of `vim-plug` to work. If the `autoload` directory does not exist prior to invoking `curl`, `curl` will fail to download the file, as `curl` is not setup to create missing directories in the destination path.
call EnsureDirectoryExists($XDG_DATA_HOME . '/nvim/site/autoload/')
if empty(glob($XDG_DATA_HOME . '/nvim/site/autoload/plug.vim'))
	" If vim-plug has not been downloaded into Vim's autoload directory, go ahead and invoke `curl` to download vim-plug.
	execute '!curl -fLo $XDG_DATA_HOME/nvim/site/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin()

Plug 'https://github.com/neovim/nvim-lspconfig.git' " Language Server client for intelligent autocompletion.

Plug 'https://github.com/fatih/vim-go.git', { 'do': ':GoUpdateBinaries' } " Go tools, such as `goimports`.
Plug 'https://github.com/hashivim/vim-terraform.git' " Terraform tools, such as `terraform fmt`.

Plug 'https://github.com/nvim-treesitter/nvim-treesitter.git', { 'do': ':TSUpdate' }
Plug 'https://github.com/ctrlpvim/ctrlp.vim.git'
Plug 'https://github.com/editorconfig/editorconfig-vim.git'
Plug 'https://github.com/preservim/nerdtree.git'
Plug 'https://github.com/mbbill/undotree.git'
Plug 'https://github.com/vim-airline/vim-airline.git' " At the time of writing Powerline (Python) does not support neovim.
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'https://github.com/rakr/vim-one.git'
Plug 'https://github.com/mhinz/vim-signify.git'
Plug 'https://github.com/ryanoasis/vim-devicons.git'

" Add plugins to Vim's `runtimepath`.
call plug#end()

"====================================================
" Backups
"
" These options manage settings associated with how backups are handled by Vim.
"====================================================

" Turn off backups for files that are being edited by Vim.
set nobackup " Do not keep a backup of a file after overwriting the file.
set noswapfile " No temporary swap files.

" Store an undo file in our local user's cache folder for the purpose of supporting the `undotree` feature for navigating through a file's edit history.
if has("persistent_undo")
	let target_path = expand($XDG_CACHE_HOME . '/nvim/undotree/')
	call EnsureDirectoryExists(target_path)
	let &undodir=target_path
	set undofile
endif

"====================================================
" Tabs and Indents
"
" These options manage settings associated with tabs and automatically indenting new lines.
"====================================================

" Number of spaces Vim should use to visually represent a TAB character when encountered within a file.
set tabstop=2

" Number of spaces Vim should use when autoindenting a new line of text, or when using the `<<` and `>>` operations (Such as pressing > or < while text is selected to change the indentation of the text). Also used by `cindent` when that option is enabled.
set shiftwidth=2

" Number of spaces Vim should insert when TAB is pressed, and the number of spaces Vim should remove when the <backspace> is pressed. This allows for a single backspace to go back this many white space characters.
set softtabstop=2

" Copy the structure of the existing lines indent when autoindenting a new line.
set copyindent

" Causes spaces to be inserted in place of tabs when the TAB key is pressed. To disable this behavior and enable the insertion of tabs when the Tab key is pressed, comment out this option.
augroup expand
	autocmd!
	autocmd Filetype javascript setlocal expandtab
augroup END

" Enable special display options to show tabs and end-of-line characters within a non-GUI window. Tabs are represented using '>-' and a sequence of '-'s that will fill out to match the proper width of a tab. End-of-line is represented by a dollar sign '$'. Displaying tabs as '>-' and end-of-lines as '$'. Trailing white space is represented by '~'. Must be toggled by a mapping to ':set list!'.
set listchars=tab:>-,eol:$,trail:~,extends:>,precedes:<

"====================================================
" Folding
"
" These options manage settings associated with folding portions of code into condensed forms, leaving only an outline of the code visible. Folding is a form of collapsing of function definitions, class definitions, sections, etc. When a portion of code is collapsed only a header associated with that section is left visible along with a line indicating statistics associated with the collapsed code; such as the number of collapsed lines, etc. The terms 'folded' and 'collapsed' within this file are used interchangeably with one another.
"====================================================

" Use tree-sitter to determine how source code or content should be folded.
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()

"====================================================
" Tree-sitter
"
" Enable and configure the AST-aware tree-sitter for syntax highlighting and folding.
"====================================================

lua <<EOF
require'nvim-treesitter.configs'.setup {
	-- A list of language parsers that should be installed and enabled to provide syntax highlighting.
	ensure_installed = { 'bash', 'cooklang', 'css', 'dockerfile', 'go', 'hcl', 'help', 'html', 'javascript', 'json', 'lua', 'python', 'regex', 'toml', 'vim', 'yaml', 'zig' },

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
EOF

"====================================================
" Language Server configuration.
"
" Setup and configuration for language servers.
"====================================================

" The following key mapping is taken from https://github.com/neovim/nvim-lspconfig#suggested-configuration
lua <<EOF
-- Mappings.
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
EOF

"====================================================
" Vim Explorer
"
" These options configure Vim's built-in file system explorer so that it behaves in a manner that meets user expectations. This includes showing files in a tree view so that entire projects can be seen at once.
"====================================================

" Will cause files selected in the Explorer window to be opened in the most recently used buffer window (Causing the previous buffer to be pushed into the background).
let g:netrw_browse_split = 4

" List files and directories in the Explorer window using the tree listing style.
let g:netrw_liststyle = 3

"====================================================
" Helper Functions
"
" These functions help with various automation tasks and can be mapped to various key combinations or function keys.
"====================================================

" Define a function that will delete trailing white space on save.
function! DeleteTrailingWS()
	exe "normal mz"
	%s/\s\+$//ge
	exe "normal `z"
endfunc

" Create an autocmd that will be executed every time the buffer is written back to file, deleting trailing white space.
augroup deleteTrailingWhiteSpace
	autocmd!

	autocmd BufWrite * :call DeleteTrailingWS()
augroup END

" Return to the last edit position when re-opening a file.
augroup returnLastLine
	autocmd!

	autocmd BufReadPost *
		\ if line("'\"") > 0 && line("'\"") <= line("$") |
		\		exe "normal! g`\"" |
		\ endif
augroup END

" Mark the buffer in the current window for movement to a new window.
function! MarkWindowSwap()
	let g:markedWinNum = winnr()
endfunction

" Mark the current window as the destination of the previously selected buffer and begin the process of swapping buffers between the two windows.
function! DoWindowSwap()
	" Mark destination buffer.
	let curNum = winnr()
	let curBuf = bufnr('%')
	exe g:markedWinNum . "wincmd w"
	" Switch to our source buffer and shuffle destination->source.
	let markedBuf = bufnr("%")
	" Hide and open so that we aren't prompted and insure our history is kept.
	exe 'hide buf' curBuf
	" Switch to our destination buffer and shuffle source->destination.
	exe curNum . "wincmd w"
	" Hide and open so that we aren't prompted and insure our history is kept.
	exe 'hide buf' markedBuf
endfunction

"====================================================
" Multi-Mode Mappings
"
" General options are define such that they are available within all operating modes. Also a collection of mappings usable within two or more modes are defined.
"====================================================

" Set a map leader so that extra key combinations can be used for quick operations.
let mapleader = ","
let g:mapleader = ","

" Use <F11> to toggle between 'paste' and 'nopaste' modes. 'paste' and 'nopaste' modes disable and enable auto-indenting respectively. Useful when pasting text that already posses the correct indenting, and you want to preserve that indention regardless of Vim's enabled auto-indent features.
set pastetoggle=<F11>

" Manage spell check by supporting mappings that turn spell check on and off.
nnoremap <silent> <F7> <ESC>:setlocal spell!<CR>
" Placing the letter 'i' at the end causes Vim to then return to insert mode after toggling the spell checker.
inoremap <silent> <F7> <ESC>:setlocal spell!<CR>i
" Placing the letter 'v' at the end causes Vim to then return to visual mode after toggling the spell checker.
vnoremap <silent> <F7> <ESC>:setlocal spell!<CR>v

" Enable the displaying of whitespace characters, including tab characters.
nnoremap <silent> <F6> <ESC>:set list!<CR>
" Placing the letter 'i' at the end causes Vim to return to insert mode after toggling list mode.
inoremap <silent> <F6> <ESC>:set list!<CR>i
" Placing the letter 'v' at the end causes Vim to return to visual mode after toggling list mode.
vnoremap <silent> <F6> <ESC>:set list!<CR>v

" Toggle all folds either open if one or more are closed.
nnoremap <F9> zR
inoremap <F9> <C-O>zR
vnoremap <F9> zR

"====================================================
" Normal Mode
"
" Useful mappings for normal mode.
"====================================================

" Make it easier to navigate around the `quickfix` window using keyboard shortcuts.
map <C-n> :cnext<CR>
map <C-m> :cprevious<CR>
nnoremap <leader>a :cclose<CR>

" Remove the Window's ^M character when the encoding is messed up.
nnoremap <leader>m mmHmt:%s/<C-V><CR>//ge<CR>'tzt'm

nnoremap <silent> <F2> :UndotreeToggle<CR>

" Support switching between Vim splits using ALT and the arrow keys.
nnoremap <silent> <A-Up> :wincmd k<CR>
nnoremap <silent> <A-Down> :wincmd j<CR>
nnoremap <silent> <A-Left> :wincmd h<CR>
nnoremap <silent> <A-Right> :wincmd l<CR>

" Support the swapping of buffers between two windows. We support two options, using either the <leader> or a function key. <F3> Marks a buffer for movement and <F4> selects the second buffer of the swap pair and then executes the swap.
nnoremap <silent> <leader>mw :call MarkWindowSwap()<CR>
nnoremap <silent> <leader>pw :call DoWindowSwap()<CR>
nnoremap <silent> <F3> :call MarkWindowSwap()<CR>
nnoremap <silent> <F4> :call DoWindowSwap()<CR>

" Resize current window by +/- 3 rows/columns using CTRL and the arrow keys.
nnoremap <silent> <C-Up> :resize +3<CR>
nnoremap <silent> <C-Down> :resize -3<CR>
nnoremap <silent> <C-Right> :vertical resize +3<CR>
nnoremap <silent> <C-Left> :vertical resize -3<CR>

" Pressing CTRL-A selects all text within the current buffer.
nnoremap <C-A> gggH<C-O>G

"====================================================
" Setup ctrlp Plugin
"
" Setup for a tool that allows for fuzzy matching on file names within the current directory, or parent directory containing a repository directory, or against opened buffers, or MRU (Most Recently Used) files.
"====================================================

" Set the default behavior for the CtrlP plugin to search against files only (not against the buffers or MRU).
let g:ctrlp_cmd = 'CtrlP'

" Directory ignore list:
" * .git/.hg/.svn - Source Code Management storage directories.
" * node_modules - Directory to house Node modules.
" * bower_components - Directory to house Bower components.
" * dist/bin/build - Common directories used to house build artifacts.
" * _book - Build artifact cache used by `gitbook`.
" * venv - The prefered Python virtual environment directory.
" * .tox - Cache directory used by `tox`.
" * coverage - Output directory for generated coverage reports.
" * .temp - Cache directory we use for Yeoman unit tests.
let g:ctrlp_custom_ignore = {
	\ 'dir': '\v[\/](\.git|\.hg|\.svn|node_modules|dist|bin|build|_book|venv|\.tox|coverage|\.temp)$',
	\ 'file': '\v\.(pyc|pyo|a|exe|dll|so|o|min.js|zip|7z|gzip|gz|jpg|png|gif|avi|mov|mpeg|doc|odt|ods)$'
	\ }

" Set the option to require CtrlP to scan for dotfiles and dotdirs.
let g:ctrlp_show_hidden = 1

"====================================================
" Setup vim-airline Plugin
"
" Setup for a vim-airline environment so that the environment will look and behave in the desired way.
"====================================================

" Enable vim-airline's buffer status bar. This buffer status bar will appear at the very top of Vim, similiar to where the multibufexpl plugin would appear.
let g:airline#extensions#tabline#enabled = 1

" Automatically populate the `g:airline_symbols` dictionary with the correct font glyphs used as the special symbols for vim-airline's status bar.
let g:airline_powerline_fonts = 1

" Set airline theme to match the Vim editor theme.
let g:airline_theme = 'one'

" Correct a spacing issue that may occur with fonts loaded via the fontconfig approach.
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"

"====================================================
" Setup vim-go Plugin
"
" Setup for a vim-go environment to enable features such as formatting on save.
" More options and recommendations available from - https://github.com/fatih/vim-go/wiki/Tutorial#edit-it
"====================================================

" Automatically add missing imports on file save while also formatting the file like `gofmt` used to do.
let g:go_fmt_command = "goimports"

" Automatically invoke the `:GoMetaLinter` command on file save, which invokes `vet`, `golint`, and `errcheck` concurrently by default.
let g:go_metalinter_autosave = 1

" Automatically show the function signature on the status line when moving your cursor over a valid identifier.
let g:go_auto_type_info = 1

" Switch to AST-aware identifier renamer that is module aware (No GOPATH necessary).
let g:go_rename_command = "gopls"

"====================================================
" Setup vim-terraform Plugin
"
" Setup vim-terraform to enable features such as formatting on save.
"====================================================

" Automatically invoke `terraform fmt` on Terraform files on buffer save.
let g:terraform_fmt_on_save = 1

" Automatically align settings with Tabularize on buffer save.
let g:terraform_align = 1

"====================================================
" Setup vim-signify Plugin
"
" Setup for the Signify plugin that adds the +, -, and ~ characters in the "gutter", a.k.a left sidebar, of Vim to indicate when lines have been added, removed, or modified as compared against a file managed by a VCS.
"====================================================

" Mapping for jumping around in a buffer between next, or previous, change hunks.
nmap <leader>gj <plug>(signify-next-hunk)
nmap <leader>gk <plug>(signify-prev-hunk)

" Use alternative signs for various states of a line under version control.
let g:signify_sign_change = '~'

" Update line status more quickly.
set updatetime=100

"====================================================
" Setup Colorscheme
"
" Setup Vim to recognize our terminal as having a particular background color, and then set our preferred color scheme (a.k.a theme).
"
" Note: This setup step must be last so that the color scheme is setup properly. If configured earlier, some setting in this configuration file will cause Vim to revert to its default color scheme (or worse, you'll get a collision of multiple color schemes.).
"====================================================

" Inform Vim to expect a dark terminal background. This will cause Vim to compensate by altering the color scheme.
set background=dark

" Enable support for italics in the One theme.
let g:one_allow_italics = 1

" Set Vim's color scheme. We purposely silence any failure notification if the desired colorscheme can't be loaded by Vim. If Vim is unable to load the desired colorscheme, it will be quite apparent to the user. By silencing error messages we gain the ability to automate tasks, such as installing plugins for the first time, that would otherwise block if an error message was displayed because the desired colorscheme wasn't available.
silent! colorscheme one

"====================================================
" Spellcheck Highlighting
"
" Setup Vim to use our own highlighting rules for words not recognized by Vim based on the `spelllang` setting. These highlight rules must be set _after_ a theme has been selected using `colorscheme`.

" SpellBad: word not recognized
" SpellCap: word not capitalized
" SpellRare: rare word
" SpellLocal: wrong spelling for selected region, but spelling exists in another region for given language.
"====================================================

" Clear existing highlighting rules used to make a spelling mistake stand out in text. The existing highlight rules must be cleared to correctly apply our custom rules.
highlight clear SpellBad
highlight clear SpellCap
highlight clear SpellRare
highlight clear SpellLocal

" Set our own highlighting rules for Vim's spell checking.
" We use `undercurl` to use squiggles under highlighted words when that option is available (gvim only). Otherwise words are simply underlined.
highlight SpellBad term=undercurl cterm=undercurl ctermfg=Red
highlight SpellCap term=undercurl cterm=undercurl ctermfg=Yellow
highlight SpellRare term=undercurl cterm=undercurl ctermfg=Magenta
highlight SpellLocal term=undercurl cterm=undercurl ctermfg=Blue
