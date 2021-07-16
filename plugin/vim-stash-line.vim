"% Preliminary validation of global variables
"  and version of the editor.

if v:version < 700
  finish
endif

" check whether this script is already loaded
if exists('g:loaded_stash_line')
  finish
endif

let g:loaded_stash_line = 1

if !exists('g:stash_line_trace')
  let g:stash_line_trace = 0
endif

if !exists('g:stash_line_open_command')
  if has('win16') || has('win32') || has('win64')
    let g:stash_line_open_command = 'start '
  elseif has('mac') || has('macunix') || has('gui_macvim')
    let g:stash_line_open_command = 'open '
  elseif executable('xdg-open')
    let g:stash_line_open_command = 'xdg-open '
  endif
endif

if !exists('g:stash_line_map')
  let g:stash_line_map = '<leader>st'
endif

if !exists('g:stash_line_git_remote')
  let g:stash_line_git_remote = ""
endif

func! s:stash_line() range
  " Get Line Number/s
  let lineNum = line('.')
  let fileName = resolve(expand('%:t'))
  let fileDir = resolve(expand("%:p:h"))
  let cdDir = "cd '" . fileDir . "'; "

  let l:remotes = system(cdDir . "git remote")
  let l:remote_list = split(l:remotes, '\n')
  if len(l:remote_list) == 0
    echom "It seems the repo does not have any remote"
    return
  endif

  " try to find git remote:
  " if force interactive input, or g:gh_git_remote is not set, or
  " g:stash_line_git_remote is not the remote of current file, try to find git
  " remote name again
  if g:stash_line_git_remote == "" || index(l:remote_list, g:stash_line_git_remote) < 0
    let g:stash_line_git_remote = s:find_git_remote(l:remote_list)
  endif

  if g:stash_line_git_remote == ""
    return
  endif

  let remote_url = system(cdDir . "git config --get remote." . g:stash_line_git_remote . ".url")

  " Get Directory & File Names
  let fullPath = resolve(expand("%:p"))
  " Git Commands
  let commit = s:Commit(cdDir)
  let gitRoot = system(cdDir . "git rev-parse --show-toplevel")

  " Strip Newlines
  let remote_url = <SID>StripNL(remote_url)
  let commit = <SID>StripNL(commit)
  let gitRoot = <SID>StripNL(gitRoot)
  let fullPath = <SID>StripNL(fullPath)

  " Git Relative Path
  let relative = split(fullPath, gitRoot)[-1]

  if s:Stash(remote_url)
    let lineRange = s:StashLineRange(a:firstline, a:lastline, lineNum)
    let url = s:StashUrl(remote_url) . '/browse' . relative . '#' . lineRange
  else
    throw 'The remote: ' . remote_url . ' has not been recognized as belonging to ' .
      \ 'one of the supported git hosting environments: ' .
      \ 'Stash.'
  endif

  let l:finalCmd = g:stash_line_open_command . url
  if g:stash_line_trace
    echom "vim-stash-line executing: " . l:finalCmd
  endif
  call system(l:finalCmd)
endfunc

func! s:Stash(remote_url)
  return match(a:remote_url, 'stash.msk.avito.ru') >= 0
endfunc

func! s:StashLineRange(firstLine, lastLine, lineNum)
  if a:firstLine == a:lastLine
    return a:lineNum
  else
    return a:firstLine . ':' . a:lastLine
  endif
endfunc

func! s:StashUrl(remote_url)
  let l:rv = s:TransformSSHToHTTPS(a:remote_url)
  let l:rv = s:StripNL(l:rv)
  let l:rv = s:StripSuffix(l:rv, '.git')

  return l:rv
endfunc

func! s:StripNL(l)
  return substitute(a:l, '\n$', '', '')
endfun

func! s:StripSuffix(input,fix)
  return substitute(a:input, a:fix . '$' , '', '')
endfun

func! s:StripPrefix(input,fix)
  return substitute(a:input, '^' . a:fix , '', '')
endfun

func! s:TransformSSHToHTTPS(input)
  " If the remote is using ssh protocol, we need to turn a git remote like this:
  " `git@github.com:<suffix>`
  " or
  " `ssh://git@github.com/<suffix>`
  " To a url like this:
  " `https://github.com/<suffix>`
  let l:rv = a:input
  "let l:sed_cmd = "sed 's\/^[^@]*@\\([^:\\\/]*\\)[:\\\/]\/https:\\\/\\\/\\1\\\/\/;'"
  let l:sed_cmd = "sed 's\/^[^@]*@\\([^:\\\/]*\\)[:\\\/0-9]*\\(\\/[a-z]*\\/\\)/https:\\\/\\\/\\1\\\/projects\\2repos\\\//;'"
  let l:rv = system("echo " . l:rv . " | " . l:sed_cmd)
  return l:rv
endfun

func! s:find_git_remote(remote_list)
  let l:remote = ""

  if len(a:remote_list) > 1
    call inputsave()
    let l:remote = input('Please select one remote(' . join(a:remote_list, ',') . '): ')
    call inputrestore()

    if index(a:remote_list, l:remote) < 0
      echom " <- seems it is not a valid remote name"
      let l:remote = ""
    endif
  elseif len(a:remote_list) == 1
    let l:remote = a:remote_list[0]
  endif

  return l:remote
endfunc

func! s:Commit(cdDir)
  return system(a:cdDir . 'git rev-parse --abbrev-ref HEAD')
endfunc

noremap <silent> <Plug>(stash-line) :call <SID>stash_line()<CR>
if !hasmapto('<Plug>(stash-line)') && exists('g:stash_line_map')
    exe "map" g:stash_line_map "<Plug>(stash-line)"
end
