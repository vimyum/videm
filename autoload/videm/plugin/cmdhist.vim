" Menu-Plugin 'cmdhist'

let g:VidemPG_CmdHist=get(g:, 'VidemPG_CmdHist', $HOME .'/.bash_history')

func! MenuCmdhistInitFunc()
	if filereadable(g:VidemPG_CmdHist) <= 0
		echo g:VidemPG_CmdHist
		echo input('History file is not readable.','')
		sleep 1
	end
		echo g:VidemPG_CmdHist
		sleep 1
endf

func! MenuCmdhistEvalFunc(msg, flg)
    if a:flg == 0
        call videm#main#newWin(2, a:msg)
    elseif a:flg == 1
        let name = input("Name:", matchstr(a:msg, '\S*\s'))
        let dir  = b:curPos
        cal videm#prj#addVar('CMD_L', {"abbr":name, "dir":dir, "word":a:msg})
    endif
endf

func! MenuCmdhistSrcFunc()
    let tmpf = tempname()
    call system("tail -200 $HOME/.bash_history | sed 's/^:.*;//' | egrep '" .
                \ g:HiExZshKeywords ."' | tail -". g:HiExZshKeyNum ." > ". tmpf)
    let histList = readfile(tmpf)
    call delete(tmpf)
	return histList
endfunc

let MenuCmdhistInit = function("MenuCmdhistInitFunc")
let MenuCmdhistEval = function("MenuCmdhistEvalFunc")
let MenuCmdhistSrc  = function("MenuCmdhistSrcFunc")

let MenuItems  = {"@Initialize":MenuCmdhistInit, "@Evaluation":MenuCmdhistEval, '@Source':MenuCmdhistSrc}
let MenuObject = ["Cmd_History", "mw", MenuItems]

cal videm#menu#addMenu("cmdhist", MenuObject)
