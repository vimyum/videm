let s:mark_array = {}

function! s:HiExMakWin()
	if s:winlist[s:winName('mark')] != ""
		call videm#tmux#sendMsg(s:winlist[s:winName('mark')], ":qa!")
		let s:winlist[s:winName('mark')] = ""
		return
	endif
	try
		call videm#tmux#splitWin(s:HiExMainPane, g:HiExMakWinHeight, "export VIDEM_NAVI=". s:hiExPane . 
					\" && export VIDEM_MAIN=". s:HiExMainPane .
					\" && vim -c \"call HiExMakWinStart()\"")
		call videm#tmux#selectPane($VIDEM_NAVI)
	catch
		return
	endtry
endfunction

let g:HiExMakCmd=":marks ABCDEFGHIJKLMNOPQRSTUVWXYZ"
let g:HiExMakEnd="ENTER"
let g:HiExMakInvalid="-invalid-"

function! HiExMakWinStart()
	nno <silent>	q		:qa!<CR>
	nno <silent>	<CR>	:cal <SID>HiExMakSelect()<CR>
	nno <silent>	tt		:cal <SID>HiExMakWinSave()<CR>
	autocmd VimLeave *		:cal HiExMakCloseWin()<CR>:<BS>
	syntax match Comment /^\s\S\s/

	call s:HiExMakWinLoad()

	call videm#tmux#sendMsg($VIDEM_NAVI, ":cal videm#main#setWinNum('mark', '". $TMUX_PANE ."')")
	call s:HiExWaitVimOpen()

	call videm#tmux#sendMsg($VIDEM_MAIN, g:HiExMakCmd)
	call system("tmux capture-pane -t ". $VIDEM_MAIN ." 2>&1 | cat")
	call videm#tmux#sendMsg($VIDEM_MAIN, "q")
	let tmpf = tempname()
	call system("tmux save-buffer ". tmpf ." 2>&1 | cat")
	let mfile = readfile(tmpf)
	call delete(tmpf)
	let noise = 2
	for i in mfile
		if match(i, g:HiExMakCmd) == 0 || noise == 1
			let noise -= 1
			continue
		endif
		if match(i, g:HiExMakEnd) >= 0 
			break
		endif
		if noise != 0
			continue
		endif
		if match(i, g:HiExMakInvalid) >= 0 
			continue
		endif
		"exe "norm i".i."\n"
		let mark=substitute(i, '\s\(\S\)\s\+.*', '\1', "")
		if has_key(s:mark_array, mark) == 0
			exe "norm i".i."\n"
		else
			exe "norm i ". mark ."\t\t". s:mark_array[mark] ."\n"
		endif
	endfor
	call cursor(1,2)
endfunction

function! HiExMakCloseWin()
	call s:HiExMakWinSave()
	call videm#tmux#sendMsg($VIDEM_NAVI, ":call HiExSetSubP('mark','')")
endfunction

function! s:HiExMakSelect()
	let mark=substitute(getline("."), '\s\(\S\)\s\+.*', '\1', "")
	call s:HiExWaitVimOpen()
	call videm#tmux#sendMsg($VIDEM_MAIN, "'". mark)
endfunction

function! s:HiExMakWinLoad()
	let s:mark_array = {}
	try
		for line in readfile(g:HiExMakFile)
			let ent = split(line, '%%')
			let s:mark_array[ent[0]] = ent[1]
		endfor
	catch
		return
	endtry
endfunction

function! s:HiExMakWinSave()
	exec "normal gg"
	let start = line('.')
	exec "normal G"
	let pos = getpos(".")
	let end = pos[1]
	let lines = getline(start, end)
	let mark_list = []
	for i in lines
		let ent = substitute(i, '\s\(\S\)\s\+\(.*\)', '\1%%\2', "")
		if match(ent, '%%') < 0
			continue
		endif
		call add(mark_list, ent)
	endfor
	call writefile(mark_list, g:HiExMakFile)
endfunction


