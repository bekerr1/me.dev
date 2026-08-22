" Minimal editor for git commit messages, rebase todos and merge resolution.
" Loaded with `nvim -u this-file`, which skips init.lua, lazy.nvim and every
" plugin. Startup is instant and nothing here can break because a plugin update
" broke -- which matters when it is standing between you and a commit.

set nocompatible
filetype plugin indent on
syntax on

" Commit message conventions: 50-char subject, 72-char body.
set textwidth=72
set colorcolumn=51,73
set nowrap

set number
set ruler
set showcmd
set laststatus=2
set statusline=%f\ %m%=%l:%c\ \ %P

set spell spelllang=en_us
set spellcapcheck=

" No state on disk. These are transient buffers.
set noswapfile
set nobackup
set nowritebackup
set noundofile

set backspace=indent,eol,start
set incsearch
set ignorecase
set smartcase

" Same muscle memory as the main config, and nothing else.
nnoremap J 15jzz
nnoremap K 15kzz
nnoremap ss :w<CR>
nnoremap QQ :q<CR>

" Start on the first line, in insert mode, for a fresh commit message.
autocmd FileType gitcommit
  \ if getline(1) ==# '' | execute 1 | startinsert | endif

" A readable, low-contrast look without loading a colorscheme plugin.
set background=dark
highlight ColorColumn ctermbg=236 guibg=#282727
highlight LineNr      ctermfg=242 guifg=#7a8382
highlight Comment     ctermfg=244 guifg=#a6a69c
