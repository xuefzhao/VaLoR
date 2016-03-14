#STEP1. To make fake NIST bed files with off breakpoints:

Commands used:
```
Fake.Off.Breakpoints.py --bed Personalis_1000_Genomes_deduplicated_deletions.bed --off 0
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
```


#STEP2. Apply VaLoR on simulatd files through bed module:

General command for applying VaLoR:
```
VaLoR bed --reference ref.fa --sv-type sv --sv-input input.bed --pacbio-input pacbio.bam --output-path out_folder
```

Commands:
```
VaLoR bed --reference /scratch/remills_flux/xuefzhao/reference/hg19/hg19.fa --sv-type del --sv-input /scratch/remills_flux/xuefzhao/PacbioValidation/NA12878/NIST_DEL/Personalis_1000_Genomes_deduplicated_deletions.bed --pacbio-input /scratch/remills_flux/xuefzhao/NA12878.Pacbio/alignment/sorted_final_merged.bam --output-path /scratch/remills_flux/xuefzhao/PacbioValidation/NA12878/NIST_DEL_Vali/VaLoRPersonalis_1000_Genomes_deduplicated_deletions
```