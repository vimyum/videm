" Menu-Plugin 'tab'

if !has_key(g:VidemMenuPluginItems, 'tab')
	let g:VidemMenuPluginItems['tab'] = ["Move Next","Move Prev","New"]
endif

func! MenuTabNewFunc(flg)
	cal videm#main#tabNew()
endf
func! MenuTabMvNextFunc(flg)
	cal videm#main#tabMv("next")
endf
func! MenuTabMvPrevFunc(flg)
	cal videm#main#tabMv("prev")
endf
func! MenuTabTestFunc(flg)
	echo "This is tab menu"
endf

let MenuTabNew    = function("MenuTabNewFunc")
let MenuTabMvNext = function("MenuTabMvNextFunc")
let MenuTabMvPrev = function("MenuTabMvPrevFunc")
let MenuTabTest   = function("MenuTabTestFunc")

let MenuTabItems = {"New":MenuTabNew, "Move Next":MenuTabMvNext, "Move Prev":MenuTabMvPrev, "test":MenuTabTest }
let MenuObject = ["TabMenu", "mt", MenuTabItems]

cal videm#menu#addMenu("tab", MenuObject)
