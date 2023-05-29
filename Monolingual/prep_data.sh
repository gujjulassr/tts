#!/usr/bin/env bash

. ./cmd.sh
[ -f path.sh ] && . ./path.sh
set -e
# Acoustic model parameters
numLeavesTri1=2500
numGaussTri1=15000
numLeavesMLLT=2500
numGaussMLLT=15000
numLeavesSAT=2500
numGaussSAT=15000
numGaussUBM=400
numLeavesSGMM=7000
numGaussSGMM=9000

lang=$1
gender=$2
domain=$3
direc=$lang"_"$gender"_"$domain

[ $# -ne 3 ] && echo "Wrong number of arguments supplied" && exit 1 ;

txt_path=/raid/ee17resch11001/LIMMITS/Domain_wise_data/$direc/text/
wav_path=/raid/ee17resch11001/LIMMITS/Domain_wise_data/$direc/wav/

exp_path=exp_"$lang"_$gender
data_path=$exp_path/data

feats_nj=1
train_nj=1
decode_nj=1

echo ============================================================================
echo "                    Extract Pitch Features                                "
echo ============================================================================
echo ============================================================================
echo "                    Extract FBANK Features                                "
echo ============================================================================

data_path=$exp_path/data/train
tts_path=$exp_path/tts
ali=$exp_path/tri1_ali

mkdir -p $tts_path

if [ -f $tts_path/pitch.ark ]; then
	echo "Pitch features file $tts_path/pitch.ark exits. Skipping Pitch extraction"
else
	echo "Extracting Pitch Fbank features"
 	python3 compute-feats.py $lang $gender 1024 256 1024 80
fi

echo ============================================================================
echo "                    Formatting Data for Prosody TTS Training              "
echo ============================================================================
#ali-to-phones --per-frame $ali/final.mdl ark:"gunzip -c $ali/ali.1.gz|" ark,t:-> tmp/align.txt
#cat tmp/align.txt | awk '{print $1 " ["; for (i=2; i<NF; i++) print $i; print $i " ]"}' | copy-feats ark,t:- ark:$tts_path/align.ark

#paste-feats --length-tolerance=1 ark:$tts_path/align.ark ark:$tts_path/pitch.ark ark:$tts_path/fbank.ark ark:$tts_path/feat_tts.ark

#cut -d ' ' -f1 tmp/align.txt | shuf | tail -10 > tmp/test.scp
while read j; do k=`basename $j`; echo $k >> tmp/list ; done<$data_path/wav_t2.scp
tail -10 tmp/list > tmp/test.scp

#subset-feats --exclude=tmp/test.scp ark:$tts_path/feat_tts.ark ark,scp:$tts_path/train.ark,$tts_path/train.scp
#subset-feats --include=tmp/test.scp ark:$tts_path/feat_tts.ark ark,scp:$tts_path/test.ark,$tts_path/test.scp

