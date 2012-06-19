"=============================================================================
" VIDEM (IDE with Vim and Tmux)
" File: autoload/videm/prj.vim
" Author: Sagara Takahiro <vimyum@gmail.com>
"=============================================================================
if exists("g:loaded_videm_base_auto") || &cp
	finish
endif
let g:loaded_videm_base_auto = 1

let s:selected_list = []
let s:winlist  = ["", "", "", "", "", ""]
let s:cmd_tmux_version="tmux -V"

func! videm#main#start() "{{{
	if s:CheckEnvironment() < 0
		cal input("Failed to start videm","")
		exe "qa!"
	endif
	cal s:SetKeyMap()
	cal s:SetScriptSetting()
	cal s:SetLocal()
	cal s:SetHightlights()
	cal s:SetSynMatch()
	let b:curPos = getcwd() . "/"
	let b:lsFlag = "-t "
	let b:dirList = []
	let b:videm_mark_dic = {} 
	let b:videm_mark_dir  = ""

	cal s:HiExReadCacheFile()
	cal s:Clear()
	cal s:Show(b:curPos)
	cal s:SetTabline()

	setl nomodifiable
	
	if !exists("s:autocommands_loaded2")
		let s:autocommands_loaded2 = 1
		cal videm#prj#select("1")
	endif
	cal videm#bmark#load()
endf "}}}

func s:SetScriptSetting() "{{{
	if exists("s:autocommands_loaded")
		return
	endif
	let s:autocommands_loaded = 1

	let s:navi_hidden = 0
	let s:navi_width  = 0
	let s:navi_cal    = 0
	let s:tabTitle    = ["",""]

	au VimLeave *  :cal <SID>WriteCacheFile()
	au VimLeave *  :cal videm#bmark#save()
	au VimLeave *  :cal <SID>CloseSubWin()
	au TabEnter *  :cal s:SetTabline()

	try
		call videm#prj#loadFile()
	catch
		echo "Failed to open project file \"". g:VidemProjectFile ."\""
	endtry
	let s:hiExPane = $TMUX_PANE
	cal videm#tmux#sendMsg($VIDEM_MAIN, "export VIDEM_MAIN=" . $VIDEM_MAIN)
	cal videm#tmux#sendMsg($VIDEM_MAIN, "export VIDEM_NAVI=" . $TMUX_PANE)
	cal videm#tmux#sendClr($VIDEM_MAIN)


	"Load Menu-Plugins
	cal videm#menu#setup()
endf "}}}

func s:SetKeyMap() "{{{
	nno <silent> <buffer> +			:cal <SID>VidemMark()<CR>:<BS>
	vno <silent> <buffer> +			:cal <SID>VidemMarkRange()<CR>:<BS>
	nno <silent> <buffer> %			:cal <SID>VidemMarkReverse()<CR>:<BS>
	nno <silent> <buffer> e			:cal videm#main#select(0, "-", 0)<CR>:<BS>
	nno <silent> <buffer> <space>	:cal videm#main#select(2, "-", 0)<CR>:<BS>
	nno <silent> <buffer> go 	  	:cal VidemSelectMark(3)<CR>:<BS>
	nno <silent> <buffer> <CR>		:cal VidemSelectMark(4)<CR>:<BS>
	nno <silent> <buffer> x 	  	:cal videm#main#select(5, "-", 0)<CR>:<BS>
	nno <silent> <buffer> u			:cal <SID>GoPre()<CR>:<BS>
	nno <silent> <buffer> <C-u>		:cal <SID>MoveDir()<CR>:<BS>
	nno <silent> <buffer> <C-n>		:cal videm#main#newWin(0,"")<CR>:<BS>
	nno <silent> <buffer> .			:cal <SID>ShowAll()<CR>:<BS>
	nno <silent> <buffer> f			:cal <SID>Filter()<CR>:<BS>
	nno <silent> <buffer> r			:cal <SID>Reload()<CR>:<BS>
	nno <silent> <buffer> gh		:cal <SID>GoHome()<CR>:<BS>
	nno <silent> <buffer> gt		:cal <SID>GoTrush()<CR>:<BS>
	nno <silent> <buffer> gm		:cal <SID>GoMedia()<CR>:<BS>
	nno <silent> <buffer> gs		:cal <SID>GoSave()<CR>:<BS>
	nno <silent> <buffer> gl		:cal <SID>GoLoad()<CR>:<BS>
	nno <silent> <buffer> gD		:cal <SID>EmptyTrush()<CR>:<BS>
	nno <silent> <buffer> J			:cal <SID>DownRuc()<CR>:<BS>
	nno <silent> <buffer> K			:cal <SID>HiExUpRuc()<CR>:<BS>
	nno <silent> <buffer> U			:cal <SID>HiExUpDir()<CR>:<BS>
	nno <silent> <buffer> a			:cal videm#bmark#add(0)<CR>:<BS>
	nno <silent> <buffer> b			:cal videm#bmark#open()<CR>:<BS>
	nno <silent> <silent> <F12>		:cal videm#main#close()<CR>:<BS>
	nno <silent> <buffer> mf		:cal <SID>CreateFile()<CR>>:<BS>
	nno <silent> <buffer> md		:cal <SID>HiExMkDir()<CR>:<BS>
	nno <silent> <buffer> mv		:cal <SID>FileOpe("rename")<CR>:<BS>
	nno <silent> <buffer> dd		:cal <SID>FileOpe("mv")<CR>:<BS>
	nno <silent> <buffer> DD		:cal <SID>FileOpe("rm")<CR>:<BS>
	nno <silent> <buffer> yy		:cal <SID>FileOpe("cp")<CR>:<BS>
	nno <silent> <buffer> p			:cal <SID>Paste(1)<CR>:<BS>
	nno <silent> <buffer> <C-p>		:cal <SID>Paste(0)<CR>:<BS>
	nno <silent> <buffer> <NL>		:cal videm#main#newWin(1,"")<CR>:<BS>
	"Tab operation
	nno <silent> <buffer> tc		:call <SID>HiExTabNew()<CR>:echo "created."<CR>
	nno <silent> <buffer> ta		:call <SID>HiExTabSetTitle()<CR>:<BS>
	nno <silent> <buffer> tk		:call <SID>HiExTabClose()<CR>:<BS>
	nno <silent> <buffer> tn		:call videm#main#tabMv("next")<CR>:<BS>
	nno <silent> <buffer> tN		:call videm#main#tabMv("prev")<CR>:<BS>
	nno <silent> <buffer> w		:call <SID>HiExTabMenu()<CR>:<BS><C-R>=HiExTabMenuShow()<CR>
	nno <silent> <buffer> L		:tabn<CR>
	nno <silent> <buffer> H		:tabN<CR>
	"Projcet Management
	nno <silent> <buffer> Pc		:cal videm#prj#new()<CR>:<BS>
	nno <silent> <buffer> Pw		:cal videm#prj#copy()<CR>:<BS>
	nno <silent> <buffer> Pd		:cal videm#prj#delete()<CR>:<BS>
	nno <silent> <buffer> Po		:cal videm#prj#select(0)<CR>:<BS>
	nno <silent> <buffer> PO		:cal videm#prj#menu()<CR>:<BS><C-R>=videm#prj#menuShow()<CR>
	nno <silent> <buffer> Pl		:cal videm#prj#list()<CR>:<BS>
	nno <silent> <buffer> Pa		:cal videm#prj#addFile()<CR>:<BS>
	nno <silent> <buffer> A		    :cal videm#prj#addFile()<CR>:<BS>
	nno <silent> <buffer> Ps		:cal videm#prj#saveFile()<CR>:<BS>
	nno <silent> <buffer> PP		:cal videm#prj#openFiles()<CR>:<BS>
	nno <silent> <buffer> Pf		:cal videm#prj#open()<CR>:<BS>
	nno <silent> <buffer> Pq		:cal videm#prj#closeFiles()<CR>:<BS>


	nno <silent> <buffer> W		:call videm#main#cal()<CR>:<BS>
	nno <silent> <buffer> <C-l>	:call videm#tmux#sendClr($VIDEM_MAIN)<CR>:<BS>
	nno <silent> <buffer> gb		:call videm#bmark#addHistDir(simplify(b:curPos))<CR>:<BS>
	nno <silent> <buffer> zz		:call <SID>HiExHideNavi()<CR>:<BS>

	nno <silent> <buffer> tt		:call <SID>HiExMakWin()<CR>:<BS>
	nno <silent> <buffer> TT		:call <SID>HiTest()<CR>:<BS>

	nno <silent> <buffer> st		:call <SID>VidemSortType("-t")<CR>:<BS>
	nno <silent> <buffer> se		:call <SID>VidemSortType("-X")<CR>:<BS>
	nno <silent> <buffer> ss		:call <SID>VidemSortType("-S")<CR>:<BS>
	nno <silent> <buffer> sa		:call <SID>VidemSortType("")<CR>:<BS>
endf "}}}

func s:SetLocal() "{{{
	setl nowrap
	setl hidden
	setl incsearch
	setl laststatus=2
	setl showtabline=2
	setl bufhidden=hide
	setl conceallevel=2
	setl concealcursor=nvic 
endf "}}}

func s:SetSynMatch() "{{{
	syn match Comment    '^ \..*'
	syn match VidemDir /.*\// contains=ALL
	syn match VidemRUC /.* @/ contains=Todo
	syn match Todo       / @/   conceal
	syn match VidemSelected /.* %/ contains=VidemConcealMark
	syn match VidemConcealMark / %/ conceal
endf "}}}

func s:SetHightlights() "{{{
	cal s:SetHilight("VidemDir",   "ctermfg=39")
	cal s:SetHilight("VidemRUC",   "ctermfg=183")
	cal s:SetHilight("VidemSelected", "ctermfg=3")

	cal s:SetHilight("VidemTabLineFill",  'ctermfg=3 ctermbg=4')
	cal s:SetHilight("VidemStatusLine ",  'ctermfg=111 ctermbg=234')
	cal s:SetHilight("VidemStatusLineNC ",'ctermfg=234 ctermbg=234')
	cal s:SetHilight("VidemPmenu",        'ctermbg=145 ctermfg=black')
	cal s:SetHilight("VidemPmenuSel",     'ctermbg=blue')
	cal s:SetHilight("VidemModeMsg",      'ctermbg=233')

	cal s:SetHilight("VidemStatusColor",   'ctermfg=111 ctermbg=234')
	cal s:SetHilight("VidemMenuLineColor", 'ctermfg=234 ctermbg=234')
	cal s:SetHilight("VidemMenuColor",     'ctermfg=19 ctermbg=3')

	exe "let g:VidemStatusColor='" . s:GetHighlight("VidemStatusColor") . "'"
	exe "let g:VidemMenuLineColor='" . s:GetHighlight("VidemMenuLineColor") . "'"
	exe "let g:VidemMenuColor='" . s:GetHighlight("VidemMenuColor") . "'"
	
	"Overwrite general color
	cal s:Highlight("TabLineFill")
	cal s:Highlight("StatusLine")
	cal s:Highlight("StatusLineNC")
	cal s:Highlight("Pmenu")
	cal s:Highlight("PmenuSel")
endf

func s:GetHighlight(color)
	redir => msg
	silent exe "hi ". a:color
	redir END
	return substitute(join(remove(split(msg, '\s\+'), 2, -1), ' '), '\n', '', '')
endf

func s:Highlight(color)
	let newColor = s:GetHighlight("Videm". a:color)
	exe 'hi '. a:color .' '. newColor
	retu
endf 

func s:SetHilight(name, color)
	if !highlight_exists(a:name)
		exe 'hi '. a:name .' '. a:color
	endif
endf "}}}

func! videm#main#close() "{{{
	call videm#tmux#sendMsg($VIDEM_MAIN, ":qa!")
	call videm#tmux#sendMsg($VIDEM_MAIN, "export VIDEM_MAIN=")
	call videm#tmux#sendClr($VIDEM_MAIN)
	exec "qa!"
endf "}}}

func! s:CheckEnvironment() "{{{
	" Check Tmux Version
	if strlen ($TMUX_PANE) <= 0
		let tmux_ver = split(system(s:cmd_tmux_version), '\s')
		if tmux_ver[0] != "tmux" || str2nr(tmux_ver[1]) < 1 || str2nr(tmux_ver[2]) < 6
			echo "videm requres Tmux (viersion 1.6 or later)"
			return -1
		endif
	endif
	" Check Conceal Option
	if !has('conceal')
		echo "videm requires 'conceal' option for Vim"
		return -1
	endif
	" Check OS
	if has('win32')
		echo "videm can run on only Linux or Mac"
		return -1
	elseif has('macunix') "For Mac
		let g:VidemOsOpen   = get(g:, 'VidemOsOpen',  'open')
		let g:VidemMediaDir = get(g:, 'VidemMediaDir','/media/')
	else                  "For Linux
		let g:VidemOsOpen   = get(g:, 'VidemOsOpen',  'gnome-open')
		let g:VidemMediaDir = get(g:, 'VidemMediaDir','/Volumes/')
	endif
	return 0
endf "}}}

let s:winName = { "XXX":0, "bmark":1, "prj":2, "mark":3, "cal":4, "ref":5 }
func! videm#main#addWinName(name)
	if has_key(s:winName, a:name)
		return
	endif
	let num = len(s:winName)
	let s:winName[a:name] = num
endfunc

func! videm#main#getWinNum(name)
	retu s:winlist[s:winName[a:name]]
endf

func! videm#main#setWinNum(name, var)
	let s:winlist[s:winName[a:name]] = a:var
endf

func! videm#main#regWin(name)
	cal videm#tmux#sendMsg($VIDEM_NAVI, 
				\ ":cal videm#main#setWinNum('". a:name .
				\ "','". $TMUX_PANE ."')")
endf

func! videm#main#clrWin(name)
	cal videm#tmux#sendMsg($VIDEM_NAVI, 
				\ ":cal videm#main#setWinNum('". a:name ."','')")
endf

func! s:CloseSubWin()
	for i in s:winlist
		if i != "" 
			call videm#tmux#sendMsg(i, ":qa!")
		endif
	endfor
	sleep 500m
endf

"================= Script Variables ======================
let s:cacheDat = g:VidemCacheFile . ".dat"
let s:cacheIdx = g:VidemCacheFile . ".idx"
let s:histArray = []
let s:histDirArray = []
let s:bmkArray = []
let s:ruc = {}
let s:histBufNr = 0
let s:findBufNr = 0
let s:histEndLn = 0
let s:filterStr = "."
let s:filterPreStr = ""
let s:tabTitle = ["",""] "0:dummy, 1:firstPage


let s:cmdDir = "/"
let s:navi_pane = ""

let s:VidemRelative    = {"pdf":["gopen","-"], "ppt":["gopen","-"], "pptx":["gopen","-"],
			\ "gz":["new","tar zxvf"], "mp4":["gopen","-"]}
let s:VidemRelativeExt = {"tcl":["new","ns2"], "sh":["new",""], "nam":["new","nam"]}

let s:videm_yank_num = 0
"=========================================================

"================= Buffer Variables ======================
let b:curPos = "/"
let b:prePos = "/"
let b:isAll  = 0
let b:isFilt = 0
"=========================================================

func! s:Show(pos)
	let s:isAll = 0
	let files = system("ls -p " . b:lsFlag . a:pos . " | egrep '" . s:filterStr . "'")
	exe "norm! i ../\n" . files
	delete
	if g:HiExCacheNum > 0
		call s:ShowRuc(a:pos)
	endif
	cal cursor(1,2)
endf

func! s:ShowAll()
	setl modifiable
	call s:Clear()
	if s:isAll == 1
		let files = system("ls -p " . b:lsFlag . b:curPos)
		let s:isAll = 0
	else 
		"let files = system("ls -p -A --ignore='*' " . b:lsFlag . b:curPos)
		let files = system("ls -p -A " . b:lsFlag . b:curPos)
		let s:isAll = 1
	endif
	execute "normal i ../\n" . files
	call s:ShowRuc(b:curPos)
	setl nomodifiable
endf

func! s:Clear()
	%delete
endf

" Recent Used Collections (RUC) {{{
function! s:ShowRuc(key)
	setlocal modifiable
	if has_key(s:ruc, a:key) == 0
		return
	endif
	let rucList = s:ruc[a:key]
	let entIdx = 0
	for rucEnt in rucList
		let rucEnt = escape(rucEnt, '/')
		"execute is to be replace with search()
		exec "normal ggj"
		if search( rucEnt . "$", 'n') > 0
			exe '%s/\(' . rucEnt . '\)$/\1 @' 
		else
			if search( rucEnt . " @$", 'n') <= 0
				if s:isAll == 1 && strpart(rucEnt, 0, 1) == "." && s:isFilt == 0
					call remove(rucList, entIdx)
				elseif s:isAll == 0 && strpart(rucEnt, 0, 1) != "." && s:isFilt == 0
					call remove(rucList, entIdx)
				endif
				let entIdx -= 1
			endif
		endif
		let entIdx += 1
	endfor
	setlocal nomodifiable
endfunction

function! s:HiExAddRuc(key, val)
	if has_key(s:ruc, a:key) == 0
		call extend(s:ruc, {a:key : [a:val]})
		return
	endif
	let entIdx = index(s:ruc[a:key], a:val)
	if entIdx >= 0
		call remove(s:ruc[a:key], entIdx)
	endif
	call add(s:ruc[a:key], a:val)
	if len(s:ruc[a:key]) > g:HiExCacheNum
		call remove(s:ruc[a:key], 0)
	endif
endfunction

function! s:DownRuc()
	let l:nowL = line(".")
	call cursor(l:nowL, 1)
	call search(".* @", 'w')
	let l:nowL = line(".")
	call cursor(l:nowL, 2)
	execute "noh"
endfunction

function! s:HiExUpRuc()
	let l:nowL = line(".")
	call cursor(l:nowL, 1)
	call search(" .* @", 'bw')
	let l:nowL = line(".")
	call cursor(l:nowL, 2)
	execute "noh"
endfunction


"}}}

function! s:AddDirList(ent)
	call add(b:dirList, a:ent)
	if len(b:dirList) > g:HiExDirListLen
		call remove(b:dirList, 0)
	endif
endfunction

" Select Mark {{{
func! s:VidemMark()
	if b:videm_mark_dir != b:curPos
		let b:videm_mark_dic = {}
	endif
	let b:videm_mark_dir = b:curPos

	setl modifiable
	let ent=getline(".")
	if ent =~ '\s%$'
		let ent = substitute(ent, '\s%$', '', '')
		let newent = ent
		if has_key(b:videm_mark_dic, newent)
			if b:videm_mark_dic[newent] == '@'
				let newent .= ' @'
			endif
			call remove(b:videm_mark_dic, ent)
		endif
		cal setline(".", newent)
	else
		if ent =~ '\s@$'
			let ent = substitute(ent, '\s@$', '', '')
			let b:videm_mark_dic[ent]="@"
		else
			let b:videm_mark_dic[ent]="-"
		endif
		cal setline(".", ent . ' %')
	endif
	setl nomodifiable
endf

func! s:VidemMarkRange() range
	let nline = a:firstline
	let oline = line('.')
	let lline = a:lastline
	while nline <= lline
		call cursor(nline, 2)
		call s:VidemMark()
		let nline += 1
	endwhile
	call cursor(oline, 2)
endf

func! s:VidemMarkReverse()
	let nline = 2
	let oline = line('.')
	let lline=line('$')
	while nline <= lline
		call cursor(nline, 2)
		call s:VidemMark()
		let nline += 1
	endwhile
	call cursor(oline, 2)
endf

func! s:SetMarkBuf(flg)
	if len(b:videm_mark_dic) <= 0  || a:flg != 0
		return
	endif
	let msg = join(keys(b:videm_mark_dic), ' ')
	call videm#tmux#setb(msg)
endf

"}}}

"Select Function {{{
" 0: OpenFile with Vim
" 1: MoveDir
" 2: Show information 
" 3: Open with Gnome-open
" 4: Open File with relative application    
" 5: Execute File with relative application
func! videm#main#select(flg, dst, stay)
	let s:isFilt = 0
	let moveFocus = 0
	let retval   = 0
	setlocal modifiable
	exe "noh"
	if a:dst == "-"
		let l:curWord = expand("<cfile>")
		if l:curWord == "../"
			let l:newEnt = substitute(b:curPos, '.[^/]*\/$', '/', "g") 
		else
			call s:HiExAddRuc(b:curPos, l:curWord)
			let l:newEnt  = b:curPos . l:curWord
		endif
	else
		let l:newEnt = a:dst
	endif
	let l:ftype = getftype(l:newEnt)
	if a:flg == 2
		let fileInfo =  system("ls -pdhl ". l:newEnt ." |cut -d' ' -f1,3,4,5")
		echo fileInfo
		sleep 2
		call videm#main#setStatusLine(tabpagenr())
		return
	endif

	if l:ftype == "dir"
		call s:Clear()
		call s:SetCurPos(l:newEnt)  
		call s:AddDirList(l:newEnt)
		call s:Show(b:curPos)
		call s:DownRuc()
		if a:flg == 1
			call videm#tmux#sendMsg($VIDEM_MAIN, videm#tmux#moveDir() . b:curPos)
		endif
		call s:SetTabline()
	elseif l:ftype == "file"
		if a:dst == "-"
			let moveFocus = 1
		endif
		if a:flg == 3 "open with gnome-open
			call system(g:VidemOsOpen . " " . l:newEnt)
			let moveFocus = 0
		else
			let fext = fnamemodify(l:newEnt, ":e")
			let relative_list = copy(s:VidemRelative)
			if a:flg == 5
				let relative_list = extend(relative_list, 
							\s:VidemRelativeExt, "force")
			endif
			if a:flg == 0 || has_key(relative_list, fext) == 0 
				let l:ftypeDetail = system("file " . l:newEnt . " | cut -d' ' -f2-")
				let l:ftypeDetail = strpart(l:ftypeDetail, 0, strlen(l:ftypeDetail) - 1)
				if match(l:ftypeDetail, "text") < 0 
					echo l:newEnt . " type is \"" . l:ftypeDetail . "\""
					let confRet = confirm("Do you open type(" . l:ftypeDetail . ")", "&Yes\n&No", 1)
					if confRet > 1
						setlocal nomodifiable
						return -1
					endif
				endif
				call videm#tmux#sendMsg($VIDEM_MAIN, videm#tmux#openFile("-") . l:newEnt)
				let retval = 1
			else "open with relative application in Videm
				let moveFocus = 0
				let ope = relative_list[fext]
				if     ope[0] == "gopen"
					cal system(g:VidemOsOpen . " " . l:newEnt)
				elseif ope[0] == "new"
					let s:cmdDir = b:curPos
					cal videm#main#newWin(2, (ope[1] == "" ? './' : ope[1] . " ") . l:newEnt)
				endif
			endif
		endif

		call s:ShowRuc(b:curPos)

		"Update History Array
		call videm#bmark#addHist(simplify(l:newEnt))
		call videm#bmark#addHistDir(simplify(b:curPos))
	else
		echo "type: unkown " . l:ftype
	endif
	setlocal nomodifiable
	if moveFocus == 1 && a:stay != 1
		call videm#tmux#selectPane($VIDEM_MAIN)
	endif
	return retval
endf "}}}

function! s:Filter()
	if empty(s:filterPreStr)
		let s:filterPreStr = g:HiExDefaultFilter
	endif
	let s:filterStr = input("Filter:", s:filterPreStr)
	if empty(s:filterStr)
		let s:filterStr = "."
	else
		let s:filterPreStr = s:filterStr
		let s:isFilt = 1
	endif
	call s:Reload()
	let s:filterStr = "."
endfunction

" Jump Directory functions {{{
function! s:GoHome()
	call videm#main#select(0, $HOME . "/", 0)
	call s:Reload()
endfunction

function! s:GoTrush()
	call videm#main#select(0, g:HiExTrushBin . "/", 0)
	call s:Reload()
endfunction

function! s:GoMedia()
	call videm#main#select(0, g:VidemMediaDir , 0)
	call s:Reload()
endfunction

let s:VidemGoDir="/"
function! s:GoSave()
	let s:VidemGoDir = b:curPos
	echo "store current dir"
endfunction

function! s:GoLoad()
	call videm#main#select(0, s:VidemGoDir, 0)
	call s:Reload()
endfunction
"}}}

func! s:EmptyTrush()
	echo "Trush:" . g:HiExTrushBin
	let l:confRet = confirm("Empty Trush? ", "&Yes\n&No", 1)
	if l:confRet > 1
		return
	endif
	call system("rm -r " . g:HiExTrushBin ."/*")
endf

function! s:Reload()
	let b:videm_mark_dir  = ""
	let b:videm_mark_dic = {}
	setlocal modifiable
	call s:Clear()
	call s:Show(b:curPos)
	call s:DownRuc()
	setlocal nomodifiable
endfunction

function! s:MoveDir()
	if getftype(b:curPos) == "dir"
		call videm#tmux#sendMsg($VIDEM_MAIN, videm#tmux#moveDir() . b:curPos)
	endif
endfunction


" Open New Window {{{
function! videm#main#newWin(flag, msg) "(flag)1: open & edit file, 0; just open.
	call s:SetMarkBuf(a:flag)
	let l:ftype = "unknown"
	if a:flag == 1
		let l:newEnt = expand("<cfile>")
		if  match(l:newEnt, '/') < 0
			let l:ftype = getftype(b:curPos . l:newEnt)
		else
			let l:ftype = getftype(l:newEnt)
		endif
	endif
	if getftype(b:curPos) != "dir"
		return
	endif
	call system("tmux new-window")
	if l:ftype == "file"
		call videm#tmux#sendMsg("-", "cd " . b:curPos . " && vim " . l:newEnt)
		call videm#bmark#addHist(simplify(l:newEnt))
		call videm#bmark#addHistDir(simplify(b:curPos))
	else
		if     a:flag == 2
			call videm#tmux#sendMsg("-", "cd " . s:cmdDir)
			call videm#tmux#sendMsgNR("-", a:msg)
			call videm#tmux#sendClr("-")
		elseif a:flag == 3
			call videm#tmux#sendMsg("-", "cd " . s:cmdDir)
			call videm#tmux#sendMsg("-", a:msg)
			call videm#tmux#sendClr("-")
		else
			call videm#tmux#sendMsg("-", "cd " . b:curPos)
			call videm#tmux#sendMsg("-", "export VIDEM_MAIN=" . $VIDEM_MAIN)
			call videm#tmux#sendClr("-")
			call videm#bmark#addHistDir(simplify(b:curPos))
		endif
	endif
endfunction
"}}}

func! s:HiExUpDir()
	let updir = substitute(b:curPos, '.[^/]*\/$', '/', "g")
	call videm#main#select(0, updir, 0)
endf

function! s:WriteCacheFile()
	let l:keyArray = []
	let l:valArray = []
	for key in keys(s:ruc)
		call add(l:keyArray, key)
		call add(l:valArray, join(s:ruc[key]))
	endfor
	call writefile(l:keyArray, s:cacheIdx)
	call writefile(l:valArray, s:cacheDat)
endfunction

function! s:HiExReadCacheFile()
	if getftype(s:cacheIdx) != "file" || getftype(s:cacheDat) != "file"
		return
	endif
	let l:keyArray = readfile(s:cacheIdx)
	let l:valArray = readfile(s:cacheDat)
	let idx = 0
	for key in l:keyArray
		call extend(s:ruc, {key : split(l:valArray[idx])})
		let idx = idx + 1
	endfor
endfunction


function! s:GoPre()
	try
		if len(b:dirList) <= 0
			call videm#main#select(0, b:prePos, 0)
		else
			while b:dirList[-1] == b:curPos
				call remove(b:dirList, -1)
			endwhile
			call videm#main#select(0, remove(b:dirList, -1), 0)
			call remove(b:dirList,-1)
		endif
	catch
		return
	endtry
endfunction

function! s:CreateFile()
	let inputStr = input("NewFile:", "" )
	if strlen(inputStr ) == 0
		return
	endif
	let inputStr = fnameescape(substitute(inputStr, '^>', '', ''))
	call videm#tmux#sendMsg($VIDEM_MAIN, videm#tmux#openFile("-") . b:curPos . inputStr)
	call videm#tmux#selectPane($VIDEM_MAIN)
endfunction

function! s:HiExMkDir()
	let inputStr = input("NewDir:", "" )
	if strlen(inputStr) == 0
		echo "inputStr is invalid"
		return
	endif
	exec "cd " . b:curPos
	let inputStr = fnameescape(substitute(inputStr, '^>', '', ''))
	let inputStr = fnamemodify(inputStr, ":p")
	if getftype(inputStr) != ""
		echo inputStr ." is already exist"
		return
	endif
	try
		call mkdir(inputStr)
	catch
		echo "failed to create dir"
	endtry
	call s:Reload()
endfunction

function! s:HiExDateSub(str)
	let datestr = system("date +%Y%m%d")
	return substitute(a:str, '%t', videm#string#stripLF(datestr), "g")
endfunction

"flg: rm, mv, cp, rename
function! s:FileOpeFunc(flg)
	let l:ent = expand("<cfile>")
	let l:from = b:curPos . l:ent
	let l:ftype = getftype(l:from)

	if a:flg == "rename"
		let l:inputStr = input("Rename:", "" )
		if strlen(l:inputStr ) == 0
			return
		endif
		let l:inputStr = s:HiExDateSub(l:inputStr)
		echo l:inputStr
		let l:newname = b:curPos . l:inputStr
		call system("mv " . l:from ." ". l:newname)
	elseif a:flg == "rm" || (a:flg == "mv" && b:curPos == g:HiExTrushBin . "/")
		"Delete Item
		if a:flg == "rm"
			let l:confRet = confirm("Delete: " . l:ent  , "&Yes\n&No", 1)
			if l:confRet > 1
				return
			endif
		endif
		call system("rm -r " . l:from)
	else
		"Move or Copy
		if s:HiExCheckTrush() != 0
			return 0
		endif

		"check same name in TrushBin
		let l:to = fnamemodify(g:HiExTrushBin, ":p") . l:ent
		let l:chkname = substitute(l:to, "/$", "", "g")
		if strlen(getftype(l:chkname)) != 0 
			call system("mv " . l:chkname . " " . l:chkname .".". reltimestr(reltime()))
		endif

		if a:flg == "mv"
			call system("mv " . l:from . " " . l:to)
		else
			call system("cp -r " . l:from . " " . l:to)
		endif
	endif
	let np = getpos(".")
	call s:Reload()
	call setpos(".", np)
endfunction

function! s:HiExCheckTrush()
	if isdirectory(g:HiExTrushBin) == 0
		call mkdir(g:HiExTrushBin)
	endif
	return 0
endfunction

func! VidemSelectMark(flg)
	if b:videm_mark_dir != b:curPos
		let b:videm_mark_dic = {}
	endif
	let diclen = len(b:videm_mark_dic)
	if diclen <= 0 || getline('.') !~ '\s%$'
		call videm#main#select(a:flg, "-", 0)
		return
	endif
	let cnt = 0
	for key in keys(b:videm_mark_dic)
		if search(key, 'cw') > 0
			let ret = videm#main#select(a:flg, "-", 1)
			if ret < 0
				return
			elseif ret == 1
				call videm#tmux#vimWaitOpen()
			endif
			let cnt += 1
		endif
	endfor
endf

func! s:AddSelectList(flg)
	if a:flg == "cp" || a:flg == "mv"
		cal add(s:selected_list, expand("<cfile>"))
	endif
endf

func! s:FileOpe(flg)
	let s:selected_list = []
    if b:videm_mark_dir != b:curPos
        let b:videm_mark_dic = {}
    endif
    let diclen = len(b:videm_mark_dic)
    if diclen <= 0
        cal s:FileOpeFunc(a:flg)
		cal s:AddSelectList(a:flg)
        return
    endif
    let cnt = 0
    for key in keys(b:videm_mark_dic)
        if search(key, 'cw') > 0
			cal s:AddSelectList(a:flg)
            cal s:FileOpeFunc(a:flg)
            let cnt += 1
        endif
    endfor
    let s:videm_yank_num = cnt
endf

func! s:Paste(isCopy)
	let diclen = len(b:videm_mark_dic)
	for fname in s:selected_list
		echo g:HiExTrushBin . fname
		cal s:PasteFunc(fname, a:isCopy, 0)
	endfor
	if a:isCopy == 0
		let s:videm_yank_num = 0
		let s:selected_list = []
	endif
endf

function! s:PasteFunc(fname, isCopy, cnt)
	if s:HiExCheckTrush() != 0
		return
	endif
	let l:from = fnamemodify(g:HiExTrushBin, ":p") . a:fname
	if a:cnt == 0
		let l:to   = b:curPos . a:fname
	else 
		let l:to   = b:curPos . a:fname . "." . a:cnt
	endif
	if strlen(getftype(l:to)) != 0
		if a:cnt == 0
			let l:confRet = confirm("Overwrite ?: " . l:from  , "&Yes\n&No", 1)
		else
			let l:confRet = 2
		endif
		if l:confRet > 1
			"Rename
			let newcnt = a:cnt + 1
			call s:PasteFunc(a:fname, a:isCopy, newcnt)
			return
		endif
	endif
	if a:isCopy == 0
		call system("mv ". l:from ." ". l:to)
	else
		call system("cp -r ". l:from ." ". l:to)
	endif
	call s:Reload()
	call search(a:fname, "wc")
endfunction

function! HiExReloadFiles()
	call videm#prj#loadFile()
	call videm#bmark#load()
	echo ""
endfunction

function! s:HiExTabSetTitle()
	let msg = input("Title:", "" )
	if strlen(msg) == 0
		return
	endif
	let s:tabTitle[tabpagenr()] = msg
	call videm#main#setStatusLine(tabpagenr())
	echo ""
endfunction

func! videm#main#setStatusLine(num)
	exe "set statusline=[". a:num .']\ '.s:tabTitle[a:num] ."%=". 
				\ videm#prj#name()
endf

func! HiExSetSubP(subpid, id)
	let s:winlist[a:subpid] = a:id
	echo ""
endf

func! videm#main#cal()
	let winNum = videm#main#getWinNum('cal')
	if winNum != ""
		cal videm#tmux#sendMsg(winNum, ":qa!")
		return
	endif
	call videm#tmux#splitWin($TMUX_PANE, g:HiExCalWinHeight, "export VIDEM_NAVI=". $TMUX_PANE .
				\" && export VIDEM_MAIN=". $VIDEM_MAIN .
				\" && vim -c \"cal videm#cal#display()\"")
	echo ''
endf

func! videm#main#waitVimOpen()
	if videm#tmux#checkVim() == 0
		call videm#tmux#sendMsg($VIDEM_MAIN, "vim")
		while videm#tmux#checkVim() == 0
			"busy loop
		endwhile
	endif
endf

function! s:VidemMenu(msg)
	if len($VIDEM_NAVI) <= 0
		return
	endif
	if s:HiExNaviIsHide()
		call videm#tmux#sendCtrlC($VIDEM_NAVI)
		call videm#tmux#sendMsg($VIDEM_NAVI, ":VidemToggleWin")
	endif
	call videm#tmux#sendMsgNR($VIDEM_NAVI, a:msg)
	call videm#tmux#selectPane($VIDEM_NAVI)
endfunction

" Called by Main Window
function! s:HiExToggleNaviWin()
	if len($VIDEM_NAVI) <= 0
		return
	endif
	if s:HiExNaviIsHide()
		call videm#tmux#sendCtrlC($VIDEM_NAVI)
	endif
	call videm#tmux#sendMsg($VIDEM_NAVI, ":VidemToggleWin")
endfunction

function! s:HiExNaviIsHide()
	if len($VIDEM_NAVI) <= 0
		" Called in NAVI window
		if winwidth(0) > 2
			return 0
		endif
		return 1
	endif
	" Called in outside of NAVI window
	let chk = matchstr(system("tmux list-pane 2>&1 | grep '". $VIDEM_NAVI ."$'"), '[2x')
	return len(chk)
endfunction

func! s:HiExHideNavi()
	if strlen(s:hiExPane) <= 0 || strlen($TMUX_PANE) <= 0 || s:hiExPane != $TMUX_PANE
		echo "Use in Videm Navi Window (". $VIDEM_NAVI
		sleep 2
		return
	endif
	let s:navi_hidden = 1 - s:navi_hidden
	if s:navi_hidden == 1
		"Hide Window
		let s:navi_width = (winwidth(1) - 2)
		if s:winlist[s:winName('cal')] != ""
			let s:navi_cal = 1
			call videm#tmux#sendMsg(s:winlist[s:winName('cal')], ":qa!")
			let s:winlist[s:winName('cal')] = ""
		else
			let s:navi_cal = 0
		endif
		call system("tmux resize-pane -t ". $TMUX_PANE ." -R ". s:navi_width)
		call system("tmux select-pane -t ". $VIDEM_MAIN)
		sleep 1000000
	else
		"Open Window
		call system("tmux resize-pane -t ". $TMUX_PANE ." -L ". s:navi_width)
		if s:navi_cal == 1
			call videm#main#cal()
			call system("tmux last-pane")
		endif
	endif
endf

function! s:HiExRefWin()
	let widx = s:winlist[s:winNum('ref')]
	if widx != ""
		"Move to Reference window
		"Check is hidden?
		if s:HiExRefIsHide()
			"Open
			call videm#tmux#sendCtrlC(widx)
			call videm#tmux#sendMsg(widx, ":VidemRefToggle")
		endif
		if videm#tmux#selectPane(widx) < 0
			let widx = ""
		endif
		return
	endif
	try
		call videm#tmux#sendMsg(s:HiExMainPane, ":call VidemRefOpen('".
					\ videm#prj#getVar('CTAGS') ."')")
	catch
		return
	endtry
endfunction

function! s:HiExRefIsHide()
	let chk = matchstr(system("tmux list-pane 2>&1 | grep ". s:winlist[s:winNum('ref')]), '[2x')
	return len(chk)
endfunction

function! s:SetCurPos(cur)
	let b:prePos = b:curPos
	let b:curPos = a:cur
endfunction

function! s:VidemSortType(flg)
	let b:lsFlag = a:flg . ' '
	call s:Reload()
endf

" Tab Commands {{{
func! s:SetTabline()
	if !exists("b:curPos")
		return
	endif
	let l:name = substitute(b:curPos, "^" . $HOME, "~", "")
	call videm#main#setStatusLine(tabpagenr())
	exe "set tabline=" . l:name
endf

func! videm#main#setTabLine()
	if !exists("b:curPos")
		return
	endif
	let l:name = substitute(b:curPos, "^" . $HOME, "~", "")
	call videm#main#setStatusLine(tabpagenr())
	exe "set tabline=" . l:name
endf


func! videm#main#tabNew()
	cal add(s:tabTitle,"")
	exe "tabl"
	exe "tabe"
	cal videm#main#start()
endf

func! videm#main#tabCloseAll()
	while 1
		try
			execute "tabc"
		catch
			let s:tabTitle = ["",""]
			return
		endtry
	endwhile
endf

func! videm#main#tabTListClear()
	let s:tabTitle    = ["",""]
endf

func! videm#main#tabTListSet(idx, name)
	let s:tabTitle[a:idx] = a:name
endf

func! videm#main#tabTListGet(idx)
	return s:tabTitle[a:idx]
endf

function! s:HiExTabMenu()
	exec "new"
	inoremap <silent><buffer> <CR> <ESC>:call HiExTabMenuCR()<CR>
	inoremap <silent><buffer> w <ESC>:call <SID>HiExMenuClose()<CR>
	call s:HiExMenuInit("Select")
endfunction

function! HiExTabMenuCR()
	let msg=getline(".")
	let tabnr = substitute(msg, '^\[\([0-9]\+\)\].*', '\1', "")
	call s:HiExMenuClose()
	let cnt = 0
	if tabnr == ""
		echo ""
		return
	endif
	while tabnr != tabpagenr()
		exec "tabN"
		let cnt += 1
		if cnt > 100
			return
		endif
	endwhile
endfunction

func! videm#main#tabMv(flg)
	let nowtab = tabpagenr()
	let nowtabTitle = s:tabTitle[nowtab]
	if a:flg == "next"
		if nowtab < len(s:tabTitle) - 1
			exec "tabm ". nowtab
		else
			exec "tabm 0"
		endif
	elseif a:flg == "prev"
		if nowtab > 1
			exec "tabm ". (nowtab - 2)
		else  
			exec "tabm"
		endif
	endif
	call remove(s:tabTitle, nowtab)
	let newtab = tabpagenr()
	call insert(s:tabTitle, nowtabTitle, newtab)
	call videm#main#setStatusLine(tabpagenr())
endf

func! s:HiExTabClose()
	let removeTabIdx = tabpagenr()
	try
		exe "tabc"
	catch
		return
	endtry
	exe "tabN"
	call remove(s:tabTitle, removeTabIdx)
endf

func! HiExTabMenuShow()
	let tabNameList = []
	let cnt = 0
	for i in s:tabTitle
		if cnt == 0
			let cnt += 1
			continue
		endif
		cal add(tabNameList,  "[". cnt . "] ". s:tabTitle[cnt])
		let cnt += 1
	endfor
	cal complete(col('.'), tabNameList)
	return ''
endf

"}}}

func! s:HiTest()
	echo s:selected_list
	sleep 3
endf
