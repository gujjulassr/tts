#!/bin/bash

wav_path=$1
txt_path=$2
data_path=$3

lang=$4
gender1=$5

CHARS=$(printf "%b" "\U00A0\U1680\U180E\U2000\U2001\U2002\U2003\U2004\U2005\U2006\U2007\U2008\U2009\U200A\U200B\U202F\U205F\U3000\UFEFF")

m=male
g=female

#Check equality two string variables

if [ $gender1 == $m ]; then
  gender='m'
else
  gender='f'
fi

#Remove special
for txt_file in `ls $text_path`
do
    text=`cat $text_path/$txt_file`
    for reqsubstr in '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' '(' ')';do
      if [ -z "${text##*$reqsubstr*}" ] ;then
        echo $txt_file
      fi
    done
done

string='This is a string. It has 5 ords, 2 sen, 1 para.'
for reqsubstr in '1' '2' '3' '4' '5';do
  if [ -z "${string##*$reqsubstr*}" ] ;then
    echo "String '$string' contain substring: '$reqsubstr'."
  else
    echo "String '$string' don't contain substring: '$reqsubstr'."
  fi
done
