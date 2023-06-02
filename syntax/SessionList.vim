" --------------------------------------------------------------------------------
"  Vim syntax file
"  Language:    SessionList
"  Last Change: 2022 12 09
" --------------------------------------------------------------------------------
"
" --------------------------------------------------------------------------------

if exists("b:current_syntax")
    finish
endif

" this file uses line continuations
let s:cpo_sav = &cpo
set cpo&vim

syn keyword SessionListHelp gs gl gL gR
syn match SessionListHelpPattern /\vSS (test\.vim)?/
syn match SessionListCurrent /\vsession_current_name \=\zs.+/
syn match SessionListName /\v\[\d\d\]\.\s.+/ contains=SessionListNum
syn match SessionListNum /\v\[\d\d\]\.\s/ contained


hi def link SessionListHelp         Question
hi def link SessionListHelpPattern  Question
hi def link SessionListNum          LineNr
hi def link SessionListName         Statement


" 自分好みの色を設定
highlight SessionListCurrent cterm=bold ctermfg=Green gui=bold guifg=Green

" Postscript {{{1
let b:current_syntax = "SessionList"

let &cpo = s:cpo_sav
unlet! s:cpo_sav

" vim: nowrap sw=2 sts=2 ts=8 noet fdm=marker:

