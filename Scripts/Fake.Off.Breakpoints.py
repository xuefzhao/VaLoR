#!/usr/bin/env python

#!python
#For debug use only
#fake off breakpoints:
#command='Fake.Off.Breakpoints.py --bed input.bed --off 5'
#sys.argv=command.split()
import os
import re
import sys
import getopt
opts,args=getopt.getopt(sys.argv[1:],'i:',['bed=','off=','pacbio-input=','output-path=','sv-type='])
dict_opts=dict(opts)
input_file=dict_opts['--bed']
off_num=int(dict_opts['--off'])
output_file='.'.join(input_file.split('.')[:-1]+[str(off_num),'bed'])
fin=open(input_file)
fo=open(output_file,'w')
for line in fin:
	pin=line.strip().split()
	pin2=[pin[0],int(pin[1])+off_num,int(pin[2])+off_num]+pin[3:]
	print >>fo, '\t'.join([str(i) for i in pin2])

fin.close()
fo.close()






Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 5
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -5
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 10
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -10
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 15
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -15
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 20
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -20
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 25
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -25
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 30
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -30
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 35
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -35
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 40
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -40
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 45
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -45
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 50
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -50
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 55
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -55
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 60
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -60
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 65
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -65
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 70
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -70
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 75
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -75
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 80
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -80
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 85
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -85
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 90
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -90
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 95
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -95
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 100
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off -100

