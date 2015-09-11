import re
import sys
from commands import Commands

def show_error(fname, line_no, msg):
  msg = 'ERROR: %s (at %s:%s)'%(msg, fname, line_no+1)
  print msg
  sys.exit(-1)

class ParseError(Exception):
  pass

def iterate_nested(lines, start_line_no=0):
  level = 0
  ljust = 0
  ljust_stack = []
  for i, line in lines:
    line_no = i+start_line_no
    if line.lstrip() == '#' or line.strip() == '':
      continue
    m = re.search(r'[^ ]', line)
    #print 'seaching: |%s'%line, m.start()
    cljust = m.start()
    if cljust > ljust:
      yield line_no, 'begin'
      ljust_stack.append(ljust)
      ljust = cljust
    else:
      while cljust < ljust:
        yield line_no, 'end'
        ljust = ljust_stack.pop()
    yield line_no, line 


def get_section(lines):
  i, line = lines.next()
  #print 'SECTION:', line
  if line != 'begin':
    raise ValueError('block not indented')
  nested = 1
  section = []
  ljust = 0
  for i, line in lines:
    #print 'SECTION:', line
    if line == 'begin':
      nested += 1
    elif line == 'end':
      nested -= 1
      if not nested:
        break
    else:
      if not section:
        m = re.search(r'[^ ]', line)
        #print 'seaching: |%s'%line, m.start()
        ljust = m.start()
      section.append((i, line[ljust:]))
  #print 'SECTION:'
  #print section
  #print 'END'
  return iterate_nested(section)

class Parser(object):
  def __init__(self, filename, verbose=0):
    self.filename = filename
    self.line_no = 0
    self.recipes = {}
    self.commands = {}
    self.verbose = verbose
    for cmd_name, cmd_cls in Commands.__dict__.iteritems():
      if hasattr(cmd_cls, 'opcode'):
        opcodes = cmd_cls.opcode.split(',')
        for opcode in opcodes:
          if opcode not in self.commands:
            self.commands[opcode] = cmd_cls
          else:
            raise ParseError('opcode %s registered twice'%(opcode))

  def parse(self, lines):
    cmds = []
    for line_no, line in lines:
      self.line_no = line_no
      #print line_no, line
      line = line.strip()
      if line[0] == '#' or line == '' or line == 'begin':
        continue
      elif line == '.':
        cmd_obj = self.commands[line](cmd, lines, self)
        cmds.append(cmd_obj)
        continue
      try:
        op, cmd= line.split(' ', 1)
      except:
        self.error('invalid cmd %s')
      op = op.strip()
      cmd = cmd.strip()
      if self.verbose:
        print '\tOP =',op, 'CMD =', cmd
      try:
        cmd_obj = self.commands[op](op, cmd, lines, line_no, self)
      except KeyError:
        self.error('invalid cmd prefix %s'%op)
      if op == 'recipe':
        self.recipes[cmd_obj.name] = cmd_obj
      else:
        cmds.append(cmd_obj)
    return cmds

  def parse_section(self, lines):
    section = get_section(lines)
    return self.parse(section)
  
  def log(self, msg):
    if self.verbose:
      print msg

  def error(self, msg):
    #raise ParseError(msg)
    show_error(self.filename, self.line_no, msg)
  def get_derror(self, line_no):
    fname = self.filename
    def derror(msg):
      show_error(fname, line_no, msg)
    return derror
