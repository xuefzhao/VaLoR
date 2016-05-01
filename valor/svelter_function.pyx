def svelter_read_in(filein):
	out={}
	fin=open(filein)
	pin=fin.readline().strip().split()
	rec=-1
	for line in fin:
		pin=line.strip().split()
		rec+=1
		if not pin[4] in out.keys():
			out[pin[4]]={}
		if not pin[5] in out[pin[4]].keys():
			out[pin[4]][pin[5]]=[]
		if not pin[3].split(':') in out[pin[4]][pin[5]]:
			out[pin[4]][pin[5]].append(pin[3].split(':')+[rec])
	fin.close()
	return out
def write_PacVal_score_hash_svelter(PacVal_file_in,PacVal_file_out,PacVal_score_hash):
	fo=open(PacVal_file_out,'w')
	rec=-1
	fin=open(PacVal_file_in)
	for line in fin:
		pin=line.strip().split()
		rec+=1
		if rec in PacVal_score_hash.keys():
			print >>fo, ' '.join([str(i) for i in pin+[str(PacVal_score_hash[rec])]])
		else:
			print >>fo, ' '.join([str(i) for i in pin+['-1']])
	fo.close()
	fin.close()

