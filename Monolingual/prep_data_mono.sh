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


txt_path=/raid/ee17resch11001/LIMMITS/Data/Telugu_F_1/txt/
orig_wav_path=/raid/ee17resch11001/LIMMITS/Data/Telugu_F_1/wav/
wav_path=/raid/ee17resch11001/LIMMITS/Data/Telugu_F_1/wav_22k/

if [ -d "$wav_path" ]; then
	echo ============================================================================
	echo "                      Resampled wavfiles available                        "
	echo ============================================================================	
else
	echo ============================================================================
	echo "                           Resampling wavfiles                            "
	echo ============================================================================	
	max_dur=24.9
	min_dur=2.0	
	mkdir -p $wav_path
	for file in `ls $orig_wav_path`
	do
		dur="$(soxi -D $orig_wav_path/$file)"
		#echo $dur
		if [ $(echo "$dur < $max_dur" | bc) -ne 0 ]; then
			if [ $(echo "$dur > $min_dur" | bc) -ne 0 ]; then
				sox -v 0.99 $orig_wav_path/$file -r 22050 -b 16 $wav_path/$file
			fi
		fi
	done
fi

exp_path=exp_"$lang"_$gender
data_path=$exp_path/data

feats_nj=1
train_nj=1
decode_nj=1

echo ============================================================================
echo "                Data & Lexicon & Language Preparation                     "
echo ============================================================================
local/tts_data_prep.sh $wav_path $txt_path $data_path/train $lang $gender



local/tts_dict_prep.sh $data_path $lang $gender



# Caution below: we remove optional silence by setting "--sil-prob 0.0",
# in TIMIT the silence appears also as a word in the dictionary and is scored.
prepare_lang_new.sh --sil-prob 0.5 --position-dependent-phones false \
	--num-sil-states 3  \
	$data_path/dict "sil" $data_path/lang_tmp $data_path/lang

local/timit_format_data.sh $data_path




echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set          "
echo ============================================================================
# Now make MFCC features.
mfccdir=$exp_path/mfcc
for x in train; do
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $feats_nj $data_path/$x $exp_path/make_mfcc/$x $mfccdir
  steps/compute_cmvn_stats.sh $data_path/$x $exp_path/make_mfcc/$x $mfccdir
done

echo ============================================================================
echo "                     MonoPhone Training &  Alignment                     "
echo ============================================================================

steps/train_mono.sh  --boost-silence 1.0 --careful true --totgauss 1000 \
       --nj "$train_nj" --cmd "$train_cmd" $data_path/train $data_path/lang $exp_path/mono

align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" \
 $data_path/train $data_path/lang $exp_path/mono $exp_path/mono_ali

echo ============================================================================
echo "           tri1 : Deltas + Delta-Deltas Training & Alignment               "
echo ============================================================================

# Train tri1, which is deltas + delta-deltas, on train data.
steps/train_deltas.sh --boost-silence 1.0 --cmd "$train_cmd" \
 $numLeavesTri1 $numGaussTri1 $data_path/train $data_path/lang $exp_path/mono_ali $exp_path/tri1

align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" \
  $data_path/train $data_path/lang $exp_path/tri1 $exp_path/tri1_ali
  

data_path=$exp_path/data/train
tts_path=$exp_path/tts
ali=$exp_path/tri1_ali
lang_dir=$exp_path/data/lang

mkdir -p $tts_path

ali-to-phones --per-frame $ali/final.mdl ark:"gunzip -c $ali/ali.1.gz|" ark,t:-> tmp/align.txt
cat tmp/align.txt | awk '{print $1 " ["; for (i=2; i<NF; i++) print $i; print $i " ]"}' | copy-feats ark,t:- ark:$tts_path/align.ark

echo ============================================================================
echo "                    Get alignment scores for each utterance               "
echo ============================================================================

ctm=$ali/phone_alignments.ctm
	
ali-to-phones --per-frame --ctm-output $ali/final.mdl "ark:gunzip -c $ali/ali.*.gz|" $ctm
steps/get_train_ctm.sh $data_path $lang_dir $ali
word_alignments=$ali/ctm

new_dir=$data_path/test_alignments_wavefiles_tri1
mkdir -p $new_dir
for file_id in `cat $ali/ctm | cut -d ' ' -f1 | sort -u`
do
	#cp data_giridhar/$i/$file_id.wav $new_dir
	grep $file_id $ctm|awk '{printf $3 " " $3+$4 " " $5 "\n"}'>$new_dir/$file_id.PHN1
	utils/int2sym.pl  -f 3 $lang_dir/phones.txt $new_dir/$file_id.PHN1 >$new_dir/$file_id.PHN
	rm $new_dir/$file_id.PHN1
	grep $file_id $word_alignments|awk '{printf $3 " " $3+$4 " " $5 "\n"}'>$new_dir/$file_id.WRD
	cp $data_path/text $new_dir
done


echo ============================================================================
echo "                    Extract Pitch Features                                "
echo ============================================================================
echo ============================================================================
echo "                    Extract FBANK Features                                "
echo ============================================================================


if [ -f $tts_path/pitch.ark ]; then
	echo "Pitch features file $tts_path/pitch.ark exits. Skipping Pitch extraction"
else
	echo "Extracting Pitch Fbank features"
 	python3 compute-feats.py $lang $gender 1024 256 1024 80
fi



#if [ -f $tts_path/fbank.ark ]; then
#	echo "FBANK features file $tts_path/fbank.ark exits. Skipping fbank extraction"
#else
#	python3 compute-fbank-feats.py $lang $gender
#fi

echo ============================================================================
echo "                    Formatting Data for Prosody TTS Training              "
echo ============================================================================

paste-feats --length-tolerance=1 ark:$tts_path/align.ark ark:$tts_path/pitch.ark ark:$tts_path/fbank.ark ark:$tts_path/spgram.ark ark:$tts_path/tap.ark ark:$tts_path/feat_tts.ark

cut -d ' ' -f1 tmp/align.txt | tail -50 > tmp/test.scp

subset-feats --exclude=tmp/test.scp ark:$tts_path/feat_tts.ark ark,scp:$tts_path/train.ark,$tts_path/train.scp
subset-feats --include=tmp/test.scp ark:$tts_path/feat_tts.ark ark,scp:$tts_path/test.ark,$tts_path/test.scp

