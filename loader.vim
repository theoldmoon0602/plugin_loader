" PluginLoader : A VimPlugin Loader & Downloader

" Include Guard
if exists('g:loader_loaded')
  finish
endif
let g:loader_loaded=1

" Command Definitions
command! -nargs=1 LoadPlugin <args>

" Variables
let g:loader#dir=expand("<sfile>:h") . "/plugins"

" Python Script
python3 << ENDPYTHON
import vim, os, sys, subprocess

def loader_append_to_rtp(p):
  """ add a plugin path to runtimepath last """
  print("ADD: " + p)
  if os.path.isdir(p):
    vim.command('set rtp+=' + p)

def loader_load_local_plugin(name):
  """ load local vim plugin -- add plugin path to runtimepath """
  rtp = [vim.eval("g:loader#dir")] + [os.path.normpath(p) for p in vim.list_runtime_paths()]
  plugindirs = [os.path.join(p, name)
    for p in rtp
      if os.path.isdir(p) and (name in os.listdir(p))]
  if not plugindirs:
    return False
  for p in plugindirs:
    [vim.command("helptags " + doc) for doc in [os.path.join(p, "doc")] if os.path.isdir(doc)]
    loader_append_to_rtp(p)
  return True

def loader_clone_from_github(u, loader_dir):
  """ clone plugin to loader_dir """
  try:
    subprocess.run(["git", "clone", "--recursive", u.githuburl, os.path.join(loader_dir, u.pluginname)], check=True)
  except:
    return False
  return True

def loader_load(name):
  """ load plugin and try to clone from github """
  p = loader_parsename(name)

  if not p.pluginname:
    vim.err_write("Invalid Plugin Name : " + name)
    return

  if loader_load_local_plugin(p.pluginname):
    return

  if not p.githuburl:
    vim.err_write("Failed to load : " + name)
    return

  if not loader_clone_from_github(p, vim.eval("g:loader#dir")):
    vim.err_write("Failed to clone from : " + p.githuburl)
    return

  if not loader_load_local_plugin(p.pluginname):
    vim.err_write("Failed to load : " + name)

def loader_parsename(name):
  """ parse given name to github url and repository name and plugin name """
  import re, os
  GITHUBPREFIX="https://github.com/"
  if name.startswith(GITHUBPREFIX):
    githuburl = name
    pluginname = os.path.basename(name[len(GITHUBPREFIX):])
  elif re.match("^[A-Za-z0-9\-]+\/[A-Za-z0-9\-\.]+$", name):
    githuburl = GITHUBPREFIX + name 
    pluginname = os.path.basename(name)
  else:
    githuburl = None
    pluginname = name

  from collections import namedtuple
  return namedtuple('PluginPath', ['githuburl', 'pluginname'])(githuburl, pluginname)
ENDPYTHON

" Function Definition
function! loader#load(name)
  python3 loader_load(vim.eval('a:name'))
endf

