" Wade Fletcher's .vimrc

" Line numbers
set number
highlight LineNr ctermfg=darkgrey


" Indentation
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
set autoindent "Auto indent
set si "Smart indent
set breakindent 

" Syntax highlighting
syntax enable


" Line wrapping
set wrap


" Spell checking
setlocal spell
set spelllang=en_us
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u


" Statusline
set laststatus=2
set noshowmode


" Install vim-plug if it doesn't already exist
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


" More powerful backspace
set backspace=indent,eol,start


" Remove swapfiles
set noswapfile


" Custom commands
command Snips tabnew ~/.dotfiles/vim/.vim/UltiSnips/tex.snippets


" Install plugins
call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'mattn/emmet-vim'
Plug 'scrooloose/nerdtree'
Plug 'w0rp/ale'
Plug 'arcticicestudio/nord-vim'
Plug 'itchyny/lightline.vim'
Plug 'lervag/vimtex'
Plug 'sirver/ultisnips'

call plug#end()


" UltiSnips config
let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'

" vimtex config
let g:tex_flavor='latex'
let g:vimtex_view_method = 'skim'
let g:vimtex_quickfix_mode=0

" nord-vim config
colorscheme nord
let g:nord_cursor_line_number_background = 1
let g:nord_uniform_status_lines = 1
let g:nord_bold_vertical_split_line = 1
let g:nord_uniform_diff_background = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1
let g:nord_underline = 1
hi Comment ctermfg=5

" lightline config
let g:lightline = {
    \ 'colorscheme': 'nord',
    \ 'separator': { 'left': '', 'right': '' },
    \ 'subseparator': { 'left': '', 'right': '' },
\ }
