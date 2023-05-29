#!/usr/bin/env bash

# Copyright 2013   (Authors: Daniel Povey, Bagher BabaAli)

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.

# Call this script from one level above, e.g. from the s3/ directory.  It puts
# its output in data/local/.

# The parts of the output of this that will be needed are
# [in data/local/dict/ ]
# lexicon.txt
# extra_questions.txt
# nonsilence_phones.txt
# optional_silence.txt
# silence_phones.txt

# run this from ../
srcdir=$1/train
dir=$1/dict
lmdir=$1/nist_lm
tmpdir=$1/lm_tmp

lang=$2
gender=$3

mkdir -p $dir $lmdir $tmpdir

[ -f path.sh ] && . ./path.sh

#(1) Dictionary preparation:

# Make phones symbol-table (adding in silence and verbal and non-verbal noises at this point).
# We are adding suffixes _B, _E, _S for beginning, ending, and singleton phones.

# silence phones, one per line.
echo sil > $dir/silence_phones.txt
echo sil > $dir/optional_silence.txt

# nonsilence phones; on each line is a list of phones that correspond
# really to the same base phone.

# Create the lexicon, using ipa mapping
cut -d' ' -f2- $srcdir/text | tr ' ' '\n' | sort -u | grep -v -F -f $dir/silence_phones.txt > tmp/words.txt
sed -i '/^[[:space:]]*$/d'  tmp/words.txt


