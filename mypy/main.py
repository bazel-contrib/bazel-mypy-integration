

import sys
from mypy.main import main

if __name__ == '__main__':
    if main.__version__ and '0.981' <= main.__version__:
        main()
    else:
        main(None, sys.stdout, sys.stderr)
