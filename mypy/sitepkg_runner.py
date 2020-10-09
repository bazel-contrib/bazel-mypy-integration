"""
`mypy` determines site packages to look in for modules with `py.typed` files by,
in a subprocess, calling the provided python executable on a specific file that
finds and returns site packages. That file essentially calls
print(sitepkgs.getsitepackages()).

In order to add bazel-managed pip dependencies to the search path, we provide
this executable as the "python executable" for mypy to use when it wants to find
site packages, and add our bazel external packages to the search path.
"""

import sys
import os
from mypy import sitepkgs

def external_packages():
    r = []
    for dir in os.listdir('external/'):
        fulld = os.path.abspath(os.path.join('external', dir))
        if not os.path.isdir(fulld):
            continue
        r.append(fulld)
    return r

if __name__ == '__main__':
    pkgs = sitepkgs.getsitepackages()
    print(repr(pkgs + external_packages()))
