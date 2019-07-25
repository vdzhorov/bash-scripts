#!/bin/bash
#
# Usage of the script: ./nginx_rewrite_rule_generator.sh {map|rewrite} urls.txt, where:
# the first parameter (map|rewrite) indicates what you want to generate - nginx rewrites or maps.
# Warning: Rewrites do not work for URIs that contain query string. If you have such URIs then maybe
# you should look into generating nginx maps using this script.
#
# This script will bulk-generate Nginx 301 redirects from a txt input file.
# The format of the txt file where the domains are places is as follows:
# <Old URL>                        <New URL>
# https://example.com/old/location https://example.com/new/location
# 
# This will result in the following in case you want rewrites:
# rewrite ^/example.com/old/location$ https://example.com/new/location permanent;
# or in case you want maps:
# map $request_uri $new_uri {
#     default "";
#     /old/locationl     /new/location;
# }
#
# You will need to to include this in your server block afterwards:
#
#     if ($new_uri != "") {
#         rewrite ^(.*)$ $new_uri? permanent;
#     }
# Everything will be outputed to a file which you can configure via $OUTPUT_FILE.
# The array ESCAPE_CHARS hold characters which are replaced by the same character,
# but preceeded with / (used for rewrites, not maps). This is needed as Nginx otherwise interprets them as environment variables.
# 
# Author: Valentin Dzhorov

FILE="$2"
OUTPUT_FILE='rewrite_rules.txt'
ESCAPE_CHARS=(']' '[' '}' '{')

if [ ! -f "$FILE" ]; then
  echo "File $FILE not found. Exiting."
  exit 1
fi

if [ "$#" -ne 2 ]; then
  echo "Illegal number of parameters. Usage: $0 {map|rewrite} $FILE"
  exit 1
fi

function string_replace () {
  for i in "${ESCAPE_CHARS[@]}"; do
  sed -r -i "s/\\${i}/\/\\${i}/g" $1
  done
}

function convert_to_rewrites () {
  local file_input=$1;
  while IFS= read -r line
  do
  local domain=$(echo $line | awk '{print $1}' | cut -d '/' -f1-3)
  echo -n 'rewrite ^'
  local line1=$(echo "$line" | awk '{print $1}' | awk -F "$domain" 'BEGIN {ORS=" "} BEGIN {OFS=""} {print $2, "$"}')
  echo -n "$line1 "
  echo -n "$line" | awk 'BEGIN {OFS=""} {print $2, " permanent" , ";"}'
  done < "$file_input"
}

function convert_to_map () {
  local file_input=$1;
  echo 'map $request_uri $new_uri {'
  echo '    default "";'
  while IFS= read -r line
  do
  echo "    $line;"
  done < "$file_input"
  echo '}'
}

case "$1" in
  rewrite)
    convert_to_rewrites $FILE > $OUTPUT_FILE
    string_replace $OUTPUT_FILE
    ;;

  map)
    convert_to_map $FILE > $OUTPUT_FILE 
    ;;

  *)
    echo "Usage: $0 {map|rewrite} $FILE"
    exit 1
esac
