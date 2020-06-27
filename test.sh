#!/bin/bash

profiles="basic,extended"
hasProfile() {
  echo $profiles
  for i in ${profiles/,/ }
  do
    echo $i
    echo $1
    if [ "$i" = "$1" ]
    then
      return 0
    fi
  done
  return 1
}

if hasProfile basic
then
  echo "has basic"
fi

if hasProfile extended
then
  echo "has extended"
fi
