#!/bin/bash
# How to use 
# sh localization_check.sh

# This script will run needed python script automatically

green_echo(){
    GREEN="\033[0;32m"
    NO_COLOR="\033[0m"
    printf "${GREEN}${1} ${NO_COLOR}\n"
}

scriptDirectory="$(git rev-parse --show-toplevel)"/Scripts/LocalizationCheck
cd $scriptDirectory

green_echo "⌘ do plural check"
./plural_check.py
green_echo "⌘ plural check finish"

echo ''
green_echo "⌘ check wrong translation"
./wrong_translation_check.py
green_echo "⌘ check wrong translation finish"

echo ''
green_echo "⌘ check duplicated localized key"
./check_duplicated_key.py
green_echo "⌘ check duplicated localized key finish"