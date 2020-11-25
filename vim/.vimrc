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


" Install vim-plug if it doesn't already exist
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


" More powerful backspace
set backspace=indent,eol,start



" Install plugins
call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'mattn/emmet-vim'
Plug 'scrooloose/nerdtree'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-surround'
Plug 'w0rp/ale'

Plug 'lervag/vimtex'
    let g:tex_flavor='latex'
    let g:vimtex_view_method = 'skim'
    let g:vimtex_quickfix_mode=0

Plug 'sirver/ultisnips'
    let g:UltiSnipsExpandTrigger = '<tab>'
    let g:UltiSnipsJumpForwardTrigger = '<tab>'
    let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'

Plug 'KeitaNakamura/tex-conceal.vim'
    set conceallevel=1
    let g:tex_conceal='abdmg'
    hi Conceal ctermbg=none

call plug#end()
