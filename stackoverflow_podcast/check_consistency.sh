#!/bin/bash

ls *.mp3 |while read line; do
  current_size=$(ls -l "$line" |awk '{print $5}')
  expected_size=$(ls "$line" |awk -F "_" '{print $5}')
  if [ "$current_size" != "$expected_size" ]; then
    echo "$current_size - $expected_size - $line"
  fi
done
