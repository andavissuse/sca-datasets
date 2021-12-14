#!/bin/sh

#
# This script updates all datasets with new supportconfigs.  Note
# that this script assumes no change in dataset schemas.  Changes
# should be implemented by creating new (additional) datasets.
#
# Inputs: None (uses sca-datasets.conf file for configuration)
#
# Outputs/Results: Updated *.dat files in the datasets directory
#

# functions
function usage() {
	echo "Usage: `basename $0` [-d(ebug)]"
}

# arguments
if [ "$1" = "--help" ]; then
        usage
	exit 0
fi
while getopts 'hd' OPTION; do
	case $OPTION in
                h)
                        usage
			exit 0
                        ;;
                d)
                        DEBUG=1
			debugOpt="-d"
                        ;;
        esac
done

# config file
confFile="/usr/etc/sca-datasets.conf"
[ -r "$confFile" ] && source ${confFile}
confFile="/etc/sca-datasets.conf"
[ -r "$confFile" ] && source ${confFile}
confFile="../sca-datasets.conf"
[ -r "$confFile" ] && source ${confFile}
if [ -z "$confFile" ]; then
	echo "*** ERROR: $0: No sca-datasets.conf file, exiting..." >&2
	exit 1
fi
ingestHome="$SCA_INGEST_HOME"
datasetsHome="$SCA_DATASETS_HOME"
datasetsBinPath="$SCA_DATASETS_BIN_PATH"
datasetsTmpPath="$SCA_DATASETS_TMP_PATH"
datasetsLogPath="$SCA_DATASETS_LOG_PATH"
[ $DEBUG ] && echo "*** DEBUG: $0: ingestHome: $ingestHome, datasetsHome: $datasetsHome, datasetsBinPath: $datasetsBinPath, datasetsTmpPath: $datasetsTmpPath, datasetsLogPath: $datasetsLogPath"

curDate=`date +%Y%m%d`

# current rawdata info
pushd $ingestHome >/dev/null
rawdataCommit=`git log rawdata.dvc | head -1 | cut -d' ' -f2`
popd >/dev/null

# create list of new supportconfigs
echo "This script will use dvc to determine new rawdata supportconfigs"
echo "that have not yet been added to datasets.  New supportconfigs will"
echo "be recorded in $datasetsTmpPath/new-scs.txt then copied to"
echo "$datasetsLogPath/new-scs-$curDate.txt after processing."
echo -n "Create $datasetsTmpPath/new-scs.txt (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	datasetsRawdataCommit=`cat $datasetsHome/rawdata.dvc.git`
	if [ "$datasetsRawdataCommit" != "$rawdataCommit" ]; then
        	dvc diff $datasetsRawdataCommit $rawdataCommit | sed "s/^ *\.\.\/\.\.//" | sed -n '/Deleted:/q;p' | grep -E "^/" > $datasetsTmpPath/new-scs.txt
	fi
	if [ ! -s "$datasetsTmpPath/new-scs.txt" ]; then
		echo "No new supportconfigs, exiting..."
		exit 0
	fi
fi

# feature datasets
echo "Update binary-valued datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $datasetsBinPath/datasets-features.sh "$debugOpt" >> "$datasetsLogPath"/features-$curDate.log 2>&1
	[ ! $DEBUG ] && $datasetsBinPath/datasets-features.sh >> "$datasetsLogPath"/features-$curDate.log 2>&1
fi
# srs dataset
echo "Update srs datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $datasetsBinPath/datasets-srs.sh "$debugOpt" >> "$datasetsLogPath"/srs-$curDate.log 2>&1
	[ ! $DEBUG ] && $datasetsBinPath/datasets-srs.sh >> "$datasetsLogPath"/srs-$curDate.log 2>&1
fi
# bugs dataset
echo "Update bugs datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
        [ $DEBUG ] && $datasetsBinPath/datasets-bugs.sh "$debugOpt" >> "$datasetsLogPath"/bugs-$curDate.log 2>&1
        [ ! $DEBUG ] && $datasetsBinPath/datasets-bugs.sh >> "$datasetsLogPath"/bugs-$curDate.log 2>&1
fi
# certs dataset
echo "Update certs datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $datasetsBinPath/datasets-certs.sh "$debugOpt" >> "$datasetsLogPath"/certs-$curDate.log 2>&1
	[ ! $DEBUG ] && $datasetsBinPath/datasets-certs.sh >> "$datasetsLogPath"/certs-$curDate.log 2>&1
fi
# supportconfig names dataset
echo "Update sc-names datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $datasetsBinPath/datasets-sc-names.sh "$debugOpt" >> "$datasetsLogPath"/sc-names-$curDate.log 2>&1
	[ ! $DEBUG ] && $datasetsBinPath/datasets-sc-names.sh >> "$datasetsLogPath"/sc-names-$curDate.log 2>&1
fi

# copy new-scs.txt to log area
echo "Copy $datasetsTmpPath/new-scs.txt to $datasetsLogPath/new-scs-$curDate.txt (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	cp $datasetsTmpPath/new-scs.txt $datasetsLogPath/new-scs-${curDate}.txt
fi
# write rawdata.<git-commit>
echo "Write latest rawdata git commit to rawdata.dvc.git (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	echo $rawdataCommit > $datasetsHome/rawdata.dvc.git
fi
echo "Finished updating datasets, press any key to exit..."
read tmpVar

exit 0
