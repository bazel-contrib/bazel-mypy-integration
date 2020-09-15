import zipfile

from fully_qualified import string_tools

from internal import hangman_tools_internal


def things() -> str:
    if string_tools.make_string(1):
        return "Things"
    else:
        return hangman_tools_internal.stuff()
