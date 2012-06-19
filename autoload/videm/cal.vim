let s:wdayTitlesJP = ["日","月","火","水","木","金","土"]
let s:wdayTitlesCN = ["天","一","二","三","四","五","六"]
let s:wdayTitlesEN = ["Su","Mo","Tu","We","Th","Fr","Sa"]
let s:calDict = {}

" Today Data
let s:tyear=1970
let s:tmon =1
let s:tday =1

" Current Data
let s:year=1970
let s:mon =1
let s:day =1

let s:useTabTitle = 0

func videm#cal#useTabLine(num)
	let s:useTabTitle = a:num
endf

func videm#cal#display(...)
	"For VIDEM
	if $VIDEM_NAVI != ""
		cal videm#main#regWin('cal')
		auto VimLeave * :cal <SID>Close()
	endif
	"End

	let s:tyear = strftime('%Y')
	let s:tmon  = matchstr(strftime('%m'), '[^0].*')
	let s:tday  = matchstr(strftime('%d'), '[^0].*')
	let s:year = s:tyear
	let s:mon  = s:tmon
	let s:day  = s:tday
	if a:0 == 1
		let s:day  = matchstr(a:1, '[^0].*')
	elseif a:0 == 2
		let s:day  = matchstr(a:1, '[^0].*')
		let s:mon  = matchstr(a:2, '[^0].*')
	elseif a:0 == 3
		let s:day  = matchstr(a:1, '[^0].*')
		let s:mon  = matchstr(a:2, '[^0].*')
		let s:year = matchstr(a:3, '[^0].*')
	elseif a:0 > 3
		return
	endif

	set nowrap
	nno <silent><buffer> <C-n>	:cal <SID>NextMon()<CR>
	nno <silent><buffer> <C-p>	:cal <SID>PrevMon()<CR>
	nno <silent><buffer> q		:qa!<CR>
	auto VimResized * :cal <SID>Reload()

	cal s:SetHilight()
	cal s:Reload()
endf

func! s:Close()
	cal videm#main#clrWin('cal')
endf

func! s:Reload()
	setl modifiable
	exe "%delete"
	cal s:BulidCal(s:year, s:mon)
	setl nomodifiable
	cal s:MoveToday()
	norm! 10
endf

func s:SetHilight()
	hi VidemCalToday     ctermfg=3 ctermbg=24
	hi VidemCalHolyday   ctermfg=167
	hi VidemCalWDayTitle ctermfg=12
	hi VidemCalDateTitle ctermbg=5 ctermfg=3 

	hi TabLineFill ctermfg=5 ctermbg=3

	let adj = (winwidth(0) - 20) / 2 + 1
	let adj2 = adj + 1
	if s:tyear == s:year && s:tmon == s:mon
		if s:tday < 10
			exe "syn match VidemCalToday '". '\s\@<=\s'. 
						\ s:tday .'\s\@=' . "'"
		else
			exe "syn match VidemCalToday '". '\s\@<='.
						\ s:tday .'\s\@=' . "'"
		endif
	endif
	exe "syn match VidemCalHolyday '". '\%(^\s\{'. adj .
				\ '}.\{18}\)\@<=\s*\d\{1,2}' ."' contains=ALL"
	exe "syn match VidemCalHolyday '". '^\s\{'. adj .','.
				\ adj2 .'}\d\+' . "' contains=ALL"
endf

func! s:GetWdayTitle()
	if !exists("g:wdayTitlesLang")
		retu s:wdayTitlesJP
	endif g:wdayTitlesLang == 'EN'
		retu s:wdayTitlesEN
	elseif g:wdayTitlesLang == 'CN'
		retu s:wdayTitlesCN
	endif
	retu s:wdayTitlesJP
endf

func! s:BulidCal(year, mon)
	cal cursor(1,1)
	let dp = ""
	let wdayTitleList = s:GetWdayTitle()
	let wdayTitle = join(wdayTitleList, ' ')
	exe "syn match VidemCalWDayTitle '". wdayTitle ."'"
	let adjs = repeat(" ", (winwidth(0) - 20) / 2)
	let dp =  adjs ." ". wdayTitle
	put =dp
	let lday  = s:GetLastDate(a:year, a:mon)
	let wday = s:GetWDay(a:year, a:mon, 1)
	let day = 1
	let dp =  repeat('   ', wday)
	while day <= lday
		if day < 10
			let dp .= '  '. day
		else
			let dp .= ' '. day
		endif
		let day  += 1
		let wday += 1
		if (wday % 7) == 0
			let wday = 0
			let dp = adjs . dp
			put =dp
			let dp = ""
		endif
	endwhile
	if strlen(dp)
		let dp = adjs . dp
		put =dp
	endif

	let dateTitle = "<". a:year ."年". a:mon . "月>"
	let pad =(winwidth(0) - videm#string#getDispLen(dateTitle))/2 + 2
	if s:useTabTitle == 0
		let pads = repeat(" ", pad)
		cal setline(1, pads . dateTitle . pads)
		syn match VidemCalDateTitle '^\s\+<.\+>\s\+$'
	else
		let pads = repeat('\ ', pad)
		let tabTitle= pads . dateTitle
		exe "set tabline=" . tabTitle
		set showtabline=2
	endif
endf

func! s:GetLastDate(year, mon)
	if a:mon == 2
		if a:year % 4==0
			if (a:year % 100) == 0 && (a:year % 400) != 0
				retu 28
			else 
				retu 29 
			endif
		else
			return 28
		endif
	elseif a:mon == 4 || a:mon == 6 || 
				\ a:mon==9 || a:mon == 11
		retu 30
	else 
		retu 31
	endif
endf

func! s:GetWDay(year, mon, day)
	let yu = matchstr(a:year, '^\d\{2}')
	let yl = matchstr(a:year, '\d\{2}$')
	if a:mon < 2
		let m = a:mon + 12
	else
		let m = a:mon
	endif
	return (a:day + (26*(m + 1))/10 + yl + (yu/4) + (yl/4) + (yu*5) - 1) % 7
endf

func! s:MoveToday()
	if s:mon != s:tmon || s:year != s:tyear
		exec 'syn clear VidemCalToday'
		cal search(' 1 ', "cw")
		cal cursor(line('.') + 1, col('.'))
	elseif s:tday < 10
		cal search('\s\@<=\s'. s:tday .'\s\@=' , 'cwe')
	else
		cal search('\s\@<='.   s:tday .'\s\@=' , 'cwe')
	endif
	norm! 10<C-y>
endf

function! s:NextMon()
    let s:mon += 1
    if s:mon > 12
        let s:mon   = 1
        let s:year += 1
    endif
	cal s:Reload()
endfunction

function! s:PrevMon()
    let s:mon -= 1
    if s:mon < 1
        let s:mon   = 12
        let s:year -= 1
    endif
	cal s:Reload()
endfunction
