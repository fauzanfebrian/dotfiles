" =====================================================================
" ~/.vimrc — Minimal, fast, non-IDE Vim (Linux Mint + Ghostty/Cobalt2)
" Goals:
"   - Quick editing, no IDE bloat
"   - Stable absolute numbers (with a neat number separator: `12|`)
"   - Clean gutter: signs only when needed, no glowing cursorline
"   - Sensible defaults, tiny plugin set (gitgutter, fzf, nerdtree, etc.)
" =====================================================================

" 0) Plugin manager bootstrap (vim-plug)
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  " Install on first open, then quit
  autocmd VimEnter * PlugInstall --sync | q
endif

" 1) Plugins (small, useful, no IDE creep)
call plug#begin('~/.vim/plugged')
  Plug 'tpope/vim-sensible'              " sane defaults
  Plug 'tpope/vim-surround'              " cs"' etc.
  Plug 'tpope/vim-commentary'            " gcc toggles comments
  Plug 'cohama/lexima.vim'               " autopairs
  Plug 'itchyny/lightline.vim'           " clean statusline
  Plug 'airblade/vim-gitgutter'          " tiny git signs in gutter
  Plug 'preservim/nerdtree'              " file tree (on demand)
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'                " :Files, :Rg, etc.
  Plug 'editorconfig/editorconfig-vim'   " obey .editorconfig if present
call plug#end()

" =====================================================================
" 2) Display & basics
" =====================================================================
set nocompatible
filetype plugin indent on
syntax on

" Let terminal (Ghostty+Cobalt2) own the palette; pass truecolor
if has('termguicolors') | set termguicolors | endif
set background=dark

" Numbers: stable absolute; no active-line glow
set number
set norelativenumber
set nocursorline
set ruler
set cmdheight=1
set scrolloff=4
set splitbelow
set splitright

" Keep redraw calm during macros
set lazyredraw

" Encoding/files
set encoding=utf8
set ffs=unix,dos,mac

" Make the left gutter slim unless signs are present
" GitGutter will pop the sign column only when needed
set signcolumn=auto
let g:gitgutter_signs = 1
let g:gitgutter_sign_column_always = 0
let g:gitgutter_sign_added    = '▎'
let g:gitgutter_sign_modified = '▎'
let g:gitgutter_sign_removed  = '▁'
let g:gitgutter_async = 1

" Number column width and visual separator (Vim 9.1+ supports 'statuscolumn')
set numberwidth=4
if exists('+statuscolumn')
  " Left gutter = [line number padded to 4][bar]
  " Example: "  12| " then the text
  set statuscolumn=%=%{printf('%-4d',v:lnum)}\| 
endif

" =====================================================================
" 3) Search and navigation (smart, quiet)
" =====================================================================
set ignorecase
set smartcase
set hlsearch
set incsearch
set showmatch
set mat=2

" Wildmenu + ignore junk
set wildmenu
set wildignore=*.o,*~,*.pyc,*.so,*.swp,*.zip
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store,node_modules/*,dist/*,build/*

" Clear search highlight quickly
nnoremap <leader>/ :nohlsearch<CR>

" Window navigation with Ctrl-hjkl
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" =====================================================================
" 4) Indent and whitespace
" =====================================================================
set expandtab
set smarttab
set shiftwidth=2
set tabstop=2
set smartindent
set shiftround
set wrap
set linebreak

" Trim trailing spaces on save (safe list)
function! CleanExtraSpaces() abort
  let save_cursor = getpos(".")
  let old_query = getreg('/')
  silent! %s/\s\+$//e
  call setpos('.', save_cursor)
  call setreg('/', old_query)
endfunction
augroup TrimSpace
  autocmd!
  autocmd BufWritePre *.txt,*.js,*.ts,*.tsx,*.py,*.wiki,*.sh,*.go,*.json,*.yml,*.yaml,*.css,*.scss,*.lua,*.vim :call CleanExtraSpaces()
augroup END

" =====================================================================
" 5) Files, backups, undo, autoread
" =====================================================================
set nobackup
set nowritebackup
set noswapfile
set undofile
set undodir=~/.vim/undodir

" Auto-reload files changed on disk
set autoread
autocmd FocusGained,BufEnter * silent! checktime

" Return to last edit position on open
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif

" =====================================================================
" 6) Leader, saves, sidebar, fzf
" =====================================================================
let mapleader = " "                 " space as leader

" Save/quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" NERDTree on demand
nnoremap <leader>e :NERDTreeToggle<CR>

" fzf shortcuts
nnoremap <leader>f :Files<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>h :History<CR>

" If launching Vim with a directory, open tree then return to file window
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') |
  \ execute 'NERDTree' argv()[0] | wincmd p | endif

" ripgrep integration for :Rg (fast content search)
if executable('rg')
  let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --glob "!.git/*"'
  command! -nargs=* Rg call fzf#vim#grep(
        \ 'rg --column --line-number --no-heading --color=always --smart-case --hidden --glob "!.git/*" '.shellescape(<q-args>), 1,
        \ fzf#vim#with_preview(), <bang>0)
endif

" =====================================================================
" 7) Statusline (lightline)
" =====================================================================
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left':  [ [ 'mode', 'paste' ],
      \              [ 'readonly', 'filename', 'modified' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'filetype' ] ]
      \ }
      \ }

" =====================================================================
" 8) Buffers, tabs, quick helpers (minimal)
" =====================================================================
" Close current buffer without wrecking the window layout
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt() abort
  let l:cur = bufnr('%')
  let l:alt = bufnr('#')
  if buflisted(l:alt)
    buffer #
  else
    bnext
  endif
  if bufnr('%') == l:cur | enew | endif
  if buflisted(l:cur) | execute 'bdelete! '.l:cur | endif
endfunction
nnoremap <leader>bd :Bclose<CR>
nnoremap <leader>ba :bufdo bd<CR>
nnoremap <leader>l :bnext<CR>
nnoremap <leader>h :bprevious<CR>

" Tab helpers
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>to :tabonly<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>tm :tabmove<Space>
let g:lasttab = 1
nnoremap <leader>tl :exe 'tabn '.g:lasttab<CR>
autocmd TabLeave * let g:lasttab = tabpagenr()

" Switch CWD to the open buffer’s directory
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" Remap 0 to first non-blank (quality of life)
nnoremap 0 ^

" Spell check toggle and helpers
nnoremap <leader>ss :setlocal spell!<CR>
nnoremap <leader>sn ]s
nnoremap <leader>sp [s
nnoremap <leader>sa zg
nnoremap <leader>s? z=

" Quick scratch buffers
nnoremap <leader>q :e ~/buffer<CR>
nnoremap <leader>x :e ~/buffer.md<CR>

" Toggle paste mode
nnoremap <leader>pp :setlocal paste!<CR>

" Sudo write: :W to save with privileges
command! W execute 'w !sudo tee % >/dev/null' | edit!

