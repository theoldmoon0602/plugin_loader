" PluginLoader : A VimPlugin Loader & Downloader

" Include Guard
if exists('g:loader_loaded')
  finish
endif
let g:loader_loaded=1

" Command Definitions
command! -nargs=1 LoadPlugin <args>

" Python Script
python3 << ENDPYTHON
import vim, os, sys, subprocess
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

def loader_load_local_plugin(name):
  """ load local vim plugin """
  rtp = [os.path.normpath(p) for p in vim.list_runtime_paths()]
  rtp = list(set(rtp))
  plugindirs = [os.path.join(p, name)
    for p in rtp
      if os.path.isdir(p) and (name in os.listdir(p))]
  if not plugindirs:
    return False
  for p in plugindirs:
    [loader_genhelptags(d) for d in loader_getdocdirs(p)]
    loader_append_to_rtp(p)
  return True

def loader_clone_from_github(u, loader_dir):
  """ clone plugin to loader_dir """
  from urllib.parse import urljoin
  u1, u2 = u.split("/")
  try:
    subprocess.run(["git", "clone", "--recursive", urljoin("https://github.com/", u), os.path.join(loader_dir, u2)], check=True)
  except:
    return False
  return True

def loader_load(name):
  """ load vim plugin """
  p = name.rfind("/", 0, -1)
  localname = name
  if p != -1:
    localname = name[p+1:]
  if loader_load_local_plugin(localname):
    return

  u = loader_githubrepo_normalize(name)
  if not u:
    vim.command("echoerr 'Plugin Load Failed: " + name + "'")
    return

  if not loader_clone_from_github(u, os.path.expanduser("~/.config/nvim/")):
    vim.command("echoerr 'Plugin Clone Failed: " + name + "'")
    return

  if not loader_load_local_plugin(localname):
    vim.command("echoerr 'Plugin Load Failed: " + name + "'")
    return


def loader_githubrepo_normalize(url):
  """ normalize github repsitory url. If invalid url given, return None """
  if url[:len("https://")] == "https://":
    url = url[len("https://"):]
  if url[:len("github.com")] == "github.com":
    url = url[len("github.com/"):]

  import re
  if re.match(r"[a-zA-Z0-9]+/[a-zA-Z0-9\.]+$", url) == None:
    return None
  return url
ENDPYTHON

" Function Definition
function! loader#load(name)
  python3 loader_load(vim.eval('a:name'))
endf

