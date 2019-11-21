#!/bin/bash

echo ''
echo '--------------------------'
echo '--___--///^^^^STARTING app SEARCH'
echo '-------------__________-------------'
echo ''

#grep -rHn --color=auto "${1}" src/common src/modules config/ src/*.js .gitlab-ci.yml
grep -rHn --color=auto "${1}" ./src 
