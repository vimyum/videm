"=============================================================================
" What Is This: VIDEm (IDE with Vim and Tmux)
" File: videm.vim
" Author: Sagara Takahiro <vimyum@gmail.com>
"=============================================================================
if exists("g:loaded_videm_tmux_auto") || &cp
	finish
endif
let g:loaded_videm_tmux_auto = 1

function! videm#tmux#getbuf()
	let l:tmp = system("tmux getb | cat")
	return videm#string#stripLF(l:tmp)
endfunction

function! videm#tmux#sendMsg(target, msg) "(Retrun) Success: 1, Error: < 0
	if a:target == "-"
		let result = system("tmux send \"". a:msg ."\" 2>&1 | cat")
	else
		let result = system("tmux send -t ". a:target ." \"". a:msg ."\" 2>&1 | cat")
	endif
	return (1 - len(result))
endfunction

function! videm#tmux#sendMsgNR(target, msg)
	if a:target == "-"
		let result = system("tmux send \"". a:msg ."\" 2>&1 | cat")
	else
		let result = system("tmux send -t ". a:target ." \"". a:msg ."\" 2>&1 | cat")
	endif
	return (1 - len(result))
endfunction

function! videm#tmux#selectPane(target)
	let result = system("tmux select-pane -t ". a:target ." 2>&1 | cat")
	return (1 - len(result))
endfunction

function! videm#tmux#newWin()
	let result = system("tmux new-window 2>&1 | cat")
	return (1 - len(result))
endfunction

function! videm#tmux#renameWin(target, name)
	if a:target == "-"
		let result = system("tmux rename-window '". a:name ."' 2>&1 | cat")
	else
		let result = system("tmux rename-window ". a:target ." '". a:name ."' 2>&1 | cat")
	endif
	return (1 - len(result))
endfunction

function! videm#tmux#resizePane(target, flg, size)
	if a:target == "-"
		let result = system("tmux resize-pane -". a:flg ." ". a:size ." 2>&1 | cat")
	else
		let result = system("tmux resize-pane -t ".a:target ." -". a:flg ." ". a:size ." 2>&1 | cat")
	endif
	return (1 - len(result))
endfunction

function! videm#tmux#sendClr(target)
	if a:target == "-"
		let result = system("tmux send \"\" 2>&1 | cat")
	else
		let result = system("tmux send -t ". a:target ." \"\" 2>&1 | cat")
	endif
	return (1 - len(result))
endfunction

function! videm#tmux#sendCtrlC(target)
	if a:target == "-"
		let result = system("tmux send C-c 2>&1 | cat")
	else
		let result = system("tmux send -t ". a:target ." C-c 2>&1 | cat")
	endif
	return (1 - len(result))
endfunction

function! videm#tmux#splitWin(target, size, cmd)
	if a:target == "-"
		let result = system("tmux split-window -p ". a:size ." '". a:cmd ."' 2>&1 | cat")
	else
		let result = system("tmux split-window -t ". a:target ." -p ". a:size ." '". a:cmd ."' 2>&1 | cat")
	endif
	return (1 - len(result))
endfunction

function! videm#tmux#checkVim()
	let name = system("tmux list-windows | grep active | cut -d' ' -f2 | head -1")
	let name = videm#string#stripLF(name)
	if  name == g:HiExWindowName
		return 1
	endif 
	return 0
endfunction

function! videm#tmux#openFile(tab)
	if videm#tmux#checkVim() == 1
		if a:tab == "tab"
			return ":tabe "
		else
			return ":e "
		endif
	else
		return "vim "
endfunction

function! videm#tmux#moveDir()
	if videm#tmux#checkVim()== 1
		return ":cd "
	else
		return "cd "
endfunction

func! videm#tmux#vimWaitOpen()
	if videm#tmux#checkVim() == 0
		cal videm#tmux#sendMsg($VIDEM_MAIN, "vim")
		while videm#tmux#checkVim() == 0
			"busy loop
		endwhile
	en
endf

func! videm#tmux#setb(msg)
	cal system("tmux setb '". a:msg ."'")
endf

func! videm#tmux#getActivePaneName()
	let plist  = split(system('tmux list-windows'), '\s')
	for i in plist
		let ilist = split(i, '\s')
		if len(ilist) > 5 && ilist[5] =~ 'active'
			return ilist[1]
		endif
	endfor
	return ""
endf
