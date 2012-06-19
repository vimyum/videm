"=============================================================================
" What Is This: VIDEm (IDE with Vim and Tmux)
" File: videm.vim
" Author: Sagara Takahiro <vimyum@gmail.com>
" Last Change: 
" Version: 1.0a
" Usage:
"
" ChangeLog:
" 
" Additional:
"=============================================================================

if exists("loaded_hiexplore")
	finish
endif
let loaded_hiexplore = 1

if !exists("g:VidemHistFile")
	let g:VidemBmarks  = $HOME ."/.HiExHist"
endif
if !exists("g:VidemHistNum")
	let g:VidemHistNum    = 5
endif
if !exists("g:VidemHistDirNum")
	let g:VidemHistDirNum = 5 
endif
if !exists("g:VidemBmarkNum")
	let g:VidemBmarkNum   = 10 
endif
if !exists("g:VidemBmarkWinHeight")
	let g:VidemBmarkWinHeight= 30
endif
if !exists("g:VidemPrjFile")
	let g:VidemPrjFile    = $HOME ."/.HiExProjects"
endif
if !exists("g:VidemPrjGen")
	let g:VidemPrjGen    = "Generic"
endif

"---------- Tobe Removed -----------
if !exists("g:VidemProjectFile")
	let g:VidemProjectFile    = $HOME ."/.HiExProjects"
endif
if !exists("g:HiExPrjGen")
	let g:HiExPrjGen    = "Generic"
endif
if !exists("g:VidemCacheFile")
	let g:VidemCacheFile = $HOME ."/.HiExCache"
endif
if !exists("g:HiExCacheNum")
	let g:HiExCacheNum   = 4
endif
if !exists("g:HiExDefaultFilter")
	let g:HiExDefaultFilter = "[hc/]$"
endif
if !exists("g:HiExTrushBin")
	let g:HiExTrushBin  = $HOME ."/.Trush"
endif
if !exists("g:HiExWindowName")
	let g:HiExWindowName = "Editing"
endif
if !exists("g:HiExHelpFile")
	let g:HiExHelpFile    = $HOME ."/.vim/doc/videm_help.videm"
endif
if !exists("g:HiExBackupDir")
	let g:HiExBackupDir    = $HOME ."/.backup"
endif
if !exists("g:HiExDirListLen")
	let g:HiExDirListLen    = 10
endif
if !exists("g:HiExZshHist")
	let g:HiExZshHist    = $HOME ."/.zhistory"
endif
if !exists("g:HiExZshKeywords")
	let g:HiExZshKeywords    = "^sudo|^grep|^find|^make|^ns2|^nam|^ctags"
endif
if !exists("g:HiExZshKeyNum")
	let g:HiExZshKeyNum    = 20
endif

"========== Configualbe Color Settings ==========="
if !exists("g:HiExMenuColor")
	let g:HiExMenuColor = "ctermfg=19 ctermbg=3"
endif
if !exists("g:HiExPrjWinHeight")
	let g:HiExPrjWinHeight  = 35
endif
if !exists("g:HiExPrjActFileTitle")
	let g:HiExPrjActFileTitle    = "     <<< Active Files >>>"
endif
if !exists("g:HiExPrjNonActFileTitle")
	let g:HiExPrjNonActFileTitle = "     <<< InActive Files >>>"
endif
if !exists("g:HiExMakWinHeight")
	let g:HiExMakWinHeight  = 20
endif
if !exists("g:HiExCalWinHeight")
	let g:HiExCalWinHeight= 25 
endif
if !exists("g:HiExMakFile")
	let g:HiExMakFile  = $HOME ."/.HiExMark"
endif
if !exists("g:VidemMenuItems") 
	let g:VidemMenuItems = ["Make", "Project Files", "Code Viewer", "Bookmarks",
				\ "Calendar", "Projects", "Navi", "Help", "Quit"]
endif

if !exists("g:VidemSubMenu1Items") 
	let g:VidemSubMenu1Items = ["Open", "New", "Delete", "Save"]
endif

if !exists("g:VidemSubMenu2Items") 
	let g:VidemSubMenu2Items = ["Select", "New", "Delete", "Move Next", "Move Prev", "Rename"]
endif

if !exists("g:VidemSortMenu") 
	let g:VidemSortMenuItem = ["Name", "Size", "Tiem", "R-Name", "R-Size", "R-Time"]
endif

" Auto Command for Every File {{{
autocmd VimEnter *      :call <SID>VidemEnterCheck()
autocmd VimLeave *      :call <SID>VidemLeaveCheck()

func! s:VidemEnterCheck()
	if strlen($TMUX_PANE) > 0 && strlen($VIDEM_MAIN) && $TMUX_PANE == $VIDEM_MAIN
		"let s:orgName = system("tmux list-windows | grep '(active)$' | cut -d\" \" -f2")
		"let s:orgName = videm#string#stripLF(s:orgWindowName)
		let s:orgName = videm#tmux#getActivePaneName()
		call videm#tmux#renameWin("-", g:HiExWindowName)
		autocmd SwapExists * let v:swapchoice = 'o'
	endif
endf
	
func! s:VidemLeaveCheck()
	if strlen($VIDEM_MAIN) > 0 && strlen($TMUX_PANE) > 0 && $VIDEM_MAIN == $TMUX_PANE
		call videm#tmux#renameWin("-", s:orgName)
	endif
endf
"}}}

com! Videm :call videm#main#start()
command! -nargs=1 VidemMenu       :call <sid>VidemMenu(<q-args>)
command! -nargs=0 VidemNaviToggle :call <sid>HiExToggleNaviWin()
command! -nargs=0 VidemToggleWin  :call <sid>HiExHideNavi()

nno Q :qa!<CR>
