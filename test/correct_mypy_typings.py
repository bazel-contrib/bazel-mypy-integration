from typing import Callable


def twice(i: int, next_: Callable[[int], int]) -> int:
    return next_(next_(i))


def add(i: int) -> int:
    return i + 1


print(twice(3, add))
