#!/bin/bash

build_job_pwd=$(cat ../build_job_pwd.txt)
cpu_arch=$(uname -m)

cmd="bundle exec slather coverage --arch $cpu_arch --path-equivalence $build_job_pwd,$PWD"
echo "$cmd"

$cmd --cobertura-xml
$cmd
