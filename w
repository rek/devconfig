#!/bin/bash

echo ''
echo '--------------------------'
echo '--___--///^^^^STARTING DRAGON SEARCH'
echo '-------------__________-------------'
echo ''

grep --exclude-dir=processor --exclude-dir=fixtures --exclude-dir=node_modules --exclude-dir=vendor -rHn --color=auto "${1}" src/scripts/ grunt/ .gitlab-ci.yml
