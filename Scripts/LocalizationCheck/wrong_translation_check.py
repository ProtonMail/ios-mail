#!/usr/bin/env python3

# Check if there is wrong translation
# For example, it should be `Proton Mail` rather than `ProtonMail`
# Run this script to get suspect translation

# How to use
# python wrong_translation_check.py
# if it find errors, will print information you need on the terminal

import pathlib
import os
import re


def find_localizations() -> list:
    script_path  = pathlib.Path(__file__).resolve().parent
    parent = script_path / '..' / '..'
    proton_dir = parent / 'ProtonMail' / 'ProtonMail' / 'Resource' / 'Localization'
    dirs = [path for path in proton_dir.iterdir() if path.name.endswith('.lproj')]
    paths = []
    for directory in dirs:
        path = proton_dir / directory.name / 'Localizable.strings'
        paths.append(path.resolve())
    return paths


def find_translation_needed_to_be_fixed(path: str):
    with open(path, 'r') as fp:
        lines = fp.readlines()
        regex = re.compile('".*;\n')
        translation_only = [line for line in lines if regex.search(line)]
        results = check_translations(translation_only)
        if len(results) > 0:
            print('\n【Please check file {}】'.format(path))
            for result in results:
                print(result)


def check_translations(translations: list) -> list:
    results = []
    protonmails = []
    for translation in translations:
        splits = translation.split('=')
        if len(splits) != 2:
            continue
        target = splits[1]
        proton_result = warning_if_contain_protonmail(target)
        if proton_result != '':
            protonmails.append(proton_result)
    results.extend([string for string in protonmails])
    return results


def warning_if_contain_protonmail(target: str) -> str:
    lower = target.lower()
    if 'protonmail' not in lower:
        return ''
    # check the following cases
    # proton.me
    # https://proton.me/support
    # support@protonmail.zendesk.co
    # https://twitter.com/protonmail
    if 'proton.me' in lower or 'support@protonmail' in lower or '/protonmail' in lower:
        return ''

    # Contain protonmail but not a link
    regex = re.compile(re.escape('protonmail'), re.IGNORECASE)
    result = regex.sub('\033[91mprotonmail\033[0m', target)
    result = result.replace('\n', '')
    return result


if __name__ == '__main__':
    paths = find_localizations()
    if len(paths) == 0:
        raise("ERROR: Can't find localization files")
    for path in paths:
        find_translation_needed_to_be_fixed(path)
