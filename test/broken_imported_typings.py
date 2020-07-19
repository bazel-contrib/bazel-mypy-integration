from test.broken_generated import thrice


def add(i: int) -> int:
    return i + 1


print(thrice(3, add))
