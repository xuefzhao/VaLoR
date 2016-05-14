def bed_readin(dict_opts):
	PacVal_file_in=dict_opts['--sv-input']
	filein=dict_opts['--sv-input']
	PacVal_file_out=filein+'.PacVal'
	PacVal_score_hash={}
	sv_type=dict_opts['--sv-type']
	ka='a/a'
	if sv_type in ['DEL','del','deletion','DELETION']:
		kb=DEL_alt_make([1,1])
	elif sv_type in ['INV','inv','inversion','INVERSION']:
		kb=INV_alt_make([1,1])
	elif sv_type in ['DUP_TANDEM','dup_tandem','DUPTAN','tandem_dup']:
		kb=DUP_TAN_alt_make([1,1])
	elif sv_type in ['INS','ins','insertion','INSERTION']:
		ka='/'
		kb='a/a'
	else:
		print 'error: sv type not recognized!'
		kb='a/a'
		return 'Error'
	out_hash={}
	fin=open(filein)
	rec=-1
	for line in fin:
		rec+=1
		pin=line.strip().split()
		if not pin[0] in out_hash.keys():
			out_hash[pin[0]]=[]
		kb_new=kb
		if len(pin)>3:
			if pin[3] in ['het','HET','heter','heterozygous']:
				kb_new='/'.join([kb.split('/')[0],ka.split('/')[0]])
			else:
				kb_new=kb
		if len(pin)>3:
			pin_info=[pin[0]]+[int(i) for i in pin[1:3]]+[ka,kb_new,rec]+pin[3:]
		else:
			pin_info=[pin[0]]+[int(i) for i in pin[1:3]]+[ka,kb_new,rec,'']
		if not pin_info in out_hash[pin[0]]:
			out_hash[pin[0]].append(pin_info)
	fin.close()
	return out_hash
def DEL_alt_make(genotype):
	#eg of genotype:[0,0],[0,1],[1,1]
	if type(genotype[0])==type(1) and type(genotype[1])==type(1):
		if sum(genotype)==0:
			kb='a/a'
		elif sum(genotype)==1:
			kb='/a'
		elif sum(genotype)==2:
			kb='/'
		else:
			kb='error'
		return kb
	else:
		print 'wrong genotype!'
		return 'error'
def INV_alt_make(genotype):
	#eg of genotype:[0,0],[0,1],[1,1]
	if type(genotype[0])==type(1) and type(genotype[1])==type(1):
		if sum(genotype)==0:
			kb='a/a'
		elif sum(genotype)==1:
			kb='a^/a'
		elif sum(genotype)==2:
			kb='a^/a^'
		else:
			kb='error'
		return kb
	else:
		print 'wrong genotype!'
		return 'error'
def DUP_TAN_alt_make(genotype):
	#eg of genotype:[0,0],[0,1],[1,1]
	if type(genotype[0])==type(1) and type(genotype[1])==type(1):
		if sum(genotype)==0:
			kb='a/a'
		elif sum(genotype)==1:
			kb='aa/a'
		elif sum(genotype)==2:
			kb='aa/aa'
		else:
			kb='error'
		return kb
	else:
		print 'wrong genotype!'
		return 'error'
def INS_alt_make(genotype):
	if type(genotype[0])==type(1) and type(genotype[1])==type(1):
		if sum(genotype)==0:
			kb='ac/ac'
		elif sum(genotype)==1:
			kb='abc/ac'
		elif sum(genotype)==2:
			kb='abc/abc'
		else:
			kb='error'
		return kb
	else:
		print 'wrong genotype!'
		return 'error'		
def write_PacVal_score_hash(PacVal_file_in,PacVal_file_out,PacVal_score_hash):
	fo=open(PacVal_file_out,'w')
	rec=-1
	fin=open(PacVal_file_in)
	for line in fin:
		pin=line.strip().split()
		rec+=1
		if rec in PacVal_score_hash.keys():
			pin2=pin+[str(PacVal_score_hash[rec])]
		else:
			pin2=pin+['-1'] #SV locates in repetitive regions, cannot validate
		print >>fo, ' '.join([str(i) for i in pin2])
	fin.close()
	fo.close()