from typing import List

from testing_deps.foo.fizz import fizz_filterer
from testing_deps.bar.boo import boo_func


def main() -> None:
    my_list = [
        "Applesauce",
        "Car",
        "Giant Man",
        "Zebra",
        "Antelope",
        "Anxiety",
        "Avarice",
        "Lice",
        "Firetruck",
    ]

    boo_func(my_list)

    starts_with_A = lambda x: type(x) == str and x.startswith("A")
    fizz_filterer(my_list, filter_func=starts_with_A)

    another_list: List[int] = [1, 10, 100]
    # This below is a typing violation.
    boo_func(another_list)


if __name__ == "__main__":
    main()
