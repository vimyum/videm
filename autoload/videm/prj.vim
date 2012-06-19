"=============================================================================
" What Is This: VIDEm (IDE with Vim and Tmux)
" File: autoload/videm/prj.vim
" Author: Sagara Takahiro <vimyum@gmail.com>
"=============================================================================
if exists("g:loaded_videm_prj_auto") || &cp
	finish
endif
let g:loaded_videm_prj_auto = 1

"Project:[current dir], [ctags], [Make directory], [Make option], [GDB option],
"        [files(opened)], [files], [last modified], [svn], [cvs],
"        [color theme]
let s:prjTemplate = [
			\[$HOME. "/", "/tmp/"],
			\["/home/","/tmp/"],
			\["Home","Temp"],
			\"./tags,./../tags",
			\[{"abbr":"LS", "word":"ls", "dir":"/tmp"}],
			\"","",
			\[],
			\[],
			\"",
			\"svn",
			\"/tmp/memo.videm"]

let s:PRJ_DIR    = 0 "Current directory
let s:PRJ_DIR_T  = 1 "Current directory
let s:PRJ_CTAGS  = 2 
let s:PRJ_CMD	 = 3 "Command Array
let s:PRJ_MAKE_O = 4 "Make options
let s:PRJ_GDB_O  = 5 "GDB options
let s:PRJ_FILE_O = 6 "Project files (opened)
let s:PRJ_FILE_C = 7 "Project files
let s:PRJ_LAST   = 8
let s:PRJ_SVN    = 9
let s:PRJ_MEMO   = 10

let s:prjName = {"DIR_L":0, "NAME_L":1, "CTAG":2,"CMD_L":3, "MAKE":4,  "XXX2":5, 
			\ "AFILE_L":6, "FILE_L":7, "LAST":8, "SVN":9, "MEMO":10 }

let s:prjArray = {g:HiExPrjGen : deepcopy(s:prjTemplate)} 
let s:nowPrj   = g:HiExPrjGen

func! videm#prj#getVar(name)
	retu s:prjArray[s:nowPrj][s:prjName[a:name]]
endf

func! videm#prj#setVar(name, var)
	let s:prjArray[s:nowPrj][s:prjName[a:name]] = a:var
endf

func! videm#prj#addVar(name, var)
	cal add(s:prjArray[s:nowPrj][s:prjName[a:name]], a:var)
endf

func! videm#prj#rmVar(name, var)
	cal remove(s:prjArray[s:nowPrj][a:name], a:var)
endf

func! videm#prj#name()
	retu s:nowPrj
endf

func! videm#prj#getPrjNameList()
	retur keys(s:prjArray)
endf

func! videm#prj#openPrj(name)
	if has_key(s:prjArray, a:name) == 0
		return
	endif
	let s:nowPrj = a:name
	call videm#main#tabCloseAll()
	call s:GetDir()
endf

func! videm#prj#select(start) abort
	if a:start == 1
		let msg = g:HiExPrjGen
	else
		let msg = input("Project:", "" )
		if strlen(msg) == 0
			return
		elseif has_key(s:prjArray, msg) == 0
			call input("No such project!","")
			return
		endif
	endif
	cal videm#prj#openPrj(msg)
endf

func! videm#prj#addFile()
	let ent = b:curPos . expand("<cfile>")
	call videm#prj#loadFile()
	call add(s:prjArray[s:nowPrj][s:PRJ_FILE_O], ent)
	call s:SaveFiles()
	let winNum = videm#main#getWinNum()
	if winNum != ""
		call videm#tmux#sendMsg(winNum, ":call videm#prj#winReload()")
	endif
endf

func! videm#prj#open()
	let winNum = videm#main#getWinNum('prj')
	if winNum != ""
		cal videm#tmux#sendMsg(winNum, ":qa!")
		cal videm#main#setWinNum('prj',"")
		return
	endif
	try
		call s:SaveFiles()
		call videm#tmux#splitWin($VIDEM_MAIN, g:HiExPrjWinHeight,
					\ "export VIDEM_NAVI=". $VIDEM_NAVI . 
					\" && export VIDEM_MAIN=". $VIDEM_MAIN .
					\" && export VIDEM_PRJ=". s:nowPrj .
					\" && vim -c \"call videm#prj#start()\"")
	catch
		return
	endtry
endf

func! videm#prj#winSelect() range
	let l:selected = getline(a:firstline, a:lastline)
	let files=[]
	for ent in l:selected
		call add(files, ent)
	endfor
	if a:flg == 2
		call videm#lib#openMultiFilesNew(files)
	else
		call videm#lib#openMultiFiles(files)
	endif
	if a:flg == 0
		exec "quit!"
	endif
endf

func! videm#prj#loadFile()
	let s:prjArray = {}
	try
		for line in readfile(g:VidemProjectFile)
			let t_NAME =  strpart(line, 0, stridx(line, "%"))
			let line = substitute(line, "^[^%]*%", "", "")
			let last_flg = 0
			let s:prjArray[t_NAME] = []
			while 1
				let len = strlen(line)
				let tmp = strpart(line, 0, stridx(line, "%"))
				let line = substitute(line, "^[^%]*%", "", "")
				if tmp[0] == "[" && tmp[strlen(tmp) - 1] == "]"
					call add(s:prjArray[t_NAME], videm#string#str2list(tmp))
				else
					call add(s:prjArray[t_NAME], tmp)
				endif
				if last_flg == 1
					break
				endif
				if match(line, "%") < 0
					let last_flg = 1
				endif
			endwhile
		endfor
	catch
		echo "Failed to Read ". g:VidemProjectFile
	endtry
	if len(s:prjArray) <= 0
		let s:prjArray[g:HiExPrjGen] = deepcopy(s:prjTemplate)
	endif
endf

func! videm#prj#new()
	let msg = input("Project:", "" )
	if strlen(msg) == 0
		echo ""
		return
	endif
	if has_key(s:prjArray, msg) != 0
		call input(msg ." is already exist!","")
		return
	endif
	let s:prjArray[msg] = deepcopy(s:prjTemplate)
	let s:nowPrj = msg
	call videm#main#setStatusLine(tabpagenr())
endf

func! videm#prj#copy()
	let msg = input("Copy Project:", s:nowPrj )
	if strlen(msg) == 0
		return
	endif
	if has_key(s:prjArray, msg) != 0
		call input(msg ." is already exist!","")
		return
	endif
	let s:prjArray[msg] = deepcopy(s:prjArray[s:nowPrj])
	let s:nowPrj = msg
	call videm#main#setStatusLine(tabpagenr())
endf

func! videm#prj#delete()
	let msg = input("Project:", "" )
	if strlen(msg) == 0
		let msg = s:nowPrj
	endif
	if has_key(s:prjArray, msg) == 0
		call input("No such project!","")
		echo ""
		return
	elseif msg == g:HiExPrjGen
		call input(g:HiExPrjGen ." is needed!","")
		echo ""
		return
	endif
	let confRet = confirm("Remove Project: ". msg , "&Yes\n&No", 1)
	if l:confRet > 1
		return
	endif
	if msg == s:nowPrj
		let s:nowPrj = g:HiExPrjGen
	endif
	call remove(s:prjArray, msg)
endf

func! videm#prj#saveFile()
	let confRet = confirm("Save Navigator", "&Yes\n&No", 1)
	if l:confRet <= 1 
		call s:SetDir()
	endif
	call s:SaveFiles()
	echo ""
endf

func! videm#prj#openFiles()
	let files = s:prjArray[s:nowPrj][s:PRJ_FILE_O]
	call videm#lib#openMultiFiles(files)
endf

func! videm#prj#closeFiles()
	if videm#tmux#checkVim()
		call videm#tmux#sendMsg($VIDEM_MAIN, ":qa")
	endif
	call videm#tmux#sendClr($VIDEM_MAIN)
endf

func! videm#prj#list()
	for key in keys(s:prjArray)
		echo key
	endfor
	call input("--- OK ---", "")
endf

func! videm#prj#start()
	let s:nowPrj = $VIDEM_PRJ
	cal videm#main#regWin('prj')
	cal s:WinInit()
	try
		cal videm#prj#loadFile()
	catch
		echo "fail"
	endtry
	cal s:WinShow()
	cal cursor(2,1)
endf

"""""""""""""""""commnds in window"""""""""""""""""""
func! videm#prj#winSave()
	exec "normal gg"
	let start = line('.')
	exec "normal G"
	let pos = getpos(".")
	let end = pos[1]
	let lines = getline(start, end)

	let s:prjArray[s:nowPrj][s:PRJ_FILE_O] = []
	let s:prjArray[s:nowPrj][s:PRJ_FILE_C] = []
	let splitflg = 0

	for i in lines
		"Skip Separator
		if match(i, g:HiExPrjActFileTitle) >= 0 
			continue
		endif
		if match(i, g:HiExPrjNonActFileTitle) >= 0
			let splitflg = 1
			continue
		endif
		if splitflg == 0
			call add(s:prjArray[s:nowPrj][s:PRJ_FILE_O], i)
		else
			call add(s:prjArray[s:nowPrj][s:PRJ_FILE_C], i)
		endif
	endfor
	call s:SaveFiles()
endf

func! videm#prj#winReload()
	exec "%delete"
	try
		call videm#prj#loadFile()
	catch
		echo "fail"
	endtry
	call s:WinShow()
endf


func! videm#prj#winSelectOpe(ope) range
	let l:selected = getline(a:firstline, a:lastline)
	let flist = ""
	for ent in l:selected
		"let ent = substitute(ent, "^[ ]*", "", "")
		let ent = substitute(ent, '\s*\(\S\+\).*', '\1', "")
		if ent == ""
			continue
		endif
		let ent = fnamemodify(ent,":p")
		let l:ftype = getftype(ent)
		if l:ftype != "file" && l:ftype != "dir"
			continue
		endif
		let flist = flist ." ". ent
	endfor

	if a:ope == "tar"
		call s:WinOpeTar(flist)
	elseif a:ope == "grep"
		call s:WinOpeGrep(flist)
	endif
endf

func! videm#prj#winMove(flg)
	let pos = getpos(".")
	let npos = copy(pos)
	if a:flg == "K"
		if pos[1] <= 1
			return
		endif
		for i in reverse(range(0, pos[1] - 1))
			let line = getline(i)
			if match(line, '^\s*=') >= 0 || match(line, '^\s*<') >= 0
				let npos[1] = i
				break
			endif
		endfor
	elseif a:flg == "J"
		exe "norm G"
		let eline = line(".")
		if pos[1] >= eline
			return
		endif
		for i in range(pos[1] + 1, eline)
			let line = getline(i)
			if match(line, '^\s*=') >= 0 || match(line, '^\s*<') >= 0
				let npos[1] = i
				break
			endif
		endfor
	endif
	call setpos(".", npos)
endfunc


"""""""""""""""""internal window functions"""""""""""""""""""
func! s:WinShow()
	let ofiles = s:prjArray[s:nowPrj][s:PRJ_FILE_O]
	let cfiles = s:prjArray[s:nowPrj][s:PRJ_FILE_C]
	setlocal modifiable
	call cursor(1,1)
	let msg = videm#string#padding(g:HiExPrjActFileTitle, winwidth(0) -1, " ")
	exec "normal! i". msg ."\n"
	for tmp in ofiles
		exec "normal i". tmp ."\n"
	endfor
	let msg = videm#string#padding(g:HiExPrjNonActFileTitle, winwidth(0) -1, " ")
	exec "normal! i". msg ."\n"
	for tmp in cfiles
		exec "normal i". tmp ."\n"
	endfor
	exec "delete"
endf

func! s:WinInit()
	nno <silent><buffer> <CR>		:call videm#prj#winSelect(0)<CR>:<BS>
	vno <silent><buffer> <CR>		:call videm#prj#winSelect(0)<CR>:<BS>
	nno <silent><buffer> <space>	:call videm#prj#winSelect(1)<CR>:<BS>
	vno <silent><buffer> <space>	:call videm#prj#winSelect(1)<CR>:<BS>
	nno <silent><buffer> <NL>		:call videm#prj#winSelect(2)<CR>:<BS>
	vno <silent><buffer> <NL> 		:call videm#prj#winSelect(2)<CR>:<BS>
	nno <silent><buffer> t			:call videm#prj#winSelectOpe("tar")<CR>:<BS>
	vno <silent><buffer> t			:call videm#prj#winSelectOpe("tar")<CR>:<BS>
	nno <silent><buffer> R			:call videm#prj#winSelectOpe("grep")<CR>:<BS>
	vno <silent><buffer> R			:call videm#prj#winSelectOpe("grep")<CR>:<BS>
	nno <silent><buffer> b			:quit!<CR>:<BS>
	nno <silent><buffer> q			:quit!<CR>:<BS>
	nno <silent><buffer> s			:call videm#prj#winSave()<CR>:<BS>
	nno <silent><buffer> J			:call videm#prj#winMove("J")<CR>:<BS>
	nno <silent><buffer> K			:call videm#prj#winMove("K")<CR>:<BS>

	setlocal filetype=videm
	hi Title		ctermfg=234		ctermbg=14		cterm=none
	syntax match Title /.*<<<.*>>>.*/
	syntax match Comment /#.*$/

	setlocal nobuflisted
	setlocal bufhidden
	setlocal foldmethod=manual
	autocmd VimLeave *  :call <SID>WinClose()<CR>:<BS>
	set nowrap 
endf

func! s:WinOpeTar(flist)
	let tarballname = videm#string#dateSubsitute(s:nowPrj .".%t.tar.gz")
	let tarballname = input("tarball:", tarballname)
	if empty(tarballname)
		return
	endif
	let l:to = g:HiExBackupDir ."/" . tarballname
	let l:base = l:to
	let l:cnt = 0

	while getftype(l:to) == "file"
		let l:cnt += 1
		let l:to = l:base .".". l:cnt
	endwhile
	try
		call system("tar zcf " . l:to ." ". a:flist)
	catch
		call input("Failed to create backup", "")
	endtry
	let l:ftype = getftype(l:to)
	if l:ftype != "file" 
		call input("No backup directory", "")
		return
	endif
	let fsize = getfsize(l:to) 
	if fsize < 1000
		echo "Saved as ". l:to ." (". fsize ."Byte)"
	else
		echo "Saved as ". l:to ." (". (fsize / 1000) ."KByte)"
	endif
endf

func! s:WinOpeGrep(flist)
	let ptn = input("pattern:", "")
	if empty(ptn)
		return
	endif
	let tmpf = tempname()
	echo "grep -H -n \"". ptn ."\" ". a:flist ." > ". tmpf
	call system("grep -I -H -n \"". ptn ."\" ". a:flist ." > ". tmpf)
	exec "tabe ". tmpf
	hi  FileName ctermfg=blue
	syntax match FileName /^.*:/
	call delete(tmpf) 
endf

func! s:WinClose()
	call videm#prj#winSave()
	call videm#tmux#sendMsg($VIDEM_NAVI, ":cal videm#main#setWinNum('prj','')")
	call videm#tmux#sendMsg($VIDEM_NAVI, ":cal HiExReloadFiles()")
endf

"""""""""""""""""internal functions"""""""""""""""""""
func! s:GetDir() abort
	cal videm#main#tabTListClear()
	let dir  = s:prjArray[s:nowPrj][s:PRJ_DIR]
	let dirt = s:prjArray[s:nowPrj][s:PRJ_DIR_T]
	let len = len(dir)

	for i in range(2, len)
		call videm#main#tabNew()
	endfor
	for i in range(1, len)
		cal videm#main#tabTListSet(i, dirt[i-1])
	endfor
	exec "tabfir"
	for i in range(1, len)
		call videm#main#select(0, dir[i-1], 0)
		exec "tabn"
	endfor
endf

func! s:SetDir()
	let orgTab = tabpagenr()
	exec "tablast"
	let startTab = tabpagenr()
	let s:prjArray[s:nowPrj][s:PRJ_DIR] = []
	let s:prjArray[s:nowPrj][s:PRJ_DIR_T] = []
	while 1
		exec "tabn"
		call add(s:prjArray[s:nowPrj][s:PRJ_DIR], b:curPos)
		call add(s:prjArray[s:nowPrj][s:PRJ_DIR_T], videm#main#tabTListGet(tabpagenr())])
		if startTab == tabpagenr()
			while 1
				exe "tabn"
				if orgTab == tabpagenr()
					return 
				endif
			endwhile
		endif
	endwhile
	"never reached
endf

func! s:SaveFiles()
	if len(s:prjArray) <= 0
		return
	endif
	let tmpArray = []
	for key in keys(s:prjArray)
		let tmp = key ."%" . join(s:prjArray[key], "%")
		call add(tmpArray, tmp)
	endfor
	call writefile(tmpArray, g:VidemProjectFile)
endf

