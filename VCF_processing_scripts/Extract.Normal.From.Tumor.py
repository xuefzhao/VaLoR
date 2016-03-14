#!/usr/bin/env python

#!Python
#Usage:
#Extract.Normal.From.Tumor.py --tumor tumor.bed --normal normal.bed --output output.bed --RO-cff 0.5
#Filter Delly output according to SMuFin paper: predictions obtained with Delly were rejected if the number of supporting reads were less than three and the mapping quality 20. 
#For debug use only
#command='Extract.Normal.From.Tumor.py --tumor Delly_chr22_insilico_Tumor.DEL.DEL.bed  --normal Delly_chr22_insilico_Normal.DEL.DEL.bed --output Delly_chr22_insilico_Somatic.DEL.DEL.bed --RO-cff 0.5'
#sys.argv=command.split()
import os
import re
import getopt
import sys
if len(sys.argv)==1:
        print 'Usage: Extract.Normal.From.Tumor.py [parameters]'
        print 'Parameters:'
        print '--tumor: tumor.bed'
        print '--normal: normal.bed'
        print '--output: output.bed'
        print '--RO-cff: percentage'
else:
        opts,args=getopt.getopt(sys.argv[1:],'o:h:S:',['tumor=','RO-cff=','output=','normal=','exclude='])
        dict_opts=dict(opts)
        def bed_read_in(input):
                fin=open(input)
                out={}
                for line in fin:
                        pin=line.strip().split()
                        if not pin[0] in out.keys():
                                out[pin[0]]={}
                        if not int(pin[1]) in out[pin[0]].keys():
                                out[pin[0]][int(pin[1])]=[]
                        out[pin[0]][int(pin[1])].append(int(pin[2]))
                out2={}
                for k1 in out.keys():
                        out2[k1]=[]
                        for k2 in sorted(out[k1].keys()):
                                for k3 in sorted(out[k1][k2]):
                                        out2[k1].append([k2,k3])
                fin.close()
                return out2
        dataN=bed_read_in(dict_opts['--normal'])
        dataT=bed_read_in(dict_opts['--tumor'])
        ROCff=0.5
        if '--RO-cff' in dict_opts.keys():
        	ROCff=float(dict_opts['--RO-cff'])
        out={}
        for k1 in dataT.keys():
                if k1 in dataN.keys():
                        out[k1]=[]
                        for k2 in dataT[k1]:
                                flag=0
                                for k3 in dataN[k1]:
                                        if k3[1]<k2[0]: continue
                                        elif k3[0]>k2[1]: continue
                                        else:
        				    if not max(k2+k3)-min(k2+k3)==0:
                                                if float(sorted(k2+k3)[2]-sorted(k2+k3)[1])/float(max([k2[1]-k2[0],k3[1]-k3[0]]))>ROCff:
	
                                                    flag+=1
        					else:
        				        	 flag+=1
                                if flag==0:
                                        out[k1].append(k2)
        fo=open(dict_opts['--output'],'w')
        for k1 in out.keys():
                for k2 in out[k1]:
                        print >>fo, ' '.join([str(i) for i in [k1]+k2])
        fo.close()

