set laststatus=2
set noshowmode

" Not sure the meaningful difference between 'enable' and 'on'
syntax enable
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
set autoindent "Auto indent
set si "Smart indent
set wrap "Wrap lines
set number
highlight LineNr ctermfg=darkgrey

" Install vim-plug if it doesn't already exist
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Install plugins
so ~/.vim/plugins.vim
let g:tex_flavor='latex'
let g:vimtex_view_method = 'skim'
set conceallevel=1
let g:tex_conceal='abdmg'
