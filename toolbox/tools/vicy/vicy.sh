#!/usr/bin/env zsh

if [ -z $1 ]
then
    echo "Usage: vicy.sh [e|d]"
    echo "e - Encrypt"
    echo "d - Decrypt"
    exit 1
fi

echo -n "Enter Key: " 
read -s key
echo

echo -n "Confirm Key: " 
read -s keyConfirm
echo

if [ "$1" = "e" ]
then
    echo -n "Text: " 
elif [ "$1" = "d" ]
then
    echo -n "Cipher: " 
else
    echo "Invalid mode"
    exit 1
fi

read textOrCipher
npx ts-node $(dirname "$0")/cli.ts "$1" "$key" "$keyConfirm" "$textOrCipher"
