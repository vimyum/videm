"=============================================================================
" What Is This: Videm (IDE with Vim and Tmux)
" File: autoload/videm/bmark.vim
" Author: Sagara Takahiro <vimyum@gmail.com>
"=============================================================================
if exists("g:loaded_videm_bmark_auto") || &cp
	finish
endif
let g:loaded_videm_bmark_auto = 1

let s:histArray    = []
let s:histDirArray = []
let s:bmkArray     = []

""""""""""""""""Called by videm.vim""""""""""""""""""
func! videm#bmark#open()
	if g:videm#win_list[g:videm#win#BMK] != ""
		call videm#tmux#sendMsg(videm#win_list[g:videm#win#BMK], ":quit!")
		let videm#win_list[g:videm#win#BMK] = ""
		return
	endif
	try
		call videm#bmark#save()
		call videm#tmux#splitWin($VIDEM_MAIN, g:VidemBmarkWinHeight,
					\"export VIDEM_NAVI=". $TMUX_PANE .
					\" && export VIDEM_MAIN=". $VIDEM_MAIN .
					\" && vim -c \"call videm#bmark#start()\"")
	catch
		echo "failed to open bmarks."
		sleep 1
		return
	endtry
endf

func! videm#bmark#add(isPst)
	if a:isPst != 1
		let ent = b:curPos . expand("<cfile>")
	else
		let ent = expand("<cfile>")
	endif
	let entIdx = index(s:bmkArray, ent)
	if entIdx >= 0
		call remove(s:bmkArray, entIdx)
	endif
	call add(s:bmkArray, ent)
	if len(s:bmkArray) > g:VidemBmarkNum
		call remove(s:bmkArray, 0)
	endif
	echo "New BookMark is added."
endf

func! videm#bmark#addHist(ent)
	let entIdx = index(s:histArray, a:ent)
	if entIdx >= 0
		call remove(s:histArray, entIdx)
	endif
	call add(s:histArray, a:ent)
	while len(s:histArray) > g:VidemHistNum
		call remove(s:histArray, 0)
	endwhile
endf

func! videm#bmark#addHistDir(ent)
	let entIdx = index(s:histDirArray, a:ent)
	if entIdx >= 0
		call remove(s:histDirArray, entIdx)
	endif
	call add(s:histDirArray, a:ent)
	while len(s:histDirArray) > g:VidemHistDirNum
		call remove(s:histDirArray, 0)
	endwhile
endf

func! videm#bmark#load()
	if getftype(g:VidemBmarks . ".1") == "file" 
		let s:histArray    = readfile(g:VidemBmarks . ".1")
	endif
	if getftype(g:VidemBmarks . ".2") == "file" 
		let s:histDirArray = readfile(g:VidemBmarks . ".2")
	endif
	if getftype(g:VidemBmarks . ".3") == "file" 
		let s:bmkArray     = readfile(g:VidemBmarks . ".3")
	endif
endf

func! videm#bmark#save()
	call writefile(s:histArray,    g:VidemBmarks . ".1")
	call writefile(s:histDirArray, g:VidemBmarks . ".2")
	call writefile(s:bmkArray,     g:VidemBmarks . ".3")
endf

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
func! videm#bmark#start()
	call videm#tmux#sendMsg($VIDEM_NAVI, ":cal videm#main#setWinNum('bmark', '". $TMUX_PANE ."')")
	call s:Init()
	call videm#bmark#load()
	setlocal modifiable
	call s:ShowBmark()
	call s:ShowHist()
	exec "normal! G"
	exec "delete"
	call cursor(1,1)
	setlocal nomodifiable
endf

func! s:Init()
	nnoremap <silent><buffer> <CR>		:call videm#bmark#select(0)<CR>:<BS>
	nnoremap <silent><buffer> <NL>		:call videm#bmark#select(1)<CR>:<BS>
	nnoremap <silent><buffer> dd		:call videm#bmark#delete()<CR>:<BS>
	nnoremap <silent><buffer> p		:call videm#bmark#paste(0)<CR>:<BS>
	nnoremap <silent><buffer> P		:call videm#bmark#paste(1)<CR>:<BS>
	nnoremap <silent><buffer> b		:quit!<CR>:<BS>
	nnoremap <silent><buffer> q		:quit!<CR>:<BS>
	nnoremap <silent><buffer> tt		:call videm#bmark#test()<CR>:<BS>
	setlocal nobuflisted
	setlocal bufhidden
	setlocal foldmethod=manual
	hi MyFileColor  ctermfg=15  guibg=#FFB3FF guifg=Black
	hi MyHomeColor  ctermfg=33  guibg=#FFB3FF guifg=Black
	hi Conceal		ctermfg=246		ctermbg=234		cterm=none	
	hi Folded		ctermfg=123		ctermbg=234		cterm=none
	hi Title		ctermfg=234		ctermbg=14		cterm=none
	setlocal conceallevel=2
	setlocal concealcursor=nvic
	set nowrap 
	syntax match Comment    /.*/ contains=MyFileColor
	syntax match MyFileColor /[^/]*$/ 
	syntax match MyFileColor /[^/]*\/$/
	syntax match Title /.*<<<.*>>>.*/
	execute "syntax match Todo \"" . $HOME . "\" display conceal cchar=~"

	autocmd VimLeave *	:call <SID>CloseWin()<CR>:<BS>
endf

func! s:ShowHist()
	let s:histEndLn = line(".")
	let msg = videm#string#padding("    <<< History List >>>", winwidth(0) -1, " ")
	exec "normal! Go". msg ."\n"
	for ent in reverse(copy(s:histDirArray))
		execute "normal! i" . ent . "\n"
	endfor
	for ent in reverse(copy(s:histArray))
		execute "normal! i" . ent . "\n"
	endfor
endf

func! s:ShowBmark()
	let msg = videm#string#padding("    <<< Bookmark List >>>", winwidth(0) -1, " ")
	execute "normal! i". msg ."\n"
	for ent in s:bmkArray
		execute "normal! i" . ent . "\n"
	endfor
	execute "delete"
	call cursor(1, 1)
	execute "normal! zfG"
	execute "normal! o "
endf

func! videm#bmark#select(flg)
	let l:pane = $TMUX_PANE 
	let l:ent = getline(".")
	let l:ftype = getftype(l:ent)
	if l:ftype != "file" && l:ftype != "dir"
		return
	endif
	if a:flg == 0
		if l:ftype == "dir"
			call videm#tmux#sendMsg($VIDEM_NAVI, ":call HiExSelect(0,'". l:ent ."',0)")
		else
			call videm#tmux#sendMsg($VIDEM_MAIN, videm#tmux#openFile("-") . l:ent)
		endif
		call videm#bmark#save()
		exec "quit!"
	elseif a:flg == 1
		call s:openNewWin()
	endif
endf

func! s:CloseWin()
	call videm#bmark#save()
	call videm#tmux#sendMsg($VIDEM_NAVI, ":call videm#main#setWinNum('bmark','')")
	call videm#tmux#sendMsg($VIDEM_NAVI, ":call HiExReloadFiles()")
endf

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" called by key mapping
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
func! videm#bmark#delete()
	let ent = getline(".")
	if line(".") >= s:histEndLn
		return
	endif
	setlocal modifiable
	exec "delete"
	setlocal nomodifiable
	let entIdx = index(s:bmkArray, ent)
	if entIdx >= 0
		call remove(s:bmkArray, entIdx)
	endif
endf

func! videm#bmark#paste(flg)
	let ent = getline(".")
	if line(".") >= s:histEndLn
		return
	endif
	setlocal modifiable
	if a:flg == 0
		execute "normal! p"
	else
		exec "normal! P"
	endif
	call videm#bmark#add(1)
	setlocal nomodifiable
endf

func! videm#bmark#test()
	echo "Don't look me!"
endf

function! s:openNewWin() 
	let ent = expand("<cfile>")
	let l:ftype = getftype(ent)
    call system("tmux new-window")
    if l:ftype == "file"
		let dir = fnamemodify(ent, ":h:p")
        call videm#tmux#sendMsg("-", "cd " . dir . " && vim " . ent)
        call videm#bmark#addHist(simplify(ent))
        call videm#bmark#addHistDir(simplify(dir . "/"))
    else
		call videm#tmux#sendMsg("-", "cd " . ent)
		call videm#tmux#sendMsg("-", "export VIDEM_MAIN=" . $VIDEM_MAIN)
		call videm#tmux#sendClr("-")
		call videm#bmark#addHistDir(simplify(ent))
    endif
endfunction
