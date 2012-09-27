" Copyright 2012 The Chromium Authors. All rights reserved.
" Use of this source code is governed by a BSD-style license that can be
" found in the LICENSE file.
"
" Scott Graham <scott.vimalt@h4ck3r.net>


if !has('python')
  s:ErrMsg( "Error: Required vim compiled with +python" )
  finish
endif

python << endpython
import os

def get_alternate_file(filename, file_exists=os.path.exists):
  """Return the next alternate name for a file.

  'next' in this context means that repeated calls are stable so that if
  a.h, a.c, and a.cc all exist, then repeated calls will cycle amongst them.

  >>> files = ['wee.cc', 'wee.h',]
  >>> file_exists = lambda x: x in files
  
  >>> get_alternate_file('wee.h', file_exists)
  'wee.cc'
  >>> get_alternate_file('wee.cc', file_exists)
  'wee.h'

  >>> files = ['wee.h', 'wee_win.cc', 'wee_aura.cc', 'wee_mac.cc']
  >>> get_alternate_file('wee.h', file_exists)
  'wee_aura.cc'
  >>> get_alternate_file('wee_aura.cc', file_exists)
  'wee_mac.cc'
  >>> get_alternate_file('wee_mac.cc', file_exists)
  'wee_win.cc'
  >>> get_alternate_file('wee_win.cc', file_exists)
  'wee.h'
  """

  root, ext = os.path.splitext(filename)
  underscore_exts = [
    'aura',
    'gtk',
    'linux',
    'mac',
    'posix',
    'win',
    'unittest',
  ]

  extension_cycle = [ '.h', '.cc', '.cpp' ]
  extension_cycle += ['_' + x + '.cc' for x in underscore_exts]

  orig_root = root
  for variant in underscore_exts:
    if root.endswith('_' + variant):
      at = -(len(variant) + 1)
      root = root[:at]
      ext = '_' + variant + ext
      break

  if ext not in extension_cycle:
    raise ValueError("Don't know how to handle '%s' for '%s'" % (ext, filename))
  index = extension_cycle.index(ext)
  while True:
    index = (index + 1) % len(extension_cycle)
    if extension_cycle[index] == ext:
      raise ValueError("Couldn't find any alternate for '%s'" % filename)
    candidate = root + extension_cycle[index]
    if file_exists(candidate):
      return candidate
endpython

function! AltFile()
python << endpython
import vim
name = vim.current.buffer.name
alt = get_alternate_file(name)
vim.command('edit ' + alt)
endpython
endfunction

map <silent> <tab> :call AltFile()<cr>
