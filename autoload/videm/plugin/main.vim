" Menu-Plugin 'main'

if !has_key(g:VidemMenuPluginItems, 'main')
	let g:VidemMenuPluginItems['main'] =
				\ ["Project-Files", "Calendar", "Help", "Quit"]
endif

func! MenuPrjFilesFunc(flg)
	cal videm#prj#open()
endf

func! MenuCalendarFunc(flg)
	cal videm#main#cal()
	"{{{
	"let winNum = videm#main#getWinNum('cal')
	"if winNum != ""
	"	cal videm#tmux#sendMsg(winNum, ":qa!")
	"	return
	"endif
	"call videm#tmux#splitWin($TMUX_PANE, g:HiExCalWinHeight, "export VIDEM_NAVI=". $TMUX_PANE .
	"			\" && export VIDEM_MAIN=". $VIDEM_MAIN .
	"			\" && vim -c \"cal videm#cal#display()\"")
	"echo ''
	"}}}
endf
func! MenuQuitFunc(flg)
	cal videm#main#close()
endf
func! MenuHelpFunc(flg)
	cal videm#main#select(0, g:HiExHelpFile, 0)
endf

func! MenuMakeFunc(flg)
	if a:flg == 0
		cal videm#main#waitVimOpen()
		cal videm#tmux#sendMsg(s:HiExMainPane, videm#tmux#moveDir() .
					\ videm#prj#getVar('MAKE')
		cal videm#tmux#sendMsg($VIDEM_MAIN, "^[:make")
		cal videm#tmux#selectPane($VIDEM_MAIN)
	elseif a:flg == 1
		cal videm#prj#setVar('MAKE', input("", b:curPos))
		echo ""
	endif
endf

func! MenuBmarkFunc(flg)
	cal videm#bmark#open()
endf

func! MenuPrjFunc(flg)
	cal videm#menu#callMenu('prj')
endf

func! MenuNaviFunc(flg)
	cal videm#menu#callMenu('tab')
endf


func! MenuRefFunc(flg)
	if videm#tmux#checkVim() == 0
		return
	endif
	call s:HiExRefWin()
endf

let MenuPrjFiles = function("MenuPrjFilesFunc")
let MenuCalendar = function("MenuCalendarFunc")
let MenuQuit     = function("MenuQuitFunc")
let MenuHelp     = function("MenuHelpFunc")
let MenuMake     = function("MenuMakeFunc")
let MenuBmark    = function("MenuBmarkFunc")
let MenuPrj      = function("MenuPrjFunc")
let MenuNavi     = function("MenuNaviFunc")

let MenuItems = { "Project-Files":MenuPrjFiles, "Calendar":MenuCalendar, "Quit":MenuQuit,
			\ "Help":MenuHelp}

let MenuObject = ["Menu", "MM", MenuItems]

cal videm#menu#addMenu("main", MenuObject)
