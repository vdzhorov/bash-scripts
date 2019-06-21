#!/bin/bash
#
# This script was used for bulk-generating Nginx 301 redirects from a txt file.
# The format of the txt file where the domains are places are as follows:
# <Old URL>                        <New URL>
# https://example.com/old/location https://example.com/new/location
# This will result in the following:
# rewrite ^/example.com/old/location$ https://example.com/new/location permanent;
# Everything will be outputed to a file which you can configure via $OUTPUT_FILE.
# The script takes one arguement - a file. Usage: script.sh /path/to/file.txt.
# 
# Author: Valentin Dzhorov

FILE="$1"
OUTPUT_FILE='rewrite_rules.txt'

if [ ! -f "$FILE" ]; then
  echo "File $FILE not found. Exiting."
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Illegal number of parameters. Usage: $0 $FILE"
  exit 1
fi

function convert () {
  local file_input=$1;
  while IFS= read -r line
  do
  local domain=$(echo $line | awk '{print $1}' | cut -d '/' -f1-3)
  echo -n 'rewrite ^' 
  echo -n "$line" | awk '{print $1}' | awk -F "$domain" 'BEGIN {ORS=" "} BEGIN {OFS=""} {print $2, "$"}'
  echo -n "$line" | awk 'BEGIN {OFS=""} {print $2, " permanent" , ";"}'
  done < "$file_input"
}

convert $FILE > $OUTPUT_FILE
