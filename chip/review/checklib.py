# check.py's imports, constants and functions, without its command-line code, so other scripts can call its parsers.
import ast
from pathlib import Path


def load(path=Path.home() / 'flash/flow/check.py'):
    tree = ast.parse(Path(path).read_text())
    # Constants come before the command-line code, which starts at the first top-level if; its assignments read argv.
    first_if = min((n.lineno for n in tree.body if isinstance(n, ast.If)), default=10 ** 9)
    defs = (ast.Import, ast.ImportFrom, ast.FunctionDef, ast.ClassDef)
    tree.body = [n for n in tree.body if isinstance(n, defs) or (isinstance(n, ast.Assign) and n.lineno < first_if)]
    names = {'__name__': 'check_lib'}
    exec(compile(tree, str(path), 'exec'), names)
    return names
