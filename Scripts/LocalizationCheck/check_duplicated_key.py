#!/usr/bin/env python3

# Check if there is duplicated localized key in Localization.swift
# For example
# lazy var str1 = NSLocalizedString("test", comment: "string 1")
# lazy var str2 = NSLocalizedString("test", comment: "string 2")
# Above strings have same localized key but according to usuage translation could different
# Same localized key could cause problem
# In translation always the same, then we don't need these duplicated
import pathlib
import re


def find_localization_swift() -> str:
    script_path = pathlib.Path(__file__).resolve().parent
    parent = script_path / '..' / '..'
    file_path = parent / 'ProtonMail' / 'ProtonMail' / \
        'Utilities' / 'APP_share_push_uiTest' / 'Localization.swift'
    return file_path


def find_duplicated(path: str) -> dict:
    with open(path, 'r') as f:
        checked_value = []
        duplicated = {}
        lines = f.readlines()
        regex = re.compile(
            r'lazy var (_.*) = NSLocalizedString\("(.*)", comment:.*\)')
        for line in lines:
            result = regex.search(line)
            if result is None:
                continue
            key = result.group(1)
            localized = result.group(2)
            if localized.lower() in checked_value:
                duplicated[key] = localized
            else:
                checked_value.append(localized.lower())
    return duplicated


if __name__ == '__main__':
    path = find_localization_swift()
    duplicated = find_duplicated(path)
    if len(duplicated) > 0:
        print('\033[91mFind duplicated localized strings\033[0m')
        print('\033[91mNOTE this is case insensitive\033[0m')
        print('\033[91mPlease check want to keep or remove them\033[0m')
        for key, value in duplicated.items():
            print('{} - {}'.format(key, value))
