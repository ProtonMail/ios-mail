#!/bin/bash

build_job_pwd=$(cat ../build_job_pwd.txt)
cpu_arch=$(uname -m)

cmd="bundle exec slather coverage --arch $cpu_arch"
echo "$cmd"

$cmd --cobertura-xml
$cmd
