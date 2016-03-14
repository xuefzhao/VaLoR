#!/usr/bin/env python

#!python
#For debug use only
#command='Extract.VCF.For.Single.Sample.py -i /scratch/remills_flux/xuefzhao/PacbioValidation/1000G_SV_Calls/ALL.chr9.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes.vcf --sample NA12878'
#sys.argv=command.split()
import os
import sys
import getopt
if len(sys.argv)<2:
	print 'Usage: Extract.VCF.For.Single.Sample.py -i input.vcf --sample sample_name'
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
	break_flag=0
	opts,args=getopt.getopt(sys.argv[1:],'i:',['sample=','reference=','pacbio-input=','output-path=','sv-type='])
	dict_opts=dict(opts)
	input_file=dict_opts['-i']
	sample_name=dict_opts['--sample']
	fin=open(input_file)
	fo=open('.'.join(input_file.split('.')[:-1]+[sample_name,'vcf']),'w')
	for line in fin:
		pin=line.strip().split()
		if pin[0][:2]=='##':
			print >>fo, '\t'.join(pin)
		else:
			if pin[0][0]=='#':
				if not sample_name in pin:
					print 'Error: sample not in input file !'
					break_flag+=1
				else:
					sample_pos=pin.index(sample_name)
				print >>fo, '\t'.join(pin[:9]+[sample_name])
			else:
				if break_flag==0:
					if genotype_decide(pin,sample_pos)>0:
						pnew=pin[:9]+[pin[sample_pos]]
						print >>fo,  '\t'.join(pnew)
				else: 
					break
	fin.close()
	fo.close()

