SCRIPTS=../scripts
SIM_DATA=../../ngsSim/examples
ANGSD=../../angsd



##### Clean-up
rm -f testA*
touch -d 'next minute' $SIM_DATA/testAF.ANC.fas.fai


##### Genotypes' and sample allele frequencies' posterior probabilities
$ANGSD/angsd -glf $SIM_DATA/testA.glf.gz -fai $SIM_DATA/testAF.ANC.fas.fai -nInd 24 -doMajorMinor 1 -doMaf 1 -doPost 1 -doGeno 32 -doSaf 1 -anc $SIM_DATA/testAF.ANC.fas -out testA
$ANGSD/misc/realSFS testA.saf.idx -seed 12345 > testA.saf.ml
$ANGSD/angsd -glf $SIM_DATA/testA.glf.gz -fai $SIM_DATA/testAF.ANC.fas.fai -nInd 24 -doSaf 1 -anc $SIM_DATA/testAF.ANC.fas -out testA.rf

# Estimated and true pooled site frequency spectrum
#Rscript --vanilla --slave -e 'barplot(rbind(as.numeric(scan("../../ngsSim/examples/testA.frq", what="char")), exp(as.numeric(scan("testA.saf.ml", what="char")))), beside=T, legend=c("True","Estimated"))'





##### PCA
# Get covariance matrix
gunzip -f testA.geno.gz testA.rf.saf.gz
../ngsCovar -probfile testA.geno -outfile testA.covar1 -nind 24 -nsites 10000 -call 0 -sfsfile testA.rf.saf -norm 0
../ngsCovar -probfile testA.geno -outfile testA.covar2 -nind 24 -nsites 10000 -call 0 -minmaf 0.05
../ngsCovar -probfile testA.geno -outfile testA.covar3 -nind 24 -nsites 10000 -call 1 -minmaf 0.05

# Plot results
#Rscript --vanilla --slave -e 'write.table(cbind(seq(1,24),rep(1,24),c(rep("A",10),rep("B",8),rep("C",6))), row.names=F, sep="\t", col.names=c("FID","IID","CLUSTER"), file="testA.clst", quote=F)'
#Rscript --vanilla --slave $SCRIPTS/plotPCA.R -i testA.covar1 -c 1-2 -a testA.clst -o testA.pca.SAF.pdf
#Rscript --vanilla --slave $SCRIPTS/plotPCA.R -i testA.covar2 -c 1-2 -a testA.clst -o testA.pca.MAF.pdf
#Rscript --vanilla --slave $SCRIPTS/plotPCA.R -i testA.covar3 -c 1-2 -a testA.clst -o testA.pca.MAFcall.pdf





##### Statistics
# Pop 1
$ANGSD/angsd -glf $SIM_DATA/testA1.glf.gz -fai $SIM_DATA/testAF.ANC.fas.fai -nInd 10 -doMajorMinor 1 -doMaf 1 -doPost 1 -doGeno 32 -doSaf 1 -anc $SIM_DATA/testAF.ANC.fas -out testA1
$ANGSD/misc/realSFS testA1.saf.idx -seed 12345 > testA1.saf.ml
$ANGSD/angsd -glf $SIM_DATA/testA1.glf.gz -fai $SIM_DATA/testAF.ANC.fas.fai -nInd 10 -doSaf 1 -anc $SIM_DATA/testAF.ANC.fas -pest testA1.saf.ml -out testA1.rf
# Pop 2
$ANGSD/angsd -glf $SIM_DATA/testA2.glf.gz -fai $SIM_DATA/testAF.ANC.fas.fai -nInd 8 -doMajorMinor 1 -doMaf 1 -doPost 1 -doGeno 32 -doSaf 1 -anc $SIM_DATA/testAF.ANC.fas -out testA2
$ANGSD/misc/realSFS testA2.saf.idx -seed 12345 > testA2.saf.ml
$ANGSD/angsd -glf $SIM_DATA/testA2.glf.gz -fai $SIM_DATA/testAF.ANC.fas.fai -nInd 8 -doSaf 1 -anc $SIM_DATA/testAF.ANC.fas -pest testA2.saf.ml -out testA2.rf

# Get stats
gunzip -f testA1.rf.saf.gz testA2.rf.saf.gz
../ngsStat -npop 2 -postfiles testA1.rf.saf testA2.rf.saf -nsites 10000 -iswin 1 -nind 10 8 -outfile testA.stat -block_size 100

# Plot results
#Rscript --vanilla --slave $SCRIPTS/plotSS.R -i testA.stat -o testA.stat.pdf -n pop1-pop2
#Rscript --vanilla --slave $SCRIPTS/plotSS.R -i testA.stat -o testA.stat.pop1.pdf -n pop1





##### Fst
# 2D-SFS
../ngs2dSFS -postfiles testA1.rf.saf testA2.rf.saf -outfile testA.joint.spec -relative 1 -nind 10 8 -nsites 10000 -maxlike 1
#Rscript --vanilla --slave $SCRIPTS/plot2dSFS.R testA.joint.spec testA.joint.spec.pdf pop1 pop2

# Estimate Fst
gunzip -f testA1.saf.gz testA2.saf.gz
../ngsFST -postfiles testA1.saf testA2.saf -priorfile testA.joint.spec -nind 10 8 -nsites 10000 -outfile testA.fst1
../ngsFST -postfiles testA1.saf testA2.saf -priorfiles testA1.saf.ml testA2.saf.ml -nind 10 8 -nsites 10000 -outfile testA.fst2
../ngsFST -postfiles testA1.rf.saf testA2.rf.saf -nind 10 8 -nsites 10000 -outfile testA.fst3

# Plot
#Rscript --vanilla --slave $SCRIPTS/plotFST.R -i testA.fst -o testA.fst.pdf -w 100 -s 50





##### Check MD5
rm -f *.arg
TMP=`mktemp`
md5sum testA* | sort -k 2,2 > $TMP
if diff $TMP test.md5 > /dev/null
then
    echo "ngsPopGen: All tests OK!"
else
    echo "ngsPopGen: test(s) failed!"
fi
