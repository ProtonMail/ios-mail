#!/usr/bin/env python3

# Check if link in the project are available 
# This script will retrieve links from all of swift files 
# Do http request to check if response code is 200 

# How To use: python linkAvailabilityCheck.py
import glob
import multiprocessing
import pathlib
import re
import requests

def find_root() -> str:
    script_path = pathlib.Path(__file__).resolve().parent
    root_path = script_path / '..' / 'ProtonMail'
    return str(root_path)

def folder_filter(path: str) -> bool:
    excepted = ['Pods', 'ProtonMailUITests', 'ProtonMailTests']
    for str in excepted:
        if str in path:
            return False
    return True

def find_swift_files(root: str) -> list:
    template = root + '/**/*.swift'
    paths = glob.glob(template, recursive=True)
    filtered = list(filter(folder_filter, paths))
    return filtered

def link_filter(link: str) -> bool:
    excepted = ['maps.apple.com', r'https://verify.\(', r'https://account.\(']
    for str in excepted:
        if str in link:
            return False
    return True

def find_link(path: str) -> list:
    pattern = '= "(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})"'
    with open(path, 'r') as f:
        lines = f.readlines()
        links = re.findall(pattern, "".join(lines))
        filtered = list(filter(link_filter, links))
        return filtered

def verify_link(link: str):
    response = requests.get(link)
    if response.status_code != 200:
        print('\033[91mPlease check: {}\033[0m'.format(link))
        return False
    return True        

if __name__ == '__main__':
    print('⌘ Checking URL availability...')
    root_path = find_root()
    paths = find_swift_files(root_path)
    links = set()
    for path in paths:
        result = find_link(path)
        links.update(result)
    
    pool_obj = multiprocessing.Pool()
    results = pool_obj.map(verify_link,links)
    print('⌘ Finish check link ability')
    if False in results:
        raise 'Error'