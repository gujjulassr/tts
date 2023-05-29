import numpy as np
import epitran
import sys
import re

if len(sys.argv) < 5:
    print('Usage: prepare_text utt_ids text_path')
    exit(1)


in_file = sys.argv[1]
out_file=sys.argv[2]
lang = sys.argv[3]
gender=sys.argv[4]
lang=lang.lower()

dictionary={'telugu':'tel-Telu-chal-new','hindi':'hin-Deva-chal-new','marathi':'mar-Deva-chal-new'}
epi = epitran.Epitran(dictionary[lang])

fout=open(out_file, 'w')
fout.write('sil sil\n')
fout.write('p_pau p_pau\n')
fout.write('c_pau c_pau\n')
fout.write('q_pau q_pau\n')
fout.write('pau pau\n')
with open(in_file) as fin:
    for word in fin:
        ipa = epi.trans_delimiter(word)
        
        #ipa=ipa.replace(u"\ufeff", '')
        #ipa=ipa.replace(u"\u200c", '')
        #ipa=ipa.replace(u"\u201d", '')
        #ipa=ipa.replace(u"\u00A0", '')
        #ipa=ipa.replace(u"‍‍\u200d", '')

        #include closure regions for unvoiced stops
        #Marathi
        ipa=ipa.replace(u'\u0074\u0361\u0255 ', 'cl \u0074\u0361\u0255 ')
        #Telugu
        ipa=ipa.replace('k ', 'cl k ')
        ipa=ipa.replace(u'\u0074\u0361\u0283 ', 'cl \u0074\u0361\u0283 ')
        ipa=ipa.replace(u'\u0074\u032A ', 'cl \u0074\u032A ')
        ipa=ipa.replace(u'\u0288 ', 'cl \u0288 ')
        ipa=ipa.replace('p ', 'cl p ')
        #Hindi
        ipa=ipa.replace(u'\u0074 ', 'cl \u0074 ')   
        
        #include closure regions for aspirated unvoiced stops
        #Telugu
        ipa=ipa.replace(u'\u006B\u02B0 ', 'cl \u006B\u02B0 ')
        ipa=ipa.replace(u'\u0074\u0361\u0283\u02B0 ', 'cl \u0074\u0361\u0283\u02B0 ')
        ipa=ipa.replace(u'\u0288\u02B0 ', 'cl \u0288\u02B0 ')
        ipa=ipa.replace(u'\u0074\u02B0 ', 'cl \u0074\u02B0 ')
        ipa=ipa.replace(u'\u0070\u02B0 ', 'cl \u0070\u02B0 ')
       
        #Deal with geminate unvoiced stops
        #Telugu
        ipa=ipa.replace('cl k cl k', 'cl g_k')
        ipa=ipa.replace(u'cl \u0074\u0361\u0283 cl \u0074\u0361\u0283', 'cl g_\u0074\u0361\u0283')
        ipa=ipa.replace(u'cl \u0074\u032A cl \u0074\u032A', 'cl g_\u0074\u032A')
        ipa=ipa.replace(u'cl \u0288 cl \u0288', 'cl g_\u0288')
        ipa=ipa.replace('cl p cl p', 'cl g_p')
        #Hindi
        ipa=ipa.replace('cl t cl t', 'cl g_t')
        #Marathi
        ipa=ipa.replace(u'cl \u0074\u0361\u0255 cl \u0074\u0361\u0255', 'cl g_\u0074\u0361\u0255')
        
        #Deal with geminated sounds
        #Telugu 
        ipa=ipa.replace(u'\u0261 \u0261', 'g_\u0261')
        ipa=ipa.replace(u'\u0064\u0361\u0292 \u0064\u0361\u0292', 'g_\u0064\u0361\u0292')
        ipa=ipa.replace(u'\u0074\u0361\u0283\u02B0 \u0074\u0361\u0283\u02B0', 'g_\u0074\u0361\u0283\u02B0')
        ipa=ipa.replace(u'\u0256 \u0256', 'g_\u0256')
        ipa=ipa.replace(u'\u0074\u032A\u02B0 \u0074\u032A\u02B0', 'g_\u0074\u032A\u02B0')
        ipa=ipa.replace(u'\u0064\u032A \u0064\u032A', 'g_\u0064\u032A')
        ipa=ipa.replace(u'\u0064\u032A\u0324 \u0064\u032A\u0324', 'g_\u0064\u032A\u0324')
        ipa=ipa.replace('n n', 'g_n')
        ipa=ipa.replace(u'\u0070\u02B0 \u0070\u02B0', 'g_\u0070\u02B0')
        ipa=ipa.replace('b b', 'g_b')
        ipa=ipa.replace(u'\u0062\u0324 \u0062\u0324', 'g_\u0062\u0324')
        ipa=ipa.replace('m m', 'g_m')
        ipa=ipa.replace('j j', 'g_j')
        ipa=ipa.replace('r r', 'g_r')
        ipa=ipa.replace('l l', 'g_l')
        ipa=ipa.replace('v v', 'g_v')
        ipa=ipa.replace(u'\u028B \u028B', 'g_\u028B')
        ipa=ipa.replace('s s', 'g_s')
        ipa=ipa.replace(u'\u0283 \u0283', 'g_\u0283')
        ipa=ipa.replace(u'\u0282 \u0282', 'g_\u0282')
        
        #Hindi
        ipa=ipa.replace(u'\u0074\u02B0 \u0074\u02B0', 'g_\u0074\u02B0')         
        ipa=ipa.replace('d d', 'g_d')
        ipa=ipa.replace(u'\u0064\u0324 \u0064\u0324', 'g_\u0064\u0324')
        
        #Marathi
        ipa=ipa.replace(u'\u0064\u0361\u0291 \u0064\u0361\u0291', 'g_\u0064\u0361\u0291')      
        ipa=ipa.replace(u'cl \u0074\u0361\u0255 cl \u0074\u0361\u0255', 'cl g_\u0074\u0361\u0255')
        if lang == 'marathi':
            ipa=ipa.replace(u'\u0061\u02D0 \u0303', '\u0061\u0303\u02D0')
            ipa=ipa.replace(u'\u0075\u02D0 \u0303', '\u0061\u0303\u02D0')
            ipa=ipa.replace(u'\u006D \u0303', '\u006D')          
        

        ipa = re.sub(' +', ' ', ipa)
        fout.write(word.strip())
        fout.write(' ')
#        fout.write(ipa)
        fout.write(ipa.strip())
        fout.write('\n')
fout.close()
