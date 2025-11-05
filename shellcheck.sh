#!/bin/bash

find . -name "*.sh" -exec shellcheck -e SC2154,SC2016 -f 'gcc' -s bash '{}' +
