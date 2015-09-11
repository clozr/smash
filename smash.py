#!/usr/bin/env python
import os, sys
from optparse import OptionParser
from core import recipes, get_config
from fabric.api import env

from optparse import OptionParser, BadOptionError

class PassThroughOptionParser(OptionParser):
  def _process_long_opt(self, rargs, values):
    try:
      OptionParser._process_long_opt(self, rargs, values)
    except BadOptionError, err:
      self.largs.append(err.opt_str)

  def _process_short_opts(self, rargs, values):
    try:
      OptionParser._process_short_opts(self, rargs, values)
    except BadOptionError, err:
      self.largs.append(err.opt_str)



usage = "usage: %prog [options] recipe"
parser = PassThroughOptionParser(usage=usage)

#def listify(option, opt, value, parser):
#  setattr(parser.values, option.dest, value.split(','))

parser.add_option('-c', '--config',   dest='config', action='store', type='string', help="config", default=None)
parser.add_option('-i', '--identity-file',   dest='ident_file', action='store', type='string', help="ssh identity file", default=None)
parser.add_option('-u', '--user',   dest='user', action='store', type='string', help="remote ssh user", default='root')
parser.add_option('-H', '--host',   dest='hosts', action='store', type='string', help="hosts")
#parser.add_option('-r', '--recipe',   dest='recipe', action='store', type='string', help="recipe", default=0.5)

(options, args) = parser.parse_args()
env.host_string = options.hosts
if len(args) > 0:
  recipe_name = args[0]
  if len(args) > 1:
    print args[1:]
else:
  parser.print_help()
  sys.exit(-1)


if options.config:
  CONFIG = get_config(options.config)
else:
  CONFIG = {}
if options.ident_file:
  env.user = options.user
  env.key_filename = options.ident_file
else:
  print 'using ssh config'
  env.use_ssh_config = True
recipes.run(recipe_name, CONFIG)
