from scipy.io import wavfile
from amfm_decompy import pYAAPT, basic_tools
import numpy as np
from utils import kaldi_pad

scpfile='data/train/wav.scp'

with open(scpfile) as fp:
    scp=fp.read().splitlines()

for utt in scp:
    utt_id=utt.split('\t')[0]
    utt_file=utt.split('\t')[1]
    print(utt_id)


'''

wav_file='/raid/ksrm/speechData/telugu_male_mono/wav_16k/tel_0008.wav'
fs, wav = wavfile.read(wav_file)
wav = wav/(2**15)
wav = kaldi_pad(wav,80)
wav = np.pad(wav, 200)
signal = basic_tools.SignalObj(data=wav, fs=fs)
pitch=pYAAPT.yaapt(signal, **{'f0_min' : 65.0, 'f0_max': 300, 'frame_length': 25, 'frame_space':5.})
'''
