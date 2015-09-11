from email.mime.text import MIMEText
from random import randint
from jinja2 import Environment, FileSystemLoader
import gzip
import cStringIO

def render_file(fname, tpl_file, context):
  print "Reading File:", tpl_file
  with open('templates/%s'%tpl_file, 'r') as fp:
    template = fp.read()

  print "Writing File:", fname
  with open(fname, 'w+') as fp:
    fp.write(template % context)

def generate_password(length, badChars='', alpha = '1234567890qwertyuiop[]asdfghjkl;zxcvbnm,.!@#$%^&*()_+-=-{}:<>|QWERTYUIOPASDFGHJKLZXCVBNM~`?'):
  return "".join([list(set(alpha)^set(badChars))[randint(0,len(list(set(alpha)^set(badChars)))-1)] for i in range(length)])

def attach_text(path, subtype, filename=None):
  fp = open(path)
  txtpart = MIMEText(fp.read(), _subtype=subtype)
  if filename:
    txtpart.add_header('Content-Disposition','attachment', filename=filename)
  fp.close()
  return txtpart

def gzip_content(multipart):
  gfileobj = cStringIO.StringIO()
  gfile = gzip.GzipFile(fileobj=gfileobj, mode='wb')
  gfile.write(multipart.as_string())
  gfile.close()
  print 'returning compressed data'
  return gfileobj.getvalue()

env = Environment(loader=FileSystemLoader('templates'))

def render_template1(out_file, template_file, context):
  template = env.get_template(template_file)
  text = template.render(context)
  print "rendered: %s"%(out_file)
  with open(out_file, 'w+') as fp:
    fp.write(text)

def render_template(template_file, out_file, context):
  template = env.get_template(template_file)
  text = template.render(context)
  print "rendered: %s"%(out_file)
  with open(out_file, 'w+') as fp:
    fp.write(text)
