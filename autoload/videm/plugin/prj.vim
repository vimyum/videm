" Menu-Plugin 'prj-main'

if !has_key(g:VidemMenuPluginItems, 'prj-main')
	let g:VidemMenuPluginItems['prj-main'] =
				\ ["Open", "New", "Copy", "Delete", "List", "Save"]
endif

func! MenuPrjOpenFunc(flg)
	cal videm#menu#callMenu("prj-sel")
endf
func! MenuPrjNewFunc(flg)
	cal videm#prj#new()
endf
func! MenuPrjCopyFunc(flg)
	cal videm#prj#copy()
endf
func! MenuPrjDeleteFunc(flg)
	cal videm#prj#delete()
endf
func! MenuPrjListFunc(flg)
	cal videm#prj#list()
endf
func! MenuPrjSaveFunc(flg)
	cal videm#prj#saveFile()
endf

let MenuPrjOpen   = function("MenuPrjOpenFunc")
let MenuPrjNew    = function("MenuPrjNewFunc")
let MenuPrjCopy   = function("MenuPrjCopyFunc")
let MenuPrjDelete = function("MenuPrjDeleteFunc")
let MenuPrjList   = function("MenuPrjListFunc")
let MenuPrjSave   = function("MenuPrjSaveFunc")

let MenuPrjItems = { "Open":MenuPrjOpen, "New":MenuPrjNew, "Copy":MenuPrjCopy,
			\ "List":MenuPrjList, "Delete":MenuPrjDelete, "Save":MenuPrjSave}

let MenuObject = ["ProjectMenu", "mp", MenuPrjItems]

cal videm#menu#addMenu("prj-main", MenuObject)
