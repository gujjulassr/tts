#!/bin/bash
. path.sh

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

rm tmp/*
mkdir tmp
test_N=50
total_N=`ls $wav_path|wc -l`
train_N=$total_N

mkdir -p $data_path
ls $wav_path/*.wav |sort|head -$train_N > tmp/flist_all

#Remove special
for txt_file in `ls $txt_path`
do
    check=0
    raw_text=`cat $txt_path/$txt_file`
    for reqsubstr in '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' '(' ')' '%' '३' '८' '९' '५' '४' '६' '७' '१' '२' '॰' '०';do   
      if [ -z "${raw_text##*$reqsubstr*}" ] ;then
        check=1
        #echo $txt_file
      fi
    done
    if [ $check == '1' ]; then
      name=$(basename $txt_file ".txt")
      wavfile=$name".wav"
      echo $wav_path/$wavfile
    fi
done > tmp/remove_list

python3 local/remove_text.py tmp/flist_all tmp/remove_list tmp/flist

sed -e 's:.*/\(.*\)/\(.*\).\(WAV\|wav\)$:\2:' tmp/flist > tmp/uttids

for ii in `cat tmp/uttids`
do
echo "$lang"_$gender1 >>tmp/ln_gender
done

paste tmp/uttids tmp/flist > $data_path/wav.scp

paste -d "\t" tmp/uttids tmp/ln_gender > $data_path/utt2spk
echo "$lang"_"$gender1" `cat tmp/uttids` > $data_path/spk2utt
echo "$lang"_"$gender1 $gender" > $data_path/spk2gender

for utt in `cat tmp/uttids`
do
	echo $utt "sil" `cat $txt_path/$utt.txt | sed 's/,/ c_pau /g' | sed 's/।/ p_pau /g' | sed 's/-/ c_pau /g' | sed 's/\./ p_pau /g' | sed 's/?/ q_pau /g' | tr -d "[']"|tr -d '[!:;"]'` "sil"
done > tmp/text

python3 local/del_zero_width_char.py tmp/text $data_path/text

wav-to-duration --read-entire-file=true scp:$data_path/wav.scp ark,t:$data_path/dur.ark || exit 1
awk -v dur=$data_path/dur.ark \
  'BEGIN{
     while(getline < dur) { durH[$1]=$2; }
     print ";; LABEL \"O\" \"Overall\" \"Overall\"";
     print ";; LABEL \"F\" \"Female\" \"Female speakers\"";
     print ";; LABEL \"M\" \"Male\" \"Male speakers\"";
   }
   { wav=$1; spk=wav; sub(/_.*/,"",spk); $1=""; ref=$0;
     gender=(substr(spk,0,1) == "f" ? "F" : "M");
     printf("%s 1 %s 0.0 %f <O,%s> %s\n", wav, spk, durH[wav], gender, ref);
   }
  ' $data_path/text >$data_path/stm || exit 1

  # Create dummy GLM file for sclite:
echo ';; empty.glm
  [FAKE]     =>  %HESITATION     / [ ] __ [ ] ;; hesitation token
  ' > $data_path/glm

echo "Data preparation succeeded"
