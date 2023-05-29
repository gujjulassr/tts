#!/bin/bash
. path.sh
ctm=local/1.ctm
file_id=S0001_0005
ali_dir=exp_telugu_female/mono_ali
ali-to-phones --frame-shift=0.005 --ctm-output $ali_dir/final.mdl "ark:gunzip -c $ali_dir/ali.1.gz|" $ctm

grep $file_id $ctm|awk '{printf $3 " " $3+$4 " " $5 "\n"}'>local/$file_id.lab

