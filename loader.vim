let s:fdir=expand("<sfile>:p:h")
function loader#load(name)
  let l:pyname = s:fdir . '/loader.py'
  python3 << ENDPYTHON
    
import vim, os

def loader_getchilddirs(d):
  """ get specified child directory against d(direcotry) """
  names = ["plugin", "autoload"]
  return [p
    for n in names
      for p in [os.path.join(d, n)] # temporary variable
        if os.path.isdir(p)]
  

def loader_getsources(d):
  """ get vim script source files from d(directory)"""
  return [os.path.join(d, p)
    for p in os.listdir(d)
      if p.endswith('.vim') or p.endswith('.nvim')]

def loader_loadsources(fs):
  """ load vim script source files """
  for f in fs:
    vim.command('source {}'.format(f))

def loader_load(name):
  """ load vim plugin """
  rtp = [os.path.normpath(p.rstrip('after')) for p in vim.eval("&rtp").split(",")]
  rtp = list(set(rtp))
  dirpathes = [os.path.join(p, name)
    for p in rtp
      if os.path.isdir(p) and (name in os.listdir(p))]
  fs = [f
    for d in dirpathes
      for c in loader_getchilddirs(d)
        for f in loader_getsources(c)]
  loader_loadsources(fs)

ENDPYTHON
  python3 loader_load(vim.eval('a:name'))
endf

