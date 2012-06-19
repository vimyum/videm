"=============================================================================
" What Is This: VIDEm (IDE with Vim and Tmux)
" File: autoload/videm/prj.vim
" Author: Sagara Takahiro <vimyum@gmail.com>
"=============================================================================
if exists("g:loaded_videm_menu_auto") || &cp
	finish
endif
let g:loaded_videm_menu_auto = 1
let s:menuTitle = "Menu"
let s:menuSub = 0

let g:VidemMenuPluginDir=get(g:, 'VidemMenuPluginDir', $HOME .'/.vim/autoload/videm/plugin/')
let g:VidemMenuPluginItems = {}

let s:menuItems = {}
let s:menuNum = 0
let s:errorMsg = "--Error--"

"<Menu Object>
"  0: Display Name
"  1: Short Curt ('-' indicates no shortcut)
"  2: Function Dictionary
"  3: MenuID (internal used only)

func! videm#menu#setup()
	"Read Plugin with Source
	let pfiles = split(glob(g:VidemMenuPluginDir .'*.vim'),'\n')
	for i in pfiles
		exe 'source '. expand(i)
	endfor
	for i in keys(s:menuItems)
		let item = s:menuItems[i]
		exe 'nno <silent> MS'. item[3] .' :cal videm#menu#open("'. i .
					\ '")<CR>:<BS><C-R>=videm#menu#show("'. i .'")<CR>'
		if strlen(item[i]) <= 0
			continue
		endif
		exe 'nno <silent> '. item[1]  .' :cal videm#menu#open("'. i .
					\ '")<CR>:<BS><C-R>=videm#menu#show("'. i .'")<CR>'
	endfor
endf

func! videm#menu#callMenu(name)
	cal videm#tmux#sendMsgNR("-", 'MS'. s:menuItems[a:name][3])
endf

func! videm#menu#addMenu(name, obj)
	let obj = copy(a:obj)
	let s:menuNum += 1
	let menuID = videm#string#getDFStr(s:menuNum)
	cal add(obj, menuID)
	let s:menuItems[a:name] = obj
	if !has_key(g:VidemMenuPluginItems, a:name)
		return
	endif
	for i in g:VidemMenuPluginItems[a:name]
		if !has_key(obj[2], i)
			cal input('Menu item unmatch with plugin "'. a:name .'"')
			exe 'qa!'
		endif
	endfor
endf

func! videm#menu#open(name)
	let item = s:menuItems[a:name]
	if has_key(item[2], '@Initialize')
		cal call(item[2]['@Initialize'], [])
	endif
	exe 'new'
	exe 'ino <silent><buffer> <CR> <ESC>:cal videm#menu#select("'.
				\ a:name . '", 0)<CR>'
	exe 'ino <silent><buffer> <Space> <ESC>:cal videm#menu#select("'.
				\ a:name . '", 1)<CR>'
	exe 'ino <silent><buffer> c    <ESC>:cal videm#menu#select("'.
				\ a:name . '", 2)<CR>'
	ino <silent><buffer> m <ESC>:cal videm#menu#close()<CR>
	ino <silent><buffer> q <ESC>:cal videm#menu#close()<CR>
	inoremap <buffer> j <C-N>
	inoremap <buffer> k <C-P>
	inoremap <silent><buffer> q <ESC>:call videm#menu#close()<CR>

	exe "set tabline=". item[0]
	exe "hi TabLineFill " . g:VidemMenuColor
	exe "hi StatusLineNC ". g:VidemStatusColor
	exe "hi StatusLine "  . g:VidemMenuLineColor
	exe "res 1"
	exe "star"
endf

func videm#menu#select(name, flg)
	let msg=getline(".")
	call videm#menu#close()
	let funcDict = s:menuItems[a:name][2]
	if msg == s:errorMsg
		echo ""
	elseif has_key(funcDict, '@Evaluation')
		cal call(funcDict['@Evaluation'], [msg, a:flg])
	elseif has_key(funcDict, msg)
		cal call(funcDict[msg], [a:flg])
	endif
	if has_key(funcDict, '@CleanUp')
		cal call(funcDict['@CleanUp'], flg)
	endif
endf

func! videm#menu#show(name)
	let funcDict = s:menuItems[a:name][2]
	if has_key(funcDict, '@Source')
		let srclist = call(funcDict['@Source'], [])
		if len(srclist) > 0
			cal complete(col('.'), srclist)
		else
			cal complete(col('.'), [s:errorMsg])
		endif
	elseif has_key(g:VidemMenuPluginItems, a:name)
		cal complete(col('.'), g:VidemMenuPluginItems[a:name])
	else
		cal complete(col('.'), keys(funcDict))
	endif
	return ''
endf

function! videm#menu#close()
	exe "hi TabLineFill ".  g:VidemMenuColor
	exe "hi StatusLineNC ". g:VidemMenuLineColor
	exe "hi StatusLine ".   g:VidemStatusColor
	exe "quit!"
	cal videm#main#setTabLine()
endfunction

"{{{
"function! HiExGenMenuCR(flg) "flg 0:select, 1:config
"	let msg=getline(".")
"	call videm#menu#close()
"
"	if msg == "Make"
"		if a:flg == 0
"			cal s:HiExWaitVimOpen()
"			cal videm#tmux#sendMsg(s:HiExMainPane, videm#tmux#moveDir() .
"						\ videm#prj#getVar('MAKE')
"			cal videm#tmux#sendMsg($VIDEM_MAIN, ":make")
"			cal videm#tmux#selectPane($VIDEM_MAIN)
"		elseif a:flg == 1
"			cal videm#prj#setVar('MAKE', input("", b:curPos))
"			echo ""
"		endif
"
"	elseif msg == "Project Files"
"		call videm#prj#open()
"
"	elseif msg == "Bookmarks"
"		call s:HiExBmkWin()
"
"	elseif msg == "Code Viewer"
"		if videm#tmux#checkVim() == 0
"			return
"		endif
"		call s:HiExRefWin()
"		
"	elseif msg == "Wiki"
"		if a:flg == 0
"			call videm#main#select(0, videm#prj#getVar('MEMO'), 0)
"		elseif a:flg == 1
"			cal videm#prj#setVar('MEMO', input("File:", videm#prj#getVar('MEMO')))
"			echo ""
"		endif
"
"	elseif msg == "Calendar"
"		call s:HiCalOpen()
"
"	elseif msg == "Mailer"
"		echo "make"
"		sleep 1
"
"	elseif msg == "Projects"
"		let s:menuTitle = "Project_Menu"
"		let s:menuSub = 1
"		call videm#tmux#sendMsgNR("-", "MS1")
"		return
"		
"	elseif msg == "Navi"
"		let s:menuTitle = "Navi_Menu"
"		let s:menuSub = 2
"		call videm#tmux#sendMsgNR("-", "MS2")
"		return
"
"	elseif s:menuSub == 1 && msg == "Open"
"		call videm#tmux#sendMsgNR("-", "MSP")
"
"	elseif s:menuSub == 1 && msg == "Save"
"		call videm#prj#saveFile()
"
"	elseif s:menuSub == 1 && msg == "New"
"		call videm#prj#new()
"
"	elseif s:menuSub == 2 && msg == "Select"
"		call videm#tmux#sendMsgNR("-", "MSW")
"
"	elseif s:menuSub == 2 && msg == "New"
"		call s:HiExTabNew()
"
"	elseif s:menuSub == 2 && msg == "Rename"
"		call s:HiExTabSetTitle()
"
"	elseif s:menuSub == 2 && msg == "Move Next"
"		call s:HiExTabMv("next")
"
"	elseif s:menuSub == 2 && msg == "Move Prev"
"		call s:HiExTabMv("prev")
"
"	elseif s:menuSub == 2 && msg == "Delete"
"		call s:HiExTabClose()
"
"	elseif msg == "Todo"
"		echo "make"
"		sleep 1
"
"	elseif msg == "Quit"
"		call s:VidemClose()
"
"	elseif msg == "Config"
"		echo "make"
"		sleep 1
"	elseif msg == "Help"
"		call videm#main#select(0, g:HiExHelpFile, 0)
"	endif
"	let s:menuSub = 0
"endfunction
"}}}
"
""{{{
"function! s:Init(title)
"	inoremap <buffer> j <C-N>
"	inoremap <buffer> k <C-P>
"	inoremap <silent><buffer> q <ESC>:call videm#menu#close()<CR>
"	exe "set tabline=". a:title
"	"exe "hi TabLineFill " . g:HiExMenuColor
"	exe "hi TabLineFill ctermfg=3 ctermbg=5"
"	exe "hi StatusLineNC ". g:HiExStatusColor
"	exe "hi StatusLine "  . g:HiExMenuBorderColor
"	exe "res 1"
"	exe "star"
"endfunction
""}}}
"
