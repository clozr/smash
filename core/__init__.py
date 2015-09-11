from parser import Parser, iterate_nested
from commands import get_config, RecipeNotFound

class RecipeModule(object):
  def __init__(self, filename):
    self.filename = filename
    self.recipes = {}
    self.cmds = None
    self.load(filename)

  def load(self, recipe_name, verbose=0):
    with open('recipes/%s.sh'%(recipe_name)) as fp:
      lines = iterate_nested(enumerate(fp))
      parser = Parser(recipe_name, verbose=verbose)
      if verbose:
        print 'PARSE:', recipe_name
      self.cmds = parser.parse(lines)
      if verbose:
        print 'END'
      self.recipes.update(parser.recipes)

  def get_recipe(self, recipe_name):
    #print 'GET RECIPE:', recipe_name
    if recipe_name:
      return self.recipes.get(recipe_name)
    else:
      return self
  
  def __call__(self, ctx, mgr):
    for cmd in self.cmds:
      cmd(ctx, mgr)


class RecipeManager(object):
  def __init__(self):
    self.recipe_mods = {}

  def run(self, recipe_path, ctx):
    #print 'RM:', recipe_path, 'CTX:', ctx
    try:
      mod_name, recipe_name = recipe_path.split('.')
    except:
      mod_name, recipe_name = recipe_path, ''

    recipe_mod = self.recipe_mods.get(mod_name, None)
    if not recipe_mod:
      recipe_mod = RecipeModule(mod_name)
      self.recipe_mods[mod_name] = recipe_mod

    try:
      recipe = recipe_mod.get_recipe(recipe_name)
    except KeyError:
      raise RecipeNotFound(recipe_name, mod_name)
    recipe(ctx, self)

recipes = RecipeManager()
