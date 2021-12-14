#!/bin/sh

#
# This script reads the latest new-<date>.txt file to get supportconfigs.  For each
# supportconfig, it:
#
#	1) writes the supportconfig md5sum and name to an sc-names.dat
#	   file in the datasets area
#
# Inputs: None (uses sca-datasets.conf file for configuration)
#
# Outputs/Results: Updated sc-names.dat file in the datasets directory
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
datasetsTmpPath="$SCA_DATASETS_TMP_PATH"
datasetsPath="$SCA_DATASETS_RESULTS_PATH"
[ $DEBUG ] && echo "*** DEBUG: $0: datasetsTmpPath: $datasetsTmpPath, datasetsPath: $datasetsPath" >&2

# process new supportconfigs
scsFile="$datasetsTmpPath/new-scs.txt"
if [ ! -f "$datasetsPath"/sc-names.dat ]; then
	echo "000_md5sum scName" > "$datasetsPath"/sc-names.dat
fi
scNum=0
while IFS= read -r sc; do
	[ $DEBUG ] && echo "*** DEBUG: $0: sc: $sc" >&2
	scNum=$(( scNum + 1 ))
	scTxtFile=`tar tf "$sc" | grep "supportconfig\.txt"`
	if [ -z "$scTxtFile" ]; then
		continue
	fi
       	scMd5=`md5sum -b "$sc" | cut -d" " -f1`
	if [ -z "$scMd5" ]; then
		continue
	fi
       	if grep -q "$scMd5" "$datasetsPath"/sc-names.dat; then
               	continue
	fi
	scName=`basename "$sc"`
	[ $DEBUG ] && echo "*** DEBUG: $0: scNum: $scNum, scMd5: $scMd5, scName: $scName" >&2
	echo "$scMd5 $scName" >> "$datasetsPath"/sc-names.dat
done < $scsFile

exit 0
