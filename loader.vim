let s:fdir=expand("<sfile>:p:h")

command! -nargs=1 LoadPlugin <args>

function! loader#load(name)
  let l:pyname = s:fdir . '/loader.py'
  python3 << ENDPYTHON
    
import vim, os, sys
from itertools import chain 

def loader_getchilddirs(d, names):
  """ get specified child directory against d(direcotry) """
  return [p
    for n in names
      for p in [os.path.join(d, n)] # temporary variable
        if os.path.isdir(p)]

def loader_getsourcedirs(d):
  """ get vim script directories """
  return loader_getchilddirs(d, ["plugin", "autoload"])

def loader_getdocdirs(d):
  """ get document directory named "doc" """
  return loader_getchilddirs(d, ["doc"])

def loader_genhelptags(ds):
  """ registry document directory """
  map(lambda p: vim.command("helptags {}".format(p)), ds)

def loader_getsources(d):
  """ get vim script source files from d(directory)"""
  return [os.path.join(d, p)
    for p in os.listdir(d)
      if p.endswith('.vim') or p.endswith('.nvim')]

def loader_loadsources(fs):
  """ load vim script source files """
  for f in fs:
    vim.command('source {}'.format(f))

def loader_prepend_to_rtp(p):
  """ add a plugin path to runtimepath head """
  if os.path.isdir(p):
    vim.command('set rtp^=' + p)

def loader_append_to_rtp(p):
  """ add a plugin path to runtimepath last """
  if os.path.isdir(p):
    vim.command('set rtp+=' + p)

def loader_load(name):
  """ load vim plugin """
  rtp = [os.path.normpath(p) for p in vim.list_runtime_paths()]
  rtp = list(set(rtp))
  plugindirs = [os.path.join(p, name)
    for p in rtp
      if os.path.isdir(p) and (name in os.listdir(p))]
  if not plugindirs:
    sys.stderr.write("Plugin directory not found: {}\n".format(name))

  for p in plugindirs:
    [loader_genhelptags(d) for d in loader_getdocdirs(p)]
    loader_append_to_rtp(p)

ENDPYTHON
  python3 loader_load(vim.eval('a:name'))
endf

