" Menu-Plugin 'prj-sel'(Project-Selecting)

func! MenuPrjSelEvalFunc(msg, flg)
	cal videm#prj#openPrj(a:msg)
endf

func! MenuPrjSelSrcFunc()
	retu videm#prj#getPrjNameList()
endfunc

let MenuPrjSelEval = function("MenuPrjSelEvalFunc")
let MenuPrjSelSrc  = function("MenuPrjSelSrcFunc")

let MenuItems  = {"@Evaluation":MenuPrjSelEval, '@Source':MenuPrjSelSrc}
let MenuObject = ["Open_Project", "mP", MenuItems]

cal videm#menu#addMenu("prj-sel", MenuObject)
