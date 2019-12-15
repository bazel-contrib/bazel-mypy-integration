from typing import Callable


def twice(i: int, next_: Callable[[int], int]) -> int:
    return next_(next_(i))


# BROKEN: This function does not return a 'str'
def add(i: int) -> str:
    return i + 1


print(twice(3, add))
