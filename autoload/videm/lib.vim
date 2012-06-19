if exists("g:loaded_videm_lib_auto") || &cp
	finish
endif
let g:loaded_videm_lib_auto = 1

func! videm#lib#openMultiFiles(fileList)
	let cnt = 0
	for name in a:fileList
		let name = substitute(name, "^[ ]*", "", "") "ignore indent
		let name = substitute(name, '\s\+$', "", "")  "ignore tail space
		let name = substitute(name, '\s*#.*$', "", "")  "remove comment
		let name = fnamemodify(name,":p")
		if getftype(name) != "file"
			continue
		endif
		if cnt == 0
			call videm#tmux#sendMsg($VIDEM_MAIN, videm#tmux#openFile("-") . name)
		else 
			while videm#tmux#checkVim() == 0
				"busy loop
			endwhile
			call videm#tmux#sendMsg($VIDEM_MAIN, ":e " . name)
		endif
		let cnt += 1
	endfor
endf

func! videm#lib#openMultiFilesNew(fileList)
	let cnt = 0
	let title = ""
	let newDir = "/"
	let newlist = []
	for oname in a:fileList
		let cnt += 1
		let name = videm#string#fnameSanitize(oname)
		if getftype(name) != "file"
			if cnt == 1
				if oname[0] == "<"
					let title = substitute(oname, '<\(.*\)>', '\1', '')
				else
					let title = substitute(oname, '=\+\s*\(.*\)\s=\+', '\1', '')
				endif
			endif
			continue
		endif
		if newDir == "/"
			let newDir = strpart(name, 0, strridx(name,'/')) . "/"
		endif
		call add(newlist, name)
	endfor
	call videm#tmux#newWin()
	call videm#tmux#sendMsg("-", "cd " . newDir . " && vim " . join(newlist, " "))
	if title != ""
		call videm#tmux#renameWin("-", title)
	endif
endf

func! videm#lib#dec2bc(num)
	let num = a:num
	let str = ""
	while (num > 0)
		let rem = num % 2
		if rem == 1
			let str = "1". str
		else
			let str = "0". str
		endif
		let num = num / 2
	endwhile
	retu str
endf
	
