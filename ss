#!/bin/bash

echo ''
echo '--------------------------'
echo '--___--///^^^^STARTING DEEP SEARCH'
echo '-------------__________-------------'
echo ''

grep -rHn --color=auto "${1}" src/ config/ .gitlab-ci.yml
