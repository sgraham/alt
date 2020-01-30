" Copyright 2012 The Chromium Authors. All rights reserved.
" Use of this source code is governed by a BSD-style license that can be
" found in the LICENSE file.
"
" Scott Graham <scott.vimalt@h4ck3r.net>


if !has('python3')
  s:ErrMsg( "Error: Required vim compiled with +python3" )
  finish
endif

execute 'py3file ' expand('<sfile>:p:h') . '/alt.py'

function! AltFileAll()
python3 << endpython
import vim
name = vim.current.buffer.name
alt = get_alternate_file(name, False)
vim.command('edit ' + alt)
endpython
endfunction

function! AltFileThisOs()
python3 << endpython
import vim
name = vim.current.buffer.name
alt = get_alternate_file(name, True)
vim.command('edit ' + alt)
endpython
endfunction

if !exists('g:alt_no_maps')
  map <silent> - :call AltFileAll()<cr>
  map <silent> ` :call AltFileThisOs()<cr>
endif
