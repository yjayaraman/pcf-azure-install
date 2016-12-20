#!/bin/bash

set -e


declare -A props
while read -r; do
  [[ $REPLY = *=* ]] || continue
  props[${REPLY%%=*}]=${REPLY#*=}
done <create_azure_gov.txt

echo "${props[ENVIRONMENT]}"