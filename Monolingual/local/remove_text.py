import sys
with open(sys.argv[2]) as file:
    remove_list = [line.strip() for line in file]
fout=open(sys.argv[3],'w')
with open(sys.argv[1]) as fin:
    for fil in fin:
        fil = fil.strip()
        if not fil in remove_list:
            fout.write(fil)
            fout.write('\n')
fout.close()

