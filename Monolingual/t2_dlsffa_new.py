import kaldiio
from kaldiio import ReadHelper
import numpy as np
import os, sys
import subprocess
threshold=-100
print (threshold)
ll=0
wavs_dict={}
lang = 'Hindi' # sys.argv[1] 
spkr = 'Female' #sys.argv[2]
scp_file = f'exp_{lang}_{spkr}/data/train/wav.scp'
new_scp_file = f'exp_{lang}_{spkr}/data/train/wav_t2_new.scp'

f=open(scp_file).read().splitlines()
for i in range(len(f)):

	key=f[i].split('\t')[0]
	value=f[i].split('\t')[1]
	wavs_dict[key]=value
h=open(new_scp_file,'w')

with ReadHelper(f'ark:exp_{lang}_{spkr}/tri1_ali/per_frame_logprobs.1.ark') as reader:
    
  	for utt_id, scores in reader:
  		os.system(f'mkdir -p exp_{lang}_{spkr}/data/test_alignments_wavefiles_tri1')
  		f=open(f'exp_{lang}_{spkr}/data/train/test_alignments_wavefiles_tri1/%s.WRD'%(utt_id)).read().splitlines()
  		#g=open('giridhar/%s/test_alignments_wavefiles_tri1/%s_scores_temp1.txt'%(i,utt_id),'w')
  
  		log_word_scores=[]
  		for j in range(len(f)):
  			log_scores=np.mean(scores[int(float(f[j].split()[0])*100):int(float(f[j].split()[1])*100)])
  			log_word_scores.append(log_scores)
  		#print(log_word_scores)
  		log_word_scores=np.array(log_word_scores)
  		log_word_scores1=log_word_scores
  		log_word_scores[log_word_scores>=threshold]=1
  		log_word_scores[log_word_scores<threshold]=0
  		#print(log_word_scores)
  		#print('\n')
  		good_words=sum(log_word_scores1)
  		if good_words>=len(f)*0.95:
  			#print(log_word_scores1)
  			#print(utt_id)
  			#print(ll)
  			h.write(utt_id)
  			h.write('\t')
  			h.write(wavs_dict[utt_id])
  			h.write('\n')
  			ll=ll+1
print(ll)
h.close()

with open(scp_file) as fp:
    scp=fp.read().splitlines()

total_dur = 0.0
for utt in scp:
    utt_id=utt.split('\t')[0]
    utt_file=utt.split('\t')[1]
    proc = subprocess.Popen(["soxi -D %s"%(utt_file)], stdout=subprocess.PIPE, shell=True)
    (dur, err) = proc.communicate()
    dur = float(dur.strip().decode("utf-8"))
    total_dur += dur
total_dur = total_dur/3600.0
print ('The total duration of actual files is', '%.2f'%total_dur, 'hours')

with open(new_scp_file) as fp:
    scp=fp.read().splitlines()

new_total_dur = 0.0
for utt in scp:
    utt_id=utt.split('\t')[0]
    utt_file=utt.split('\t')[1]
    proc = subprocess.Popen(["soxi -D %s"%(utt_file)], stdout=subprocess.PIPE, shell=True)
    (dur, err) = proc.communicate()
    dur = float(dur.strip().decode("utf-8"))
    new_total_dur += dur
new_total_dur = new_total_dur/3600.0
print ('The total duration of new files is', '%.2f'%new_total_dur, 'hours')

print ('Percentage of data is', '%.2f'%((new_total_dur/total_dur)*100))
