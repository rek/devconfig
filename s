#!/bin/bash

echo ''
echo '--------------------------'
echo '--___--///^^^^STARTING DTE SEARCH'
echo '-------------__________-------------'
echo ''

grep -rHn --color=auto "${1}" src/common src/modules config/ src/*.js .gitlab-ci.yml
