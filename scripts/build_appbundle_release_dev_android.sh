#!/bin/bash
# 
# Собирает релизный билд под android. Первым параметром указать версию

if [ -z "$1" ]
  then
    echo "No version supplied"
    exit 1
fi

 flutter build appbundle --release --build-number=$1