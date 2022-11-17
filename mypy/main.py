

import sys
from mypy.main import main
from mypy.version import __version__

# According to https://github.com/python/mypy/blob/v0.971/mypy/version.py
# - Release versions have the form "0.NNN".
# - Dev versions have the form "0.NNN+dev" (PLUS sign to conform to PEP 440).
# - For 1.0 we'll switch back to 1.2.3 form.
def version_tuple(v: str) -> tuple[int, ...]:
    """Silly method of creating a comparable version object"""
    return tuple(map(int, (v.split("+")[0].split("."))))

if __name__ == '__main__':
    # 0.981 began requiring keyword arguments
    if version_tuple(__version__) < (0, 981):
        main(None, sys.stdout, sys.stderr)
    else:
        # The first arg was removed
        main(stdout=sys.stdout, stderr=sys.stderr)
