import os
os.environ["OMP_NUM_THREADS"] = "1" # export OMP_NUM_THREADS=1
os.environ["OPENBLAS_NUM_THREADS"] = "1" # export OPENBLAS_NUM_THREADS=1
os.environ["MKL_NUM_THREADS"] = "1" # export MKL_NUM_THREADS=1
os.environ["VECLIB_MAXIMUM_THREADS"] = "1" # export VECLIB_MAXIMUM_THREADS=1
os.environ["NUMEXPR_NUM_THREADS"] = "1" # export NUMEXPR_NUM_THREADS=1
os.environ['TF_XLA_FLAGS'] = '--tf_xla_enable_xla_devices'
os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
os.environ["CUDA_VISIBLE_DEVICES"] = ""

import tensorflow as tf
import sys
from scipy.io import wavfile
from amfm_decompy import pYAAPT, basic_tools
import numpy as np
from utils import kaldi_pad, log10
from kaldiio import WriteHelper
from utils import kaldi_pad, preemphasis, minmax_norm, load_wav, spectrogram, melspectrogram, norm_spec
from kaldiio import WriteHelper
import sys 
import torch
import torch.utils.data
from scipy.io.wavfile import read
import opensmile
import joblib
import audiofile
import pandas as pd
  

lang = sys.argv[1]
gender=sys.argv[2]
frame_length=int(sys.argv[3])
frame_step=int(sys.argv[4])
fft_length=int(sys.argv[5])
num_mel_bins=int(sys.argv[6])

# We're using the audio processing from TacoTron2 to make sure it matches
sys.path.insert(0, 'tacotron2')
from tacotron2.layers import TacotronSTFT

MAX_WAV_VALUE = 32768.0
stft = TacotronSTFT(filter_length=fft_length,
                                 hop_length=frame_step,
                                 win_length=frame_length,
                                 sampling_rate=22050,
                                 mel_fmin=0.0, mel_fmax=8000.0)

def kaldi_pad(wav, frame_shift):
    old_length=len(wav)
    num_frames = (old_length + frame_shift // 2) // frame_shift
    new_length = num_frames*frame_shift
    diff = new_length-old_length

    if diff > 0:
        wav = np.concatenate([wav, np.zeros(diff)])
    else:
        wav = wav[:new_length]

    return wav

def load_wav_to_torch(full_path):
    """
    Loads wavdata into torch array
    """
    sampling_rate, data = read(full_path)
    return  data, sampling_rate      #torch.from_numpy(data).float(), sampling_rate

def get_spec_mel(audio):
    audio_norm = audio / MAX_WAV_VALUE
    audio_norm = audio_norm.unsqueeze(0)
    audio_norm = torch.autograd.Variable(audio_norm, requires_grad=False)
    melspec, spec = stft.mel_spectrogram(audio_norm)
    melspec = torch.squeeze(melspec, 0)
    spec = torch.squeeze(spec, 0)
    return melspec, spec

outstem = 'tmp'
min_dB = -100
max_dB = 25

if gender=='male':
    f0_min = 50.0
    f0_max = 300.0
elif gender=='female':
    f0_min = 90.0
    f0_max = 400.0    
else:
    f0_min = 50.0
    f0_max = 400.0
    
smile = opensmile.Smile(
    feature_set=opensmile.FeatureSet.eGeMAPSv02,
    feature_level=opensmile.FeatureLevel.LowLevelDescriptors,
)    

scpfile='exp_%s_%s/data/train/wav_t2.scp'%(lang,gender)
fout=WriteHelper('ark,scp:exp_%s_%s/tts/pitch.ark,exp_%s_%s/tts/pitch.scp'%(lang,gender,lang,gender))
spec_out=WriteHelper('ark,scp:exp_%s_%s/tts/spgram.ark,exp_%s_%s/tts/spgram.scp'%(lang,gender,lang,gender))
fbank_out=WriteHelper('ark,scp:exp_%s_%s/tts/fbank.ark,exp_%s_%s/tts/fbank.scp'%(lang,gender,lang,gender))
tap_out=WriteHelper('ark,scp:exp_%s_%s/tts/tap.ark,exp_%s_%s/tts/tap.scp'%(lang,gender,lang,gender))

with open(scpfile) as fp:
    scp=fp.read().splitlines()

f0s_all=[]
for utt in scp:
    utt_id=utt.split('\t')[0]
    utt_file=utt.split('\t')[1]
    fs, wav = wavfile.read(utt_file)
    wav = wav/(2**15)
    wav = kaldi_pad(wav,frame_step)
    wav1 = np.pad(wav, 512)
    signal = basic_tools.SignalObj(data=wav1, fs=fs)
    pitch=pYAAPT.yaapt(signal, **{'f0_min' : f0_min, 'f0_max': f0_max, 'frame_length': 46.44, 'frame_space':11.61})
    f0 = pitch.samp_values
    f0[f0<1]=1
    fout(utt_id, np.expand_dims(f0, axis=-1))
    f0s_all.append(f0)
    
    wav, sr = audiofile.read(utt_file)
    wav = np.concatenate((wav, np.zeros(frame_step-len(wav)%frame_step)))
    tap_feats = smile.process_signal(wav, sr)
    tap_feats_arr = tap_feats.to_numpy()
    
    audio, sr = load_wav_to_torch(utt_file)
    audio = kaldi_pad(audio, 256)
    melspectrogram, spectrogram = get_spec_mel(torch.from_numpy(audio).float())

    spec_out(utt_id, spectrogram.numpy().T)
    fbank_out(utt_id, melspectrogram.numpy().T)
    tap_out(utt_id, tap_feats_arr)          

fout.close()
fbank_out.close()
spec_out.close()
tap_out.close()

f0s_all=np.hstack(f0s_all)
unique_f0s=np.unique(f0s_all)
min_f0=unique_f0s[1]
max_f0=unique_f0s[-1]
print ('min_f0:', min_f0, 'max_f0:', max_f0)
dict={'min_f0':min_f0,'max_f0':max_f0}
np.save('exp_%s_%s/tts/f0_stats'%(lang,gender),dict)


