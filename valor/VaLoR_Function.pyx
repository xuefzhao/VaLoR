import os
import numpy as np
import scipy
from scipy.cluster.vq import vq, kmeans, whiten
from scipy import stats
from scipy.stats import linregress
from sklearn import cluster
from scipy.spatial import distance
import sys
import matplotlib.pyplot as plt
from sklearn import cluster
import plotting
import random
global invert_base
invert_base = { 'A' : 'T', 'T' : 'A', 'C' : 'G', 'G' : 'C','N' : 'N','a' : 't', 't' : 'a', 'c' : 'g', 'g' : 'c','n' : 'n'}
def alt_sv_to_list(alt_sv):
	out=[[],[]]
	for x in alt_sv.split('/')[0]:
			if not x=='^':
					out[0].append(x)
			else:
					out[0][-1]+=x
	for x in alt_sv.split('/')[1]:
			if not x=='^':
					out[1].append(x)
			else:
					out[1][-1]+=x
	return out
def bam_in_decide(bam_in,bps):
	if os.path.isfile(bam_in):
		return bam_in
	else:
		temp_bam_in=[]
		bam_in_path='/'.join(bam_in.split('/')[:-1])+'/'
		if 'XXX' in bam_in.split('/')[-1]:
			bam_in_keys=bam_in.split('/')[-1].split('XXX')
		elif '*' in bam_in.split('/')[-1]:
			bam_in_keys=bam_in.split('/')[-1].split('*')
		else:
			print 'Error: invalid name for pacbio files !'
		for k1 in os.listdir(bam_in_path):
			if k1.split('.')[-1]==bam_in.split('.')[-1]:
				flag=0
				for y in bam_in_keys:
					if not y in k1:
						flag+=1
				if flag==0:
					temp_bam_in.append(bam_in_path+k1)
		bam_out=''
		for x in temp_bam_in:
			if bps[0]+'.' in x: # if bam files were separated by chromosome, we requre chromo+'.' to be in the name , eg; "namepart.chr1.namepart.bam"
				bam_out=x
		if not bam_out=='':
			return bam_out
		else:
			print 'error: pacbio file not found!'
			return bam_out
def bl_len_hash_calculate(bps,ref_sv):
	bl_len_hash={}
	for x in ref_sv.split('/')[0]:
		bl_len_hash[x]=int(bps[ord(x)-97+2])-int(bps[ord(x)-97+1])
	return bl_len_hash
def bps_check(bps,chromosomes):
	flag=0
	for x in bps[1:]:
		if x in chromosomes:
			return 1
	for x in range(len(bps)-2):
		if int(bps[x+2])-int(bps[x+1])>10**6:
			flag+=1
	return flag
def bp_let_to_hash(info,flank_length):
	k1=info[0]
	k3=info[2:]
	out_hash={}
	let_info=['left']+[i for i in k1.split('/')[0]]+['right']
	k3_info=[int(i) for i in k3[1:]]
	k3_info_new=[k3_info[0]-flank_length]+k3_info+[k3_info[-1]+flank_length]
	rec=-1
	for x in let_info:
		rec+=1
		out_hash[x]=[k3_info_new[rec]+1,k3_info_new[rec+1]]
	out_hash_keys=out_hash.keys()
	for x in out_hash_keys:
		out_hash[x+'^']=out_hash[x]
	return out_hash
def chromos_readin(ref):
	fin=open(ref+'.fai')
	chromos=[]
	for line in fin:
			pin=line.strip().split()
			chromos.append(pin[0])
	fin.close()
	return chromos
def cigar2reaadlength(cigar):
	import re
	pcigar=re.compile(r'''(\d+)([MIDNSHP=X])''')
	cigars=[]
	for m in pcigar.finditer(cigar):
		cigars.append((m.groups()[0],m.groups()[1]))
	MapLen=0
	for n in cigars:
		if n[1]=='M' or n[1]=='D' or n[1]=='N':
			MapLen+=int(n[0])
	return MapLen
def cigar2alignstart(cigar,start,bps,flank_length):
	#eg cigar2alignstart(pbam[5],int(pbam[3]),bps)
	import re
	pcigar=re.compile(r'''(\d+)([MIDNSHP=X])''')
	cigars=[]
	for m in pcigar.finditer(cigar):
		cigars.append((m.groups()[0],m.groups()[1]))
	read_rec=0
	align_rec=start
	for x in cigars:
		if x[1]=='S':
			read_rec+=int(x[0])
		if x[1]=='M':
			read_rec+=int(x[0])
			align_rec+=int(x[0])
		if x[1]=='D':
			align_rec+=int(x[0])
		if x[1]=='I':
			read_rec+=int(x[0])
		if align_rec>int(bps[1])-flank_length: break
	return [read_rec,int(align_rec)-int(bps[1])+flank_length]
def cigar2alignstart_2(cigar,start,bps):
	#eg cigar2alignstart(pbam[5],int(pbam[3]),bps)
	import re
	pcigar=re.compile(r'''(\d+)([MIDNSHP=X])''')
	cigars=[]
	for m in pcigar.finditer(cigar):
		cigars.append((m.groups()[0],m.groups()[1]))
	read_rec=0
	align_rec=start
	for x in cigars:
		if x[1]=='S':
			read_rec+=int(x[0])
		if x[1]=='M':
			read_rec+=int(x[0])
			align_rec+=int(x[0])
		if x[1]=='D':
			align_rec+=int(x[0])
		if x[1]=='I':
			read_rec+=int(x[0])
		if align_rec>int(bps[1]): break
	return [read_rec,int(align_rec)-int(bps[1])]
def cigar2alignstart_left(cigar,start,bps,flank_length):
	#eg cigar2alignstart(pbam[5],int(pbam[3]),bps)
	import re
	pcigar=re.compile(r'''(\d+)([MIDNSHP=X])''')
	cigars=[]
	for m in pcigar.finditer(cigar):
		cigars.append((m.groups()[0],m.groups()[1]))
	read_rec=0
	align_rec=start
	for x in cigars:
		if x[1]=='S':
			read_rec+=int(x[0])
		if x[1]=='M':
			read_rec+=int(x[0])
			align_rec+=int(x[0])
		if x[1]=='D':
			align_rec+=int(x[0])
		if x[1]=='I':
			read_rec+=int(x[0])
		if align_rec>int(bps[1])-flank_length: break
	return [read_rec,int(align_rec)-int(bps[1])+flank_length]
def cigar2alignstart_right(flank_length,cigar,start,bps):
	#eg cigar2alignstart(pbam[5],int(pbam[3]),bps)
	import re
	pcigar=re.compile(r'''(\d+)([MIDNSHP=X])''')
	cigars=[]
	for m in pcigar.finditer(cigar):
		cigars.append((m.groups()[0],m.groups()[1]))
	read_rec=0
	align_rec=start
	for x in cigars:
		if x[1]=='S':
			read_rec+=int(x[0])
		if x[1]=='M':
			read_rec+=int(x[0])
			align_rec+=int(x[0])
		if x[1]=='D':
			align_rec+=int(x[0])
		if x[1]=='I':
			read_rec+=int(x[0])
		if align_rec>int(bps[2])+flank_length: break
	return [read_rec,-int(align_rec)+(int(bps[2])+flank_length)]
def cluster_simple_dis(y,simple_dis_cff):
	temp=tranform_diagnal_to_horizonal(y)
	temp_hash=list_to_hash(temp)
	temp[0].sort()
	temp2=[temp[0][i+1]-temp[0][i] for i in range(len(temp[0])-1)]
	temp2_index=[i for i in range(len(temp2)) if temp2[i]>simple_dis_cff]
	if not temp2_index==[]:
		temp2_index=[-1]+temp2_index
		temp2_new=[temp[0][temp2_index[i]+1:temp2_index[i+1]+1] for i in range(len(temp2_index)-1)]
		temp2_new.append(temp[0][(temp2_index[-1]+1):])
		temp3_new=[]
		for y in temp2_new:
			temp3_new.append([])
			y2=list_unique(y)
			for z in y2:
				temp3_new[-1]+=temp_hash[z]
		temp4_new=[tranform_horizonal_to_diagnal([temp2_new[i],temp3_new[i]]) for i in range(len(temp2_new))]
		return temp4_new
	else:
		return [y]
def cluter_to_diagnal(out,clu_dis_cff,lenght_cff,dots_num_cff):
	#search for clusters according to diagnal. based on dis of a dot to diagnal:
	out2=tranform_diagnal_to_horizonal(out)
	out2_hash1={}
	for k1 in range(len(out2[1])):
		if not out2[1][k1] in out2_hash1.keys():
			out2_hash1[out2[1][k1]]=[]
		out2_hash1[out2[1][k1]].append(out2[0][k1])
	cluster_a=cluster_numbers(out2_hash1.keys(),clu_dis_cff)
	cluster_b=[]
	for x in cluster_a:
		cluster_b.append([])
		for y in x:
			cluster_b[-1]+=out2_hash1[y]
	cluster_2_a=[]
	cluster_2_b=[]
	cluster_2_rest=[[],[]]
	for x in range(len(cluster_b)):
		if max(cluster_b[x])-min(cluster_b[x])>lenght_cff and len(cluster_b[x])>dots_num_cff:
			cluster_2_a.append([])
			for y in cluster_a[x]:
				cluster_2_a[-1]+=[y for i in out2_hash1[y]]
			cluster_2_b.append(cluster_b[x])
		else:
			cluster_2_rest[0]+=cluster_a[x]
			cluster_2_rest[1]+=cluster_b[x]
	diagnal_segs=[]
	for x in range(len(cluster_2_a)):
		diagnal_segs.append(tranform_horizonal_to_diagnal([cluster_2_b[x],cluster_2_a[x]]))
def cluster_numbers(list,dis_cff):
	out=[[]]
	for k1 in sorted(list):
		if out[-1]==[]:
			out[-1].append(k1)
		else:
			if k1-out[-1][-1]<dis_cff:
				out[-1].append(k1)
			else:
				out.append([k1])
	return out
def cluster_subgroup(cluster_a,point_dis_cff):
	out=[[]]
	for x in sorted(cluster_a):
		if out[-1]==[]:
			out[-1].append(x)
		else:
			if x-out[-1][-1]<point_dis_cff:
				out[-1].append(x)
			else:
				out.append([x])
	return out
def cluster_check(cluster_a,cluster_b,point_dis_cff):
	out=[[],[]]
	rec=-1
	for x in cluster_b:
		rec+=1
		temp_out=cluster_subgroup(x,point_dis_cff)
		if len(temp_out)==1:
			out[0].append(cluster_a[rec])
			out[0].append()
def cluster_dis_to_diagnal(out,clu_dis_cff,dots_num_cff):
	out1=tranform_diagnal_to_distance(out)
	out1_hash=list_to_hash(out1)
	cluster_a=cluster_numbers(out1[0],clu_dis_cff)
	out_clustered=[]
	out_left=[[],[]]
	for x in cluster_a:
		if len(x)>dots_num_cff:
			x2=list_unique(x)
			out_clustered.append([[],[]])
			for y in x2:
				for z in out1_hash[y]:
					out_clustered[-1][0].append(out[0][z])
					out_clustered[-1][1].append(out[1][z])
		else:
			x2=list_unique(x)
			for y in x2:
				for z in out1_hash[y]:
					out_left[0].append(out[0][z])
					out_left[1].append(out[1][z])
	out2=tranform_anti_diagnal_to_distance(out_left)			
	out2_hash=list_to_hash(out2)
	cluster_b=cluster_numbers(out2[0],clu_dis_cff)
	out_anti_diag=[]
	for x in cluster_b:
		if len(x)>dots_num_cff:
			x2=list_unique(x)
			out_anti_diag.append([[],[]])
			for y in x2:
				for z in out2_hash[y]:
					out_anti_diag[-1][0].append(out_left[0][z])
					out_anti_diag[-1][1].append(out_left[1][z])
	return [out_clustered,out_anti_diag]
def cluster_dots_based_simplely_on_dis(data_list,simple_dis_cff,info):
	#subgroups dots based on their distance on x-axil first, and then on y-axil. distance >50 would be used as the cutoff.
	out=[]
	for x in data_list:
		y=k_means_cluster_Predict(x,info)
		out+=y
	return out
def cluster_range_decide(other_cluster):
	out=[]
	for x in other_cluster:
		out.append([])
		out[-1].append([min(x[0]),max(x[0])])
		out[-1].append([min(x[1]),max(x[1])])
	return out
def cluster_size_decide(range_cluster):
	out=[]
	for x in range_cluster:
		size=(x[0][1]-x[0][0])*(x[1][1]-x[1][0])
		out.append(np.sqrt(size))
	return out
def compute_bic(kmeans,X):
	"""
	Computes the BIC metric for a given clusters
	Parameters:
	-----------------------------------------
	kmeans:  List of clustering object from scikit learn
	X	 :  multidimension np array of data points
	Returns:
	-----------------------------------------
	BIC value
	"""
	# assign centers and labels
	centers = [kmeans.cluster_centers_]
	labels  = kmeans.labels_
	#number of clusters
	m = kmeans.n_clusters
	# size of the clusters
	n = np.bincount(labels)
	#size of data set
	N, d = X.shape
	#compute variance for all clusters beforehand
	cl_var=[]
	for i in xrange(m):
		if not n[i] - m==0:
			cl_var.append((1.0 / (n[i] - m)) * sum(distance.cdist(X[np.where(labels == i)], [centers[0][i]], 'euclidean')**2))
		else:
			cl_var.append(float(10**20) * sum(distance.cdist(X[np.where(labels == i)], [centers[0][i]], 'euclidean')**2))
	const_term = 0.5 * m * np.log10(N)
	BIC = np.sum([n[i] * np.log10(n[i]) -
		   n[i] * np.log10(N) -
		 ((n[i] * d) / 2) * np.log10(2*np.pi) -
		  (n[i] / 2) * np.log10(cl_var[i]) -
		 ((n[i] - m) / 2) for i in xrange(m)]) - const_term
	return(BIC)
def complementary(seq):
	seq2=[]
	for i in seq:
			if i in 'ATGCN':
					seq2.append('ATGCN'['TACGN'.index(i)])
			elif i in 'atgcn':
					seq2.append('atgcn'['tacgn'.index(i)])
	return ''.join(seq2)
def chop_pacbio_read_simple_short(bam_in,info,flank_length):
	bps=info[2:]
	block_length={}
	for x in range(len(info[2:])-2):
		block_length[chr(97+x)]=int(info[x+4])-int(info[x+3])
	alA_len=np.sum([block_length[x] for x in info[1].split('/')[0] if not x=='^'])
	alB_len=np.sum([block_length[x] for x in info[1].split('/')[1] if not x=='^'])
	alRef_len=int(info[-1])-int(info[3])
	len_cff=max([alA_len,alB_len,alRef_len])
	if len_cff>10**4:
		len_cff=min([alA_len,alB_len,alRef_len])
	bam_in_new=bam_in_decide(bam_in,bps)
	if bam_in_new=='': return [[],[],[]]
	fbam=os.popen(r'''samtools view %s %s:%d-%d'''%(bam_in_new,bps[0],int(bps[1])-flank_length,int(bps[-1])+flank_length))
	out=[]
	out2=[]
	out3=[]
	tandem_test=[]
	for line in fbam:
		pbam=line.strip().split()
		if not pbam in tandem_test:
			tandem_test.append(pbam)
			#out3.append(int(pbam[3])-int(bps[1])+flank_length)
			if not pbam[0]=='@': 
				if int(pbam[3])<int(bps[1])-flank_length+1:
					align_info=cigar2alignstart(pbam[5],int(pbam[3]),bps,flank_length)
					align_start=align_info[0]
					miss_bp=align_info[1]+1
					if not miss_bp>flank_length/2:
						align_pos=int(pbam[3])
						target_read=pbam[9][align_start:]
						if len(target_read)>flank_length+len_cff:
							out.append(target_read[:max([alA_len,alB_len,alRef_len])+2*flank_length])
							out2.append(miss_bp)
							out3.append(pbam[0])
	fbam.close()
	return [out,out2,out3]
def chop_pacbio_read_insert_short(bam_in,bps,flank_length,insert_seq):
	bam_in_new=bam_in_decide(bam_in,bps)
	if bam_in_new=='': return [[],[],[]]
	fbam=os.popen(r'''samtools view %s %s:%d-%d'''%(bam_in_new,bps[0],int(bps[1])-2*flank_length,int(bps[1])+flank_length))
	out=[]
	out2=[]
	out3=[]
	tandem_test=[]
	for line in fbam:
		pbam=line.strip().split()
		if not pbam in tandem_test:
			tandem_test.append(pbam)
			if not pbam[0]=='@': 
				if int(pbam[3])<int(bps[1])-flank_length+1 and len(pbam[9])>flank_length+len(insert_seq):
					align_info=cigar2alignstart_left(pbam[5],int(pbam[3]),bps,flank_length)
					align_start=align_info[0]
					miss_bp=align_info[1]+1
					#print [align_start,miss_bp]
					target_read=pbam[9][align_start:]
					if len(target_read)>2*flank_length and miss_bp<flank_length:
						out.append(target_read[:2*flank_length])
						out2.append(miss_bp)
						out3.append(pbam[0])
	fbam.close()
	return [out,out2,out3]
def chop_pacbio_read_insert_long(bam_in,bps,flank_length,insert_seq):
	bam_in_new=bam_in_decide(bam_in,bps)
	if bam_in_new=='': return [[],[],[]]
	fbam=os.popen(r'''samtools view %s %s:%d-%d'''%(bam_in_new,bps[0],int(bps[1])-2*flank_length,int(bps[1])+flank_length))
	out=[]
	out2=[]
	out3=[]
	tandem_test=[]
	for line in fbam:
		pbam=line.strip().split()
		if not pbam in tandem_test:
			tandem_test.append(pbam)
			if not pbam[0]=='@': 
				if int(pbam[3])<int(bps[1])-flank_length+1 and len(pbam[9])>flank_length:
					align_info=cigar2alignstart_left(pbam[5],int(pbam[3]),bps,flank_length)
					align_start=align_info[0]
					miss_bp=align_info[1]+1
					#print [align_start,miss_bp]
					target_read=pbam[9][align_start:]
					if len(target_read)>2*flank_length and miss_bp<flank_length:
						out.append(target_read[:2*flank_length])
						out2.append(miss_bp)
						out3.append(pbam[0])
	fbam.close()
	return [out,out2,out3]
def chop_pacbio_read_left(bam_in,bps,flank_length):
	#get reads align starts bps[1]-flank_length, and ends bps[1]+flank
	bam_in_new=bam_in_decide(bam_in,bps)
	if bam_in_new=='': return [[],[],[]]
	fbam=os.popen(r'''samtools view %s %s:%d-%d'''%(bam_in_new,bps[0],int(bps[1])-2*flank_length,int(bps[1])+flank_length))
	out=[]
	out2=[]
	out3=[]
	tandem_test=[]
	for line in fbam:
		pbam=line.strip().split()
		if not pbam in tandem_test:
			tandem_test.append(pbam)
			if not pbam[0]=='@': 
				if int(pbam[3])<int(bps[1])-flank_length+1:
					align_info=cigar2alignstart_left(pbam[5],int(pbam[3]),bps,flank_length)
					align_start=align_info[0]
					miss_bp=align_info[1]+1
					#print [align_start,miss_bp]
					target_read=pbam[9][align_start:]
					if len(target_read)>2*flank_length and miss_bp<flank_length:
						out.append(target_read[:2*flank_length])
						out2.append(miss_bp)
						out3.append(pbam[0])
	fbam.close()
	return [out,out2,out3]
def chop_pacbio_read_right(bam_in,bps,flank_length):
	bam_in_new=bam_in_decide(bam_in,bps)
	if bam_in_new=='': return [[],[],[]]
	fbam=os.popen(r'''samtools view %s %s:%d-%d'''%(bam_in_new,bps[0],int(bps[2])-flank_length,int(bps[2])+flank_length))
	out=[]
	out2=[]
	out3=[]
	tandem_test=[]
	for line in fbam:
		pbam=line.strip().split()
		if not pbam in tandem_test:
			tandem_test.append(pbam)
			if not pbam[0]=='@': 
				if int(pbam[3])+int(cigar2reaadlength(pbam[5]))>int(bps[2])+flank_length-1:
					align_info=cigar2alignstart_right(flank_length,pbam[5],int(pbam[3]),bps)
					align_end=align_info[0]
					miss_bp=align_info[1]+1
					target_read=pbam[9][:align_end]
					if len(target_read)>2*flank_length:
						out.append(target_read[::-1][:2*flank_length])
						out2.append(miss_bp)
						out3.append(pbam[0])
	fbam.close()
	return [out,out2,out3]
def chop_pacbio_read_left_vcf(bps,flank_length,bam_in):
	#chop reads going from bps[1]-flank_length 
	bps_new=[bps[0],bps[2],bps[2]+flank_length]
	bam_in_new=bam_in_decide(bam_in,bps)
	if bam_in_new=='': return [[],[],[]]
	fbam=os.popen(r'''samtools view %s %s:%d-%d'''%(bam_in_new,bps_new[0],int(bps_new[1])-flank_length,int(bps_new[1])+flank_length))
	out=[]
	out2=[]
	out3=[]
	for line in fbam:
		pbam=line.strip().split()
		if not pbam[0]=='@': 
			if int(pbam[3])<int(bps_new[1])-flank_length+1:
				align_info=cigar2alignstart_left(pbam[5],int(pbam[3]),bps_new,flank_length)
				align_start=align_info[0]
				miss_bp=align_info[1]+1
				if align_start<flank_length/2:
				#print [align_start,miss_bp]
					target_read=pbam[9][align_start:]
					if len(target_read)>2*flank_length:
						out.append(target_read[:2*flank_length])
						out2.append(miss_bp)
						out3.append(pbam[0])
	fbam.close()
	return [out,out2,out3]
def data_re_format(dotdata_ref):
	out=[[],[]]
	for x in dotdata_ref:
		out[0].append(x[0])
		out[1].append(x[1])
	return out
def decide_bp_temp(chrom,junction,bp_let_hash):
	if not '^' in junction[0] and not '^' in junction[1]:
		bp_temp_info=[chrom,bp_let_hash[junction[0]][1],bp_let_hash[junction[1]][0]]
	elif '^' in junction[0] and not '^' in junction[1]:
		bp_temp_info=[chrom,bp_let_hash[junction[0]][0],bp_let_hash[junction[1]][0]]
	elif not '^' in junction[0] and '^' in junction[1]:
		bp_temp_info=[chrom,bp_let_hash[junction[0]][1],bp_let_hash[junction[1]][1]]
	elif  '^' in junction[0] and'^' in junction[1]:
		bp_temp_info=[chrom,bp_let_hash[junction[0]][0],bp_let_hash[junction[1]][1]]
	return bp_temp_info
def decide_main_diagnal(dis_info):
	temp=[len(x[0]) for x in dis_info[0]]
	temp_index=temp.index(max(temp))
	temp_info=dis_info[0][temp_index]
	x_y_dis=[temp_info[1][x]-temp_info[0][x] for x in range(len(temp_info[0]))]
	return np.median(x_y_dis)
def dotdata(kmerlen,seq1, seq2):
	# parse command-line arguments
	if len(sys.argv) < 4:
		#print "you must call program as:  "
		#print "   python ps1-dotplot.py <KMER LEN> <FASTA 1> <FASTA 2> <PLOT FILE>"
		#print "   PLOT FILE may be *.ps, *.png, *.jpg"
		sys.exit(1)
	# match every nth base. Or set to 0 to allow third base mismatches
	nth_base = 1
	inversions = True
	hits = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
	return hits
def dotdata_write(plotfile,hits_list):
	fo=open(plotfile,'w')
	for x in hits_list:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
def dotplot_subfigure_simple_short(plt_figure_index,kmerlen,seq1,seq2,seq3,seq4,figurename):
	nth_base = 1
	inversions = True
	hits_ref_ref = kmerhits(seq2, seq2, kmerlen, nth_base, inversions)
	hits_ref = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
	hits_alt1 = kmerhits(seq1, seq3, kmerlen, nth_base, inversions)
	hits_alt2 = kmerhits(seq1, seq4, kmerlen, nth_base, inversions)
	if float(len(hits_ref))/float(len(hits_ref_ref))<0.1:
		kmerlen_new=int(0.8*kmerlen)
		hits_ref = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
		hits_alt1 = kmerhits(seq1, seq3, kmerlen, nth_base, inversions)
		hits_alt2 = kmerhits(seq1, seq4, kmerlen, nth_base, inversions)
	elif float(len(hits_ref))/float(len(hits_ref_ref))>10:
		kmerlen_new=int(1.2*kmerlen)
		hits_ref = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
		hits_alt1 = kmerhits(seq1, seq3, kmerlen, nth_base, inversions)
		hits_alt2 = kmerhits(seq1, seq4, kmerlen, nth_base, inversions)
	fig=plt.figure(plt_figure_index)
	makeDotplot_subfigure(hits_ref_ref,'ref vs. ref',221)
	makeDotplot_subfigure(hits_ref,'read vs. ref',222)
	makeDotplot_subfigure(hits_alt1,'read vs. allele1',223)
	makeDotplot_subfigure(hits_alt2,'read vs. allele2',224)
	plt.savefig(figurename)
	#plt.show()
	plt.close(fig)
def dotplot_subfigure_simple_long(plt_figure_index,kmerlen,seq1,seq2,seq3,seq4,figurename):
	nth_base = 1
	inversions = True
	hits_ref_ref = kmerhits(seq2, seq2, kmerlen, nth_base, inversions)
	hits_ref1 = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
	hits_ref2 = kmerhits(seq1, seq3, kmerlen, nth_base, inversions)
	hits_alt = kmerhits(seq1, seq4, kmerlen, nth_base, inversions)
	if float(len(hits_ref1))/float(len(hits_ref_ref))<0.1:
		kmerlen_new=int(0.8*kmerlen)
		hits_ref1 = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
		hits_ref2 = kmerhits(seq1, seq3, kmerlen, nth_base, inversions)
		hits_alt = kmerhits(seq1, seq4, kmerlen, nth_base, inversions)
	elif float(len(hits_ref1))/float(len(hits_ref_ref))>10:
		kmerlen_new=int(1.2*kmerlen)
		hits_ref1 = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
		hits_ref2 = kmerhits(seq1, seq3, kmerlen, nth_base, inversions)
		hits_alt = kmerhits(seq1, seq4, kmerlen, nth_base, inversions)
	fig=plt.figure(plt_figure_index)
	makeDotplot_subfigure(hits_ref_ref,'ref vs. ref',221)
	makeDotplot_subfigure(hits_alt,'read vs. alt_junction',222)
	makeDotplot_subfigure(hits_ref1,'read vs. ref_left',223)
	makeDotplot_subfigure(hits_ref2,'read vs. ref_right',224)
	plt.savefig(figurename)
	#plt.show()
	plt.close(fig)
def dotplot(kmerlen,seq1,seq2,plotfile):
	nth_base = 1
	inversions = True
	hits = kmerhits(seq1, seq2, kmerlen, nth_base, inversions)
	p = makeDotplot(plotfile, hits, len(seq1), len(seq2))
def dup_decide(structure):
	flag=0
	for x in structure:
		if not x=='^':
			if structure.count(x)>1:
				flag+=1
	return flag
def end_point_calculate(alt_sv,bl_len_hash):
	end_point=0
	for x in alt_sv.split('/')[0]:
		if not x=='^':
			end_point+=bl_len_hash[x]
	return end_point
def eu_dis_calcu_1(fo_ref,rsquare_ref,align_off,delta):
	#this function calculates total distance of dots to diagnal, with direction considered; smaller = better ;  especially designed for duplcations;
	temp_data1=[[],[]]
	for x in fo_ref:
		temp_data1[0].append(int(x[0])-align_off)
		temp_data1[1].append(int(x[1]))
	if not temp_data1[0]==[]:
		out=sum([temp_data1[1][x]-temp_data1[0][x] for x in range(len(temp_data1[0]))])
		rsquare_ref.append(abs(out))
	return rsquare_ref
def eu_dis_calcu_2(fo_ref,rsquare_ref,align_off,delta):
	#this function calculates total distance of dots to diagnal; smaller = better ; not suitable for duplications
	temp_data1=[[],[]]
	for x in fo_ref:
		temp_data1[0].append(int(x[0])-align_off)
		temp_data1[1].append(int(x[1]))
	if not temp_data1[0]==[]:
		out=sum([abs(temp_data1[1][x]-temp_data1[0][x]) for x in range(len(temp_data1[0]))])
		rsquare_ref.append(abs(out))
	return rsquare_ref
def eu_dis_calcu_3a(fo_ref,rsquare_ref,align_off,delta):
	#this function calculates total distance of dots to diagnal; smaller = better
	fo1=open(fo_ref+'.txt')
	temp_data1=[[],[]]
	for line in fo1:
		po1=line.strip().split()
		temp_data1[0].append(int(po1[0])-align_off)
		temp_data1[1].append(int(po1[1]))
	fo1.close()
	rec1=1
	for x in range(len(temp_data1[0])):
		if abs(temp_data1[1][x]-temp_data1[0][x])<float(temp_data1[0][x])/10.0:
			rec1+=1
	rsquare_ref.append(float(len(temp_data1[0]))/float(rec1))
	return rsquare_ref
def eu_dis_calcu_3(fo_ref,rsquare_ref,align_off,delta):
	#count total #dots/#dots locates close to diagnal; smaller = better
	#either diagnal or reverse diganal
	fo1=open(fo_ref+'.txt')
	temp_data1=[[],[]]
	for line in fo1:
		po1=line.strip().split()
		temp_data1[0].append(int(po1[0])-align_off)
		temp_data1[1].append(int(po1[1]))
	fo1.close()
	temp_data1.append(temp_data1[1][::-1])
	rec1=1
	for x in range(len(temp_data1[0])):
		if abs(temp_data1[1][x]-temp_data1[0][x])<float(temp_data1[0][x])/10.0:
			rec1+=1
	rec2=1
	for x in range(len(temp_data1[0])):
		if abs(temp_data1[2][x]-temp_data1[0][x])<float(temp_data1[0][x])/10.0:
			rec2+=1
	rsquare_ref.append(float(len(temp_data1[0]))/float(rec1))
	return rsquare_ref
def eu_dis_calcu_simple_long(fo_ref):
	#return number of dots falling within 10# dis to diagnal
	temp_data1=[[],[]]
	for x in fo_ref:
		temp_data1[0].append(int(x[0]))
		temp_data1[1].append(int(x[1]))
	temp_data2=[[],[]]
	for x in range(len(temp_data1[0])):
		if np.abs(temp_data1[0][x]-temp_data1[1][x])<float(temp_data1[0][x])/10.0:
			temp_data2[0].append(temp_data1[0][x])
			temp_data2[1].append(temp_data1[1][x])			
	return len(temp_data2[0])
def eu_dis_calcu_check_dup(fo_ref,fo1_alt,fo2_alt,rsquare_ref,rsquare_alt1,rsquare_alt2,y2,delta,info):
	#Calculate total distance of all dots to diagnal; smaller=better.
	structure1=info[0].split('/')[0]
	structure2=info[1].split('/')[0]
	structure3=info[1].split('/')[1]
	if sum([int(dup_decide(structure1)),int(dup_decide(structure2)),int(dup_decide(structure3))])>0:
			rsquare_ref=eu_dis_calcu_1(fo_ref,rsquare_ref,y2,delta)
			rsquare_alt1=eu_dis_calcu_1(fo1_alt,rsquare_alt1,y2,delta)
			rsquare_alt2=eu_dis_calcu_1(fo2_alt,rsquare_alt2,y2,delta)
	else:
			rsquare_ref=eu_dis_calcu_2(fo_ref,rsquare_ref,y2,delta)
			rsquare_alt1=eu_dis_calcu_2(fo1_alt,rsquare_alt1,y2,delta)
			rsquare_alt2=eu_dis_calcu_2(fo2_alt,rsquare_alt2,y2,delta)
	return [rsquare_ref,rsquare_alt1,rsquare_alt2]
def file_initiate(file):
	if not os.path.isfile(file):
		fo=open(file,'w')
		fo.close()
def flank_length_calculate(bps):
	if int(bps[-1])-int(bps[1])<100:
		flank_length=2*(int(bps[-1])-int(bps[1]))
	else:
		if int(bps[-1])-int(bps[1])<500:
			flank_length=int(bps[-1])-int(bps[1])
		else:
			flank_length=500
	return flank_length
def junc_check(junction,k1):
	test=['left']+[i for i in k1.split('/')[0]]+['right']
	test=[i+'^' for i in test[::-1]]+test
	dis=test.index(junction[1])-test.index(junction[0])
	return dis
def keep_diagnal_and_anti_diag_for_csv(dotdata_ref,clu_dis_cff,dots_num_cff):
	out=data_re_format(dotdata_ref)
	dis_info=cluster_dis_to_diagnal(out,clu_dis_cff,dots_num_cff)
	out=[]
	for x in dis_info:
		for y in x:
			for z in range(len(y[0])):
				out.append([y[0][z],y[1][z]])
	return out
def kmerhits(seq1, seq2, kmerlen, nth_base=1, inversions=False):
	# hash table for finding hits
	lookup = {}
	# store sequence hashes in hash table
	#print "hashing seq1..."
	seq1len = len(seq1)
	for i in xrange(seq1len - kmerlen + 1):
		key = seq1[i:i+kmerlen]
		for subkey in subkeys(key, nth_base, inversions):
			lookup.setdefault(subkey, []).append(i)
	# match every nth base by look up hashes in hash table
	#print "hashing seq2..."
	hits = []
	for i in xrange(len(seq2) - kmerlen + 1):
		key = seq2[i:i+kmerlen]
		# only need to specify inversions for one seq
		for subkey in subkeys(key, nth_base, False):
			subhits = []
			if kmerlen>30:
				for k1 in lookup.keys():
					if edit_dis_setup(k1,subkey)<int(kmerlen/10)+1:
						print subhits
						subhits+=lookup[k1]
			else:
				subhits=lookup.get(subkey,[])
			if subhits != []:
				# store hits to hits list
				for hit in subhits:
					hits.append((i, hit))
				# break out of loop to avoid doubly counting
				# exact matches
				break
	return hits
def edit_dis_setup(seq1,seq2):
	cost_matrix=np.full((len(seq1)+1,len(seq2)+1),np.inf)
	move_matrix=np.full((len(seq1)+1,len(seq2)+1),-1.0)
	opt_dist=editDistance(seq1, seq2, cost_matrix,move_matrix, len(seq1), len(seq2))
	return opt_dist
def editDistance(seq1,seq2,cost_matrix,move_matrix,r,c):
	[iCost, dCost , mCost]=[1,1,1]
	if cost_matrix[r][c]==float('inf'):
		if r==0 and c==0:
			cost_matrix[r][c]=0
		elif r==0:
			move_matrix[r][c]=0
			cost_matrix[r][c]=editDistance(seq1,seq2,cost_matrix,move_matrix,r,c-1)+iCost
		elif c==0:
			move_matrix[r][c]=1
			cost_matrix[r][c] = editDistance(seq1,seq2,cost_matrix,move_matrix,r-1,c)+dCost
		else:
			iDist=editDistance(seq1,seq2,cost_matrix,move_matrix,r,c-1) + iCost
			dDist=editDistance(seq1,seq2,cost_matrix,move_matrix,r-1,c) + dCost
			if seq1[r-1] == seq2[c-1]:
				mDist=editDistance(seq1,seq2,cost_matrix,move_matrix,r-1,c-1)
			else:
				mDist=editDistance(seq1,seq2,cost_matrix,move_matrix,r-1,c-1)+mCost
			if iDist<dDist:
				if iDist < mDist:  # insertion is optimal
					move_matrix[r][c] = 0
					cost_matrix[r][c] = iDist
				else:	#match is optimal
					move_matrix[r][c] = 2
					cost_matrix[r][c] = mDist
			else:
				if dDist < mDist:	#deletion is optimal
					move_matrix[r][c]=1
					cost_matrix[r][c]=dDist
				else:	#match is optimal
					move_matrix[r][c]=2
					cost_matrix[r][c]=mDist
	return cost_matrix[r][c]
def print_eidt(seq1,seq2,move_matrix):
	r=len(seq1)
	c=len(seq2)
	[o1,o2,m]=['','','']
	while r>-1 and c>-1 and move_matrix[r][c]>0:
		if (move_matrix[r][c]==0):	#insertion
			o1="-"+o1
			o2=seq2[c-1]+o2
			m="I"+m
			c-=1
		elif move_matrix[r][c]==1:	#deletion
			o1=seq1[r-1]+o1
			o2="-"+o2
			m="D"+m
			r-=1
		elif move_matrix[r][c]==2:	#match / mismatch
			o1 = seq1[r-1] + o1; 
			o2 = seq2[c-1] + o2;
			if seq1[r-1] == seq2[c-1]:
				m='-'+m
			else:
				m='*'+m
			r-=1
			c-=1
	print m
	print o1
	print o2
def k_means_cluster(data_list):
	#print data_list
	array_diagnal=np.array([[data_list[0][x],data_list[1][x]] for x in range(len(data_list[0]))])
	ks = range(1,min([5,len(data_list[0])+1]))
	KMeans = [cluster.KMeans(n_clusters = i, init="k-means++").fit(array_diagnal) for i in ks]
	BIC = [compute_bic(kmeansi,array_diagnal) for kmeansi in KMeans]
	ks_picked=ks[BIC.index(max(BIC))]
	if ks_picked==1:
		return [data_list]
	else:
		out=[]
		std_rec=[scipy.std(data_list[0]),scipy.std(data_list[1])]
		whitened = whiten(array_diagnal)
		centroids, distortion=kmeans(whitened,ks_picked)
		idx,_= vq(whitened,centroids)
		for x in range(ks_picked):
			group1=[[int(i) for i in array_diagnal[idx==x,0]],[int(i) for i in array_diagnal[idx==x,1]]]
			out.append(group1)
		return out
def k_means_cluster(data_list):
	if max(data_list[0])-min(data_list[0])>10 and max(data_list[1])-min(data_list[1])>10:
		array_diagnal=np.array([[data_list[0][x],data_list[1][x]] for x in range(len(data_list[0]))])
		ks = range(1,min([5,len(data_list[0])+1]))
		KMeans = [cluster.KMeans(n_clusters = i, init="k-means++").fit(array_diagnal) for i in ks]
		KMeans_predict=[cluster.KMeans(n_clusters = i, init="k-means++").fit_predict(array_diagnal) for i in ks]
		BIC=[]
		BIC_rec=[]
		for x in ks:
			if KMeans_predict[x-1].max()<x-1: continue
			else:
				BIC_i=compute_bic(KMeans[x-1],array_diagnal)
				if abs(BIC_i)<10**8:
					BIC.append(BIC_i)
					BIC_rec.append(x)
		#BIC = [compute_bic(kmeansi,array_diagnal) for kmeansi in KMeans]
		#ks_picked=ks[BIC.index(max(BIC))]
		ks_picked=BIC_rec[BIC.index(max(BIC))]
		if ks_picked==1:
			return [data_list]
		else:
			out=[]
			std_rec=[scipy.std(data_list[0]),scipy.std(data_list[1])]
			whitened = whiten(array_diagnal)
			centroids, distortion=kmeans(whitened,ks_picked)
			idx,_= vq(whitened,centroids)
			for x in range(ks_picked):
				group1=[[int(i) for i in array_diagnal[idx==x,0]],[int(i) for i in array_diagnal[idx==x,1]]]
				out.append(group1)
			return out
	else:
		return [data_list]
def k_means_cluster_Predict(data_list,info):
	array_diagnal=np.array([[data_list[0][x],data_list[1][x]] for x in range(len(data_list[0]))])
	ks = range(1,len(info))
	KMeans = [cluster.KMeans(n_clusters = i, init="k-means++").fit(array_diagnal) for i in ks]
	BIC = [compute_bic(kmeansi,array_diagnal) for kmeansi in KMeans]
	ks_picked=ks[BIC.index(max(BIC))]
	if ks_picked==1:
		return [data_list]
	else:
		out=[]
		std_rec=[scipy.std(data_list[0]),scipy.std(data_list[1])]
		whitened = whiten(array_diagnal)
		centroids, distortion=kmeans(whitened,ks_picked)
		idx,_= vq(whitened,centroids)
		for x in range(ks_picked):
			group1=[[int(i) for i in array_diagnal[idx==x,0]],[int(i) for i in array_diagnal[idx==x,1]]]
			out.append(group1)
		return out
def let_to_letters(k2):
	letters=[[]]
	for x in k2:
		if not x in ['^','/']:
			letters[-1].append([x])
		elif x=='/':
			letters.append([])
		elif x=='^':
			letters[-1][-1][-1]+=x
	letters[0]=[['left']]+letters[0]+[['right']]
	letters[1]=[['left']]+letters[1]+[['right']]
	return letters
def list_to_hash(out):
	out_hash={}
	for x in range(len(out[0])):
		if not out[0][x] in out_hash.keys():
			out_hash[out[0][x]]=[]
		out_hash[out[0][x]].append(out[1][x])
	return out_hash
def list_unique(list):
	out=[]
	for x in list:
		if not x in out:
			out.append(x)
	return out
def makeDotplot(filename, hits, lenSeq1, lenSeq2):
	#"""generate a dotplot from a list of hits filename may end in the following file extensions: *.ps, *.png, *.jpg"""
	if len(hits)==0: 
		#print hits
		return ' '
	x, y = zip(* hits)
	slope1 = 1.0e6 / (825000 - 48000)
	slope2 = 1.0e6 / (914000 - 141000)
	offset1 = 0 - slope1*48000
	offset2 = 0 - slope2*141000
	hits2 = quality(hits)
	#print "%.5f%% hits on diagonal" % (100 * len(hits2) / float(len(hits)))
	# create plot
	p = plotting.Gnuplot()
	p.enableOutput(False)
	p.plot(x, y, xlab="sequence 2", ylab="sequence 1")
	p.plotfunc(lambda x: slope1 * x + offset1, 0, 1e6, 1e5)
	p.plotfunc(lambda x: slope2 * x + offset2, 0, 1e6, 1e5)
	# set plot labels
	p.set(xmin=0, xmax=lenSeq2, ymin=0, ymax=lenSeq1)
	p.set(main="dotplot (%d hits, %.5f%% hits on diagonal)" %
		  (len(hits), 100 * len(hits2) / float(len(hits))))
	p.enableOutput(True)
	# output plot
	p.save(filename)
	return p
def makeDotplot_subfigure(hits, title,figure_pos):
	#"""generate a dotplot from a list of hits filename may end in the following file extensions: *.ps, *.png, *.jpg"""
	if len(hits)==0: 
		#print hits
		return ' '
	x, y = zip(* hits)
	slope1 = 1.0e6 / (825000 - 48000)
	slope2 = 1.0e6 / (914000 - 141000)
	offset1 = 0 - slope1*48000
	offset2 = 0 - slope2*141000
	hits2 = quality(hits)
	xlib_range=int(float(max(x))/float(10**(len(str(max(x)))-1)))+1
	if xlib_range<3:
		xlib=[(i+1)*10**(len(str(max(x)))-1) for i in range(xlib_range)]
		xlib_new=[xlib[0]/2]
		for xi in range(len(xlib)-1):
			xlib_new.append(xlib_new[0]*(2*(xi+1)+1))
		xlib+=xlib_new
		xlib.sort()
	elif xlib_range<5:
		xlib=[(i+1)*10**(len(str(max(x)))-1) for i in range(xlib_range)]
	else:
		xlib=[(i+1)*2*10**(len(str(max(x)))-1) for i in range(xlib_range/2+1)]
	plt.subplot(figure_pos)
	plt.plot(x, y,'+',color='r')
	plt.xticks(xlib, [str(i) for i in xlib])
	plt.title(title)
	plt.grid(False)
	#print "%.5f%% hits on diagonal" % (100 * len(hits2) / float(len(hits)))
	# create plot
def name_hash_modify(name_hash):
	out=[]
	for x in name_hash:
		if '/' in x:
			y=x.replace('/','-')
		else:
			y=x
		out.append(y)
	return out
def path_mkdir(path):
		if not os.path.isdir(path):
				os.system(r'''mkdir %s'''%(path))
def path_modify(path):
	if not path[-1]=='/':
		path+='/'
	return path
def Pacbio_prodce_ref_alt_short(ref,flank_length,info):
	#fin=open(txt_file)
	#pin=fin.readline().strip().split()
	#fin.close()
	pin=info
	ref_sv=pin[0]
	ref_sv='/'.join(['1'+ref_sv.split('/')[0]+'2','1'+ref_sv.split('/')[0]+'2'])
	alt_sv=pin[1]
	alt_sv='/'.join(['1'+alt_sv.split('/')[0]+'2','1'+alt_sv.split('/')[1]+'2'])
	chrom=pin[2]
	bps=pin[2:]
	bps=[bps[0]]+[str(int(bps[1])-flank_length)]+bps[1:]+[str(int(bps[-1])+flank_length)]
	ref_hash={}
	rec=0
	for x in ref_sv.split('/')[0]:
		rec+=1
		fref=os.popen(r'''samtools faidx %s %s:%d-%d'''%(ref,chrom,int(bps[rec]), int(bps[rec+1])))
		fref.readline().strip().split()
		seq=''
		while True:
				pref=fref.readline().strip().split()
				if not pref: break
				seq+=pref[0]
		fref.close()
		ref_hash[x]=seq
	ref_hash=ref_hash_modi(ref_hash)
	alt_sv_list=alt_sv_to_list(alt_sv)
	ref_seq=''.join([ref_hash[x] for x in ref_sv.split('/')[0]])
	alt_1_seq=''.join([ref_hash[x] for x in alt_sv_list[0]])
	alt_2_seq=''.join([ref_hash[x] for x in alt_sv_list[1]])
	return [upper_string(ref_seq),upper_string(alt_1_seq),upper_string(alt_2_seq)]
def Pacbio_prodce_ref_alt_ins_short(ref,flank_length,info,insert_seq):
	ref_sv='12/12'
	alt_sv='1'+info[1].split('/')[0]+'2/1'+info[1].split('/')[1]+'2'
	chrom=info[2]
	bps=info[2:]
	bps=[bps[0],str(int(bps[1])-flank_length),bps[1],str(int(bps[1])+flank_length)]
	ref_hash={}
	rec=0
	for x in ref_sv.split('/')[0]:
		rec+=1
		fref=os.popen(r'''samtools faidx %s %s:%d-%d'''%(ref,chrom,int(bps[rec]), int(bps[rec+1])))
		fref.readline().strip().split()
		seq=''
		while True:
				pref=fref.readline().strip().split()
				if not pref: break
				seq+=pref[0]
		fref.close()
		ref_hash[x]=seq
	ref_hash['a']=insert_seq
	ref_hash=ref_hash_modi(ref_hash)
	alt_sv_list=alt_sv_to_list(alt_sv)
	ref_seq=''.join([ref_hash[x] for x in ref_sv.split('/')[0]])
	alt_1_seq=''.join([ref_hash[x] for x in alt_sv_list[0]])
	alt_2_seq=''.join([ref_hash[x] for x in alt_sv_list[1]])
	return [upper_string(ref_seq),upper_string(alt_1_seq),upper_string(alt_2_seq)]
def Pacbio_prodce_ref_alt_junc(ref,flank_length,info,junction,bp_let_hash):
	chrom=info[2]
	ref_hash={}
	if not '^' in junction[0] and not '^' in junction[1]:
		#['a','c']
		bps=[chrom,bp_let_hash[junction[0]][1]-flank_length,bp_let_hash[junction[0]][1],bp_let_hash[junction[1]][0],bp_let_hash[junction[1]][0]+flank_length]
		bps_left=[chrom,bp_let_hash[junction[0]][1]]
		bps_right=[chrom,bp_let_hash[junction[1]][0]]
		ref_hash[junction[0]+'_ri']=ref_seq_readin(ref,chrom,int(bps[1]),int(bps[2]),'FALSE')
		ref_hash[junction[1]+'_le']=ref_seq_readin(ref,chrom,int(bps[3]),int(bps[4]),'FALSE')
	elif '^' in junction[0] and not '^' in junction[1]:
		#['a^','c']
		bps=[chrom,bp_let_hash[junction[0]][0],bp_let_hash[junction[0]][0]+flank_length,bp_let_hash[junction[1]][0],bp_let_hash[junction[1]][0]+flank_length]
		bps_left=[chrom,bp_let_hash[junction[0]][0]]
		bps_right=[chrom,bp_let_hash[junction[1]][0]]
		ref_hash[junction[0]+'_ri']=ref_seq_readin(ref,chrom,int(bps[1]),int(bps[2]),'TRUE')
		ref_hash[junction[1]+'_le']=ref_seq_readin(ref,chrom,int(bps[3]),int(bps[4]),'FALSE')
	elif not '^' in junction[0] and '^' in junction[1]:
		#['a','c^']
		bps=[chrom,bp_let_hash[junction[0]][1]-flank_length,bp_let_hash[junction[0]][1],bp_let_hash[junction[1]][1]-flank_length,bp_let_hash[junction[1]][1]]
		bps_left=[chrom,bp_let_hash[junction[0]][1]]
		bps_right=[chrom,bp_let_hash[junction[1]][1]]
		ref_hash[junction[0]+'_ri']=ref_seq_readin(ref,chrom,int(bps[1]),int(bps[2]),'FALSE')
		ref_hash[junction[1]+'_le']=ref_seq_readin(ref,chrom,int(bps[3]),int(bps[4]),'TRUE')
	elif '^' in junction[0] and '^' in junction[1]:
		#['a^','c^']
		bps=[chrom,bp_let_hash[junction[0]][0],bp_let_hash[junction[0]][0]+flank_length,bp_let_hash[junction[1]][1]-flank_length,bp_let_hash[junction[1]][1]]			
		bps_left=[chrom,bp_let_hash[junction[0]][0]]
		bps_right=[chrom,bp_let_hash[junction[1]][1]]
		ref_hash[junction[0]+'_ri']=ref_seq_readin(ref,chrom,int(bps[1]),int(bps[2]),'TRUE')
		ref_hash[junction[1]+'_le']=ref_seq_readin(ref,chrom,int(bps[3]),int(bps[4]),'TRUE')
	ref_hash['ref_le']=ref_seq_readin(ref,chrom,bps_left[1]-flank_length,bps_left[1]+flank_length,'FALSE')
	ref_hash['ref_ri']=ref_seq_readin(ref,chrom,bps_right[1]-flank_length,bps_right[1]+flank_length,'FALSE')
	return [upper_string(ref_hash['ref_le']),upper_string(ref_hash['ref_ri']),upper_string(ref_hash[junction[0]+'_ri']+ref_hash[junction[1]+'_le'])]
	#return [ref1,ref2,alt]
def Pacbio_prodce_ref_alt_multi_chrom(out_path,ref,flank_length,k1):
	#eg of k1:['22', '50934615', 'chr22', 50567289, 50567789, '', '22', 50934615, 50935115, '.', '.']
	chrom=k1[0]
	ref_hash={}
	alt_a=k1[2:5]
	alt_b=k1[6:9]
	reverse_flag=[]
	for i in k1[9:]:
		if i=='.':
			reverse_flag.append('FALSE')
		elif i=='^':
			reverse_flag.append('TRUE')
		else:
			print 'Error: wrong k1 info, reverse not properly stated.'
	if reverse_flag==['FALSE','FALSE']: 
		ref_seq_a=ref_seq_readin(ref,chrom,int(alt_a[2])-flank_length,int(alt_a[2])+flank_length,'FALSE')
		ref_seq_b=ref_seq_readin(ref,chrom,int(alt_b[1])-flank_length,int(alt_b[1])+flank_length,'FALSE')
		ref_seq_a2=ref_seq_readin(ref,chrom,int(alt_a[2])-flank_length,int(alt_a[2]),'FALSE')
		ref_seq_b2=ref_seq_readin(ref,chrom,int(alt_b[1]),int(alt_b[1])+flank_length,'FALSE')
	elif reverse_flag==['FALSE','TRUE']:
		ref_seq_a=ref_seq_readin(ref,chrom,int(alt_a[2])-flank_length,int(alt_a[2])+flank_length,'FALSE')
		ref_seq_b=ref_seq_readin(ref,chrom,int(alt_b[2])-flank_length,int(alt_b[2])+flank_length,'FALSE')
		ref_seq_a2=ref_seq_readin(ref,chrom,int(alt_a[2])-flank_length,int(alt_a[2]),'FALSE')
		ref_seq_b2=ref_seq_readin(ref,chrom,int(alt_b[2])-flank_length,int(alt_b[2]),'FALSE')
	elif reverse_flag==['TRUE','FALSE']:
		ref_seq_a=ref_seq_readin(ref,chrom,int(alt_a[1])-flank_length,int(alt_a[1])+flank_length,'FALSE')
		ref_seq_b=ref_seq_readin(ref,chrom,int(alt_b[1])-flank_length,int(alt_b[1])+flank_length,'FALSE')
		ref_seq_a2=ref_seq_readin(ref,chrom,int(alt_a[1]),int(alt_a[1])+flank_length,'FALSE')
		ref_seq_b2=ref_seq_readin(ref,chrom,int(alt_b[1]),int(alt_b[1])+flank_length,'FALSE')
	alt_seq=ref_seq_readin(ref,chrom,int(alt_a[1]),int(alt_a[2]),reverse_flag[0])+ref_seq_readin(ref,chrom,int(alt_b[1]),int(alt_b[2]),reverse_flag[1])
	return [ref_seq_a,ref_seq_b,alt_seq,ref_seq_a2,ref_seq_b2]
def qc_ref_file_initiate(qc_file_name):
	if not os.path.isfile(qc_file_name):
		fo=open(qc_file_name,'w')
		print >>fo, ' '.join(['sample_name','chromosome','bp1','bp2','diagnal_per','rep_per'])
		fo.close()
def qc_ref_file_write(qc_file_name,sample_name,bps,region_QC,affix,seq2):
	if affix=='':
		fo=open(qc_file_name,'a')
		print >>fo, ' '.join([str(i) for i in [sample_name]+bps+[region_QC[0],max(region_QC[1])/float(len(seq2))]])
		fo.close()
	else:
		fo=open(qc_file_name,'a')
		print >>fo, ' '.join([str(i) for i in [sample_name]+bps+[region_QC[0],max(region_QC[1])/float(len(seq2))]+[affix]])
		fo.close()
def qc_ref_region_check(qc_file_name,window_size,ref,out_path,sample_name,info):
	k1=info[0]
	k2=info[1]
	k3=info[2:]
	case_name='_'.join([str(i) for i in k3+[k1.replace('/','-'),k2.replace('/','-')]])
	txt_file=out_path+case_name+'.txt'
	#fo=open(txt_file,'w')
	#print >>fo, ' '.join([str(i) for i in [k1,k2]+k3])
	#fo.close()
	ref_sv=info[0]
	alt_sv=info[1]
	chrom=info[2]
	bps=info[2:]
	#delta=delta_calculate(bps)
	if bps[2]-bps[1]<5000:
		flank_length=flank_length_calculate(bps)
		seqs=Pacbio_prodce_ref_alt_short(ref,flank_length,info)
		seq2=seqs[0]
		dotdata_qual_check=dotdata(window_size,seq2[flank_length:-flank_length],seq2[flank_length:-flank_length])
		region_QC=qual_check_repetitive_region(dotdata_qual_check)
		QC_plot_name=out_path+sample_name+'.'+'.'.join([str(i) for i in bps])+'.png'
		p = makeDotplot(QC_plot_name, dotdata_qual_check, len(seq2), len(seq2))
		qc_ref_file_write(qc_file_name,sample_name,bps,region_QC,'ab',seq2)		
	else:
		flank_length=500
		info_a=info[:3]+[info[3]-500,info[3]+500]
		info_b=info[:3]+[info[4]-500,info[4]+500]
		#left bp flank
		seqs=Pacbio_prodce_ref_alt_short(ref,flank_length,info_a)
		seq2=seqs[0]
		dotdata_qual_check=dotdata(window_size,seq2,seq2)
		region_QC=qual_check_repetitive_region(dotdata_qual_check)
		QC_plot_name=out_path+sample_name+'.'+'.'.join([str(i) for i in bps])+'.a.png'
		p = makeDotplot(QC_plot_name, dotdata_qual_check, len(seq2), len(seq2))
		qc_ref_file_write(qc_file_name,sample_name,bps,region_QC,'a',seq2)		
		#right bp flank
		seqs=Pacbio_prodce_ref_alt_short(ref,flank_length,info_b)
		seq2=seqs[0]
		dotdata_qual_check=dotdata(window_size,seq2,seq2)
		region_QC=qual_check_repetitive_region(dotdata_qual_check)
		QC_plot_name=out_path+sample_name+'.'+'.'.join([str(i) for i in bps])+'.b.png'
		p = makeDotplot(QC_plot_name, dotdata_qual_check, len(seq2), len(seq2))
		qc_ref_file_write(qc_file_name,sample_name,bps,region_QC,'b',seq2)		
def quality(hits):
	"""determines the quality of a list of hits"""
	slope1 = 1.0e6 / (825000 - 48000)
	slope2 = 1.0e6 / (914000 - 141000)
	offset1 = 0 - slope1*48000
	offset2 = 0 - slope2*141000
	goodhits = []
	for hit in hits:
		upper = slope1 * hit[0] + offset1
		lower = slope2 * hit[0] + offset2
		if lower < hit[1] < upper:
			goodhits.append(hit)
	return goodhits
def qual_check_R(dotdata_qual_check):
	out1=[]
	out2=[]
	for x in dotdata_qual_check:
		out1.append(x[0])
		out2.append(x[1])
	print out1
	print out2
def qual_check_R_2(dotdata_qual_check,txt_file):
	fo=open(txt_file+'.QC','w')
	for x in dotdata_qual_check:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
def qual_check_R_3(dotdata_qual_check):
	fo=open('/home/xuefzhao/temp.txt','w')
	for x in range(len(dotdata_qual_check[0])):
		print >>fo, ' '.join([str(i) for i in [dotdata_qual_check[0][x],dotdata_qual_check[1][x]]])
	fo.close()
def qual_check_repetitive_region(dotdata_qual_check):
	#qual_check_R_2(dotdata_qual_check,txt_file)  #not necessary for validator
	diagnal=0
	other=[[],[]]
	for x in dotdata_qual_check:
		if x[0]==x[1]:
			diagnal+=1 
		else:
			if x[0]>x[1]:
				other[0].append(x[0])
				other[1].append(x[1])
	if len(dotdata_qual_check)>0 and float(len(other[0]))/float(len(dotdata_qual_check))>0.1 and float(len(other[0]))/float(len(dotdata_qual_check))<0.5:
		other_cluster=X_means_cluster_reformat(other)
		range_cluster=cluster_range_decide(other_cluster)
		size_cluster=cluster_size_decide(range_cluster)
	else:
		size_cluster=[0]
	return [float(diagnal)/float(len(dotdata_qual_check)),size_cluster]
def qual_predict_repetitive_region(dotdata_qual_check,simple_dis_cff,clu_dis_cff,dots_num_cff):
	#search for all potential blocks (in diagnal / anti-diagnal direction)
	diagnal=0
	other=[[],[]]
	for x in dotdata_qual_check:
		if x[0]==x[1]:
			diagnal+=1 
		else:
			if x[0]>x[1]:
				other[0].append(x[0])
				other[1].append(x[1])
	out2=cluster_dis_to_diagnal(other,clu_dis_cff,dots_num_cff)
	out3=[]
	for x in out2:
		out3.append([])
		for y in x:
			temp=[i for i in cluster_simple_dis(y,simple_dis_cff) if len(i[0])>dots_num_cff]
			out3[-1]+=temp
	out4=[cluster_range_decide(out3[0]),cluster_range_decide(out3[1])]
	out5=[cluster_size_decide(out4[0]),cluster_size_decide(out4[1])]
	out4b=[[out4[0][i] for i in range(len(out5[0])) if out5[0][i]>100],[out4[1][i] for i in range(len(out5[1])) if out5[1][i]>100]]
	return out4b				
def ref_seq_readin(ref,chrom,start,end,reverse_flag):
	#reverse=='TRUE': return rev-comp-seq
	#else: return original seq
	fref=os.popen(r'''samtools faidx %s %s:%d-%d'''%(ref,chrom,int(start),int(end)))
	fref.readline().strip().split()
	seq=''
	while True:
			pref=fref.readline().strip().split()
			if not pref: break
			seq+=pref[0]
	fref.close()
	if not reverse_flag=='TRUE':
		return seq
	else:
		return reverse(complementary(seq))
def read_hash_unify(all_reads):
	out=[[],[],[]]
	for x in range(len(all_reads[0])):
		if not all_reads[0][x] in out[0]:
			out[0].append(all_reads[0][x])
			out[1].append(all_reads[1][x])
			out[2].append(all_reads[2][x])
	return out
def read_hash_minimize(all_reads):
	all_reads_unique=read_hash_unify(all_reads)
	read_hash=all_reads_unique[0]
	miss_hash=all_reads_unique[1]
	name_hash=name_hash_modify(all_reads_unique[2])							
	if len(read_hash)>30:
		new_read_hash=random.sample(range(len(read_hash)),30)
		read_hash2=[read_hash[i] for i in new_read_hash]
		miss_hash2=[miss_hash[i] for i in new_read_hash]
		name_hash2=[name_hash[i] for i in new_read_hash]
		read_hash=read_hash2
		miss_hash=miss_hash2
		name_hash=name_hash2
	return [read_hash,miss_hash,name_hash]
def ref_hash_modi(ref_hash):
	out={}
	for x in ref_hash.keys():
			out[x]=ref_hash[x]
			out[x+'^']=reverse(complementary(ref_hash[x]))
	return out
def remove_files_short(txt_file):
	for x in os.listdir('/'.join(txt_file.split('/')[:-1])):
		if txt_file.split('/')[-1].replace('.txt','') in x:
			if not x.split('.')[-1]=='png':
				if not x.split('.')[-1]=='rsquare':
					if not x==txt_file.split('/')[-1]:
						if not x.split('.')[-2]=='start':
							os.system(r'''rm %s'''%('/'.join(txt_file.split('/')[:-1])+'/'+x))
def reverse(seq):
	return seq[::-1]
def key_modify(key):
	if 'R' in key:
			key=key.replace('R','N')
	if 'r' in key:
			key=key.replace('r','n')
	if 'Y' in key:
			key=key.replace('Y','N')
	if 'y' in key:
			key=key.replace('y','n')
	if 'S' in key:
			key=key.replace('S','N')
	if 's' in key:
			key=key.replace('s','n')
	if 'W' in key:
			key=key.replace('W','N')
	if 'w' in key:
			key=key.replace('w','n')
	if 'K' in key:
			key=key.replace('K','N')
	if 'k' in key:
			key=key.replace('k','n')
	if 'M' in key:
			key=key.replace('M','N')
	if 'm' in key:
			key=key.replace('m','n')
	if 'B' in key:
			key=key.replace('B','N')
	if 'b' in key:
			key=key.replace('b','n')
	if 'D' in key:
			key=key.replace('D','N')
	if 'd' in key:
			key=key.replace('d','n')
	if 'H' in key:
			key=key.replace('H','N')
	if 'h' in key:
			key=key.replace('h','n')
	if 'V' in key:
			key=key.replace('V','N')
	if 'v' in key:
			key=key.replace('v','n')
	return key
def subkeys(key, nth_base, inversions):
	subkeys_info = []
	key=key_modify(key)
	keylen = len(key)
	# speed tip from:
	# http://wiki.python.org/moin/PythonSpeed/PerformanceTips#String_Concatenation
	if nth_base == 1:
		subkeys_info = [key]
	elif nth_base != 0:
		for k in range(nth_base):
			substr_list = [key[j] for j in range(keylen) if (j % nth_base == k)]
			subkeys_info.append("".join(substr_list))
	else:
		# nth_base = 0 is a special case for third base mismatches
		# for every codon, only include the first 2 bases in the hash
		subkeys_info = ["".join([key[i] for i in range(len(key)) if i % 3 != 2])]
	if inversions:
		for i in range(len(subkeys_info)):
			subkeys_info.append("".join([invert_base[c] for c in reversed(subkeys_info[i])]))
	return subkeys_info
def shift_diagnal_for_csv(dotdata_ref,clu_dis_cff,dots_num_cff):
	out=data_re_format(dotdata_ref)
	dis_info=cluster_dis_to_diagnal(out,clu_dis_cff,dots_num_cff)
	dis_off=decide_main_diagnal(dis_info)
	return dis_off
def tranform_diagnal_to_horizonal(out):
	#transformation: x2=x+y, y2=x-y
	#out=read_in_dotplot_files(filein)
	out2=[[],[]]
	for x in range(len(out[0])):
		out2[0].append(out[0][x]+out[1][x])
		out2[1].append(out[0][x]-out[1][x])
	return out2
def tranform_diagnal_to_distance(out):
	out2=[[],[]]
	for x in range(len(out[0])):
		out2[0].append(abs(out[0][x]-out[1][x]))
		out2[1].append(x)
	return out2
def tranform_anti_diagnal_to_distance(out):
	out2=[[],[]]
	for x in range(len(out[0])):
		out2[0].append(out[0][x]+out[1][x])
		out2[1].append(x)
	return out2
def tranform_horizonal_to_diagnal(out):
	out2=[[],[]]
	for x in range(len(out[0])):
		out2[0].append(int(float(out[0][x]+out[1][x])/2.0))
		out2[1].append(int(float(out[0][x]-out[1][x])/2.0))
	return out2
def upper_string(string):
	return ''.join([i.upper() for i in string])
def write_dotfile(dotdata_for_record,rec_name,txt_file,rec_start):
	fout='.'.join(txt_file.split('.')[:-1])+'.ref.'+rec_name+'.start.'+str(rec_start)
	fo=open(fout,'w')
	for x in dotdata_for_record[0]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
	fout='.'.join(txt_file.split('.')[:-1])+'.alt1.'+rec_name+'.start.'+str(rec_start)
	fo=open(fout,'w')
	for x in dotdata_for_record[1]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
	fout='.'.join(txt_file.split('.')[:-1])+'.alt2.'+rec_name+'.start.'+str(rec_start)
	fo=open(fout,'w')
	for x in dotdata_for_record[2]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
def write_dotfile_left(dotdata_for_record,rec_name,txt_file):
	fout='.'.join(txt_file.split('.')[:-1])+'.ref.left.'+rec_name+'.start.'+str(0)
	fo=open(fout,'w')
	for x in dotdata_for_record[0]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
	fout='.'.join(txt_file.split('.')[:-1])+'.alt1.left.'+rec_name+'.start.'+str(0)
	fo=open(fout,'w')
	for x in dotdata_for_record[1]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
	fout='.'.join(txt_file.split('.')[:-1])+'.alt2.left.'+rec_name+'.start.'+str(0)
	fo=open(fout,'w')
	for x in dotdata_for_record[2]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
def write_dotfile_right(dotdata_for_record,rec_name,txt_file):
	fout='.'.join(txt_file.split('.')[:-1])+'.ref.right.'+rec_name+'.start.'+str(0)
	fo=open(fout,'w')
	for x in dotdata_for_record[0]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
	fout='.'.join(txt_file.split('.')[:-1])+'.alt1.right.'+rec_name+'.start.'+str(0)
	fo=open(fout,'w')
	for x in dotdata_for_record[1]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
	fout='.'.join(txt_file.split('.')[:-1])+'.alt2.right.'+rec_name+'.start.'+str(0)
	fo=open(fout,'w')
	for x in dotdata_for_record[2]:
		print >>fo, ' '.join([str(i) for i in x])
	fo.close()
def write_null_individual_stat(txt_file):
	fout='.'.join(txt_file.split('.')[:-1])+'.pacval'
	fo=open(fout,'w')
	print >>fo, ' '.join(['alt','ref'])
	fo.close()
def X_means_cluster(data_list):
	temp_result=[i for i in k_means_cluster(data_list) if not i==[[],[]]]
	if temp_result==[data_list]:
		return temp_result[0]
	else:
		out=[]
		for i in temp_result:
			out+=X_means_cluster(i)
		return out
def X_means_cluster_reformat(data_list):
	out=X_means_cluster(data_list)
	out2=[]
	for y in range(len(out)/2):
		out2.append([out[2*y],out[2*y+1]])
	return out2
#Large_Functions
def calcu_eu_dis_simple_long(global_list,svelter_list,plt_figure_index,PacVal_score_hash,info,SV_index):
	#info=[k1,k2]+k3
	[lenght_cff,dots_num_cff,clu_dis_cff, point_dis_cff, simple_dis_cff, invert_base, dict_opts, out_path, out_file_Cannot_Validate, sample_name, start, delta, bam_in, ref, chromosomes, region_QC_Cff, min_length, min_read_compare, case_number, qc_file_name]=global_list
	[PacVal_file_in,PacVal_file_out]=svelter_list
	window_size=10
	[k1,k2,k3,chrom]=[info[0],info[1],info[2:],info[2]]
	case_name='_'.join([str(i) for i in k3])
	txt_file=out_path+case_name+'.txt'
	flank_length=500
	bp_let_hash=bp_let_to_hash(info,flank_length)
	letters=let_to_letters(k2)
	for x_let in letters:
		for y in range(len(x_let)-1):
			junction=x_let[y]+x_let[y+1]
			if not junc_check(junction,k1)==1: #Normal junctions
				bps_temp=decide_bp_temp(chrom,junction,bp_let_hash)
				all_reads_left=chop_pacbio_read_left(bam_in,bps_temp,flank_length)
				all_reads_right=[[],[],[]]#for now, need a better idea how to deal with this
				read_hash_left=all_reads_left[0]
				miss_hash_left=all_reads_left[1]
				name_hash_left=name_hash_modify(all_reads_left[2])
				read_hash_right=all_reads_right[0]
				miss_hash_right=all_reads_right[1]
				name_hash_right=name_hash_modify(all_reads_right[2])
				seqs=Pacbio_prodce_ref_alt_junc(ref,flank_length,info,junction,bp_let_hash)
				seq2=seqs[0]
				dotdata_qual_check=dotdata(window_size,seq2,seq2)
				region_QC_a=qual_check_repetitive_region(dotdata_qual_check)
				seq3=seqs[1]
				dotdata_qual_check=dotdata(window_size,seq3,seq3)
				region_QC_b=qual_check_repetitive_region(dotdata_qual_check)
				if region_QC_a[0]>region_QC_Cff or sum(region_QC_a[1])/float(len(seq2))<0.3:
					if region_QC_b[0]>region_QC_Cff or sum(region_QC_b[1])/float(len(seq3))<0.3:
						seq4=seqs[2]
						rsquare_ref1=[]
						rsquare_ref2=[]
						rsquare_alt=[]
						seq1=''
						seq_length_limit=min([len(seq2),len(seq3),len(seq4)])
						if not read_hash_left==[]:
							miss_rec=-1
							rec_len=0
							rec_len_rev=1
							new_all_reads_left=read_hash_minimize(all_reads_left)
							read_hash_left=new_all_reads_left[0]
							miss_hash_left=new_all_reads_left[1]
							name_hash_left=name_hash_modify(new_all_reads_left[2])
							for x in read_hash_left:
								miss_rec+=1
								y=x
								y2=miss_hash_left[miss_rec]
								y3=name_hash_left[miss_rec]
								dotdata_ref1=dotdata(window_size,y,seq2[y2:])
								dotdata_ref2=dotdata(window_size,y,seq3[y2:])
								dotdata_alt=dotdata(window_size,y,seq4[y2:])							
								temp_rsquare=eu_dis_calcu_simple_long(dotdata_ref1)
								#if not temp_rsquare==0:
								rsquare_ref1.append(temp_rsquare)
								temp_rsquare=eu_dis_calcu_simple_long(dotdata_ref2)
								#if not temp_rsquare==0:
								rsquare_ref2.append(temp_rsquare)
								temp_rsquare=eu_dis_calcu_simple_long(dotdata_alt)
								#if not temp_rsquare==0:
								rsquare_alt.append(temp_rsquare)
								if not rsquare_ref2==[]:
									if float(max([rsquare_ref1[-1],rsquare_ref2[-1]]))==0:
										rsquare_alt[-1]+=1
										rsquare_ref1[-1]+=1
										rsquare_ref2[-1]+=1
									if float(rsquare_alt[-1]-max([rsquare_ref1[-1],rsquare_ref2[-1]]))/float(max([rsquare_ref1[-1],rsquare_ref2[-1]]))>rec_len:
										if miss_hash_left[miss_rec]<seq_length_limit:
											rec_len=float(rsquare_alt[-1]-max([rsquare_ref1[-1],rsquare_ref2[-1]]))/float(max([rsquare_ref1[-1],rsquare_ref2[-1]]))
											rec_name=name_hash_left[miss_rec]
											rec_start=miss_hash_left[miss_rec]
											seq1=y
											dotdata_for_record=[dotdata_ref1,dotdata_ref2,dotdata_alt]
									if float(min([rsquare_ref1[-1],rsquare_ref2[-1]]))==0:
										rsquare_alt[-1]+=1
										rsquare_ref1[-1]+=1
										rsquare_ref2[-1]+=1
									if float(rsquare_alt[-1]-min([rsquare_ref1[-1],rsquare_ref2[-1]]))/float(min([rsquare_ref1[-1],rsquare_ref2[-1]]))<rec_len_rev:
										if miss_hash_left[miss_rec]<seq_length_limit:
											rec_len_rev=float(rsquare_alt[-1]-min([rsquare_ref1[-1],rsquare_ref2[-1]]))/float(min([rsquare_ref1[-1],rsquare_ref2[-1]]))
											rec_name_rev=name_hash_left[miss_rec]
											rec_start_rev=miss_hash_left[miss_rec]
											seq1_rev=y
											dotdata_for_record_rev=[dotdata_ref1,dotdata_ref2,dotdata_alt]
							if rec_len>0:	
								if len(dotdata_for_record[0])>0:
									dotplot_subfigure_simple_long(plt_figure_index,window_size,seq1,seq2[rec_start:],seq3[rec_start:],seq4[rec_start:],out_path+sample_name+'.'+case_name+'.alt.'+rec_name+'.png')
							if rec_len_rev<1:
								if len(dotdata_for_record_rev[0])>0:
									dotplot_subfigure_simple_long(plt_figure_index,window_size,seq1_rev,seq2[rec_start_rev:],seq3[rec_start_rev:],seq4[rec_start_rev:],out_path+sample_name+'.'+case_name+'.ref.'+rec_name_rev+'.png')
						if not read_hash_right==[]:
							miss_rec=-1
							rec_len=0
							new_all_reads_right=read_hash_minimize(all_reads_right)
							read_hash_right=new_all_reads_right[0]
							miss_hash_right=new_all_reads_right[1]
							name_hash_right=name_hash_modify(new_all_reads_right[2])
							for x in read_hash_right:
								miss_rec+=1
								y=x
								y2=miss_hash_right[miss_rec]
								y3=name_hash_right[miss_rec]
								dotdata_ref1=dotdata(window_size,y,seq2[::-1])
								dotdata_ref2=dotdata(window_size,y,seq3[::-1])
								dotdata_alt=dotdata(window_size,y,seq4[::-1])							
								temp_rsquare=eu_dis_calcu_simple_long(dotdata_ref1)
								if not temp_rsquare==0:
									rsquare_ref1.append(temp_rsquare)
								temp_rsquare=eu_dis_calcu_simple_long(dotdata_ref2)
								if not temp_rsquare==0:
									rsquare_ref2.append(temp_rsquare)
								temp_rsquare=eu_dis_calcu_simple_long(dotdata_alt)
								if not temp_rsquare==0:
									rsquare_alt.append(temp_rsquare)
								if not len(rsquare_ref1)==len(rsquare_ref2)==len(rsquare_alt):
									min_len=min([len(rsquare_ref1),len(rsquare_ref2),len(rsquare_alt)])
									rsquare_ref1=rsquare_ref1[:min_len]
									rsquare_ref2=rsquare_ref2[:min_len]
									rsquare_alt=rsquare_alt[:min_len]
								if not rsquare_ref2==[]:
									if max([rsquare_ref2[-1],rsquare_alt[-1]])-rsquare_ref1[-1]>rec_len:
										rec_len=max([rsquare_ref2[-1],rsquare_alt[-1]])-rsquare_ref1[-1]
										rec_name=name_hash_right[miss_rec]
										rec_start=miss_hash_right[miss_rec]
										dotdata_for_record=[dotdata_ref1,dotdata_ref2,dotdata_alt]
							if rec_len>0:
								if len(dotdata_for_record[0])>0:
									dotplot_subfigure_simple_long(plt_figure_index,window_size,seq1,seq2[rec_start:],seq3[rec_start:],seq4[rec_start:],out_path+sample_name+'.'+case_name+rec_name+'.png')
						PacVal_score_hash=write_pacval_individual_stat_simple_long(PacVal_score_hash,txt_file,rsquare_ref1,rsquare_ref2,rsquare_alt,SV_index)
						remove_files_short(txt_file)
				else:
					fo=open(out_file_Cannot_Validate,'a')
					print >>fo, ' '.join([str(i) for i in info+junction])
					fo.close()
	return PacVal_score_hash
def calcu_eu_dis_complex_short(global_list,svelter_list,plt_figure_index,PacVal_score_hash,info,SV_index):
	#info=[k1,k2]+k3
	[lenght_cff,dots_num_cff,clu_dis_cff, point_dis_cff, simple_dis_cff, invert_base, dict_opts, out_path, out_file_Cannot_Validate, sample_name, start, delta, bam_in, ref, chromosomes, region_QC_Cff, min_length, min_read_compare, case_number, qc_file_name]=global_list
	[PacVal_file_in,PacVal_file_out]=svelter_list
	window_size=10
	[k1,k2,k3]=[info[0],info[1],info[2:]]
	case_name='_'.join([str(i) for i in k3])
	txt_file=out_path+case_name+'.txt'
	[ref_sv,alt_sv,chrom,bps]=[info[0],info[1],info[2],info[2:]]
	flank_length=flank_length_calculate(bps)
	if bps_check(bps,chromosomes)==0:
		bl_len_hash=bl_len_hash_calculate(bps,ref_sv)
		end_point=end_point_calculate(alt_sv,bl_len_hash)
		all_reads=chop_pacbio_read_simple_short(bam_in,info,flank_length)
		if not all_reads[0]==[]:
			all_reads_new=read_hash_minimize(all_reads)
			[read_hash,miss_hash,name_hash]=[all_reads_new[0],all_reads_new[1],name_hash_modify(all_reads_new[2])]
			[rsquare_ref,rsquare_alt1,rsquare_alt2,rec_len,rec_start,rec_name]=[[],[],[],0,0,'0']
			if not read_hash==[]:
				seqs=Pacbio_prodce_ref_alt_short(ref,flank_length,info)
				seq2=seqs[0]
				[window_size,region_QC]=window_size_refine(region_QC_Cff,window_size,seq2,flank_length)
				if region_QC[0]>region_QC_Cff or sum(region_QC[1])/float(len(seq2))<0.3:
					seq3=seqs[1]
					seq4=seqs[2]
					miss_rec=-1
					dotdata_for_record=[[],[],[]]
					seq1=''
					for y in read_hash:
						miss_rec+=1
						y2=miss_hash[miss_rec]
						y3=name_hash[miss_rec]
						dotdata_ref=dotdata(window_size,y,seq2)
						dotdata_alt1=dotdata(window_size,y,seq3)
						dotdata_alt2=dotdata(window_size,y,seq4)
						dotdata_ref_2=keep_diagnal_and_anti_diag_for_csv(dotdata_ref,clu_dis_cff,dots_num_cff)
						dotdata_alt1_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt1,clu_dis_cff,dots_num_cff)
						dotdata_alt2_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt2,clu_dis_cff,dots_num_cff)
						[rsquare_ref,rsquare_alt1,rsquare_alt2]=eu_dis_calcu_check_dup(dotdata_ref_2,dotdata_alt1_2,dotdata_alt2_2,rsquare_ref,rsquare_alt1,rsquare_alt2,y2,delta,info)
						if not len(rsquare_ref)==len(rsquare_alt1)==len(rsquare_alt2):
							min_len=min([len(rsquare_ref),len(rsquare_alt1),len(rsquare_alt2)])
							rsquare_ref=rsquare_ref[:min_len]
							rsquare_alt1=rsquare_alt1[:min_len]
							rsquare_alt2=rsquare_alt2[:min_len]
						if not rsquare_alt1==[]:
							if min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]<rec_len:
								rec_len=min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]
								rec_start=y2
								rec_name=y3
								seq1=y
								dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
						else:
							seq1=y
					if rec_len==0:
						dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
						rec_name=y3
						rec_start=y2
						seq1=y
					if len(dotdata_for_record[0])>0:
						dotplot_subfigure_simple_short(plt_figure_index,window_size,seq1,seq2[rec_start:],seq3[rec_start:],seq4[rec_start:],out_path+sample_name+'.'+case_name+rec_name+'.png')
						PacVal_score_hash=write_pacval_individual_stat_simple_short(PacVal_score_hash,txt_file,rsquare_ref,rsquare_alt1,rsquare_alt2,SV_index)
				else:
					fo=open(out_file_Cannot_Validate,'a')
					print >>fo, ' '.join([str(i) for i in info])
					fo.close()
		else:
			write_null_individual_stat(txt_file)
			remove_files_short(txt_file)
	return PacVal_score_hash
def calcu_eu_dis_ins_short(global_list,svelter_list,plt_figure_index,PacVal_score_hash,info,SV_index,insert_seq):
	#info=[k1,k2]+k3
	[lenght_cff,dots_num_cff,clu_dis_cff, point_dis_cff, simple_dis_cff, invert_base, dict_opts, out_path, out_file_Cannot_Validate, sample_name, start, delta, bam_in, ref, chromosomes, region_QC_Cff, min_length, min_read_compare, case_number, qc_file_name]=global_list
	[PacVal_file_in,PacVal_file_out]=svelter_list
	window_size=10
	[k1,k2,k3]=[info[0],info[1],info[2:]]
	case_name='_'.join([str(i) for i in k3])
	txt_file=out_path+case_name+'.txt'
	[ref_sv,alt_sv,chrom,bps]=[info[0],info[1],info[2],info[2:]]
	flank_length=flank_length_calculate(bps)
	if insert_seq in ['homo','het','']:
		insert_seq=''.join(['n' for i in range(info[4]-info[3])])
	if bps_check(bps,chromosomes)==0:
		bl_len_hash=bl_len_hash_calculate(bps,ref_sv)
		all_reads=chop_pacbio_read_insert_short(bam_in,bps,flank_length,insert_seq)
		if not all_reads[0]==[]:
			all_reads_new=read_hash_minimize(all_reads)
			[read_hash,miss_hash,name_hash]=[all_reads_new[0],all_reads_new[1],name_hash_modify(all_reads_new[2])]
			[rsquare_ref,rsquare_alt1,rsquare_alt2,rec_len,rec_start,rec_name]=[[],[],[],0,0,'0']
			if not read_hash==[]:
				seqs=Pacbio_prodce_ref_alt_ins_short(ref,flank_length,info,insert_seq)
				seq2=seqs[0]
				[window_size,region_QC]=window_size_refine(region_QC_Cff,window_size,seq2,1)
				if region_QC[0]>region_QC_Cff or sum(region_QC[1])/float(len(seq2))<0.3:
					seq3=seqs[1]
					seq4=seqs[2]
					miss_rec=-1
					dotdata_for_record=[[],[],[]]
					seq1=''
					for y in read_hash:
						miss_rec+=1
						y2=miss_hash[miss_rec]
						y3=name_hash[miss_rec]
						dotdata_ref=dotdata(window_size,y,seq2)
						dotdata_alt1=dotdata(window_size,y,seq3)
						dotdata_alt2=dotdata(window_size,y,seq4)
						dotdata_ref_2=keep_diagnal_and_anti_diag_for_csv(dotdata_ref,clu_dis_cff,dots_num_cff)
						dotdata_alt1_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt1,clu_dis_cff,dots_num_cff)
						dotdata_alt2_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt2,clu_dis_cff,dots_num_cff)
						[rsquare_ref,rsquare_alt1,rsquare_alt2]=eu_dis_calcu_check_dup(dotdata_ref_2,dotdata_alt1_2,dotdata_alt2_2,rsquare_ref,rsquare_alt1,rsquare_alt2,y2,delta,info)
						if not len(rsquare_ref)==len(rsquare_alt1)==len(rsquare_alt2):
							min_len=min([len(rsquare_ref),len(rsquare_alt1),len(rsquare_alt2)])
							rsquare_ref=rsquare_ref[:min_len]
							rsquare_alt1=rsquare_alt1[:min_len]
							rsquare_alt2=rsquare_alt2[:min_len]
						if not rsquare_alt1==[]:
							if min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]<rec_len:
								rec_len=min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]
								rec_start=y2
								rec_name=y3
								seq1=y
								dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
						else:
							seq1=y
					if rec_len==0:
						dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
						rec_name=y3
						rec_start=y2
						seq1=y
					if len(dotdata_for_record[0])>0:
						dotplot_subfigure_simple_short(plt_figure_index,window_size,seq1,seq2[rec_start:],seq3[rec_start:],seq4[rec_start:],out_path+sample_name+'.'+case_name+rec_name+'.png')
						PacVal_score_hash=write_pacval_individual_stat_simple_short(PacVal_score_hash,txt_file,rsquare_ref,rsquare_alt1,rsquare_alt2,SV_index)
				else:
					fo=open(out_file_Cannot_Validate,'a')
					print >>fo, ' '.join([str(i) for i in info])
					fo.close()
		else:
			write_null_individual_stat(txt_file)
			remove_files_short(txt_file)
	return PacVal_score_hash
def calcu_eu_dis_ins_long(global_list,svelter_list,plt_figure_index,PacVal_score_hash,info,SV_index,insert_seq):
	#info=[k1,k2]+k3
	[lenght_cff,dots_num_cff,clu_dis_cff, point_dis_cff, simple_dis_cff, invert_base, dict_opts, out_path, out_file_Cannot_Validate, sample_name, start, delta, bam_in, ref, chromosomes, region_QC_Cff, min_length, min_read_compare, case_number, qc_file_name]=global_list
	[PacVal_file_in,PacVal_file_out]=svelter_list
	window_size=10
	[k1,k2,k3]=[info[0],info[1],info[2:]]
	case_name='_'.join([str(i) for i in k3])
	txt_file=out_path+case_name+'.txt'
	[ref_sv,alt_sv,chrom,bps]=[info[0],info[1],info[2],info[2:]]
	flank_length=flank_length_calculate(bps)
	if insert_seq in ['homo','het','']:
		insert_seq=''.join(['n' for i in range(info[4]-info[3])])
	if bps_check(bps,chromosomes)==0:
		bl_len_hash=bl_len_hash_calculate(bps,ref_sv)
		all_reads=chop_pacbio_read_insert_long(bam_in,bps,flank_length,insert_seq)
		if not all_reads[0]==[]:
			all_reads_new=read_hash_minimize(all_reads)
			[read_hash,miss_hash,name_hash]=[all_reads_new[0],all_reads_new[1],name_hash_modify(all_reads_new[2])]
			[rsquare_ref,rsquare_alt1,rsquare_alt2,rec_len,rec_start,rec_name]=[[],[],[],0,0,'0']
			if not read_hash==[]:
				seqs=Pacbio_prodce_ref_alt_ins_short(ref,flank_length,info,insert_seq)
				seq2=seqs[0]
				[window_size,region_QC]=window_size_refine(region_QC_Cff,window_size,seq2,1)
				if region_QC[0]>region_QC_Cff or sum(region_QC[1])/float(len(seq2))<0.3:
					seq3=seqs[1]
					seq4=seqs[2]
					miss_rec=-1
					dotdata_for_record=[[],[],[]]
					seq1=''
					for y in read_hash:
						miss_rec+=1
						y2=miss_hash[miss_rec]
						y3=name_hash[miss_rec]
						dotdata_ref=dotdata(window_size,y,seq2)
						dotdata_alt1=dotdata(window_size,y,seq3)
						dotdata_alt2=dotdata(window_size,y,seq4)
						dotdata_ref_2=keep_diagnal_and_anti_diag_for_csv(dotdata_ref,clu_dis_cff,dots_num_cff)
						dotdata_alt1_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt1,clu_dis_cff,dots_num_cff)
						dotdata_alt2_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt2,clu_dis_cff,dots_num_cff)
						[rsquare_ref,rsquare_alt1,rsquare_alt2]=eu_dis_calcu_check_dup(dotdata_ref_2,dotdata_alt1_2,dotdata_alt2_2,rsquare_ref,rsquare_alt1,rsquare_alt2,y2,delta,info)
						if not len(rsquare_ref)==len(rsquare_alt1)==len(rsquare_alt2):
							min_len=min([len(rsquare_ref),len(rsquare_alt1),len(rsquare_alt2)])
							rsquare_ref=rsquare_ref[:min_len]
							rsquare_alt1=rsquare_alt1[:min_len]
							rsquare_alt2=rsquare_alt2[:min_len]
						if not rsquare_alt1==[]:
							if min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]<rec_len:
								rec_len=min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]
								rec_start=y2
								rec_name=y3
								seq1=y
								dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
						else:
							seq1=y
					if rec_len==0:
						dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
						rec_name=y3
						rec_start=y2
						seq1=y
					if len(dotdata_for_record[0])>0:
						dotplot_subfigure_simple_short(plt_figure_index,window_size,seq1,seq2[rec_start:],seq3[rec_start:],seq4[rec_start:],out_path+sample_name+'.'+case_name+rec_name+'.png')
						PacVal_score_hash=write_pacval_individual_stat_simple_short(PacVal_score_hash,txt_file,rsquare_ref,rsquare_alt1,rsquare_alt2,SV_index)
				else:
					fo=open(out_file_Cannot_Validate,'a')
					print >>fo, ' '.join([str(i) for i in info])
					fo.close()
		else:
			write_null_individual_stat(txt_file)
			remove_files_short(txt_file)
	return PacVal_score_hash
def calcu_eu_dis_csv_long_vcf(global_list,svelter_list,plt_figure_index,PacVal_score_hash,info,SV_index):
	#eg of info:['22', '50934615', '22', 50567289, 50567789, '', '22', 50934615, 50935115, '.', '.']
	[lenght_cff,dots_num_cff,clu_dis_cff, point_dis_cff, simple_dis_cff, invert_base, dict_opts, out_path, out_file_Cannot_Validate, sample_name, start, delta, bam_in, ref, chromosomes, region_QC_Cff, min_length, min_read_compare, case_number, qc_file_name]=global_list
	[PacVal_file_in,PacVal_file_out]=svelter_list
	flank_length=500
	window_size=10
	case_name=str(SV_index)
	txt_file=out_path+case_name+'.txt'
	all_reads_left=chop_pacbio_read_left_vcf(info[2:5],flank_length,bam_in)
	read_hash_left=all_reads_left[0]
	miss_hash_left=all_reads_left[1]
	name_hash_left=name_hash_modify(all_reads_left[2])
	read_hash_right=[]
	seqs=Pacbio_prodce_ref_alt_multi_chrom(out_path,ref,flank_length,info)
	seq2=seqs[0]
	seq2_QC=seqs[3]
	[window_size_a,region_QC_a]=window_size_refine(region_QC_Cff,window_size,seq2,flank_length)
	#dotdata_qual_check=dotdata(window_size,seq2_QC,seq2_QC)
	#region_QC_a=qual_check_repetitive_region(dotdata_qual_check)
	seq3=seqs[1]
	seq3_QC=seqs[4]
	[window_size_b,region_QC_b]=window_size_refine(region_QC_Cff,window_size,seq2,flank_length)
	#dotdata_qual_check=dotdata(window_size,seq3_QC,seq3_QC)
	#region_QC_b=qual_check_repetitive_region(dotdata_qual_check)
	window_size=max([window_size_a,window_size_b])
	if region_QC_a[0]>region_QC_Cff or sum(region_QC_a[1])/float(len(seq2))<0.3 or region_QC_b[0]>region_QC_Cff or sum(region_QC_b[1])/float(len(seq3))<0.3:
			seq4=seqs[2]
			rsquare_ref1=[]
			rsquare_ref2=[]
			rsquare_alt=[]
			if not read_hash_left==[]:
				new_read_hash_left=read_hash_minimize(all_reads_left)
				read_hash_left=new_read_hash_left[0]
				miss_hash_left=new_read_hash_left[1]
				name_hash_left=new_read_hash_left[2]
				miss_rec=-1
				rec_len=0
				for x in read_hash_left:
					miss_rec+=1
					y=x
					y2=miss_hash_left[miss_rec]
					y3=name_hash_left[miss_rec]
					dotdata_ref1=dotdata(window_size,y,seq2[y2:])
					dotdata_ref2=dotdata(window_size,y,seq3[y2:])
					dotdata_alt=dotdata(window_size,y,seq4[y2:])							
					rsquare_ref1.append(eu_dis_calcu_simple_long(dotdata_ref1))
					rsquare_ref2.append(eu_dis_calcu_simple_long(dotdata_ref2))
					rsquare_alt.append(eu_dis_calcu_simple_long(dotdata_alt))
					if not rsquare_alt==[]:
						if rsquare_alt[-1]-max([rsquare_ref1[-1],rsquare_ref2[-1]])>rec_len:
							rec_len=rsquare_alt[-1]-max([rsquare_ref1[-1],rsquare_ref2[-1]])
							rec_name=name_hash_left[miss_rec]
							rec_start=miss_hash_left[miss_rec]
							dotdata_for_record=[dotdata_ref1,dotdata_ref2,dotdata_alt]
							seq1=y
				if rec_len>0:
					if len(dotdata_for_record[0])>0:
						dotplot_subfigure_simple_long(plt_figure_index,window_size,seq1,seq2[rec_start:],seq3[rec_start:],seq4[rec_start:],out_path+sample_name+'.'+case_name+rec_name+'.png')
			write_pacval_individual_stat_simple_long(txt_file,rsquare_ref1,rsquare_ref2,rsquare_alt,SV_index)
			remove_files_short(txt_file)
	else:
		fo=open(out_file_Cannot_Validate,'a')
		print info
		print >>fo, ' '.join([str(i) for i in info])
		fo.close()
def calcu_fuzzy_dis_complex_short(global_list,svelter_list,plt_figure_index,PacVal_score_hash,info,SV_index):
	[lenght_cff,dots_num_cff,clu_dis_cff, point_dis_cff, simple_dis_cff, invert_base, dict_opts, out_path, out_file_Cannot_Validate, sample_name, start, delta, bam_in, ref, chromosomes, region_QC_Cff, min_length, min_read_compare, case_number, qc_file_name]=global_list
	[PacVal_file_in,PacVal_file_out]=svelter_list
	window_size=10
	[k1,k2,k3]=[info[0],info[1],info[2:]]
	case_name='_'.join([str(i) for i in k3])
	txt_file=out_path+case_name+'.txt'
	[ref_sv,alt_sv,chrom,bps]=[info[0],info[1],info[2],info[2:]]
	flank_length=flank_length_calculate(bps)
	if bps_check(bps,chromosomes)==0:
		bl_len_hash=bl_len_hash_calculate(bps,ref_sv)
		end_point=end_point_calculate(alt_sv,bl_len_hash)
		all_reads=chop_pacbio_read_simple_short(bam_in,info,flank_length)
		if not all_reads[0]==[]:
			all_reads_new=read_hash_minimize(all_reads)
			[read_hash,miss_hash,name_hash]=[all_reads_new[0],all_reads_new[1],name_hash_modify(all_reads_new[2])]
			[rsquare_ref,rsquare_alt1,rsquare_alt2,rec_len,rec_start,rec_name]=[[],[],[],0,0,'0']
			if not read_hash==[]:
				seqs=Pacbio_prodce_ref_alt_short(ref,flank_length,info)
				seq2=seqs[0]
				[window_size,region_QC]=window_size_refine(region_QC_Cff,window_size,seq2,flank_length)
				if region_QC[0]>region_QC_Cff or sum(region_QC[1])/float(len(seq2))<0.3:
					[seq1,seq3,seq4,miss_rec,dotdata_for_record]=['',seqs[1],seqs[2],-1,[[],[],[]]]
					for x in read_hash:
						miss_rec+=1
						y=x
						y2=miss_hash[miss_rec]
						y3=name_hash[miss_rec]
						dotdata_ref=dotdata(window_size,y,seq2)
						dotdata_alt1=dotdata(window_size,y,seq3)
						dotdata_alt2=dotdata(window_size,y,seq4)							
						dotdata_ref_2=keep_diagnal_and_anti_diag_for_csv(dotdata_ref,clu_dis_cff,dots_num_cff)
						dotdata_alt1_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt1,clu_dis_cff,dots_num_cff)
						dotdata_alt2_2=keep_diagnal_and_anti_diag_for_csv(dotdata_alt2,clu_dis_cff,dots_num_cff)
						eu_dis_calcu_check_dup(dotdata_ref_2,dotdata_alt1_2,dotdata_alt2_2,rsquare_ref,rsquare_alt1,rsquare_alt2,y2,delta,info)
						if not len(rsquare_ref)==len(rsquare_alt1)==len(rsquare_alt2):
							min_len=min([len(rsquare_ref),len(rsquare_alt1),len(rsquare_alt2)])
							rsquare_ref=rsquare_ref[:min_len]
							rsquare_alt1=rsquare_alt1[:min_len]
							rsquare_alt2=rsquare_alt2[:min_len]
						if not rsquare_alt1==[]:
							if min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]<rec_len:
								rec_len=min([rsquare_alt1[-1],rsquare_alt2[-1]])-rsquare_ref[-1]
								rec_start=y2
								rec_name=y3
								seq1=y
								dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
							else:
								seq1=y
					if rec_len==0:
						dotdata_for_record=[dotdata_ref,dotdata_alt1,dotdata_alt2]
						rec_name=y3
						rec_start=y2
						seq1=y
					if len(dotdata_for_record[0])>0:
						dotplot_subfigure_simple_short(plt_figure_index,window_size,seq1,seq2[rec_start:],seq3[rec_start:],seq4[rec_start:],out_path+sample_name+'.'+case_name+rec_name+'.png')
						PacVal_score_hash=write_pacval_individual_stat_simple_short(PacVal_score_hash,txt_file,rsquare_ref,rsquare_alt1,rsquare_alt2,SV_index)
				else:
					fo=open(out_file_Cannot_Validate,'a')
					print >>fo, ' '.join([str(i) for i in info])
					fo.close()
		else:
			write_null_individual_stat(txt_file)
			remove_files_short(txt_file)
	return PacVal_score_hash
def heatmap_data_produce_vertical(matrix_size,dotdata_ref_2,summit,dup_module):
	matrix_dots=[[i[0] for i in dotdata_ref_2],[i[1] for i in dotdata_ref_2]]
	diagnal_max=min([max(matrix_size[0]),max(matrix_size[1])])
	diagnal_dots=range(diagnal_max)
	diagnal_dots_info=[[i,i] for i in diagnal_dots]
	matrix_dots_hash=heatmap_matrix_produce_vertical(dotdata_ref_2,summit)
	diagnal_dots_hash=heatmap_matrix_produce_vertical(diagnal_dots_info,summit)
	matrix_sym_dots_hash=symmetric_by_diagnal_dots_produce(matrix_dots_hash)
def heatmap_matrix_produce_vertical(dotdata_ref_2,summit):
	out={}
	for k1 in dotdata_ref_2:
		if not k1[0] in out.keys():
			out[k1[0]]={}
		for k2 in range(-summit,summit):
			if not k1[1]-k2 in out[k1[0]].keys():
				out[k1[0]][k1[1]-k2]=abs(k2)
			else:
				out[k1[0]][k1[1]-k2]+=abs(k2)
	return out
def heatmap_data_produce_round(dotdata_ref_2,summit):
	matrix_dots=[[i[0] for i in dotdata_ref_2],[i[1] for i in dotdata_ref_2]]
	matrix={}
	for x in dotdata_ref_2:
		if not x[0] in matrix.keys():
			matrix[x[0]]={}
		if not x[1] in matrix[x[0]].keys():
			matrix[x[0]][x[1]]=0
		matrix[x[0]][x[1]]+=summit
		matrix_add_list=[]
		for z in range(1,summit+1):
			for y in range(z+1):
				matrix_add_list.append([z,x[0]+y,x[1]+(z-y)])
				matrix_add_list.append([z,x[0]-y,x[1]+(z-y)])
				matrix_add_list.append([z,x[0]+y,x[1]-(z-y)])
				matrix_add_list.append([z,x[0]-y,x[1]-(z-y)])
		matrix_add_unique_list=unify_list(matrix_add_list)
		for y in matrix_add_unique_list:
			if not y[1] in matrix.keys():
				matrix[y[1]]={}
			if not y[2] in matrix[y[1]].keys():
				matrix[y[1]][y[2]]=0
			matrix[y[1]][y[2]]+=summit-y[0]
	matrix_size=[range(min(matrix_dots[0])-summit,max(matrix_dots[0])+summit),range(min(matrix_dots[1])-summit,max(matrix_dots[1])+summit)]
	diagnal_max=min([max(matrix_size[0]),max(matrix_size[1])])
	diagnal_dots=range(diagnal_max)
	diagnal_matrix={}
	for y in diagnal_dots:
		x=[y,y]
		if not x[0] in matrix.keys():
			matrix[x[0]]={}
		if not x[1] in matrix[x[0]].keys():
			matrix[x[0]][x[1]]=0
		matrix[x[0]][x[1]]+=summit
		matrix_add_list=[]
		for z in range(1,summit+1):
			for y in range(z+1):
				matrix_add_list.append([z,x[0]+y,x[1]+(z-y)])
				matrix_add_list.append([z,x[0]-y,x[1]+(z-y)])
				matrix_add_list.append([z,x[0]+y,x[1]-(z-y)])
				matrix_add_list.append([z,x[0]-y,x[1]-(z-y)])
		matrix_add_unique_list=unify_list(matrix_add_list)
		for y in matrix_add_unique_list:
			if not y[1] in matrix.keys():
				matrix[y[1]]={}
			if not y[2] in matrix[y[1]].keys():
				matrix[y[1]][y[2]]=0
			matrix[y[1]][y[2]]+=summit-y[0]
	for x in diagnal_dots:
		if not x in matrix.keys():
			matrix[x]={}
		if not x in matrix[x].keys():
			matrix[x][x]=0
		matrix[x][x]-=summit
def merge_matrx(matrix_list):
	out={}
	for matrix_1 in matrix_list:
		for k1 in matrix_1.keys():
			for k2 in matrix_1[k1].keys():
				print (k1,k2)
				if not (k1,k2) in out.keys():
					out[(k1,k2)]=matrix_1[k1][k2]
				else:
					out[(k1,k2)]+=matrix_1[k1][k2]
	return out
def print_dot_hash(matrix_dots_hash):
	for k1 in matrix_dots_hash.keys():
		for k2 in matrix_dots_hash[k1].keys():
			print ' '.join([str(i) for i in [k1,k2,matrix_dots_hash[k1][k2]]])
summit=20
def symmetric_by_diagnal_dots_produce(dot_matrix):
	out={}
	for k1 in dot_matrix.keys():
		for k2 in dot_matrix[k1].keys():
			if not k2 in out.keys():
				out[k2]={}
			if not k1 in out[k2].keys():
				out[k2][k1]=-dot_matrix[k1][k2]
	return out
def qual_check_repetitive_region(dotdata_qual_check):
	#qual_check_R_2(dotdata_qual_check,txt_file)  #not necessary for validator
	diagnal=0
	other=[[],[]]
	for x in dotdata_qual_check:
		if x[0]==x[1]:
			diagnal+=1 
		else:
			if x[0]>x[1]:
				other[0].append(x[0])
				other[1].append(x[1])
	if len(dotdata_qual_check)>0 and float(len(other[0]))/float(len(dotdata_qual_check))>0.1 and float(len(other[0]))/float(len(dotdata_qual_check))<0.5:
		other_cluster=X_means_cluster_reformat(other)
		range_cluster=cluster_range_decide(other_cluster)
		size_cluster=cluster_size_decide(range_cluster)
	else:
		size_cluster=[0]
	return [float(diagnal)/float(len(dotdata_qual_check)),size_cluster]
def unify_list(list):
	out=[]
	for x in list:
		if not x in out:
			out.append(x)
	return out
def window_size_refine(region_QC_Cff,window_size,seq2,flank_length):
	dotdata_qual_check=dotdata(window_size,seq2[flank_length:-flank_length],seq2[flank_length:-flank_length])
	region_QC=qual_check_repetitive_region(dotdata_qual_check)
	while True:
		if window_size>100: break
		if region_QC[0]>region_QC_Cff or sum(region_QC[1])/float(len(seq2))<0.3: break
		else:
			window_size+=10
			dotdata_qual_check=dotdata(window_size,seq2[flank_length:-flank_length],seq2[flank_length:-flank_length])
			region_QC=qual_check_repetitive_region(dotdata_qual_check)
	return [window_size,region_QC]
def write_pacval_individual_stat_simple_long(PacVal_score_hash,txt_file,rsquare_ref1,rsquare_ref2,rsquare_alt,SV_index):
	fo=open('.'.join(txt_file.split('.')[:-1])+'.pacval','w')
	print >>fo, ' '.join(['alt','ref'])
	PacVal_score_hash[SV_index]=0
	if len(rsquare_ref1)>0:
		fo=open('.'.join(txt_file.split('.')[:-1])+'.pacval','w')
		#"""pick Max Counts score from two refs"""
		rsquare_ref_max=[max([rsquare_ref1[x],rsquare_ref2[x]]) for x in range(len(rsquare_ref1))]
		#"""if denominator=0, assign a small number"""
		for x in range(len(rsquare_alt)):
			if rsquare_ref_max[x]==0:
				if rsquare_alt[x]>0:
					rsquare_ref_max[x]=0.0001*rsquare_alt[x]
				else:
					rsquare_ref_max[x]=0.0001
					rsquare_alt[x]=0.0001
		#""" modify stat from Counts to -1+Counts(PacBio Read| Altered Ref)/Dis(PacBio Read| Orignal Ref)"""
		rsquare_out_ref=[0 for i in rsquare_ref_max]
		rsquare_out_alt=[-1+float(rsquare_alt[x])/float(rsquare_ref_max[x]) for x in range(len(rsquare_alt))]
		qual_score=0
		total_reads=0
		for x in range(len(rsquare_out_ref)):
			print >>fo, ' '.join([str(i) for i in [rsquare_out_alt[x],rsquare_out_ref[x]]])
			if rsquare_out_alt[x]>0:
				qual_score+=1
			total_reads+=1
		if total_reads>0:
			PacVal_score_hash[SV_index]=float(qual_score)/float(total_reads)
	fo.close()
	return PacVal_score_hash
def write_pacval_individual_stat_simple_short(PacVal_score_hash,txt_file,rsquare_ref,rsquare_alt1,rsquare_alt2,SV_index):
	fo=open('.'.join(txt_file.split('.')[:-1])+'.pacval','w')
	print >>fo, ' '.join(['alt','ref'])
	PacVal_score_hash[SV_index]=0
	if len(rsquare_ref)>0:
		#"""pick min Dis score from two alleles"""
		rsquare_alt_min=[min([rsquare_alt1[x],rsquare_alt2[x]]) for x in range(len(rsquare_ref))]
		#"""if denominator=0, assign a small number"""
		for x in range(len(rsquare_ref)):
			if rsquare_alt_min[x]==0:
				if rsquare_ref[x]>0:
					rsquare_alt_min[x]=0.0001*rsquare_ref[x]
				else:
					rsquare_ref[x]=0.0001
					rsquare_alt_min[x]=0.0001
		#""" modify stat from Dis to Dis(PacBio Read| Orignal Ref)/Dis(PacBio Read| Altered Ref)-1"""
		rsquare_out_ref=[0 for i in rsquare_ref]
		rsquare_out_alt_min=[float(rsquare_ref[x])/float(rsquare_alt_min[x])-1 for x in range(len(rsquare_alt_min))]
		qual_score=0
		total_reads=0
		for x in range(len(rsquare_out_ref)):
			y=[rsquare_out_alt_min[x],rsquare_out_ref[x]]
			if y[0]>y[1]: 
				qual_score+=1
			total_reads+=1
			print >>fo, ' '.join([str(i) for i in y])
		if total_reads>0:
			PacVal_score_hash[SV_index]=float(qual_score)/float(total_reads)
	fo.close()
	return PacVal_score_hash
