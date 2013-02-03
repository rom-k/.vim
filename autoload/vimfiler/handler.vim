"=============================================================================
" FILE: handler.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Oct 2012.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================


function! vimfiler#handler#_event_handler(event_name, ...)  "{{{1
  let context = vimfiler#initialize_context(get(a:000, 0, {}))
  let path = get(context, 'path',
        \ vimfiler#util#substitute_path_separator(expand('<afile>')))

  let ret = vimfiler#parse_path(path)
  let source_name = ret[0]
  let source_args = ret[1:]

  return s:on_{a:event_name}(source_name, source_args, context)
endfunction

" Event Handlers.

function! s:on_BufReadCmd(source_name, source_args, context)  "{{{1
  " Check path.
  let ret = unite#vimfiler_check_filetype(
        \ [insert(a:source_args, a:source_name)])
  if empty(ret)
    " File not found.
    return
  endif
  let [type, info] = ret

  let bufnr = bufnr('%')

  let b:vimfiler = {}
  let b:vimfiler.source = a:source_name
  let b:vimfiler.context = a:context
  let b:vimfiler.bufnr = bufnr('%')
  if type ==# 'directory'
    call s:initialize_vimfiler_directory(info, a:context)
  elseif type ==# 'file'
    call s:initialize_vimfiler_file(a:source_args, info[0], info[1])
  else
    call vimfiler#print_error('Unknown filetype.')
  endif

  if bufnr('%') != bufnr
    " Restore window.
    execute bufwinnr(bufnr).'wincmd w'
  endif

  call vimfiler#set_current_vimfiler(b:vimfiler)
endfunction

function! s:on_BufWriteCmd(source_name, source_args, context)  "{{{1
  " BufWriteCmd is published by :write or other commands with 1,$ range.
  return s:write(a:source_name, a:source_args, 1, line('$'), 'BufWriteCmd')
endfunction


function! s:on_FileAppendCmd(source_name, source_args, context)  "{{{1
  " FileAppendCmd is published by :write or other commands with >>.
  return s:write(a:source_name, a:source_args, line("'["), line("']"), 'FileAppendCmd')
endfunction


function! s:on_FileReadCmd(source_name, source_args, context)  "{{{1
  " Check path.
  let ret = unite#vimfiler_check_filetype(
        \ [insert(a:source_args, a:source_name)])
  if empty(ret)
    " File not found.
    call vimfiler#print_error(
          \ printf('Can''t open "%s".', join(a:source_args, ':')))
    return
  endif
  let [type, info] = ret

  if type !=# 'file'
    call vimfiler#print_error(
          \ printf('"%s" is not a file.', join(a:source_args, ':')))
    return
  endif

  call append(line('.'), info[0])
endfunction


function! s:on_FileWriteCmd(source_name, source_args, context)  "{{{1
  " FileWriteCmd is published by :write or other commands with partial range
  " such as 1,2 where 2 < line('$').
  return s:write(a:source_name, a:source_args, line("'["), line("']"), 'FileWriteCmd')
endfunction

function! s:write(source_name, source_args, line1, line2, event_name)  "{{{1
  if !exists('b:vimfiler') || !has_key(b:vimfiler, 'current_file') || !&l:modified
    return
  endif

  try
    setlocal nomodified

    call unite#mappings#do_action('vimfiler__write',
          \ [b:vimfiler.current_file], {
          \ 'vimfiler__line1' : a:line1,
          \ 'vimfiler__line2' : a:line2,
          \ 'vimfiler__eventname' : a:event_name,
          \ })
  catch
    call vimfiler#print_error(v:exception . ' ' . v:throwpoint)
    setlocal modified
  endtry
endfunction

function! s:initialize_vimfiler_directory(directory, context) "{{{1
  " Set current directory.
  let current = vimfiler#util#substitute_path_separator(
        \ a:directory)
  let b:vimfiler.current_dir = current
  if b:vimfiler.current_dir !~ '[:/]$'
    let b:vimfiler.current_dir .= '/'
  endif
  let b:vimfiler.current_files = []
  let b:vimfiler.original_files = []

  let b:vimfiler.is_visible_dot_files = 0
  let b:vimfiler.simple = a:context.simple
  let b:vimfiler.directory_cursor_pos = {}
  let b:vimfiler.current_mask = ''
  let b:vimfiler.clipboard = {}

  let b:vimfiler.global_sort_type = g:vimfiler_sort_type
  let b:vimfiler.local_sort_type = g:vimfiler_sort_type
  let b:vimfiler.is_safe_mode = g:vimfiler_safe_mode_by_default
  let b:vimfiler.winwidth = winwidth(0)
  let b:vimfiler.another_vimfiler_bufnr = -1
  call vimfiler#set_current_vimfiler(b:vimfiler)

  call vimfiler#default_settings()
  call vimfiler#mappings#define_default_mappings(a:context)

  set filetype=vimfiler

  " Initialize syntax. "{{{
  let leaf_icon = vimfiler#util#escape_pattern(
        \ g:vimfiler_tree_leaf_icon)
  let opened_icon = vimfiler#util#escape_pattern(
        \ g:vimfiler_tree_opened_icon)
  let closed_icon = vimfiler#util#escape_pattern(
        \ g:vimfiler_tree_closed_icon)
  let ro_file_icon = vimfiler#util#escape_pattern(
        \ g:vimfiler_readonly_file_icon)
  let file_icon = vimfiler#util#escape_pattern(
        \ g:vimfiler_file_icon)
  let marked_file_icon = vimfiler#util#escape_pattern(
        \ g:vimfiler_marked_file_icon)

  execute 'syntax match   vimfilerMarkedFile'
        \ '''^\s*\%('  . leaf_icon .'\)\?'
        \ . marked_file_icon . ' .*$'''
        \ 'contains=vimfilerDate,vimfilerDateToday,vimfilerDateWeek'
  execute 'syntax match   vimfilerNonMark'
        \ '''^\s*\%('.leaf_icon.'\)\?\%('.opened_icon.'\|'
        \ .closed_icon.'\|'.ro_file_icon'\|'.file_icon.'\)'' contained'
  "}}}

  if a:context.double
    " Create another vimfiler.
    call vimfiler#mappings#create_another_vimfiler()
    wincmd p
  endif

  if a:context.winwidth != 0
    execute 'vertical resize' a:context.winwidth
  endif

  call vimfiler#force_redraw_all_vimfiler()
endfunction"}}}
function! s:initialize_vimfiler_file(path, lines, dict) "{{{1
  " Set current directory.
  let b:vimfiler.current_path = a:path
  let b:vimfiler.current_file = a:dict

  " Clean up the screen.
  % delete _

  augroup vimfiler
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer>
          \ call vimfiler#handler#_event_handler('BufWriteCmd')
  augroup END

  call setline(1, a:lines)

  setlocal buftype=acwrite
  setlocal noswapfile

  " For filetype detect.
  execute 'doautocmd BufRead' fnamemodify(a:path[-1], ':t')

  let &fileencoding = get(a:dict, 'vimfiler__encoding', '')

  setlocal nomodified
endfunction"}}}

" vim: foldmethod=marker