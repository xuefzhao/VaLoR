#!/usr/bin/env python

#!python
#For debug use only
#command='Extract.VCF.For.SVs.py -i /scratch/remills_flux/xuefzhao/PacbioValidation/1000G_SV_Calls/ALL.chr9.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes.NA12878.vcf'
#sys.argv=command.split()
import os
import sys
import getopt
if len(sys.argv)<2:
	print 'Usage: Extract.VCF.For.SVs.py -i input.vcf'
else:
	def genotype_decide(pin,sample_pos):
		gt=pin[sample_pos]
		if '/' in gt:
			gt_new=gt.split('/')
		elif '|' in gt:
			gt_new=gt.split('|')
		else:
			gt_new=[0,0]
		gt_new=[int(i) for i in gt_new]
		return sum(gt_new)
	def SVtype_decide(pin):
		sv_type=''
		for x in pin[7].split(';'):
			if x.split('=')[0]=='SVTYPE':
				sv_type=x.split('=')[1]
		return sv_type
	def SVend_decide(pin):
		end=int(pin[1])
		for x in pin[7].split(';'):
			if x.split('=')[0]=='END':
				end=int(x.split('=')[1])
		return end
	def sv_hash_readin():
		global input_file
		input_file=dict_opts['-i']
		fin=open(input_file)
		sv_hash={}
		for line in fin:
			pin=line.strip().split()
			if not pin[0][0]=='#': 
				if 'SVTYPE' in pin[7]: 
					genotype=genotype_decide(pin,9)
					svtype=SVtype_decide(pin)
					if not svtype in sv_hash.keys():
						sv_hash[svtype]={}
					if not genotype in sv_hash[svtype].keys():
						sv_hash[svtype][genotype]=[]
					sv_hash[svtype][genotype].append(pin)
		fin.close()
		return sv_hash
	def sv_hash_modify():
		out={}
		for x in sv_hash.keys():
			for y in sv_hash[x].keys():
				for z in sv_hash[x][y]:
					temp_z=[z[0],int(z[1]),SVend_decide(z)]
					if not z[0] in out.keys():
						out[z[0]]={}
					if not int(z[1]) in out[z[0]].keys():
						out[z[0]][int(z[1])]={}
					if not temp_z[2] in out[z[0]][int(z[1])].keys():
						out[z[0]][int(z[1])][temp_z[2]]=[]
					out[z[0]][int(z[1])][temp_z[2]].append(z)
		return out
	def sv_hash_write():
		file_in=dict_opts['-i']
		file_out='.'.join(file_in.split('.')[:-1]+['SV','vcf'])
		fo=open(file_out,'w')
		for k1 in sorted(ordered_sv_hash.keys()):
			for k2 in sorted(ordered_sv_hash[k1].keys()):
				for k3 in sorted(ordered_sv_hash[k1][k2].keys()):
					for k4 in ordered_sv_hash[k1][k2][k3]:
						print >>fo, '\t'.join(k4)
		fo.close()
	def main():
		opts,args=getopt.getopt(sys.argv[1:],'i:',['sample=','reference=','pacbio-input=','output-path=','sv-type='])
		global dict_opts
		dict_opts=dict(opts)
		global sv_hash
		sv_hash=sv_hash_readin()
		global ordered_sv_hash
		ordered_sv_hash=sv_hash_modify()
		sv_hash_write()
	main()	


