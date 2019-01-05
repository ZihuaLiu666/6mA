################################################
#File Name: diff_exp.sh
#Author: Wanqiu Ding
#Mail: wanqiuding@163.com
#Created Time: Wed May 31 13:47:49 2017
################################################

#!/bin/sh

outDir=.
tophatVer="2"
minAnchor=8
sample=sample.conf
thread=5

usage(){
	cat <<EOF
This script is used to do gene differential expression analysis which include fastqc, pre-process, mapping ,evaluation and differential expression analysis.
	please make sure the following programs are in you PATH:
	fastqc
	tophat2
	DEseq2
	cufflinks
	cuffdiff
	RNA-seq evaluation scripts
Usage: sh $(basename $0) OPTIONS sample.conf 
sample.conf is a tab-demited file which has the following format:
ex:

Options:
	Input:
	-i|index	PREFIX	Index prefix (required)
	-r|ref	FILE	Reference genome sequence in fasta format (required)
	-g|gpe	FILE	A gene structure file in gpe format
	-o|outDir	DIR	Output directory for all results[default:./]
	-t|thread	INT	Number of threads
EOF
}

[ $1 ] || usage

shortOptions="i:r:g:o:t:s:p:"
longOptions="index:,ref:,gpe:,gtf:,outDir:,thread:,minAnchor:,slop:,tophatParams:"
eval set -- $(getopt -n $(basename $0) -a -o $shortOptions -l $longOptions -- "$@")

while [ -n "$1" ];do
	case $1 in
	-i|--index)         index=$2;shift;;
	-r|--ref)           ref=$(readlink -en $2);shift;;
	-g|--gpe)           gpe=$(readlink -en $2);shift;;
	   --gtf)           gtf=$(readlink -en $2);shift;;
	-o|--outDir)        outDir=$(readlink -mn $2);shift;;
	-t|--thread)        thread=$2;shift;;
	-s|--slop)          slop=$2;shift;;
	   --tophatParams)  tophatParams=$2;shift;;
	--)                 shift; break;;
	*)                  usage; exit 1;;
	esac
	shift
done

if [ $# -eq 0 ];then
	usage
	exit 1
fi

if [ -d log ];then
	[ -d log_old ] && rm -r log_old
	mv log log_old
fi
mkdir -p log

<<!
if [ $? -ne 0 ];then
	echo "Can't create directory $outDir" >&2
	exit 1
fi
!

echo "Started on $(date)" >>log/run.log

##prepare gpe file
if [ -d $outDir ];then
	echo "the dir exists" >>log/run.log
else
    mkdir -p $outDir
fi
##process the sample information file
newConf=sample.conf.$$.tmp
tr -s ' ' < $1 | tr ' ' '\t' >$outDir/$newConf
trap "rm $(readlink -en $outDir/$newConf)" EXIT
sampleN=$(wc -l <$outDir/$newConf)

cd $outDir
if [ $(head -n 1 $gpe | awk '{print NF}') -eq 15 ];then
	ln -sf $gpe raw.gpe
else
	cut -f2- $gpe >raw.gpe
fi
#	cp $gtf >raw.gtf

##align
echo "[INFO] $(date) Mapping..."
tophatCommonParams="-p $thread -a $minAnchor $tophatParams"
for((i=1; i<=$sampleN; i++));do
	line=$(sed -n "${i}p;" $outDir/$newConf)
	SM=$(echo $line | awk -F ' ' '{print $1}')
	LB=$(echo $line | awk -F ' ' '{print $2}')
	libType=$(echo $line | awk -F ' ' '{print $3}')
	read1Fq=$(echo $line | awk -F ' ' '{print $4}')
	read2Fq=$(echo $line | awk -F ' ' '{print $5}')
	mkdir -p $outDir/$SM/mapping/log
	tophatParams2=$tophatCommonParams" --library-type $libType --rg-id $SM-$LB --rg-sample $SM --output-dir $outDir/$SM/mapping"

	cd $outDir/$SM/mapping
	if [ "X$tophatVer" == "X1.2" ];then
		cmd="(time tophat1.2 $tophatParams2 $index $read1Fq $read2Fq 2>log/tophat1.2.log) 2>log/tophat1.2.time"
	else
		cmd="(time tophat2 $tophatParams2 $index $read1Fq $read2Fq 2>log/tophat2.log) 2>log/tophat2.time"
	fi
	echo "[CMD] $(date) $cmd"; eval $cmd

	cd $OLDPWD
done

##Get uniq alignments
echo "[INFO] $(date) Get uniq alignments..."
bgPids=""
samtoolsViewCommonParams="-b -@ $thread"
if [ "X$tophatVer" == "X1.2" ];then
	samtoolsViewCommonParams=$samtoolsViewCommonParams" -q 255"
else
	samtoolsViewCommonParams=$samtoolsViewCommonParams" -q 50"
fi
for((i=1; i<=$sampleN; i++));do
	line=$(sed -n "${i}p;" $outDir/$newConf)
	SM=$(echo $line |  awk -F ' ' '{print $1}')
	cd $outDir/$SM/mapping
	cmd="samtools view $samtoolsViewCommonParams accepted_hits.bam | samtools sort -@ $thread -m 10G - -o uniq.sorted.bam"
	if [ $(($i%$thread)) -eq 0 ];then
		eval $cmd
	else
		eval $cmd &
		bgPids=$bgPids" $!"
	fi

	cd $OLDPWD
done
wait $bgPids

##index bam and general statistics
echo "[INFO] $(date) Build BAM index..."
bgPids=""
for((i=1; i<=$sampleN; i++));do
	line=$(sed -n "${i}p;" $outDir/$newConf)
	SM=$(echo $line | awk -F ' ' '{print $1}')
	cd $outDir/$SM/mapping
	samtools index uniq.sorted.bam
	sambamba flagstat -t $thread accepted_hits.bam >raw.flagstat
	totalReadpair=$(grep Input align_summary.txt | grep -o "[0-9]*" | head -1)
	totalRead=$(echo "$totalReadpair*2"|bc)
	totalReadM=$(echo "scale=2;$totalRead/10^6"|bc)
	mappedRead=$(grep "paired in sequencing" raw.flagstat | cut -d ' ' -f1)
	mappedRate=$(echo "scale=2;$mappedRead*100/$totalRead"|bc)
	mappedToDiffChr=$(grep "with mate mapped to a different chr$" raw.flagstat | cut -d ' ' -f1)
	mappedToDiffChrPer=$(echo "scale=2;$mappedToDiffChr*100/$mappedRead"|bc)
	#medianInsertSize=$(grep "median insert size" raw_bamqc/genome_results.txt | grep -o "[0-9]*")
	#meanMapQ=$(grep "mean mapping quality" raw_bamqc/genome_results.txt | grep -o "[0-9]*")
	sambamba flagstat -t $thread uniq.sorted.bam >uniq.flagstat
	uniqRead=$(grep "paired in sequencing" uniq.flagstat | cut -d ' ' -f1)
	uniqRate=$(echo "scale=2;$uniqRead*100/$totalRead"|bc)
	(echo -e "Total \tTotal mapped reads\tMapped rate\tWith mate mapped to a different chromosome (%)\tUniquely-mapped reads\tUniquely-mapped rate (%)"
	echo -e "$totalRead\t$mappedRead\t$mappedRate\t$mappedToDiffChrPer\t$uniqRead\t$uniqRate") >mapping.stat

	cd $OLDPWD
done
wait $bgPids
#_EOF_

fragFile=$(which fragmentation.py)
pythonOpt=$(which python)
##Fragmentation evaluation
echo "[INFO] $(date) Fragmentation evaluation..."
bgPids=""
for((i=1; i<=$sampleN; i++));do
	line=$(sed -n "${i}p;" $outDir/$newConf)
	SM=$(echo $line | awk -F ' ' '{print $1}')
	LB=$(echo $line | awk -F ' ' '{print $2}')

	mkdir -p $outDir/$SM/evaluation && cd $outDir/$SM
	ln -s $outDir/$SM/mapping/uniq.sorted.bam
	ln -s $outDir/$SM/mapping/uniq.sorted.bam.bai
	cd evaluation

	cmd="$pythonOpt $fragFile --gpe $outDir/raw.gpe --bam $outDir/$SM/uniq.sorted.bam >fragmentation.tsv;
		fragmentation.R <fragmentation.tsv"
	
	if [ $(($i%$thread)) -eq 0 ];then
		eval $cmd
	else
		eval $cmd &
		bgPids=$bgPids" $!"
	fi
	cd $outDir
done
#wait $bgPids
#<<\_EOF_
##Mutation rate evaluation
echo "[INFO] $(date) Mutation rate evaluation..."
bgPids=""
for((i=1; i<=$sampleN; i++));do
    line=$(sed -n "${i}p;" $outDir/$newConf)
    SM=$(echo $line | awk -F ' ' '{print $1}')
    cd $outDir/$SM/evaluation

    cmd="mutationRate_tophat.pl --sam $outDir/$SM/uniq.sorted.bam --ref $ref >mutRate.tsv 2>mutRate.log;
    	mutRate_tophat.R <mutRate.tsv"

    if [ $(($i%$thread)) -eq 0 ];then
    	eval $cmd
    else
	eval $cmd &
	bgPids=$bgPids" $!"
    fi

    cd $outDir
done
#wait $bgPids

#calculate gene expression with zhangsj' s perl scripts
echo "[INFO] $(date) Calculate gene expression..."
bgPids=""
for((i=1; i<=$sampleN; i++));do
    line=$(sed -n "${i}p;" $outDir/$newConf)
    SM=$(echo $line | awk -F ' ' '{print $1}')
    LB=$(echo $line | awk -F ' ' '{print $3}')
	cd $outDir/$SM/mapping

	cmd="geneRPKM.pl -g $outDir/raw.gpe -l $LB -s $slop $outDir/$SM/uniq.sorted.bam >RPKM.bed6+ 2>RPKM.log"

	if [ $(($i%$thread)) -eq 0 ];then
	    eval $cmd
	else
	eval $cmd &
	bgPids=$bgPids" $!"
	fi

	cd $outDir
done
#wait $bgPids


#DNA contamination and coverage
echo "[INFO] $(date) contamination..."
bgPids=""
for((i=1; i<=$sampleN; i++));do
	line=$(sed -n "${i}p;" $outDir/$newConf)
	SM=$(echo $line | awk -F ' ' '{print $1}')
	LB=$(echo $line | awk -F ' ' '{print $3}')

	cd $outDir/$SM/evaluation
	cmd="samContam.pl -l $LB -g $outDir/raw.gpe -s $slop $outDir/$SM/mapping/uniq.sorted.bam >contam.tsv 2>contam.log;
         grep -v '^#' contam.tsv | bar.R -x=Region -y=RPKM -main='RPKM in Each Type of Region' -anno -annoTxtS=4 -width=10 -p=contamination.pdf"

	if [ $(($i%$thread)) -eq 0 ];then
	    eval $cmd
	else
	eval $cmd &
	bgPids=$bgPids" $!"
	fi
	
	cd $outDir
done
#wait $bgPids

##differential expression analysis with DEseq2 armed with htseq-count to calculate gene counts
if [ -d diff_exp ];then
	[ -d diff_exp_old ] && rm -r diff_exp_old
	mv diff_exp diff_exp_old
fi
mkdir diff_exp && cd diff_exp

samples=(control case)
cont_n=$(grep "control" $outDir/$newConf | wc -l)
case_n=$(grep "case" $outDir/$newConf | wc -l)

bgPids=""
casenum=1
#caseindex=0
controlnum=1
#controlindex=0
#IFSBAK=$IFS
#IFS=$','

for((i=1; i<=$sampleN; i++));do
    line=$(sed -n "${i}p;" $outDir/$newConf)
    SM=$(echo $line | awk -F ' ' '{print $1}')
    TYPE=$(echo $line | awk -F ' ' '{print $2}')
    if [ $TYPE == "case" ];then
#    	cmd="samtools sort -n $outDir/$SM/mapping/uniq.sorted.bam -o $TYPE.$casenum\_$SM.sortedByName.bam && samtools view $TYPE.$casenum\_$SM.sortedByName.bam | htseq-count -m intersection-nonempty -s reverse -o $TYPE.$casenum\_$SM.htseq.sam - $gtf >$TYPE.$casenum\_$SM.count 2>htseq.$TYPE.$casenum\_$SM.log &"
#htseq-count -f bam -s no case.2_KO_sample_2.sortedByName.bam /mnt/share/dingwq/data/ce11/structure/Caenorhabditis_elegans.WBcel235.87.gtf > case.2_KO_sample_2.count 2> case.2_KO_sample_2.log
       cmd="samtools sort -n $outDir/$SM/mapping/uniq.sorted.bam -o $TYPE.$casenum\_$SM.sortedByName.bam && samtools view $TYPE.$casenum\_$SM.sortedByName.bam | htseq-count -s no -o $TYPE.$casenum\_$SM.htseq.sam - $gtf >$TYPE.$casenum\_$SM.count 2>htseq.$TYPE.$casenum\_$SM.log &"
		if [ -z "$cfCase" ];then
			cfCase="$outDir/$SM/mapping/accepted_hits.bam"
		else
			cfCase=$cfCase",""$outDir/$SM/mapping/accepted_hits.bam"
		fi
		casenum=$[ casenum+1 ]
	#	caseindex=$[ caseindex+1 ]
    else
#    	cmd="samtools sort -n $outDir/$SM/mapping/uniq.sorted.bam -o $TYPE.$controlnum\_$SM.sortedByName.bam && samtools view $TYPE.$controlnum\_$SM.sortedByName.bam | htseq-count -m intersection-nonempty -s reverse -o $TYPE.$controlnum\_$SM.htseq.sam - $gtf >$TYPE.$controlnum\_$SM.count 2>htseq.$TYPE.$controlnum\_$SM.log &"
		cmd="samtools sort -n $outDir/$SM/mapping/uniq.sorted.bam -o $TYPE.$controlnum\_$SM.sortedByName.bam && samtools view $TYPE.$controlnum\_$SM.sortedByName.bam | htseq-count -s no -o $TYPE.$controlnum\_$SM.htseq.sam - $gtf >$TYPE.$controlnum\_$SM.count 2>htseq.$TYPE.$controlnum\_$SM.log &"
		if [ -z "$cfControl" ];then
			cfControl="$outDir/$SM/mapping/accepted_hits.bam"
		else
			cfControl=$cfControl",""$outDir/$SM/mapping/accepted_hits.bam"
		fi
    	controlnum=$[ controlnum+1 ]
#		controlindex=$[ controlindex+1 ]
    fi

    if [ $(($i%$thread)) -eq 0 ];then
    	eval $cmd
    else
    	eval $cmd &
	bgPids=$bgPids" $!"
    fi

done
wait $bgPids
# Identify Differentially-expressed Genes with DESeq.R
R CMD BATCH /mnt/share/dingwq/bin/DESeq.R
cd $outDir

#Identify Differentially-expressed Genes with cuffdiff
if [ -d cuffdiff_exp ];then
	[ -d cuffdiff_exp_old ] && rm -r cuffdiff_exp_old
	mv cuffdiff_exp cuffdiff_exp_old
fi
mkdir cuffdiff_exp && cd cuffdiff_exp

cuffdiff -o ./ --raw-mapped-norm -p $thread -q --no-update-check --min-reps-for-js-test 2 $gtf $cfControl $cfCase 2>cuffdiff.log

cd $outDir
#IFS=$IFSBAK

#_EOF_
