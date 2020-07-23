" 语法高亮
syntax on
" 底部显示，当前处于命令模式还是插入模式
set showmode
" 命令模式下，在底部显示，当前键入的指令
set showcmd
" 使用 utf-8 编码
set encoding=utf-8
" 启用256色
set t_Co=256
" 按下 Tab 键时，Vim 显示的空格数
set tabstop=4
" 每一级缩进的字符数
set shiftwidth=4
" Tab转空格
set expandtab
" Tab转多少个空格
set softtabstop=4
" 状态栏显示
set laststatus=2
" 光标遇到圆括号、方括号、大括号时，自动高亮对应的另一个圆括号、方括号和大括号
set showmatch
" 搜索时，高亮显示匹配结果
set hlsearch
" Vim 需要记住多少次历史操作
set history=1000
" 显示文件名：总行数，总的字符数
set statusline=[%F]%y%r%m%*%=[Line:%l/%L,Column:%c][%p%%]
" 不与 vi 完全兼容, 这样能开启更多功能
set nocompatible
" backspace有几种工作方式，默认是vi兼容的，可使用backspace在insert模式下进行编辑
set backspace=2