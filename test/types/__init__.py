import enum
from typing import List, Optional


class FooEnumType(enum.IntEnum):
    BAR = 1
    BAZ = 2
    BEE = 3
    BOO = 4


SeqOfMaybeInts = List[Optional[int]]
