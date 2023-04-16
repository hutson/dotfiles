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
