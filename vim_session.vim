let s:save_cpo = &cpo
set cpo&vim

" scriptencoding utf-8

if exists('g:loaded_vsession')
    finish
endif

let g:loaded_vsession = 1
let g:vsession_current_name = ""
let g:vsessionlist_bufnr = 0

" A function that shows or hide the session list
function! s:SessionToggle() abort
    " !の意味は同名の関数がある場合上書きする
    " abortは関数内でエラーが発生した場合、そこで処理を終了

    call s:initialSessionList()

    " すでにセッションリストが存在した場合は、閉じる
    if s:hasSessionList()
        " echo "already exists"
        execute "bd!"
        " 最初からSessionListにある場合は、元のwindowsには戻らない
        call win_gotoid(s:current_win_id)
        return 0
    endif

    " セッション一覧を表示する
    call s:SessionList()

endfunction

" セッション一覧を表示する
function! s:SessionList() abort

    let s:sessions = readdir(g:vsession_path)
    " session bufferlistに表示するためのデータを作成
    let s:sessionList = []
    let l:cnt = 0
    let l:cnttr = ''

    for item in s:sessions
        " echo item
        let l:cnt += 1

        if l:cnt < 10
            let l:cntStr = '0' . l:cnt
        else
            let l:cntStr = l:cnt
        endif

        let l:listSession = '[' . l:cntStr . ']. ' . item
        call add(s:sessionList, l:listSession)
    endfor

    " セッション一覧表示用バッファを作成
    execute "new|resize 20"
    set ma
    set filetype=SessionList

    " セッション一覧を表示
    call setline(1, '--------------------------------------------------------------------------------')
    call setline(2, '   SESSIONLIST PATH = ' . g:vsession_path)
    call setline(3, '   Use gs -> list session; gl -> load session; gL -> reloadSession; gR -> delete session' )
    call setline(4, '   :SS test.vim -> save session in test.vim :SS -> current session or default.vim' )
    call setline(5, '   ** vsession_current_name = ' . g:vsession_current_name)
    call setline(6, '--------------------------------------------------------------------------------')
    call setline(7, '' )

    call setline(8, s:sessionList)
    " カーソルをセッション一覧に移動する
    execute "normal }"
    execute "normal j"

    " SessionListバッファ番号を退避
    let g:sessionlist_bufnr = bufnr("%")
    " echo s:sessionList

    " セッションリスト表示用バッファを編集禁止にすべき
    set noma
endfunction

" セッションをロードする
function! s:SessionLoad(sessionName) abort

    " echo "filetype is " . &filetype
    if &filetype == "SessionList"
        let l:sessionName = getline(a:sessionName)
        let l:sessionName = matchstr(l:sessionName, '^\[\d\d\]\.\s\zs.\+$')
        " echo "l:sessionName is " . l:sessionName
        " echo matchstr(l:sessionName, '^\[\d\d\]\.\s\zs.\+$')

        call s:_SessionLoad(l:sessionName)

    else
        echo "Not SessionList Windows!"
    endif

    return 0
endfunction

" セッションをロードする
function! s:_SessionLoad(sessionName) abort

    if strlen(a:sessionName) > 0
        let s:sessionFullpath = g:vsession_path . "/" . a:sessionName
        " ロードしたセッション名を保持
        let g:vsession_current_name = a:sessionName

        " セッションをロードするか確認
        echo "Are you sure to load " . a:sessionName . " session?(Y/n)"
        " ユーザーの入力を検証する
        let l:answer = nr2char(getchar())

        " ==# equal match case
        if l:answer ==# 'Y'
            " echo "Selected Session name is : " . s:sessionFullpath

            for l:bufCheck in getbufinfo()
                " 保存してないバッファがあればセッションはロードしない
                if l:bufCheck.changed && l:bufCheck.name != ""
                    echo "Warning: Could not load Session. because You have Changed buferNr " . l:bufCheck.bufnr
                    return 0
                endif
            endfor

            " SessionList以外の現在開いているバッファを全部閉じる
            " bd!で実行するが、前の変更チェック処理でファイルからオープンしたバッファはこの時点では保存されたはず
            for l:bufDel in getbufinfo()
                " echo "s:current_all_buffer is " . l:bufDel.name . " bufnr is" . bufDel.bufnr
                if l:bufDel.bufnr != g:vsessionlist_bufnr && l:bufDel.listed
                    execute "bd! " . l:bufDel.bufnr
                endif
            endfor

            " セッションをロードする
            execute "source " . s:sessionFullpath

            if g:vsessionlist_bufnr != 0
                " SessionListバッファが存在する場合のみ削除
                if getbufinfo(g:vsessionlist_bufnr)[0].listed
                    " セッションリストwindowを閉じる
                    execute "bd! " . g:vsessionlist_bufnr
                endif
            endif

        elseif l:answer ==? 'n'
            echo ''
        else
            echo 'Please enter "Y" or "n"'
        endif

    else
        echo "SessionName is empty!"
    endif

    return 0
endfunction

" 新しいセッションを作成して、保存する。セッション名の指定がない場合はdefault.vimになる
function! s:SessionSave(...) abort

    call s:initialSessionList()

    let l:savedSessionName = "default.vim"

    " セッション名が指定された場合
    if a:0 > 0
        let l:savedSessionName = a:1
    " 既存のセッションをロードした時は保存時も同じセッションで保存する
    elseif g:vsession_current_name != ""
        let l:savedSessionName = g:vsession_current_name
    endif

    " セッションを保存
    execute "mksession! " . g:vsession_path . "/" . l:savedSessionName
    echo "Save successfully in session " . l:savedSessionName
    let g:vsession_current_name = l:savedSessionName

endfunction

" セッションを削除する
function! s:SessionDelete(sessionName) abort

    " echo "filetype is " . &filetype
    if &filetype == "SessionList"
        let l:sessionName = getline(a:sessionName)
        let l:sessionName = matchstr(l:l:sessionName, '^\[\d\d\]\.\s\zs.\+$')
        " echo "l:sessionName is " . l:sessionName
        " echo matchstr(l:sessionName, '^\[\d\d\]\.\s\zs.\+$')

        if strlen(l:sessionName) > 0
            let s:sessionFullpath = g:vsession_path . "/" . l:sessionName

            " セッションをロードするか確認
            echo "Are you sure to delete " . l:sessionName . " session?(Y/n)"
            " ユーザーの入力を検証する
            let l:answer = nr2char(getchar())

            " ==# equal match case
            if l:answer ==# 'Y'
                " echo "Selected Session name is : " . s:sessionFullpath
                " セッションを削除する
                " execute "!rm -rf " . s:sessionFullpath
                call delete(s:sessionFullpath)
                execute "bd!"
                call s:SessionList()

            elseif l:l:answer ==? 'n'
                echo ''
            else
                echo 'Please enter "Y" or "n"'
            endif

        else
            echo "SessionName is empty!"
        endif

    else
        echo "Not SessionList Windows!"
    endif

    return 0

endfunction

" 初期化処理
function! s:initialSessionList() abort

    " 現在のタブ及びWindowsを退避する
    let s:current_win_id = win_getid()
    let s:curent_tabnr = tabpagenr()

    " セッションディレクトリ確認
    if exists('g:vsession_path')
        let g:vsession_path = expand(g:vsession_path)
    else
        let g:vsession_path = expand('~/.vim/sessions')
    endif

    if !isdirectory(g:vsession_path)
        call mkdir(g:vsession_path, "p")
    endif

endfunction

" 現在のタブにセッションリストがあるかを判断する
function! s:hasSessionList() abort

    " 全windowを対象に処理を実施
    for item in getwininfo()

        let l:tabnr = l:item.tabnr

        " 現在のタブでのみ処理を実施
        if l:tabnr == s:curent_tabnr

            " echo "winid is " . l:item.winid . " bufname is " . bufname(l:item.bufnr)
            call win_gotoid(item.winid)

            let l:filetype = &filetype
            " echo "filetype is " . l:filetype

            " windowがnetrwのwindowかを判断
            if l:filetype == "SessionList"
                return 1
            endif

        endif

    endfor

    return 0

endfunction

" 現在のセッションをリロードする
function! s:SessionReLoad()
    let l:vsession_reload_name = g:vsession_current_name

    " 現在のセッションがある場合
    if l:vsession_reload_name != ''
        call s:_SessionLoad(l:vsession_reload_name)
    else
        echo "Warning: can't reload. because current session does not exist."
    endif
endfunction

" コマンドから関数呼び出し
command! SessionToggleCmd call s:SessionToggle()
command! -range SessionLoadCmd call s:SessionLoad(<line1>)
command! SessionReLoadCmd call s:SessionReLoad()
command! -nargs=? SS call s:SessionSave(<f-args>)
command! -range SessionDeleteCmd call s:SessionDelete(<line1>)

" コマンドのショットカットキー定義
nnoremap gs :SessionToggleCmd<CR>
nnoremap gl :SessionLoadCmd<CR>
nnoremap gL :SessionReLoadCmd<CR>
nnoremap gR :SessionDeleteCmd<CR>

let cpo = s:save_cpo
unlet s:save_cpo
