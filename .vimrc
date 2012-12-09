" Vi互換をオフ
set nocompatible

" バッファファイルを作るディレクトリ
set backupdir=$HOME/.vim/backup
" ファイル保存ダイアログの初期ディレクトリをバックアップファイル位置に設定
set browsedir=buffer
" スワップファイル用のディレクトリ
set directory=$HOME/.vim/backup
" クリップボードを連携
if has('gui_running')
    set guioptions+=a
"    set clipboard+=autoselect
else
    set clipboard+=autoselect
endif
"set guioptions+=a
"set clipboard+=autoselect
"set clipboard+=unnamed

" 新しい行のインデントを現在の行と同じにする
set autoindent
" タブの代わりに空白文字を挿入する
set expandtab
" シフト移動
set shiftwidth=4
" 行頭の余白でTabを打ち込むと'shiftwidth'の数だけインデントする
set smarttab
" ファイルの <Tab> が対応する空白の数
set tabstop=4
" 新しい行を作ったときに高度な自動インデントを行う
set smartindent

" 変更中のファイルでも保存しないで他のファイルを表示
set hidden

" インクリメンタルサーチを行う
set incsearch
" 検索時に大文字を含んでいたら大小を区別
set smartcase
" 検索をファイルの先頭へループする
set wrapscan

" タブ文字や行末など不可視文字を表示する
set list
" listで表示される文字フォーマットを指定する
set listchars=tab:^\ ,trail:~,extends:<
" 行番号を表示する
set number
" 閉じカッコが入力されたときに対応するカッコを表示する
set showmatch

" カーソルを行頭、行末で止まらないようにする
" set whichwrap=b,s,h,l,<,>,[,]

" カラースキーマ
if has('gui_running')
    colorscheme molokai
else
    set t_Co=256
    runtime! plugin/guicolorscheme.vim
"    colorscheme xoria256
"    colorscheme sorcerer
    GuiColorScheme candy
"    GuiColorScheme xoria256
endif

" 入力モード時、ステータスラインのカラーを変更
augroup InsertHook
autocmd!
autocmd InsertEnter * highlight StatusLine guifg=#ccdc90 guibg=#2E4340
autocmd InsertLeave * highlight StatusLine guifg=#2E4340 guibg=#ccdc90
augroup END
" 日本語入力をリセット
" au BufNewFile,BufRead * set iminsert=0
" 全角スペースを視覚化SJISで保存しなければいけないらしい。
" highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=#666666
" au BufNewFile,BufRead * match ZenkakuSpace /???/

" yankring.vim
let g:yankring_history_dir = '$HOME/.vim'

" フォント
set guifont=Ricty\ 11
set guifontwide=Ricty\ 11

" Highlight search
set hls

" todo.vim
au BufRead,BufNewFile *.todo setfiletype todo

" vim -b to open with xxd mode
augroup BinaryXXD
autocmd!
autocmd BufReadPre  *.bin let &binary =1
autocmd BufReadPost * if &binary | silent %!xxd -g 1
autocmd BufReadPost * set ft=xxd | endif
autocmd BufWritePre * if &binary | %!xxd -r | endif
autocmd BufWritePost * if &binary | silent %!xxd -g 1
autocmd BufWritePost * set nomod | endif
augroup END"

" unite

" JavaScript syntax
au FileType javascript call JavaScriptFold()

" カーソル位置の単語とヤンクした文字列を置換する
nnoremap <silent> cy ce<C-r>0<ESC>:let@/=@1<CR>:noh<CR>
vnoremap <silent> cy c<C-r>0<ESC>:let@/=@1<CR>:noh<CR>

" ConqueTerm
nnoremap <silent> ,g :ConqueTermSplit bash <CR>
let g:ConqueTerm_CWInsert = 1

" width
if has("gui_running")
    set lines=50
    set columns=85
endif

" QuickRun
set splitbelow

" SrcExpl, Trinity, taglist
nmap <F8> :TrinityToggleAll

