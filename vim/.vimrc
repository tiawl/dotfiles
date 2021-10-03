" TODO {{{1

" - buffers menu: test
" - explorer: - test
" - plugins: - undotree
"            - rainbow parenthesis
"            - tag list

" }}}
" Quality of life {{{1

" Vi default options unused
set nocompatible

" allow mouse use
set mouse=a

" view tabulation, end of line and other hidden characters
syntax on
set list
set listchars=tab:≫\ ,eol:.
set fillchars=vert:│,fold:-,eob:∼

" highlight corresponding patterns during a search
if !&hlsearch | set hlsearch | endif
if !&incsearch | set incsearch | endif

" line number
set number

" put the new window right of the current one
set splitright

" put the new window below of the current one
set splitbelow

" tabulation
set tabstop=2 softtabstop=2 expandtab shiftwidth=2 smarttab

" always display the number of changes after a command
set report=0

" disable default shortmessage config
" n       -> show [New] instead of [New File]
" x       -> show [unix] instead of [unix format]
" t and T -> truncate too long messages
" s       -> do not show search keys instructions when search is used
" S       -> do not search counter
" F       -> do not give the file info when editing a file
set shortmess=nxtTsSF

" automatically update a file if it is changed externally
set autoread

" visual autocomplete for command menu
set wildmenu

" give backspace its original power
set backspace=indent,eol,start

" unset blank (empty windows), options (sometimes buggy) and tabpages (unused)
set sessionoptions=buffers,curdir,folds,help,winsize,terminal

" }}}
" Performance {{{1

" draw only when needed
set lazyredraw

" indicates terminal connection, Vim will be faster
set ttyfast

" avoid visual mod lags
set noshowcmd

" }}}
" Status line {{{1

" display status line
set laststatus=2

function! FileName(modified, is_current_win)
  let l:check_current_win = (g:actual_curwin == win_getid())
  if (&modified != a:modified) || (l:check_current_win != a:is_current_win)
    return ''
  endif
  return fnamemodify(bufname('%'), ':.')
endfunction

function! StartLine()
  if g:actual_curwin != win_getid()
    return '───┤'
  endif
  return '━━━┫'
endfunction

function! ComputeStatusLineLength()
  let l:length = winwidth(winnr()) - (len(split('───┤ ', '\zs'))
    \ + len('[') + len(winnr()) + len('] ')
    \ + len(bufnr()) + len (':') + len(fnamemodify(bufname('%'), ':.'))
    \ + len(' [') + len(&ft) + len(']')
    \ + len(' C') + len(virtcol('.'))
    \ + len(' L') + len(line('.')) + len('/') + len(line('$')) + len(' ')
    \ + len(split('├', '\zs')))
  if g:actual_curwin == win_getid()
    let l:length -= len(StartMode()) + len(Mode()) + len(EndMode())
    if v:hlsearch && !empty(s:matches) && (s:matches.total > 0)
      let l:length -= len(IndexedMatch()) + len(Bar()) + len(TotalMatch())
    endif
  endif
  return l:length
endfunction

function! EndLine()
  let l:length = ComputeStatusLineLength()
  if g:actual_curwin != win_getid()
    return '├' . repeat('─', l:length)
  endif
  return '┣' . repeat('━', l:length)
endfunction

if exists('s:modes') | unlet s:modes | endif | const s:modes = {
  \ 'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL',
  \ 'V': 'VISUAL', "\<C-v>": 'VISUAL-BLOCK', 'c': 'COMMAND', 's': 'SELECT',
  \ 'S': 'SELECT-LINE', "\<C-s>": 'SELECT-BLOCK', 't': 'TERMINAL',
  \ 'r': 'PROMPT', '!': 'SHELL',
\ }

function! Mode()
  if g:actual_curwin != win_getid()
    return ''
  endif
  return s:modes[mode()[0]]
endfunction

function! StartMode()
  if g:actual_curwin != win_getid()
    return ''
  endif
  return '['
endfunction

function! EndMode()
  if g:actual_curwin != win_getid()
    return ''
  endif
  return '] '
endfunction

let s:matches = {}

function! IndexedMatch()
  if (g:actual_curwin != win_getid()) || !v:hlsearch
    return ''
  endif
  let s:matches = searchcount(#{ recompute: 1, maxcount: 0, timeout: 0 })
  if empty(s:matches) || (s:matches.total == 0)
    return ''
  endif
  return s:matches.current
endfunction

function! Bar()
  if (g:actual_curwin != win_getid()) || !v:hlsearch
  \ || empty(s:matches) || (s:matches.total == 0)
    return ''
  endif
  return '/'
endfunction

function! TotalMatch()
  if (g:actual_curwin != win_getid()) || !v:hlsearch
  \ || empty(s:matches) || (s:matches.total == 0)
    return ''
  endif
  return s:matches.total . ' '
endfunction

" status line content:
" [winnr] bufnr:filename [filetype] col('.') line('.')/line('$') [mode] matches
function! s:StatusLineData()
  set statusline+=\ [%3*%{winnr()}%0*]\ %3*%{bufnr()}%0*:
                   \%2*%{FileName(v:false,v:true)}%0*
                   \%2*%{FileName(v:false,v:false)}%0*
                   \%4*%{FileName(v:true,v:false)}%0*
                   \%1*%{FileName(v:true,v:true)}%0*
  set statusline+=\ [%3*%{&ft}%0*]
  set statusline+=\ C%3*%{virtcol('.')}%0*
  set statusline+=\ L%3*%{line('.')}%0*/%3*%{line('$')}\ %0*
  set statusline+=%{StartMode()}%3*%{Mode()}%0*%{EndMode()}
  set statusline+=%3*%{IndexedMatch()}%0*%{Bar()}%3*%{TotalMatch()}%0*
endfunction

function! s:StaticLine()
  set statusline=%{StartLine()}
  call s:StatusLineData()
  set statusline+=%{EndLine()}
endfunction

if exists('s:dots') | unlet s:dots | endif | const s:dots = [
\  '˳', '.', '｡', '·', '•', '･', 'º', '°', '˚', '˙',
\ ]

function! s:Wave(start, end)
  let l:wave = ''
  for l:col in range(a:start, a:end - 1)
    let l:wave = l:wave . s:dots[5 + float2nr(5.0 * sin(l:col *
    \ (fmod(0.05 * (s:localtime - s:start_animation) + 1.0, 2.0) - 1.0)))]
  endfor
  return l:wave
endfunction

function! StartWave()
  return s:Wave(0, 4)
endfunction

function! EndWave()
  let l:win_width = winwidth(winnr())
  return s:Wave(l:win_width - ComputeStatusLineLength() - 1, l:win_width)
endfunction

if exists('s:color_spec') | unlet s:color_spec | endif
const s:color_spec = [
  \ 51, 45, 39, 33, 27, 21, 57, 93, 129, 165, 201, 200, 199, 198, 197, 196,
  \ 202, 208, 214, 220, 226, 190, 154, 118, 82, 46, 47, 48, 49, 50
\ ]

function! s:WaveLine(timer_id)
  let s:wavecolor = fmod(s:wavecolor + 0.75, 30.0)
  execute 'highlight User5 term=bold cterm=bold ctermfg='
    \ . s:color_spec[float2nr(floor(s:wavecolor))] . ' ctermbg=' . s:black

  let s:localtime = localtime()
  set statusline=%5*%{StartWave()}%0*
  call s:StatusLineData()
  set statusline+=%5*%{EndWave()}%0*

  if (s:localtime - s:start_animation) > 40
    call timer_pause(s:line_timer, v:true)
    call s:StaticLine()
  endif
endfunction

let s:wavecolor = 0.0
let s:localtime = localtime()
let s:start_animation = s:localtime
call s:StaticLine()

if exists('s:line_timer') | call timer_stop(s:line_timer) | endif
let s:line_timer = timer_start(1000, function('s:WaveLine'), #{ repeat: -1 })
call timer_pause(s:line_timer, v:true)

function! s:AnimateStatusLine()
  let s:wavecolor = 0.0
  let s:start_animation = localtime()
  call timer_pause(s:line_timer, v:false)
endfunction

function! s:RestoreStatusLines(timer_id)
  execute 'highlight StatusLine   term=bold cterm=bold ctermfg=' . s:blue_4
    \  . ' ctermbg=' . s:black . ' |
    \      highlight StatusLineNC term=NONE cterm=NONE ctermfg=' . s:blue_1
    \  . ' ctermbg=' . s:black . ' |
    \      highlight VertSplit    term=NONE cterm=NONE ctermfg=' . s:purple_2
    \  . ' ctermbg=' . s:black
endfunction

function! s:HighlightStatusLines()
  execute 'highlight StatusLine   ctermfg=' . s:green_1 . ' |
    \      highlight StatusLineNC ctermfg=' . s:green_1 . ' |
    \      highlight VertSplit    ctermfg=' . s:green_1
  call timer_start(1000, function('s:RestoreStatusLines'))
endfunction

" }}}
" Style {{{1
"   Palette {{{2

if exists('s:red') | unlet s:red | endif
if exists('s:pink') | unlet s:pink | endif
if exists('s:orange_1') | unlet s:orange_1 | endif
if exists('s:orange_2') | unlet s:orange_2 | endif
if exists('s:orange_3') | unlet s:orange_3 | endif
if exists('s:purple_1') | unlet s:purple_1 | endif
if exists('s:purple_2') | unlet s:purple_2 | endif
if exists('s:purple_3') | unlet s:purple_3 | endif
if exists('s:blue_1') | unlet s:blue_1 | endif
if exists('s:blue_2') | unlet s:blue_2 | endif
if exists('s:blue_3') | unlet s:blue_3 | endif
if exists('s:blue_4') | unlet s:blue_4 | endif
if exists('s:green_1') | unlet s:green_1 | endif
if exists('s:green_2') | unlet s:green_2 | endif
if exists('s:white_1') | unlet s:white_1 | endif
if exists('s:white_2') | unlet s:white_2 | endif
if exists('s:grey_1') | unlet s:grey_1 | endif
if exists('s:grey_2') | unlet s:grey_2 | endif
if exists('s:black') | unlet s:black | endif

const s:red = 196
const s:pink = 205
const s:orange_1 = 202
const s:orange_2 = 209
const s:orange_3 = 216
const s:purple_1 = 62
const s:purple_2 = 140
const s:purple_3 = 176
const s:blue_1 = 69
const s:blue_2 = 105
const s:blue_3 = 111
const s:blue_4 = 45
const s:green_1 = 42
const s:green_2 = 120
const s:white_1 = 147
const s:white_2 = 153
const s:grey_1 = 236
const s:grey_2 = 244
const s:black = 232

"   }}}
"   Colorscheme {{{2

let s:redhighlight_cmd = 'highlight RedHighlight ctermfg=White ctermbg=DarkRed'

set background=dark | highlight clear | if exists('syntax_on') | syntax reset
  \ | endif
set wincolor=NormalAlt

execute 'highlight       Buffer             term=bold         cterm=bold         ctermfg=' . s:grey_2   . ' ctermbg=' . s:black    . ' |
  \      highlight       ModifiedBuf        term=bold         cterm=bold         ctermfg=' . s:red      .                            ' |
  \      highlight       BuffersMenuBorders term=bold         cterm=bold         ctermfg=' . s:blue_4   .                            ' |
  \      highlight       RootPath           term=bold         cterm=bold         ctermfg=' . s:pink     . ' ctermbg=' . s:black    . ' |
  \      highlight       ClosedDirPath      term=bold         cterm=bold         ctermfg=' . s:green_2  . ' ctermbg=' . s:black    . ' |
  \      highlight       OpenedDirPath      term=bold         cterm=bold         ctermfg=' . s:green_1  . ' ctermbg=' . s:black    . ' |
  \      highlight       FilePath           term=NONE         cterm=NONE         ctermfg=' . s:white_2  . ' ctermbg=' . s:black    . ' |
  \      highlight       Help               term=bold         cterm=bold         ctermfg=' . s:purple_2 . ' ctermbg=' . s:black    . ' |
  \      highlight       HelpKey            term=bold         cterm=bold         ctermfg=' . s:pink     . ' ctermbg=' . s:black    . ' |
  \      highlight       HelpMode           term=bold         cterm=bold         ctermfg=' . s:green_1  . ' ctermbg=' . s:black    . ' |
  \      highlight       UndoButton         term=bold         cterm=bold         ctermfg=' . s:black    . ' ctermbg=' . s:pink     . ' |
  \      highlight       Normal             term=bold         cterm=bold         ctermfg=' . s:purple_2 . ' ctermbg=' . s:black    . ' |
  \      highlight       NormalAlt          term=NONE         cterm=NONE         ctermfg=' . s:white_2  . ' ctermbg=' . s:black    . ' |
  \      highlight       ModeMsg            term=NONE         cterm=NONE         ctermfg=' . s:blue_2   . ' ctermbg=' . s:black    . ' |
  \      highlight       MoreMsg            term=NONE         cterm=NONE         ctermfg=' . s:blue_3   . ' ctermbg=' . s:black    . ' |
  \      highlight       Question           term=NONE         cterm=NONE         ctermfg=' . s:blue_3   . ' ctermbg=' . s:black    . ' |
  \      highlight       NonText            term=NONE         cterm=NONE         ctermfg=' . s:orange_1 . ' ctermbg=' . s:black    . ' |
  \      highlight       Comment            term=NONE         cterm=NONE         ctermfg=' . s:purple_2 . ' ctermbg=' . s:black    . ' |
  \      highlight       Constant           term=NONE         cterm=NONE         ctermfg=' . s:blue_1   . ' ctermbg=' . s:black    . ' |
  \      highlight       Special            term=NONE         cterm=NONE         ctermfg=' . s:blue_2   . ' ctermbg=' . s:black    . ' |
  \      highlight       Identifier         term=NONE         cterm=NONE         ctermfg=' . s:blue_3   . ' ctermbg=' . s:black    . ' |
  \      highlight       Statement          term=NONE         cterm=NONE         ctermfg=' . s:red      . ' ctermbg=' . s:black    . ' |
  \      highlight       PreProc            term=NONE         cterm=NONE         ctermfg=' . s:purple_2 . ' ctermbg=' . s:black    . ' |
  \      highlight       Type               term=NONE         cterm=NONE         ctermfg=' . s:blue_3   . ' ctermbg=' . s:black    . ' |
  \      highlight       Visual             term=reverse      cterm=reverse                                 ctermbg=' . s:black    . ' |
  \      highlight       LineNr             term=NONE         cterm=NONE         ctermfg=' . s:green_1  . ' ctermbg=' . s:black    . ' |
  \      highlight       Search             term=reverse      cterm=reverse      ctermfg=' . s:green_1  . ' ctermbg=' . s:black    . ' |
  \      highlight       IncSearch          term=reverse      cterm=reverse      ctermfg=' . s:green_1  . ' ctermbg=' . s:black    . ' |
  \      highlight       Tag                term=NONE         cterm=NONE         ctermfg=' . s:blue_3   . ' ctermbg=' . s:black    . ' |
  \      highlight       Error                                                   ctermfg=' . s:black    . ' ctermbg=' . s:red      . ' |
  \      highlight       ErrorMsg           term=bold         cterm=bold         ctermfg=' . s:red      . ' ctermbg=' . s:black    . ' |
  \      highlight       Todo               term=standout                        ctermfg=' . s:black    . ' ctermbg=' . s:blue_1   . ' |
  \      highlight       StatusLine         term=bold         cterm=bold         ctermfg=' . s:blue_4   . ' ctermbg=' . s:black    . ' |
  \      highlight       StatusLineNC       term=NONE         cterm=NONE         ctermfg=' . s:blue_1   . ' ctermbg=' . s:black    . ' |
  \      highlight       Folded             term=NONE         cterm=NONE         ctermfg=' . s:black    . ' ctermbg=' . s:orange_2 . ' |
  \      highlight       VertSplit          term=NONE         cterm=NONE         ctermfg=' . s:purple_2 . ' ctermbg=' . s:black    . ' |
  \      highlight       CursorLine         term=bold,reverse cterm=bold,reverse ctermfg=' . s:blue_4   . ' ctermbg=' . s:black    . ' |
  \      highlight       MatchParen         term=bold         cterm=bold         ctermfg=' . s:purple_1 . ' ctermbg=' . s:white_1  . ' |
  \      highlight       Pmenu              term=bold         cterm=bold         ctermfg=' . s:green_1  . ' ctermbg=' . s:black    . ' |
  \      highlight       PopupSelected      term=bold         cterm=bold         ctermfg=' . s:black    . ' ctermbg=' . s:purple_2 . ' |
  \      highlight       PmenuSbar          term=NONE         cterm=NONE         ctermfg=' . s:black    . ' ctermbg=' . s:blue_3   . ' |
  \      highlight       PmenuThumb         term=NONE         cterm=NONE         ctermfg=' . s:black    . ' ctermbg=' . s:blue_1   . ' |
  \      highlight       User1              term=bold         cterm=bold         ctermfg=' . s:pink     . ' ctermbg=' . s:black    . ' |
  \      highlight       User2              term=bold         cterm=bold         ctermfg=' . s:green_2  . ' ctermbg=' . s:black    . ' |
  \      highlight       User3              term=bold         cterm=bold         ctermfg=' . s:orange_3 . ' ctermbg=' . s:black    . ' |
  \      highlight       User4              term=bold         cterm=bold         ctermfg=Red'
highlight! link WarningMsg         ErrorMsg
highlight  link String             Constant
highlight  link Character          Constant
highlight  link Number             Constant
highlight  link Boolean            Constant
highlight  link Float              Number
highlight  link Function           Identifier
highlight  link Conditional        Statement
highlight  link Repeat             Statement
highlight  link Label              Statement
highlight  link Operator           Statement
highlight  link Keyword            Statement
highlight  link Exception          Statement
highlight  link Include            PreProc
highlight  link Define             PreProc
highlight  link Macro              PreProc
highlight  link PreCondit          PreProc
highlight  link StorageClass       Type
highlight  link Structure          Type
highlight  link Typedef            Type
highlight  link SpecialChar        Special
highlight  link Delimiter          Special
highlight  link SpecialComment     Special
highlight  link Debug              Special

execute s:redhighlight_cmd

"   }}}
"   Text properties {{{2

if index(prop_type_list(), 'statusline') != -1 | call prop_type_delete('statusline') | endif
if index(prop_type_list(), 'key')        != -1 | call prop_type_delete('key')        | endif
if index(prop_type_list(), 'help')       != -1 | call prop_type_delete('help')       | endif
if index(prop_type_list(), 'mode')       != -1 | call prop_type_delete('mode')       | endif
if index(prop_type_list(), 'undobutton') != -1 | call prop_type_delete('undobutton') | endif

call prop_type_add('statusline', #{ highlight: 'StatusLine' })
call prop_type_add('key',        #{ highlight: 'HelpKey' })
call prop_type_add('help',       #{ highlight: 'Help' })
call prop_type_add('mode',       #{ highlight: 'HelpMode' })
call prop_type_add('undobutton', #{ highlight: 'UndoButton' })

"     Buffers menu {{{3

if index(prop_type_list(), 'buf') != -1 | call prop_type_delete('buf') | endif
if index(prop_type_list(), 'mbuf') != -1 | call prop_type_delete('mbuf') | endif

call prop_type_add('buf', #{ highlight: 'Buffer' })
call prop_type_add('mbuf', #{ highlight: 'ModifiedBuf' })

"     }}}
"     Explorer {{{3

if index(prop_type_list(), 'rpath') != -1  | call prop_type_delete('rpath')  | endif
if index(prop_type_list(), 'fpath') != -1  | call prop_type_delete('fpath')  | endif
if index(prop_type_list(), 'cdpath') != -1 | call prop_type_delete('cdpath') | endif
if index(prop_type_list(), 'odpath') != -1 | call prop_type_delete('odpath') | endif

call prop_type_add('rpath',  #{ highlight: 'RootPath' })
call prop_type_add('fpath',  #{ highlight: 'FilePath' })
call prop_type_add('cdpath', #{ highlight: 'ClosedDirPath' })
call prop_type_add('odpath', #{ highlight: 'OpenedDirPath' })

"     }}}
"   }}}
"   Good practices {{{2

let s:redhighlight = v:true

" highlight unused spaces before the end of the line
function! s:ExtraSpaces()
  call matchadd('RedHighlight', '\v\s+$')
endfunction

" highlight characters which overpass 80 columns
function! s:OverLength()
  call matchadd('RedHighlight', '\v%80v.*')
endfunction

" clear/add red highlight matching patterns
function! s:ToggleRedHighlight()
  if s:redhighlight
    highlight clear RedHighlight | set synmaxcol=3000
  else
    execute s:redhighlight_cmd | set synmaxcol=200
  endif
  let s:redhighlight = !s:redhighlight
endfunction

"   }}}
" }}}
" Buffers {{{1

" allow to switch between buffers without writting them
set hidden

" return number of active listed-buffers
function! s:ActiveListedBuffers()
  return len(filter(getbufinfo(#{ buflisted: 1 }), {_, val -> !val.hidden}))
endfunction

" close Vim if only unlisted-buffers are active
function! s:CloseLonelyUnlistedBuffers()
  if s:ActiveListedBuffers() == 0
    quitall
  endif
endfunction

" Windows {{{1

function! s:NextWindow()
  if winnr() < winnr('$')
    execute winnr() + 1 . 'wincmd w'
  else
    1wincmd w
  endif
endfunction

function! s:PreviousWindow()
  if winnr() > 1
    execute winnr() - 1 . 'wincmd w'
  else
    execute winnr('$') . 'wincmd w'
  endif
endfunction

" }}}
" Dependencies {{{1

function! s:CheckDependencies()
  if v:version < 801
    let l:major_version = v:version / 100
    echoerr 'Personal Error Message: your VimRC needs Vim 8.1 to be'
      \ . ' functionnal. Your Vim version is ' l:major_version . '.'
      \ . (v:version - l:major_version * 100)
    quit
  endif
endfunction

" }}}
" Plugins {{{1
"   Buffers menu {{{2
"     Help {{{3

function! s:HelpBuffersMenu()
  let l:lines = [ '     ' . s:Key([s:help_menukey]) . '     - Show this help',
   \ '    ' . s:Key([s:exit_menukey]) . '    - Exit buffers menu',
   \ '   ' . s:Key([s:next_menukey, s:previous_menukey])
     \ . '   - Next/Previous buffer',
   \ '   ' . s:Key([s:select_menukey]) . '   - Select buffer',
   \ '     ' . s:Key([s:delete_menukey]) . '     - Delete buffer',
   \ '    < 0-9 >    - Buffer-id characters',
   \ '     < $ >     - End-of-string buffer-id character',
   \ ' ' . s:Key([s:erase_menukey]) . ' - Erase last buffer-id character',
  \ ]
  let l:text = []
  for l:line in l:lines
    let l:start = matchend(l:line, '^\s*< .\+ >\s* - \u')
    let l:properties = [#{ type: 'key', col: 1, length: l:start - 1}]
    let l:properties = l:properties + [#{ type: 'statusline',
      \ col: l:start - 2, length: 1 }]
    let l:start = 0
    while l:start > -1
      let l:start = match(l:line,
        \ '^\s*\zs< \| \zs> \s*- \u\| \zs| \|/\| .\zs-. ', l:start)
      if l:start > -1
        let l:start += 1
        let l:properties = l:properties + [#{ type: 'statusline',
          \ col: l:start, length: 1 }]
      endif
    endwhile
    call add(l:text, #{ text: l:line, props: l:properties })
  endfor
  call popup_create(l:text, #{ pos: 'topleft',
                             \ line: win_screenpos(0)[0] + winheight(0)
                             \   - len(l:text) - &cmdheight,
                             \ col: win_screenpos(0)[1],
                             \ zindex: 1,
                             \ minwidth: winwidth(0),
                             \ time: 10000,
                             \ border: [1, 0, 0, 0],
                             \ borderchars: ['━'],
                             \ borderhighlight: ["StatusLine"],
                             \ highlight: 'Help',
                             \ })
endfunction

"     }}}

let s:buf_before_menu = bufnr()
let s:menu_bufnr = ''

function! s:ReplaceCursorOnCurrentBuffer(winid)
  call win_execute(a:winid,
    \ 'call cursor(index(map(getbufinfo(#{ buflisted: 1 }),
    \ {_, val -> val.bufnr}), winbufnr(s:win_before_menu)) + 1, 0)')
endfunction

function! s:BuffersMenuFilter(winid, key)
  if a:key == s:next_menukey
    bnext
    call s:ReplaceCursorOnCurrentBuffer(a:winid)
  elseif a:key == s:previous_menukey
    bprevious
    call s:ReplaceCursorOnCurrentBuffer(a:winid)
  elseif a:key == s:select_menukey
    call popup_clear()
  elseif a:key == s:delete_menukey
    let l:listed_buf = getbufinfo(#{ buflisted: 1 })
    if len(l:listed_buf) > 1
      let l:buf = bufnr()
      if len(win_findbuf(l:buf)) == 1
        if l:buf == l:listed_buf[-1].bufnr
          bprevious
        else
          bnext
        endif
        execute 'silent bdelete ' . l:buf
        call popup_settext(a:winid, s:BuffersMenu().text)
        call s:ReplaceCursorOnCurrentBuffer(a:winid)
      endif
    endif
  elseif a:key == s:exit_menukey
    if !empty(win_findbuf(s:buf_before_menu))
      execute 'buffer ' . s:buf_before_menu
    endif
    call popup_clear()
  elseif match(a:key, s:select_menuchars) > -1
    if (a:key != "0") || (len(s:menu_bufnr) > 0)
      let s:menu_bufnr = s:menu_bufnr . a:key
      let l:matches = filter(map(getbufinfo(#{ buflisted: 1 }),
        \ {_, val -> val.bufnr}),
        \ {_, val -> match(val, '^' . s:menu_bufnr) > -1})
      if len(l:matches) == 1
        execute 'buffer ' . l:matches[0]
        call s:ReplaceCursorOnCurrentBuffer(a:winid)
        let s:menu_bufnr = ""
        echo len(l:matches) . ' match: ' . l:matches[0]
      else
        echo s:menu_bufnr . ' (' . len(l:matches) . ' matches:'
          \ . string(l:matches) . ')'
      endif
    endif
  elseif a:key == s:erase_menukey
    let s:menu_bufnr = s:menu_bufnr[:-2]
    if len(s:menu_bufnr) > 0
      let l:matches = filter(map(getbufinfo(#{ buflisted: 1 }),
        \ {_, val -> val.bufnr}),
        \ {_, val -> match(val, '^' . s:menu_bufnr) > -1})
      echo s:menu_bufnr . ' (' . len(l:matches) . ' matches:'
        \ . string(l:matches) . ')'
    else
      echo s:menu_bufnr
    endif
  elseif a:key == s:help_menukey
    call s:HelpBuffersMenu()
  endif
  return v:true
endfunction

function! s:BuffersMenu()
  let l:listed_buf = getbufinfo(#{ buflisted: 1 })
  let l:listedbuf_nb = len(l:listed_buf)

  if l:listedbuf_nb < 1
    return
  endif

  let l:text = []
  let l:width = max(mapnew(l:listed_buf,
    \ {_, val -> len(val.bufnr . ': ""' . fnamemodify(val.name, ':.'))}))

  for l:buf in l:listed_buf
    let l:line = l:buf.bufnr . ': "' . fnamemodify(l:buf.name, ':.') . '"'
    let l:line = l:line . repeat(' ', l:width - len(l:line))

    let l:property = [#{ type: 'buf', col: 0, length: l:width + 1 }]
    if l:buf.changed
      let l:property = [#{ type: 'mbuf', col: 0, length: l:width + 1 }]
    endif

    call add(l:text, #{ text: l:line, props: l:property })
  endfor

  return #{ text: l:text, height: len(l:text), width: l:width }
endfunction

function! s:DisplayBuffersMenu()
  let s:buf_before_menu = bufnr()
  let s:win_before_menu = winnr()
  let s:menu_bufnr = ''

  let l:menu = s:BuffersMenu()
  let l:popup_id = popup_create(l:menu.text,
  \ #{
    \ pos: 'topleft',
    \ line: win_screenpos(0)[0] + (winheight(0) - l:menu.height) / 2,
    \ col: win_screenpos(0)[1] + (winwidth(0) - l:menu.width) / 2,
    \ zindex: 2,
    \ drag: v:true,
    \ wrap: v:false,
    \ filter: expand('<SID>') . 'BuffersMenuFilter',
    \ mapping: v:false,
    \ border: [],
    \ borderhighlight: ['BuffersMenuBorders'],
    \ borderchars: ['━', '┃', '━', '┃', '┏', '┓', '┛', '┗'],
    \ cursorline: v:true,
  \ })
  call s:ReplaceCursorOnCurrentBuffer(l:popup_id)
  call s:HelpBuffersMenu()
endfunction

"   }}}
"   Explorer {{{2
"     Help {{{3
function! s:HelpExplorer()
  let l:lines = [ repeat('━', 41) . '┳' . repeat('━', winwidth(0) - 42),
    \ '      NORMAL Mode                        ┃        '
      \ . s:Key([s:reset_explkey]) . '        - Reset explorer',
    \ '   ' . s:Key([s:help_explkey]) . '   - Show this help              ┃  '
      \ . '    ' . s:Key([s:searchmode_explkey])
      \ . '      - Enter SEARCH Mode',
    \ '  ' . s:Key([s:exit_explkey]) . '  - Exit explorer               ┃    '
      \ . '  ' . s:Key([s:next_match_explkey, s:previous_match_explkey])
      \ . '      - Next/Previous SEARCH match',
    \ ' ' . s:Key([s:next_file_explkey, s:previous_file_explkey])
      \ . ' - Next/Previous file          ┃                SEARCH Mode',
    \ ' ' . s:Key([s:first_file_explkey, s:last_file_explkey])
      \ . ' - First/Last file             ┃       '
      \ . s:Key([s:exit_smexplkey]) . '       - Exit SEARCH Mode',
    \ '   ' . s:Key([s:open_explkey]) . '   - Open/Close dir & Open files ┃  '
      \ . '    ' . s:Key([s:evaluate_smexplkey]) . '      - Evaluate SEARCH',
    \ '   ' . s:Key([s:badd_explkey]) . '   - Add to buffers list         ┃  '
      \ . '  ' . s:Key([s:erase_smexplkey]) . '    - Erase SEARCH',
    \ '   ' . s:Key([s:yank_explkey]) . '   - Yank path                   ┃ '
      \ . '     ' . s:Key([s:next_smexplkey, s:previous_smexplkey])
      \ . '      - Next/Previous SEARCH',
    \ '   ' . s:Key([s:dotfiles_explkey]) . '   - Show/Hide dot files        '
      \ . ' ┃ ' . s:Key([s:wide_left_smexplkey, s:wide_right_smexplkey])
      \ . ' - Navigation',
  \ ]
  let l:text = [#{ text: l:lines[0], props: [#{ type: 'statusline',
    \ col: 1, length: len(l:lines[0]) }] }]
  for l:line in l:lines[1:]

    let l:start = match(l:line, ' ┃ \s*<\zs .\+ >\s* - \u')
    let l:end = matchend(l:line, ' ┃ \s*< .\+ \ze>\s* - \u')
    let l:properties =
      \ [#{ type: 'key', col: l:start + 1, length: l:end - l:start }]

    let l:start = match(l:line, ' ┃ \s*< .\+ >\s* \zs- \u')
    let l:properties = l:properties + [#{ type: 'statusline',
      \ col: l:start + 1, length: 1 }]

    let l:start = match(l:line, '^\s*<\zs .\+ >\s* - \u.* ┃')
    let l:end = matchend(l:line, '^\s*< .\+ \ze>\s* - \u.* ┃')
    let l:properties = l:properties +
      \ [#{ type: 'key', col: l:start + 1, length: l:end - l:start }]

    let l:start = match(l:line, '^\s*< .\+ >\s* \zs- \u.* ┃')
    let l:properties = l:properties + [#{ type: 'statusline',
      \ col: l:start + 1, length: 1 }]

    let l:start = 0
    while l:start > -1
      let l:start = match(l:line,
        \ ' ┃ \s*\zs< \|^\s*\zs< \| \zs> \s*- \u\| \zs| \|/\| .\zs-. ',
        \ l:start)
      if l:start > -1
        let l:start += 1
        let l:properties = l:properties + [#{ type: 'statusline',
          \ col: l:start, length: 1 }]
      endif
    endwhile

    let l:properties = l:properties + [#{ type: 'statusline',
      \ col: match(l:line, ' \zs┃ '), length: len('┃')}]

    let l:start = match(l:line, '\u\{2,}')
    let l:end = matchend(l:line, '\u\{2,} Mode\|\u\{2,}')
    let l:properties = l:properties + [#{ type: 'mode',
      \ col: l:start, length: l:end + 1 - l:start }]

    call add(l:text, #{ text: l:line, props: l:properties })
  endfor
  call popup_create(l:text, #{ pos: 'topleft',
                             \ line: win_screenpos(0)[0] + winheight(0)
                             \   - len(l:text),
                             \ col: win_screenpos(0)[1],
                             \ zindex: 3,
                             \ minwidth: winwidth(0),
                             \ time: 10000,
                             \ highlight: 'Help',
                             \ })
endfunction

"     }}}

function! s:PathCompare(file1, file2)
  if isdirectory(a:file1) && !isdirectory(a:file2)
    return 1
  elseif !isdirectory(a:file1) && isdirectory(a:file2)
    return -1
  endif
endfunction

function! s:FullPath(path, value)
  let l:content = a:path . a:value
  if isdirectory(l:content)
    return l:content . '/'
  endif
  return l:content
endfunction

function! s:InitExplorer()
  let s:expl = {}
  let s:expl['.'] = fnamemodify('.', ':p')
  let s:expl[fnamemodify('.', ':p')] = sort(map(reverse(
    \ readdir('.', '1', #{ sort: 'icase' })), {_, val ->
      \ s:FullPath(s:expl['.'], val)}), expand('<SID>') . 'PathCompare')
  let s:expl_searchmode = v:false
  let s:expl_search = ''
endfunction

let s:show_dotfiles = v:false
let s:search_cursor = 0
let s:search_hist_cursor = 0
call s:InitExplorer()

function! s:Depth(path)
  return len(split(substitute(a:path, '/$', '', 'g'), '/'))
endfunction

function! s:NormalModeExplorerFilter(winid, key)
  if a:key == s:dotfiles_explkey
    let s:show_dotfiles = !s:show_dotfiles
    call popup_settext(a:winid, s:Explorer().text)
    call win_execute(a:winid, 'if line(".") > line("$") |'
      \ . ' call cursor(line("$"), 0) | endif')
  elseif a:key == s:yank_explkey
    call win_execute(a:winid, 'let s:expl_line = line(".") - 2')
    let l:path = s:Explorer().paths[s:expl_line]
    let @" = l:path
    echo 'Unnamed register content is:'
    echohl OpenedDirPath
    echon @"
    echohl NONE
  elseif a:key == s:badd_explkey
    call win_execute(a:winid, 'let s:expl_line = line(".") - 2')
    let l:path = s:Explorer().paths[s:expl_line]
    if !isdirectory(l:path)
      execute 'badd ' . l:path
      echohl OpenedDirPath
      echo l:path
      echohl NONE
      echon ' added to buffers list'
    endif
  elseif a:key == s:open_explkey
    call win_execute(a:winid, 'let s:expl_line = line(".") - 2')
    let l:path = s:Explorer().paths[s:expl_line]
    if isdirectory(l:path)
      if has_key(s:expl, l:path)
        unlet s:expl[l:path]
      else
        let s:expl[l:path] = sort(map(reverse(
          \ readdir(l:path, '1', #{ sort: 'icase' })), {_, val ->
            \s:FullPath(l:path, val)}), expand('<SID>') . 'PathCompare')
      endif
      call popup_settext(a:winid, s:Explorer().text)
    else
      call popup_clear()
      execute 'edit ' . l:path
    endif
  elseif a:key == s:reset_explkey
    call s:InitExplorer()
    call popup_settext(a:winid, s:Explorer().text)
    call win_execute(a:winid, 'call cursor(2, 0)')
  elseif a:key == s:next_match_explkey
    call win_execute(a:winid, 'call search(histget("/", -1), "")')
  elseif a:key == s:previous_match_explkey
    call win_execute(a:winid, 'call search(histget("/", -1), "b")')
  elseif a:key == s:first_file_explkey
    call win_execute(a:winid,
      \ 'call cursor(2, 0) | execute "normal! \<C-Y>"')
  elseif a:key == s:last_file_explkey
    call win_execute(a:winid, 'call cursor(line("$"), 0)')
  elseif a:key == s:exit_explkey
    call win_execute(a:winid, 'call clearmatches()')
    call popup_clear()
  elseif a:key == s:next_file_explkey
    call win_execute(a:winid, 'if line(".") < line("$") |'
      \ . ' call cursor(line(".") + 1, 0) | endif')
  elseif a:key == s:previous_file_explkey
    call win_execute(a:winid, 'if line(".") > 2 |'
      \ . ' call cursor(line(".") - 1, 0) | else |'
      \ . ' execute "normal! \<C-Y>" | endif')
  elseif a:key == s:help_explkey
    call s:HelpExplorer()
  elseif a:key == s:searchmode_explkey
    let s:expl_searchmode = v:true
    let s:expl_search = a:key
    let s:search_cursor = 1
    let s:search_hist_cursor = 0
    echo s:expl_search
    echohl Visual
    echon ' '
    echohl NONE
  endif
endfunction

function! s:SearchModeExplorerFilter(winid, key)
  if a:key == s:evaluate_smexplkey
    let @/ = '\%>1l' . s:expl_search[1:]
    call win_execute(a:winid,
      \ 'if s:expl_search[0] == "/" | call search(@/, "c") | '
      \ . 'elseif s:expl_search[0] == "?" | call search(@/, "bc") | endif')
    call histadd('/', @/)
    let s:expl_search = ''
  elseif a:key == s:erase_smexplkey
    if s:search_cursor > 1
      let s:expl_search = slice(s:expl_search, 0, s:search_cursor - 1)
        \ . slice(s:expl_search, s:search_cursor)
      let s:search_cursor -= 1
    endif
  elseif a:key == s:exit_smexplkey
    let s:expl_search = ''
  elseif a:key == s:next_smexplkey
    if s:search_hist_cursor < 0
      let s:search_hist_cursor += 1
      let s:expl_search = '/' . histget('search', s:search_hist_cursor)
    else
      let s:expl_search = '/'
    endif
    let s:search_cursor = len(s:expl_search)
  elseif a:key == s:previous_smexplkey
    if abs(s:search_hist_cursor) < &history
      let s:search_hist_cursor -= 1
      let s:expl_search = '/' . histget('search', s:search_hist_cursor)
      let s:search_cursor = len(s:expl_search)
    endif
  elseif a:key == s:left_smexplkey
    if s:search_cursor > 1
      let s:search_cursor -= 1
    endif
  elseif a:key == s:right_smexplkey
    if s:search_cursor < len(s:expl_search)
      let s:search_cursor += 1
    endif
  elseif a:key == s:wide_left_smexplkey
    for l:i in range(s:search_cursor - 2, 0, -1)
      if match(s:expl_search[l:i], '[[:punct:][:space:]]') > -1
        let s:search_cursor = l:i + 1
        break
      endif
    endfor
  elseif a:key == s:wide_right_smexplkey
    let s:search_cursor =
      \ match(s:expl_search[1:], '[[:punct:][:space:]]', s:search_cursor + 1)
    if s:search_cursor == -1
      let s:search_cursor = len(s:expl_search)
    endif
  else
    let s:expl_search = slice(s:expl_search, 0, s:search_cursor) . a:key
      \ . slice(s:expl_search, s:search_cursor)
    let s:search_cursor += 1
    call win_execute(a:winid, 'call clearmatches() | '
      \ . 'try | call matchadd("Search", "\\%>1l" . s:expl_search[1:]) | '
      \ . 'catch | endtry ')
  endif

  if empty(s:expl_search)
    let s:expl_searchmode = v:false
  endif
  echo slice(s:expl_search, 0, s:search_cursor)
  echohl Visual
  echon slice(s:expl_search, s:search_cursor, s:search_cursor + 1)
  if s:search_cursor == len(s:expl_search)
    echon ' '
  endif
  echohl NONE
  echon slice(s:expl_search, s:search_cursor + 1)
endfunction

function! s:ExplorerFilter(winid, key)
  if !s:expl_searchmode
    call s:NormalModeExplorerFilter(a:winid, a:key)
  else
    call s:SearchModeExplorerFilter(a:winid, a:key)
  endif
  return v:true
endfunction

function! s:Explorer()
  let l:text = []
  let l:paths = []

  let l:line = s:expl['.']
  let l:property = [#{ type: 'rpath', col: 0, length: len(l:line) + 1 }]

  call add(l:text, #{ text: l:line, props: l:property })

  let l:stack = s:expl[s:expl['.']]
  let l:visited = {}
  let l:visited[s:expl['.']] = v:true
  while !empty(l:stack)
    " pop
    let l:current = l:stack[-1]
    let l:stack = l:stack[:-2]

    " construct text
    let l:arrow = ''
    let l:id = ''
    let l:name = fnamemodify(l:current, ':t')
    if isdirectory(l:current)
      let l:name = fnamemodify(l:current, ':p:s?/$??:t')
      let l:id = '/'
      if has_key(s:expl, l:current)
        let l:arrow = '▾ '
      else
        let l:arrow = '▸ '
      endif
    endif

    if s:show_dotfiles || l:name[0] != '.'
      let l:indent = repeat('  ',
        \ s:Depth(l:current) - s:Depth(s:expl['.']) - isdirectory(l:current))
      let l:line = l:indent . l:arrow . l:name . l:id

      " construct property
      let l:property = [#{ type: 'fpath', col: 0, length: winwidth(0) + 1}]
      if isdirectory(l:current)
        if has_key(s:expl, l:current)
          let l:property =
            \ [#{ type: 'odpath', col: 0, length: winwidth(0) + 1}]
        else
          let l:property =
            \ [#{ type: 'cdpath', col: 0, length: winwidth(0) + 1}]
        endif
      endif

      call add(l:text, #{ text: l:line, props: l:property })
      call add(l:paths, l:current)
    endif

    " continue dfs
    if !has_key(l:visited, l:current)
      let l:visited[l:current] = v:true
      if has_key(s:expl, l:current)
        let l:stack += s:expl[l:current]
      endif
    endif
  endwhile
  return #{ text: l:text, paths: l:paths }
endfunction

function! s:DisplayExplorer()
  call s:InitExplorer()

  let l:expl = s:Explorer()
  let l:popup_id = popup_create(l:expl.text,
  \ #{
    \ pos: 'topleft',
    \ line: win_screenpos(0)[0],
    \ col: win_screenpos(0)[1],
    \ zindex: 2,
    \ minwidth: winwidth(0),
    \ maxwidth: winwidth(0),
    \ minheight: winheight(0),
    \ maxheight: winheight(0),
    \ drag: v:true,
    \ wrap: v:true,
    \ filter: expand('<SID>') . 'ExplorerFilter',
    \ mapping: v:false,
    \ scrollbar: v:true,
    \ cursorline: v:true,
  \ })
  call win_execute(l:popup_id, 'call cursor(2, 0)')
  call s:HelpExplorer()
endfunction

"   }}}
"   Obsession {{{2

function! s:DisplayObsession()
  if len(getbufinfo(#{ buflisted: 1 })) > 1
    call inputsave()
    while v:true
      redraw!
      echon 'Build a new session in "'
      echohl PMenu
      echon fnamemodify('.', ':p')
      echohl NONE
      echon '": ['
      echohl PMenu
      echon 'Y'
      echohl NONE
      echon ']es or ['
      echohl PMenu
      echon 'N'
      echohl NONE
      echon ']o ? '
      let l:mkses = input('')
      let l:mkses = tolower(l:mkses)
      if l:mkses == s:yes_obsessionkey
        mksession!
        break
      elseif l:mkses == s:no_obsessionkey
        break
      endif
      echohl NONE
    endwhile
    call inputrestore()
  endif
endfunction

"   }}}
"   Undo tree {{{2
"     Help {{{3

function! s:HelpUndotree()
endfunction

"     }}}

function! s:UndotreeFilter(winid, key)
  if a:key == s:exit_undokey
    call popup_clear()
    execute 'highlight Pmenu         term=bold cterm=bold ctermfg='
      \    . s:green_1  . ' ctermbg=' . s:black    . ' |
      \      highlight PopupSelected term=bold cterm=bold ctermfg='
      \    . s:black    . ' ctermbg=' . s:purple_2
  elseif a:key == s:next_undokey
    call win_execute(a:winid, 'while line(".") < line("$")'
      \ . ' | call cursor(line(".") + 1, 0)'
      \ . ' | if match(getline("."), "\\d$") > -1 | break | endif | endwhile'
      \ . ' | let s:first_line_undotree = line("w0")'
      \ . ' | let s:last_line_undotree = line("w$")')
    call s:UndotreeButtons(s:Undotree(), a:winid)
  elseif a:key == s:previous_undokey
    call win_execute(a:winid, 'while line(".") > 1'
      \ . ' | call cursor(line(".") - 1, 0)'
      \ . ' | if match(getline("."), "\\d$") > -1 | break | endif | endwhile'
      \ . ' | let s:first_line_undotree = line("w0")'
      \ . ' | let s:last_line_undotree = line("w$")')
    call s:UndotreeButtons(s:Undotree(), a:winid)
  elseif a:key == s:select_undokey
    let s:line_undotree = ""
    call win_execute(a:winid, 'let s:line_undotree = getline(".")')
    execute 'undo ' . substitute(s:line_undotree, '\D*\(\d\+\)$', '\1', '')
    call popup_settext(a:winid, s:Undotree().text)
  elseif a:key == s:help_undokey
    call HelpUndotree()
  endif
  return v:true
endfunction

function! s:ParseNode(in, out)
  if empty(a:in)
    return
  endif
  let l:currentnode = a:out
  for l:entry in a:in
    if has_key(l:entry, 'alt')
      call s:ParseNode(l:entry.alt, l:currentnode)
    endif
    let l:newnode = #{ seq: l:entry.seq, p: [] }
    call extend(l:currentnode.p, [l:newnode])
    let l:currentnode = l:newnode
  endfor
endfunction

function! s:Undotree()
  let l:rawtree = undotree().entries
  let l:tree = #{ seq: 0, p: [] }
  let l:text = []
  let l:maxlength = 0

  call s:ParseNode(l:rawtree, l:tree)

  let l:slots = [l:tree]
  while l:slots != []
    let l:foundstring = v:false
    let l:index = 0

    for l:i in range(len(l:slots))
      if type(l:slots[l:i]) == v:t_string
        let l:foundstring = v:true
        let l:index = l:i
        break
      endif
    endfor

    let l:minseq = v:numbermax
    let l:minnode = {}

    if !l:foundstring
      for l:i in range(len(l:slots))
        if type(l:slots[l:i]) == v:t_dict
          if l:slots[l:i].seq < l:minseq
            let l:minseq = l:slots[l:i].seq
            let l:index = l:i
            let l:minnode = l:slots[l:i]
            continue
          endif
        endif
        if type(l:slots[l:i]) == v:t_list
          for l:j in l:slots[l:i]
            if l:j.seq < l:minseq
              let l:minseq = l:j.seq
              let l:index = l:i
              let l:minnode = l:j
              continue
            endif
          endfor
        endif
      endfor
    endif

    let l:newline = " "
    let l:node = l:slots[l:index]
    if type(l:node) == v:t_string
      if l:index + 1 != len(l:slots)
        for l:i in range(len(l:slots))
          if l:i < l:index
            let l:newline = l:newline . '| '
          endif
          if l:i > l:index
            let l:newline = l:newline . ' \'
          endif
        endfor
      endif
      call remove(l:slots, l:index)
    endif

    if type(l:node) == v:t_dict
      for l:i in range(len(l:slots))
        if l:index == l:i
          if l:node.seq == changenr()
            let l:newline = l:newline . '◊ '
          else
            let l:newline = l:newline . '• '
          endif
        else
          let l:newline = l:newline . '| '
        endif
      endfor
      let l:newline = l:newline . '   ' . l:node.seq
      if empty(l:node.p)
        let l:slots[l:index] = 'x'
      endif
      if len(l:node.p) == 1
        let l:slots[l:index] = l:node.p[0]
      endif
      if len(l:node.p) > 1
        let l:slots[l:index] = l:node.p
      endif
      let l:node.p = []
    endif

    if type(l:node) == v:t_list
      for l:k in range(len(l:slots))
        if l:k < l:index
          let l:newline = l:newline . '| '
        endif
        if l:k == l:index
          let l:newline = l:newline . '|/ '
        endif
        if l:k > l:index
          let l:newline = l:newline . '/ '
        endif
      endfor
      call remove(l:slots, l:index)
      if len(l:node) == 2
        if l:node[0].seq > l:node[1].seq
          call insert(l:slots, l:node[1], l:index)
          call insert(l:slots, l:node[0], l:index)
        else
          call insert(l:slots, l:node[0], l:index)
          call insert(l:slots, l:node[1], l:index)
        endif
      endif
      if len(l:node) > 2
        call remove(l:node, index(l:node, l:minnode))
        call insert(l:slots, l:minnode, l:index)
        call insert(l:slots, l:node, l:index)
      endif
    endif
    unlet l:node

    if l:newline != " "
      let l:newline = substitute(l:newline, '\s*$', '', 'g')
      let l:maxlength = max([l:maxlength, len(split(l:newline, '\zs'))])
      let l:properties =
        \ [#{ type: 'statusline', col: 1, length: len(l:newline) }]
      call insert(l:text, #{ text: l:newline, props: l:properties }, 0)
    endif

  endwhile

  return #{ text: l:text, max_length: l:maxlength + 1 }
endfunction

function! s:UndotreeButtons(tree, winid)
  let l:midlength = a:tree.max_length / 2
  let l:modified = v:false
  if s:first_line_undotree > 1
    if l:midlength * 2 == a:tree.max_length
      let a:tree.text[s:first_line_undotree - 1].text =
      \ repeat(' ', l:midlength - 1) . '▲' . repeat(' ', l:midlength)
    else
      let a:tree.text[s:first_line_undotree - 1].text =
      \ repeat(' ', l:midlength) . '▴' . repeat(' ', l:midlength)
    endif
    let a:tree.text[s:first_line_undotree - 1].props =
    \ [#{ type: 'undobutton', col: 1,
      \ length: len(a:tree.text[s:first_line_undotree - 1].text) }]
    let l:modified = v:true
  endif
  if s:last_line_undotree < len(a:tree.text)
    if l:midlength * 2 == a:tree.max_length
      let a:tree.text[s:last_line_undotree - 1].text =
      \ repeat(' ', l:midlength - 1) . '▼' . repeat(' ', l:midlength)
    else
      let a:tree.text[s:last_line_undotree - 1].text =
      \ repeat(' ', l:midlength) . '▾' . repeat(' ', l:midlength)
    endif
    let a:tree.text[s:last_line_undotree - 1].props =
    \ [#{ type: 'undobutton', col: 1,
      \ length: len(a:tree.text[s:last_line_undotree - 1].text) }]
    let l:modified = v:true
  endif
  if l:modified
    call popup_settext(a:winid, a:tree.text)
  endif
endfunction

function! s:DisplayUndotree()
  let s:change_before_undotree = changenr()
  let l:tree = s:Undotree()
  execute 'highlight PopupSelected term=bold cterm=bold ctermfg=' . s:pink
    \ . ' ctermbg=' . s:black
  let l:popup_id = popup_create(l:tree.text,
  \ #{
    \ pos: 'topleft',
    \ line: win_screenpos(0)[0],
    \ col: win_screenpos(0)[1],
    \ zindex: 2,
    \ minwidth: l:tree.max_length,
    \ maxwidth: l:tree.max_length,
    \ minheight: winheight(0),
    \ maxheight: winheight(0),
    \ drag: v:true,
    \ wrap: v:true,
    \ filter: expand('<SID>') . 'UndotreeFilter',
    \ mapping: v:false,
    \ scrollbar: v:false,
    \ cursorline: v:true,
  \ })
  call win_execute(l:popup_id, 'let w:c = 1 | call cursor(w:c, 0)'
  \ . ' | while substitute(getline("."), "\\D*\\(\\d\\+\\)$", "\\1", "")'
  \ . '   != s:change_before_undotree'
  \ . ' | let w:c += 1 | call cursor(w:c, 0) | endwhile'
  \ . ' | let s:first_line_undotree = line("w0")'
  \ . ' | let s:last_line_undotree = line("w$")')
  call s:UndotreeButtons(l:tree, l:popup_id)
  "diff --unchanged-line-format="" --new-line-format="+%dn %L" --old-line-format="-%dn %L$" file1 file2
  call s:HelpUndotree()
endfunction

"   }}}
"   Rainbow parenthesis {{{2
"   }}}
"   Tag summary {{{2
"   }}}
" }}}
" Filetype specific {{{1
"   Bash {{{2

function! s:PrefillShFile()
  call append(0, [ '#!/bin/bash',
  \                '', ])
endfunction

"   }}}
" }}}
" Mappings and Keys {{{1

function! s:Key(keys)
  let l:text = '< '
  let l:index = 1
  for l:key in a:keys
    if l:key == "\<Down>"
      let l:text = l:text . '↓'
    elseif l:key == "\<Up>"
      let l:text = l:text . '↑'
    elseif l:key == "\<Right>"
      let l:text = l:text . '→'
    elseif l:key == "\<Left>"
      let l:text = l:text . '←'
    elseif l:key == "\<S-Down>"
      let l:text = l:text . 'Shift ↓'
    elseif l:key == "\<S-Up>"
      let l:text = l:text . 'Shift ↑'
    elseif l:key == "\<S-Right>"
      let l:text = l:text . 'Shift →'
    elseif l:key == "\<S-Left>"
      let l:text = l:text . 'Shift ←'
    elseif l:key == "\<C-Down>"
      let l:text = l:text . 'Ctrl ↓'
    elseif l:key == "\<C-Up>"
      let l:text = l:text . 'Ctrl ↑'
    elseif l:key == "\<C-Right>"
      let l:text = l:text . 'Ctrl →'
    elseif l:key == "\<C-Left>"
      let l:text = l:text . 'Ctrl ←'
    elseif l:key == "\<Enter>"
      let l:text = l:text . 'Enter'
    elseif l:key == "\<Esc>"
      let l:text = l:text . 'Esc'
    elseif l:key == "\<BS>"
      let l:text = l:text . 'BackSpace'
    elseif l:key == "/"
      let l:text = l:text . 'Slash'
    elseif l:key == "\\"
      let l:text = l:text . 'BackSlash'
    elseif l:key == "|"
      let l:text = l:text . 'Bar'
    elseif l:key == "<"
      let l:text = l:text . 'Less'
    elseif l:key == ">"
      let l:text = l:text . 'Greater'
    else
      let l:text = l:text . l:key
    endif

    if l:index < len(a:keys)
      let l:text = l:text . ' | '
      let l:index += 1
    endif
  endfor
  return l:text . ' >'
endfunction

"   Vim mappings {{{2

if exists('s:leader')                                 | unlet s:leader                                 | endif
if exists('s:shift_leader')                           | unlet s:shift_leader                           | endif

if exists('s:search_and_replace_mapping')             | unlet s:search_and_replace_mapping             | endif
if exists('s:search_and_replace_insensitive_mapping') | unlet s:search_and_replace_insensitive_mapping | endif
if exists('s:search_insensitive_mapping')             | unlet s:search_insensitive_mapping             | endif
if exists('s:past_unnamed_reg_in_cli_mapping')        | unlet s:past_unnamed_reg_in_cli_mapping        | endif
if exists('s:vsplit_vimrc_mapping')                   | unlet s:vsplit_vimrc_mapping                   | endif
if exists('s:source_vimrc_mapping')                   | unlet s:source_vimrc_mapping                   | endif
if exists('s:nohighlight_search_mapping')             | unlet s:nohighlight_search_mapping             | endif
if exists('s:toggle_good_practices_mapping')          | unlet s:toggle_good_practices_mapping          | endif
if exists('s:call_quit_function_mapping')             | unlet s:call_quit_function_mapping             | endif
if exists('s:call_writequit_function_mapping')        | unlet s:call_writequit_function_mapping        | endif
if exists('s:buffers_menu_mapping')                   | unlet s:buffers_menu_mapping                   | endif
if exists('s:explorer_mapping')                       | unlet s:explorer_mapping                       | endif
if exists('s:undotree_mapping')                       | unlet s:undotree_mapping                       | endif
if exists('s:window_next_mapping')                    | unlet s:window_next_mapping                    | endif
if exists('s:window_previous_mapping')                | unlet s:window_previous_mapping                | endif
if exists('s:unfold_vim_fold_mapping')                | unlet s:unfold_vim_fold_mapping                | endif
if exists('s:message_command_mapping')                | unlet s:message_command_mapping                | endif
if exists('s:map_command_mapping')                    | unlet s:map_command_mapping                    | endif
if exists('s:autocompletion_mapping')                 | unlet s:autocompletion_mapping                 | endif
if exists('s:mksession_mapping')                      | unlet s:mksession_mapping                      | endif
if exists('s:animate_statusline_mapping')             | unlet s:animate_statusline_mapping             | endif

" leader keys
const s:leader                                 =                             '²'
const s:shift_leader                           =                             '³'

const s:search_and_replace_mapping             =                             ':'
const s:search_and_replace_insensitive_mapping = s:leader       .            ':'
const s:search_insensitive_mapping             = s:leader       .            '/'
const s:past_unnamed_reg_in_cli_mapping        = s:leader       .            'p'
const s:vsplit_vimrc_mapping                   = s:leader       .            '&'
const s:source_vimrc_mapping                   = s:shift_leader .            '1'
const s:nohighlight_search_mapping             = s:leader       .            'é'
const s:toggle_good_practices_mapping          = s:leader       .            '"'
const s:call_quit_function_mapping             = s:leader       .            'q'
const s:call_writequit_function_mapping        = s:leader       .            'w'
const s:buffers_menu_mapping                   = s:leader       .       s:leader
const s:explorer_mapping                       = s:shift_leader . s:shift_leader
const s:undotree_mapping                       = s:shift_leader .            'U'
const s:window_next_mapping                    = s:leader       .      '<Right>'
const s:window_previous_mapping                = s:leader       .       '<Left>'
const s:unfold_vim_fold_mapping                =                       '<Space>'
const s:message_command_mapping                = s:leader       .            'm'
const s:map_command_mapping                    = s:leader       .           'mm'
const s:autocompletion_mapping                 =                       '<S-Tab>'
const s:mksession_mapping                      = s:leader       .            'z'
const s:animate_statusline_mapping             = s:leader       .            's'

" search and replace
execute 'vnoremap '          . s:search_and_replace_mapping
  \ . ' :s/\%V//g<Left><Left><Left>'

" search and replace (case-insensitive)
execute 'vnoremap '          . s:search_and_replace_insensitive_mapping
  \ . ' :s/\%V\c//g<Left><Left><Left>'

" search (case-insensitive)
execute 'nnoremap '          . s:search_insensitive_mapping
  \ . ' /\c'

" copy the unnamed register's content in the command line
" unnamed register = any text deleted or yank (with y)
execute 'cnoremap '          . s:past_unnamed_reg_in_cli_mapping
  \ . ' <C-R><C-O>"'

" open .vimrc in a vertical split window
execute 'nnoremap <silent> ' . s:vsplit_vimrc_mapping
  \ . ' :vsplit $MYVIMRC<CR>'

" source .vimrc
execute 'nnoremap <silent> ' . s:source_vimrc_mapping
  \ . ' :source $MYVIMRC <bar> call <SID>HighlightStatusLines()<CR>'

" stop highlighting from the last search
execute 'nnoremap <silent> ' . s:nohighlight_search_mapping
  \ . ' :nohlsearch<CR>'

" hide/show good practices
execute 'nnoremap <silent> ' . s:toggle_good_practices_mapping
  \ . ' :call <SID>ToggleRedHighlight()<CR>'

" create session
execute 'nnoremap <silent> ' . s:mksession_mapping
  \ . ' :mksession! <bar> call <SID>HighlightStatusLines()<CR>'

" animate statusline
execute 'nnoremap <silent> ' . s:animate_statusline_mapping
  \ . ' :call <SID>AnimateStatusLine()<CR>'

" buffers menu
execute 'nnoremap <silent> ' . s:buffers_menu_mapping
  \ . ' :call <SID>DisplayBuffersMenu()<CR>'

" explorer
execute 'nnoremap <silent> ' . s:explorer_mapping
  \ . ' :call <SID>DisplayExplorer()<CR>'

" undotree
execute 'nnoremap <silent> ' . s:undotree_mapping
  \ . ' :call <SID>DisplayUndotree()<CR>'

" windows navigation
execute 'nnoremap <silent> ' . s:window_next_mapping
  \ . ' :silent call <SID>NextWindow()<CR>'
execute 'nnoremap <silent> ' . s:window_previous_mapping
  \ . ' :silent call <SID>PreviousWindow()<CR>'

" unfold vimscipt's folds
execute 'nnoremap '          . s:unfold_vim_fold_mapping
  \ . ' za'

" for debug purposes
execute 'nnoremap '          . s:message_command_mapping
  \ . ' :messages<CR>'
execute 'nnoremap '          . s:map_command_mapping
  \ . ' :map<CR>'

" autocompletion
execute 'inoremap '          . s:autocompletion_mapping
  \ . ' <C-n>'

"   }}}
"   Buffers menu keys {{{2

if exists('s:next_menukey')     | unlet s:next_menukey     | endif
if exists('s:previous_menukey') | unlet s:previous_menukey | endif
if exists('s:select_menukey')   | unlet s:select_menukey   | endif
if exists('s:delete_menukey')   | unlet s:delete_menukey   | endif
if exists('s:exit_menukey')     | unlet s:exit_menukey     | endif
if exists('s:select_menuchars') | unlet s:select_menuchars | endif
if exists('s:erase_menukey')    | unlet s:erase_menukey    | endif
if exists('s:help_menukey')     | unlet s:help_menukey     | endif

const s:next_menukey     =  "\<Down>"
const s:previous_menukey =    "\<Up>"
const s:select_menukey   = "\<Enter>"
const s:delete_menukey   =        "d"
const s:exit_menukey     =   "\<Esc>"
const s:select_menuchars =   '\d\|\$'
const s:erase_menukey    =    "\<BS>"
const s:help_menukey     =        "?"

"   }}}
"   Explorer keys {{{2

if exists('s:next_file_explkey')      | unlet s:next_file_explkey      | endif
if exists('s:previous_file_explkey')  | unlet s:previous_file_explkey  | endif
if exists('s:first_file_explkey')     | unlet s:first_file_explkey     | endif
if exists('s:last_file_explkey')      | unlet s:last_file_explkey      | endif
if exists('s:dotfiles_explkey')       | unlet s:dotfiles_explkey       | endif
if exists('s:yank_explkey')           | unlet s:yank_explkey           | endif
if exists('s:badd_explkey')           | unlet s:badd_explkey           | endif
if exists('s:open_explkey')           | unlet s:open_explkey           | endif
if exists('s:reset_explkey')          | unlet s:reset_explkey          | endif
if exists('s:exit_explkey')           | unlet s:exit_explkey           | endif
if exists('s:help_explkey')           | unlet s:help_explkey           | endif
if exists('s:searchmode_explkey')     | unlet s:searchmode_explkey     | endif
if exists('s:next_match_explkey')     | unlet s:next_match_explkey     | endif
if exists('s:previous_match_explkey') | unlet s:previous_match_explkey | endif
if exists('s:left_smexplkey')         | unlet s:left_smexplkey         | endif
if exists('s:right_smexplkey')        | unlet s:right_smexplkey        | endif
if exists('s:wide_left_smexplkey')    | unlet s:wide_left_smexplkey    | endif
if exists('s:wide_right_smexplkey')   | unlet s:wide_right_smexplkey   | endif
if exists('s:next_smexplkey')         | unlet s:next_smexplkey         | endif
if exists('s:previous_smexplkey')     | unlet s:previous_smexplkey     | endif
if exists('s:evaluate_smexplkey')     | unlet s:evaluate_smexplkey     | endif
if exists('s:erase_smexplkey')        | unlet s:erase_smexplkey        | endif
if exists('s:exit_smexplkey')         | unlet s:exit_smexplkey         | endif

const s:next_file_explkey      =    "\<Down>"
const s:previous_file_explkey  =      "\<Up>"
const s:first_file_explkey     =          "g"
const s:last_file_explkey      =          "G"
const s:dotfiles_explkey       =          "."
const s:yank_explkey           =          "y"
const s:badd_explkey           =          "b"
const s:open_explkey           =          "o"
const s:reset_explkey          =          "c"
const s:exit_explkey           =     "\<Esc>"
const s:help_explkey           =          "?"
const s:searchmode_explkey     =          "/"
const s:next_match_explkey     =          "n"
const s:previous_match_explkey =          "N"
const s:right_smexplkey        =   "\<Right>"
const s:left_smexplkey         =    "\<Left>"
const s:wide_right_smexplkey   = "\<C-Right>"
const s:wide_left_smexplkey    =  "\<C-Left>"
const s:next_smexplkey         =    "\<Down>"
const s:previous_smexplkey     =      "\<Up>"
const s:evaluate_smexplkey     =   "\<Enter>"
const s:erase_smexplkey        =      "\<BS>"
const s:exit_smexplkey         =     "\<Esc>"

"   }}}
"   Obsession keys {{{2

if exists('s:yes_obsessionkey') | unlet s:yes_obsessionkey | endif
if exists('s:no_obsessionkey')  | unlet s:no_obsessionkey  | endif

const s:yes_obsessionkey = "y"
const s:no_obsessionkey  = "n"

"   }}}
"   Undo tree keys {{{2

if exists('s:next_undokey')     | unlet s:next_undokey     | endif
if exists('s:previous_undokey') | unlet s:previous_undokey | endif
if exists('s:select_undokey')   | unlet s:select_undokey   | endif
if exists('s:exit_undokey')     | unlet s:exit_undokey     | endif
if exists('s:help_undokey')     | unlet s:help_undokey     | endif

const s:next_undokey     =  "\<Down>"
const s:previous_undokey =    "\<Up>"
const s:select_undokey   = "\<Enter>"
const s:exit_undokey     =   "\<Esc>"
const s:help_undokey     =        "h"

"   }}}
" }}}
" Abbreviations {{{1

" avoid intuitive write usage
cnoreabbrev w update

" avoid intuitive tabpage usage
cnoreabbrev tabe silent tabonly

" allow vertical split designation with bufnr instead of full filename
cnoreabbrev vb vertical sbuffer

" next-previous intuitive usage for multi file opening
cnoreabbrev fn next
cnoreabbrev fp previous

" allow to ignore splitbelow option for help split
cnoreabbrev h top help
cnoreabbrev help top help

" }}}
" Autocommands {{{1

augroup vimrc_autocomands
  autocmd!
"   Dependencies autocommands {{{2

  autocmd VimEnter * :call <SID>CheckDependencies()

"   }}}
"   Color autocommands {{{2

  autocmd WinEnter * set wincolor=NormalAlt

"   }}}
"   Good practices autocommands {{{2

  autocmd BufEnter * :silent call <SID>ExtraSpaces() |
    \ silent call <SID>OverLength()

"   }}}
"   Buffers autocommands {{{2

  autocmd BufEnter * :silent call <SID>CloseLonelyUnlistedBuffers()

"   }}}
"   Plugins autocommands {{{3
"     Obsessions autocommands {{{3

  autocmd VimLeavePre * :call <SID>DisplayObsession()

"     }}}
"   }}}
"   Filetype specific autocommands {{{3
"     Vimscript autocommands {{{3

  autocmd FileType vim setlocal foldmethod=marker

"     }}}
"     Tmux autocommands {{{3

  autocmd FileType tmux setlocal foldmethod=marker

"     }}}
"     Bash autocommands {{{3

  autocmd BufNewFile *.sh :call <SID>PrefillShFile()

"     }}}
"   }}}
augroup END

" }}}
