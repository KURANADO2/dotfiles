" Use space as leader(default is '\')
let mapleader=" "

" Basic Settings
" No need compatible with vi(Most of plugins will need this)
set nocompatible
" Most of plugins will dependency this
set termguicolors
" Encoding
set encoding=utf-8
" Indent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
" Enable system clipboard(You must ensure :echo has('clipboard') return 1 not 0)
set clipboard=unnamed
" Let backspace can delete chars
set backspace=indent,eol,start
" Default one line chars length greater than 78, vim will auto create new line, set tw=0 will close this function
set tw=0
" Keep the number of rows(such as tt tb H M)
set scrolloff=5
" Highlight
syntax on
" Show line number
set nu
" Enable relative number
set relativenumber
" Disable relative number
"set norelativenumber
" Highlight current line
set cursorline
" Highlight current column
" set cursorcolumn
" Auto wrap line(default value)
" set wrap
" Disable auto wrap
set nowrap
" Show command
set showcmd
" Auto complete command with TAB
set wildmenu
" Highlight search result
set hlsearch
" Cancel highlight search result when enter vim
exec "nohlsearch"
" Highlight search result during the search
set incsearch
" Ignore case when search
set ignorecase
" Enable smart case when search
set smartcase
" Enable mouse
set mouse=a
" Automatically change the current directory See: https://vim.fandom.com/wiki/Set_working_directory_to_the_current_file
set autochdir
" Hide last line mode tips if in Insert, Replace or Visual mode, we can use such airline to replace it.
set noshowmode
" Use visual bell replace ssources bellources bell
set visualbell
" The screen will not be redraw while excuting macros, registers and other commands that have not been typed.
set lazyredraw
" Show a verticle line on the 120th chars
set colorcolumn=120
" Enable hidden, See also: https://github.com/romgrk/barbar.nvim/issues/153 https://neovim.io/doc/user/options.html#'hidden'
set hidden
" Sovle The tips of 'E21: Cannot make changes, 'Modifiable' is off'
set modifiable
" Disable spell check
set nospell
" Colorschema
colorscheme sorbet

" Keybinding

" Reload ~/.vimrc file
map <LEADER>rs :source $MYVIMRC<CR>
" Open .vimrc file in anywhere
map <LEADER>rc :e ~/.vimrc<CR>

inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>

" Move quickly
noremap <C-j> 5j
noremap <C-k> 5k

" Go to start of the line
noremap <C-h> ^
" Go to end of the line
noremap <C-l> $

" Split
map sh :set nosplitright<CR>:vsplit<CR>
map sj :set splitbelow<CR>:split<CR>
map sk :set nosplitbelow<CR>:split<CR>
map sl :set splitright<CR>:vsplit<CR>

" Jump between splits
map <LEADER>h <C-w>h
map <LEADER>j <C-w>j
map <LEADER>k <C-w>k
map <LEADER>l <C-w>l
" Loot with splits
map <LEADER>w <C-w>w

" Resize split width or height with arrow keys
map <up> :res +5<CR>
map <down> :res -5<CR>
map <left> :vertical resize-5<CR>
map <right> :vertical resize+5<CR>

" New tab
" map tn :tabe<CR>
" Next left tab
map E :-tabnext<CR>
" Next right tab
map R :+tabnext<CR>
" First tab
map W :tabfirst<CR>
" Last tab
map T :tablast<CR>
" Move current tab to the left
map th :-tabmove<CR>
" Move current tab to the right
map tl :+tabmove<CR>

" Scroll
" Move up/down the view port without moving the cursor
noremap J 5<C-e>
noremap K 5<C-y>
" Move left/right the view port without moving the cursor
noremap H 20zh
noremap L 20zl

" Toggle case
map ` ~

" Indent
noremap > >>
noremap < <<

" redo
noremap U <C-r>

" Copy and paste
" Copy selection area to system clipboard
nnoremap Y v$y
" Paste in visual mode do not copy
vnoremap p "_dP

" Visual
" Select to the line end
noremap v<C-l> v$h
noremap v<C-h> v^
noremap vie ggVG
" Line visual and Block Visual
nnoremap <C-v> V
noremap V <C-v>

" Display the search results in the middle of the screen
noremap * *zz
noremap # #zz
noremap n nzz
noremap N Nzz

" Add semicolon at end-of-line
noremap <LEADER>; A;<ESC>

" Cancel search highlight
map <LEADER><CR> :nohlsearch<CR>

" Find and replace
noremap \s :%s/\v//g<left><left><left>
" Global command
noremap \g :g/\v/<left>
" Delete all blank lines
noremap \d :g/\v^$/d<CR>

" Command mode cursor movement
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>

" Record macro
noremap sm q

" Set s no any action
map s <nop>

" Save
map S :w<CR>
" Quit
map q :wq<CR>
map Q :wq<CR>

" Plugins
call plug#begin()
    " Input mehtod swtich
    Plug 'KURANADO2/smartim'
call plug#end()

" Plugin config
" smartim
let g:smartim_default = 'com.apple.keylayout.ABC'
