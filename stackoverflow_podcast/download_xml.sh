#!/bin/bash

if [ ! -f stackoverflow_podcast.xml ]; then
  wget "https://feeds.simplecast.com/XA_851k3" -O stackoverflow_podcast.xml
else
  echo "stackoverflow_podcast.xml already exists"
fi
