#!/bin/bash

#Usage
# ./setup_change_log.sh COMMIT_NUMBER
# e.g.
# ./setup_change_log.sh 4890

if [ ! "$1" ]
then 
    exit "Please provide last build number"
fi

commits=$(git log --pretty=format:"%H" --reverse | nl)
array=( $(grep -Eo "[a-z0-9]{40}" <<<$commits) )
echo ${array[$1 - 1]:0:8}
