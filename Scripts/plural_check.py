#!/usr/bin/env python3.4 

# Check keys in plural localization files
# Here is an example, the key of NSStringLocalizedFormatKey is DAY
# Localized string can retrieve plural string by this key 
# ```
# 	<key>%d day</key>
# 	<dict>
#       <key>NSStringLocalizedFormatKey</key>
# 		<string>%#@DAY@</string>
# 		<key>DAY</key>  // accidentally change to DAG
# 		<dict>
#             ...
# 		</dict>
# 	</dict>
# ```
# But sometimes writer could translate DAY to DAG (in German case)
# When this happens the localized string will return %#@DAY@ rather than the correct plural string
# Because it can't find the correspond key
# This script aims to check this situation

# HOW to use   
# python plural_check.py  
# if it find errors, will print information you need on the terminal

import re
import plistlib
import os

# Check the whole plural localization file
# Return: bad plural key list, list[str]
def check_plural_file(plural_path: str) -> list:
    with open(plural_path, 'rb') as fp:
        plist = plistlib.load(fp)
        bugs_key = []
        for localization in plist:
            dict = plist[localization]
            result = parse_plural_dict(dict)
            if len(result) > 0:
                bugs_key += result
        return bugs_key
    return []

# Parse localization dict 
# If it contains bad plural key return it
# Return: list[str], bad plural key list
# e.g. ['DAG']
def parse_plural_dict(dict) -> list:
    keys = find_plural_keys(dict)
    bugs = []
    for plural_key in keys:
        if plural_key not in dict:
            bugs.append(plural_key)
    return bugs

# Given a dictionary, it looks for the value of `NSStringLocalizedFormatKey` and returns the plural 
# substring, if the pattern for a plural is found.
# Return: list[str], the list will be empty if it can't find anything
# e.g. ['DAY']
def find_plural_keys(dict) -> list:
    formated_key = dict['NSStringLocalizedFormatKey']
    regex = re.compile('%#@(.*?)@')
    result = regex.search(formated_key)
    length = len(result.regs)
    if length <= 1:
        return []
    targets = []
    for index in range(1, length):
        target_range = result.regs[index]
        targets.append(formated_key[target_range[0]: target_range[1]])
    return targets

# Find *.stringsdict in the project 
# Return: list[str], e.g. ['/Users/anson/Documents/cache/ProtonMail/ProtonMail/nl.lproj/Localizable.stringsdict']
def find_localizations() -> list:
    script_path = os.path.dirname(os.path.realpath(__file__))
    parent = os.path.abspath(os.path.join(script_path, '..'))
    proton_dir = os.path.abspath(os.path.join(parent, 'ProtonMail/ProtonMail/Resource/Localization'))
    dirs = [path for path in os.listdir(proton_dir) if path.endswith('.lproj')]
    paths = []
    for dir_name in dirs:
        path = os.path.abspath(os.path.join(proton_dir, '{}/Localizable.stringsdict'.format(dir_name)))
        paths.append(path)
    return paths

if __name__ == '__main__':
    # paths = find_localizations()
    paths = ['/Users/anson/Documents/v4/ProtonMail/ProtonMail/Resource/Localization/Base.lproj/Localizable.stringsdict']
    for path in paths:
        bugs_key = check_plural_file(path)
        if len(bugs_key) > 0:
            bugs_key = ['【%#@{}@】'.format(key) for key in bugs_key]
            keys = ','.join(bugs_key)
            print('Please check file {}'.format(path))
            print('For keys {}'.format(keys))