import re, sys, os
from jinja2 import Template

debug = 0

if debug:
  from fabric.api import warn_only
  def run(cmd):
    print '\tRUN:', cmd
  def local(cmd):
    print '\tCMD:', cmd
  def put(*args):
    print '\tPUT:', args
  def get(*args):
    print '\tGET:', args
  def render_template(*args):
    print '\tRENDER:', args
  def generate_password(*args):
    print '\tGENPASS:', args
else:
  from fabric.api import *
  from utils import render_template, generate_password
  from datetime import datetime

class RecipeNotFound(Exception):
  pass

def get_config(config_option):
  CONFIG = {}
  config_list = config_option.split(',')
  for cfg_path in config_list:
    try:
      mod_path, cfg_name = cfg_path.rsplit('.')
    except:
      mod_path, cfg_name = cfg_path, 'CONFIG'
    config_mod = __import__('config.%s'%mod_path, globals(), locals(), [cfg_name], -1)
    try:
      cfg = getattr(config_mod, cfg_name)
    except:
      config_vars = [v for v in config_mod.__dict__.keys() if not v.startswith('__')]
      #print 'CONFIG_MOD:', config_mod, config_vars
      for v in config_vars:
        cfg = getattr(config_mod, v)
        CONFIG[v] = cfg
    CONFIG.update(cfg)
  return CONFIG


def resolve(s, ctx):
  if '%(' in s:
    return s % ctx
  else:
    #print 'RESOLVE:', s, ctx
    return str(Template(s).render(ctx))

def get_source_dest(parser, arg, N):
  tokens = arg.split()
  if len(tokens) < 1 or len(tokens) > N:
    parser.error(arg)
  if len(tokens) < 2:
    return tokens[0], tokens[0], None, None
  while len(tokens) < N:
    tokens.append(None)
  return tokens

class opcode(object):
  def __init__(self, opcode):
    self.opcode = opcode
  def __call__(self, CLS):
    class CmdCls(CLS):
      opcode = self.opcode
    return CmdCls

class Commands(object):
  @opcode('-,-&')
  class RemoteCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.cmd = arg
      self.ignore = (op == '-&')
      self.derror = parser.get_derror(line_no)

    def __call__(self, ctx, mgr):
      cmd = resolve(self.cmd, ctx)
      #retval = run(cmd, quiet=True)
      retval = run(cmd, warn_only=True)
      if retval.failed and not self.ignore:
        self.derror(retval)

  @opcode('+,+&')
  class SudoCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.cmd = arg
      self.op = op
      self.derror = parser.get_derror(line_no)
    def __call__(self, ctx, mgr):
      cmd = resolve(self.cmd, ctx)
      if self.op == '+&':
        with warn_only():
          run('sudo ' + cmd)
      else:
        try:
          run('sudo ' + cmd)
        except Exception as e:
          self.derror(str(e))

  @opcode('!')
  class LocalCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.cmd = arg
      self.derror = parser.get_derror(line_no)
    def __call__(self, ctx, mgr):
      cmd = resolve(self.cmd, ctx)
      try:
        local(cmd)
      except Exception as e:
        self.derror(str(e))

  @opcode('->')
  class UploadCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.source, self.dest, self.mode, self.owner = get_source_dest(parser, arg, 4)

    def __call__(self, ctx, mgr):
      source = resolve(self.source, ctx)
      dest = resolve(self.dest, ctx)
      try:
        put(source, dest)
      except:
        put(source, '.tmp_file')
        run('sudo mv .tmp_file %s'%(dest))
      if self.mode:
        mode = resolve(self.mode, ctx)
        run('sudo chmod %s %s'%(mode, dest))
      if self.owner:
        owner = resolve(self.owner, ctx)
        run('sudo chown %s %s'%(owner, dest))
      
  @opcode('<-')
  class DownloadCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.source, self.dest = get_source_dest(parser, arg, 2)

    def __call__(self, ctx, mgr):
      source = resolve(self.source, ctx)
      dest = resolve(self.dest, ctx)
      get(source, dest)

  @opcode('@r')
  class RenderCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.source, self.dest, self.mode, self.owner = get_source_dest(parser, arg, 4)

    def __call__(self, ctx, mgr):
      source = resolve(self.source, ctx)
      dest = resolve(self.dest, ctx)
      if self.mode:
        ldest = '_%s'%source
        render_template(source, ldest, ctx)
        put(ldest, ldest)
        run('sudo mv %s %s'%(ldest, dest))
        run('sudo chmod %s %s'%(self.mode, dest))
        if self.owner:
          run('sudo chown %s %s'%(self.owner, dest))
        local('rm -f %s'%ldest)
      else:
        render_template(source, dest, ctx)

  @opcode('@p')
  class PyExprCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.stmt = arg

    def __call__(self, ctx, mgr):
      stmt = resolve(self.stmt, ctx)
      exec(stmt, globals(), ctx)

  @opcode('@d')
  class DefineCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.var, self.expr = arg.split(' ', 1)

    def __call__(self, ctx, mgr):
      var = resolve(self.var, ctx)
      expr = resolve(self.expr, ctx)
      expr = eval(expr, globals(), ctx)
      ctx[var] = expr

  @opcode('if')
  class IfCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      arg = arg.strip().rstrip(':')
      self.cond = arg
      self.cmds = parser.parse_section(lines)
      self.derror = parser.get_derror(line_no)

    def __call__(self, ctx, mgr):
      try:
        cond = eval(self.cond, globals(), ctx)
      except Exception as e:
        self.derror(str(e))
      if cond:
        for cmd in self.cmds:
          cmd(ctx, mgr)

  @opcode('recipe')
  class RecipeCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      if not arg:
        parser.error('recipe requires a name')
      self.name = arg
      parser.log('PARSE:' + self.name)
      self.cmds = parser.parse_section(lines)
      parser.log('END')

    def __call__(self, ctx, mgr):
      print 'RECIPE:', self.name
      for cmd in self.cmds:
        #print 'running', cmd.__dict__
        cmd(ctx, mgr)

  @opcode('call')
  class CallRecipeCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      try:
        self.recipe_name, self.cfg = arg.split()
      except:
        self.recipe_name, self.cfg = arg, None
      self.derror = parser.get_derror(line_no)
      self.filename = parser.filename
      self.line_no = line_no
      #if '.' not in self.recipe_name:
      #  self.recipe_name = filename + '.' + self.recipe_name
    def get_cfg(self, ctx):
      if self.cfg:
        cfg = resolve(self.cfg, ctx)
        m = eval(cfg, globals(), ctx)
        cctx = {}
        if isinstance(m, basestring):
          cctx = get_config(m)
        elif isinstance(m, tuple) and ',' in self.cfg:
          for mi in m:
            if isinstance(mi, dict):
              cctx.update(mi)
            else:
              self.derror('invalid context')
        elif isinstance(cctx, dict):
          cctx = m
        else:
          self.derror('invalid context')
        cctx.update({'_parent': ctx})
      else:
        cctx = ctx
      return cctx

    def __call__(self, ctx, mgr):
      cctx = self.get_cfg(ctx)
      #if self.cfg:
      #  cfg = resolve(self.cfg, ctx)
      #  cctx = eval(cfg, globals(), ctx)
      #  if isinstance(cctx, basestring):
      #    cctx = get_config(cctx)
      #    # ANALYZE: should existing configuration be passed????
      #    #cctx.update(ctx)
      #else:
      #  cctx = ctx
      
      try:
        mgr.run(self.filename + '.' + self.recipe_name, cctx)
      except:
        try:
          mgr.run(self.recipe_name, cctx)
        except RecipeNotFound as e:
          msg = 'recipe `%s` not found in module'%(self.recipe_name, e[1])
          self.derror(msg)
        except Exception as e:
          self.derror(str(e))

  @opcode('@cfg')
  class SetConfigCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      self.cfg = arg
      if not self.cfg:
        raise ValueError('@c command needs a valid config spec')
      self.filename = parser.filename

    def __call__(self, ctx, mgr):
      cfg = resolve(self.cfg, ctx)
      cctx = eval(cfg, globals(), ctx)
      if isinstance(cctx, basestring):
        #print 'CCTX:', cctx
        cctx = get_config(cctx)
      ctx.update(cctx)

  @opcode('for')
  class ForLoopCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      arg = arg.strip().rstrip(':')
      FOR_PATTERN = r'(?P<var>.*)in(?P<coll>.*)'
      parser.log('FOR ARG:' + arg)
      for_loop = re.match(FOR_PATTERN, arg).groupdict()

      self.variables = map(lambda x: x.strip(), for_loop['var'].split(','))
      self.coll = for_loop['coll'].strip()
      self.cmds = parser.parse_section(lines)

    def __call__(self, ctx, mgr):
      print 'CTX:', ctx
      coll = eval(self.coll, globals(), ctx)
      if isinstance(coll, list):
        for v in coll:
          if len(self.variables) == 1:
            ctx[self.variables[0]] = v
          else:
            for i, var in enumerate(self.variables):
              ctx[var] = v[i]
          for cmd in self.cmds:
            cmd(ctx, mgr)
      elif isinstance(coll, dict):
        for k,v in coll.iteritems():
          ctx[self.variables[0]] = k
          ctx[self.variables[1]] = v
          for cmd in self.cmds:
            cmd(ctx, mgr)

  @opcode('.')
  class StopCmd(object):
    def __init__(self, op, arg, lines, line_no, parser):
      pass

    def __call__(self, ctx, mgr):
      sys.exit(0)
