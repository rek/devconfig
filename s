#!/bin/bash

echo ''
echo '--------------------------'
echo '--___--///^^^^STARTING app SEARCH'
echo '-------------__________-------------'
echo ''

grep -rHn --color=auto --include=\*.{js,ts,tsx} "${1}" . --exclude-dir={node_modules,.expo}

echo ''
