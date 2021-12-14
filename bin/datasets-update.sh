#!/bin/sh

#
# This script updates all datasets with new supportconfigs.  Note
# that this script assumes no change in dataset schemas.  Changes
# should be implemented by creating new (additional) datasets.
#
# Inputs: None (uses sca-databuild.conf file for configuration)
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
confFile="/usr/etc/sca-databuild.conf"
[ -r "$confFile" ] && source ${confFile}
confFile="/etc/sca-databuild.conf"
[ -r "$confFile" ] && source ${confFile}
confFile="../sca-databuild.conf"
[ -r "$confFile" ] && source ${confFile}
if [ -z "$confFile" ]; then
	echo "*** ERROR: $0: No sca-databuild.conf file, exiting..." >&2
	exit 1
fi
ingestHome="$SCA_INGEST_HOME"
databuildHome="$SCA_DATASETS_HOME"
databuildBinPath="$SCA_DATASETS_BIN_PATH"
databuildTmpPath="$SCA_DATASETS_TMP_PATH"
databuildLogPath="$SCA_DATASETS_LOG_PATH"
[ $DEBUG ] && echo "*** DEBUG: $0: ingestHome: $ingestHome, databuildHome: $databuildHome, databuildBinPath: $databuildBinPath, databuildTmpPath: $databuildTmpPath, databuildLogPath: $databuildLogPath"

curDate=`date +%Y%m%d`

# current rawdata info
pushd $ingestHome >/dev/null
rawdataCommit=`git log rawdata.dvc | head -1 | cut -d' ' -f2`
popd >/dev/null

# create list of new supportconfigs
echo "This script will use dvc to determine new rawdata supportconfigs"
echo "that have not yet been added to datasets.  New supportconfigs will"
echo "be recorded in $databuildTmpPath/new-scs.txt then copied to"
echo "$databuildLogPath/new-scs-$curDate.txt after processing."
echo -n "Create $databuildTmpPath/new-scs.txt (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	datasetsRawdataCommit=`cat $databuildHome/rawdata.dvc.git`
	if [ "$datasetsRawdataCommit" != "$rawdataCommit" ]; then
        	dvc diff $datasetsRawdataCommit $rawdataCommit | sed "s/^ *\.\.\/\.\.//" | sed -n '/Deleted:/q;p' | grep -E "^/" > $databuildTmpPath/new-scs.txt
	fi
	if [ ! -s "$databuildTmpPath/new-scs.txt" ]; then
		echo "No new supportconfigs, exiting..."
		exit 0
	fi
fi

# feature datasets
echo "Update binary-valued datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $databuildBinPath/datasets-features.sh "$debugOpt" >> "$databuildLogPath"/features-$curDate.log 2>&1
	[ ! $DEBUG ] && $databuildBinPath/datasets-features.sh >> "$databuildLogPath"/features-$curDate.log 2>&1
fi
# srs dataset
echo "Update srs datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $databuildBinPath/datasets-srs.sh "$debugOpt" >> "$databuildLogPath"/srs-$curDate.log 2>&1
	[ ! $DEBUG ] && $databuildBinPath/datasets-srs.sh >> "$databuildLogPath"/srs-$curDate.log 2>&1
fi
# bugs dataset
echo "Update bugs datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
        [ $DEBUG ] && $databuildBinPath/datasets-bugs.sh "$debugOpt" >> "$databuildLogPath"/bugs-$curDate.log 2>&1
        [ ! $DEBUG ] && $databuildBinPath/datasets-bugs.sh >> "$databuildLogPath"/bugs-$curDate.log 2>&1
fi
# certs dataset
echo "Update certs datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $databuildBinPath/datasets-certs.sh "$debugOpt" >> "$databuildLogPath"/certs-$curDate.log 2>&1
	[ ! $DEBUG ] && $databuildBinPath/datasets-certs.sh >> "$databuildLogPath"/certs-$curDate.log 2>&1
fi
# supportconfig names dataset
echo "Update sc-names datasets (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	[ $DEBUG ] && $databuildBinPath/datasets-sc-names.sh "$debugOpt" >> "$databuildLogPath"/sc-names-$curDate.log 2>&1
	[ ! $DEBUG ] && $databuildBinPath/datasets-sc-names.sh >> "$databuildLogPath"/sc-names-$curDate.log 2>&1
fi

# copy new-scs.txt to log area
echo "Copy $databuildTmpPath/new-scs.txt to $databuildLogPath/new-scs-$curDate.txt (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	cp $databuildTmpPath/new-scs.txt $databuildLogPath/new-scs-${curDate}.txt
fi
# write rawdata.<git-commit>
echo "Write latest rawdata git commit to rawdata.dvc.git (y/N)? "
read reply
if [ "$reply" = "y" ]; then
	echo $rawdataCommit > $databuildHome/rawdata.dvc.git
fi
echo "Finished updating datasets, press any key to exit..."
read tmpVar

exit 0
