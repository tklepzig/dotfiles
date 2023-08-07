#!/usr/bin/env python3

from random import randint
import random


def check(guess):
    def func(tuple):
        i, x = tuple
        return "full" if x == guess[i] else "half" if x in guess else x

    return func


result = []
guess_count = 1
code_length = 4
repeating_numbers = 0


print(
    "Code with length %i\nRepeating numbers: %s"
    % (code_length, "yes" if repeating_numbers else "no"),
)
if repeating_numbers:
    code = list(str(randint(10 ** (code_length - 1), (10 ** code_length) - 1)))
else:
    code = list(map(str, random.sample(range(10), 4)))

while result != ["full"] * code_length:
    guess = list(input())
    if len(guess) != code_length:
        print("Please enter %i numbers" % code_length)
        continue

    guess_count += 1
    full_matches = map(check(guess), enumerate(code))
    result = filter(lambda x: x == "half" or x == "full", list(full_matches))
    result = sorted(list(result))
    output = map(lambda x: "\u25cf" if x == "full" else "\u25cb", result)

    output = " ".join(list(output))

    # from https://stackoverflow.com/a/36210179
    print('\033[-1C\033[1A%s  %s' % ("".join(guess), output))
