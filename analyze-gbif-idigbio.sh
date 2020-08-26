#!/bin/bash
#
# Find the provider datasets that are shared by and unique to iDigBio and GBIF
#
# Some things to note:
# - Must have Apache Jena installed (see https://jena.apache.org/download/)
# - Must have an Apache Jena index available (see https://github.com/bio-guoda/preston-scripts/tree/master/query for instructions)
# - SPARQL queries are copied from https://github.com/bio-linker/linkrot-contentdrift-figures/tree/master/sparql-queries
#
# To run:
#	./analyze-gbif-idigbio.sh JOB_NAME INDEX_LOC
# e.g.
#	bash -x analyze-gbif-idigbio.sh 08-2020-analysis latest-only-index/
#
# Results will be saved in JOB_NAME/
#

workdir=$1
indexdir=$2

function query-index {
	tdbquery --loc $1 --query $2 --results tsv | tail -n+2
}

function get-content-list {
	cat $1 | cut -f2 | cut -c2-79 | grep "^hash" | sort | uniq
}

mkdir -p $workdir

query-index $indexdir queries/select-idigbio-by-activity.rq > $workdir/idigbio-query.tsv
query-index $indexdir queries/select-gbif-by-activity.rq > $workdir/gbif-query.tsv

cd $workdir

echo "URL\tContent in iDigBio\tContent in GBIF\tSeen at" > url-content-times-including-unresolvable.tsv
cat idigbio-query.tsv | awk '{ print $1 "\t" $2 "\t\t" $3 }' >> url-content-times-including-unresolvable.tsv
cat gbif-query.tsv | awk '{ print $1 "\t\t" $2 "\t" $3 }' >> url-content-times-including-unresolvable.tsv
sort -u url-content-times-including-unresolvable.tsv -o url-content-times-including-unresolvable.tsv

# Remove no-content observations from the list
grep -v ".well-known/genid" url-content-times-including-unresolvable.tsv > url-content-times.tsv

get-content-list idigbio-query.tsv > idigbio-content.tsv
get-content-list gbif-query.tsv > gbif-content.tsv

comm idigbio-content.tsv gbif-content.tsv > idigbio-gbif-shared.tsv

cut -f3 idigbio-gbif-shared.tsv | awk NF > shared-content.tsv
cut -f1 idigbio-gbif-shared.tsv | awk NF > idigbio-only-content.tsv
cut -f2 idigbio-gbif-shared.tsv | awk NF > gbif-only-content.tsv

echo "# Analysis Report" > report.txt
echo "Number of contents shared by iDigBio and GBIF: $(wc -l < shared-content.tsv)" >> report.txt
echo "Number of contents only in iDigBio: $(wc -l < idigbio-only-content.tsv)" >> report.txt
echo "Number of contents only in GBIF: $(wc -l < gbif-only-content.tsv)" >> report.txt
