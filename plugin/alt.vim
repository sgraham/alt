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

def get_alternate_file(filename, this_os=False, file_exists=os.path.exists):
  """Return the next alternate name for a file.

  'next' in this context means that repeated calls are stable so that if
  a.h, a.c, and a.cc all exist, then repeated calls will cycle amongst them.

  >>> files = ['wee.cc', 'wee.h',]
  >>> file_exists = lambda x: x in files

  >>> get_alternate_file('wee.h', file_exists=file_exists)
  'wee.cc'
  >>> get_alternate_file('wee.cc', file_exists=file_exists)
  'wee.h'

  >>> files = ['wee.h', 'wee_win.cc', 'wee_aura.cc', 'wee_mac.cc']
  >>> get_alternate_file('wee.h', file_exists=file_exists)
  'wee_aura.cc'
  >>> get_alternate_file('wee_aura.cc', file_exists=file_exists)
  'wee_mac.cc'
  >>> get_alternate_file('wee_mac.cc', file_exists=file_exists)
  'wee_win.cc'
  >>> get_alternate_file('wee_win.cc', file_exists=file_exists)
  'wee.h'

  >>> files = ['zircon/kernel/object/event_dispatcher.cpp', 'zircon/kernel/object/glue.cpp', 'zircon/kernel/object/include/object/event_dispatcher.h']
  >>> get_alternate_file('zircon/kernel/object/event_dispatcher.cpp', file_exists=file_exists)
  'zircon/kernel/object/include/object/event_dispatcher.h'
  >>> get_alternate_file('zircon/kernel/object/include/object/event_dispatcher.h', file_exists=file_exists)
  'zircon/kernel/object/event_dispatcher.cpp'
  >>> get_alternate_file('zircon/kernel/object/glue.cpp', file_exists=file_exists)
  Traceback (most recent call last):
    ...
  ValueError: Couldn't find any alternate for 'zircon/kernel/object/glue.cpp'


  >>> files = ['zircon/kernel/lib/oom/include/lib/oom.h', 'zircon/kernel/lib/oom/oom.cpp']
  >>> get_alternate_file('zircon/kernel/lib/oom/include/lib/oom.h', file_exists=file_exists)
  'zircon/kernel/lib/oom/oom.cpp'
  >>> get_alternate_file('zircon/kernel/lib/oom/oom.cpp', file_exists=file_exists)
  'zircon/kernel/lib/oom/include/lib/oom.h'
  """

  root, ext = os.path.splitext(filename)
  underscore_exts = [
    'aura',
    'aurawin',
    'aurax11',
    'gtk',
    'linux',
    'mac',
    'posix',
    'win',
    'unittest',
    'test',
  ]

  if this_os:
    if sys.platform.startswith('win32'):
      underscore_exts = [ 'aura', 'aurawin', 'win', 'win32' ]
    elif sys.platform.startswith('linux'):
      underscore_exts = [ 'aura', 'auralinux', 'fuchsia', 'posix', 'linux' ]
    elif sys.platform.startswith('darwin'):
      underscore_exts = [ 'mac', 'posix' ]
    else:
      raise ValueError('TODO: platform')

  extension_cycle = [ '.h', '.cc', '.cpp', '.c' ]
  extension_cycle += ['_' + x + '.h' for x in underscore_exts]
  extension_cycle += ['_' + x + '.cc' for x in underscore_exts]
  extension_cycle += ['_' + x + '.mm' for x in underscore_exts]
  extension_cycle += ['_' + x + '.c' for x in underscore_exts]
  extension_cycle += ['_' + x + '.m' for x in underscore_exts]
  extension_cycle += ['-' + x + '.h' for x in underscore_exts]
  extension_cycle += ['-' + x + '.cc' for x in underscore_exts]
  extension_cycle += ['-' + x + '.c' for x in underscore_exts]

  for variant in underscore_exts:
    if root.endswith('_' + variant):
      at = -(len(variant) + 1)
      root = root[:at]
      ext = '_' + variant + ext
      break

  # This is for Zircon's files that are split between fairly complicated header
  # and source locations.
  style = os.path.basename(os.path.dirname(os.path.dirname(root)))
  possible_root_locations = [root,
          os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(root))),
                       os.path.basename(root)),
          os.path.join(os.path.dirname(root), 'include', style,
                       os.path.basename(os.path.dirname(root))),
          os.path.join(os.path.dirname(root), 'include',
                       os.path.basename(os.path.dirname(root)),
                       os.path.basename(root))
          ]

  if ext not in extension_cycle:
    raise ValueError("Don't know how to handle '%s' for '%s'" % (ext, filename))
  index = extension_cycle.index(ext)
  while True:
    index = (index + 1) % len(extension_cycle)
    if extension_cycle[index] == ext:
      raise ValueError("Couldn't find any alternate for '%s'" % filename)
    for possible_root in possible_root_locations:
      candidate = possible_root + extension_cycle[index]
      if file_exists(candidate):
        return candidate
endpython

function! AltFileAll()
python << endpython
import vim
name = vim.current.buffer.name
alt = get_alternate_file(name, False)
vim.command('edit ' + alt)
endpython
endfunction

function! AltFileThisOs()
python << endpython
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
