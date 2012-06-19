function! s:HiExCmdMenu()
	exec "new"
	inoremap <silent><buffer> <CR> <ESC>:call HiExCmdMenuCR(3)<CR>
	inoremap <silent><buffer> <NL> <ESC>:call HiExCmdMenuCR(2)<CR>
	inoremap <silent><buffer> d    <ESC>:call HiExCmdMenuCR(1)<CR>
	call s:HiExMenuInit("Command")
endfunction

function! HiExCmdMenuCR(flag) "flag: 1:delete, 2:select, 3:select+CR, 
	let msg=getline(".")
	call s:HiExMenuClose()
	if len(msg) <= 0
		return
	endif
	let clist = {}
	let cnt = 0
	for i in videm#prj#getVar('CMD_L')
		if i["word"] == msg
			let clist = i
			break
		endif
		let cnt += 1
	endfor
	if empty(clist) == 1
		return
	endif
	if a:flag == 2 || a:flag == 3
		let s:cmdDir = i["dir"]
		call videm#main#newWin(2, msg)
		call videm#tmux#renameWin("-", clist["abbr"])
	elseif a:flag == 1
		cal videm#prj#rmVar('CMD_L', cnt)
	endif
endfunction

func! HiExCmdMenuShow()
	let compList = []
	for i in videm#prj#getVar('CMD_L')
		call add(compList, {"word":i["word"], "abbr":i["abbr"]})
	endfor
	call complete(col('.'), compList)
	return ''
endfunc

