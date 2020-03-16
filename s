#!/bin/bash

echo ''
echo '--------------------------'
echo '--___--///^^^^STARTING ./src/ SEARCH'
echo '-------------__________-------------'
echo ''

grep -rHn --color=auto "${1}" ./src 

echo ''
