#!/bin/sh

#
# This script reads <tmpdir>/new-scs.txt file for supportconfigs.  For each
# supportconfig, it:
#
#       1) searches the supportconfig path for an SR ID
#       2) writes the supportconfig md5sum and SR ID to
#          an srs.dat file in the datasets area
#
# Inputs: None (uses sca-datasets.conf file for configuration)
#
# Outputs/Results:  Updated srs.dat file in the datasets directory
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
l3ScsDir="$SCA_DATASETS_RAWDATA_L3_SCS_DIR"
datasetsPath="$SCA_DATASETS_RESULTS_PATH"
[ $DEBUG ] && echo "*** DEBUG: $0: datasetsTmpPath: $datasetsTmpPath, l3ScsDir: $l3ScsDir, datasetsPath: $datasetsPath" >&2

# create list of new supportconfigs that could be related to srs
scsFile="$datasetsTmpPath/new-sr-scs.txt"
cat "$datasetsTmpPath/new-scs.txt" | grep "$l3ScsDir" > $scsFile
if [ ! -s "$scsFile" ]; then
        [ $DEBUG ] && echo "*** DEBUG: $0: No new supportconfigs to process, exiting..."
        exit 0
fi

# process new supportconfigs
if [ ! -f $datasetsPath/srs.dat ]; then
        echo "000_md5sum Id" > $datasetsPath/srs.dat
fi
scNum=0
while IFS= read -r sc; do
	[ $DEBUG ] && echo "*** DEBUG: $0: sc: $sc" >&2
	scNum=$(( scNum + 1 ))
        scMd5=`md5sum -b $sc | cut -d" " -f1`
        [ $DEBUG ] && echo "*** DEBUG: $0: scNum: $scNum, scMd5: $scMd5" >&2
        if [ -z "$scMd5" ]; then
		[ $DEBUG ] && echo "*** DEBUG: $0: No md5sum, skipping..." >&2
		continue
	fi
	if grep -q "$scMd5" "$datasetsPath"/srs.dat; then
		[ $DEBUG ] && echo "*** DEBUG: $0: Supportconfig already processed, skipping..." >&2
                continue
        fi
	scTxtFile=`tar tf $sc | grep "supportconfig\.txt"`
	if [ -z "$scTxtFile" ]; then
		[ $DEBUG ] && echo "*** DEBUG: $0: No supportconfig.txt, skipping..." >&2
		continue
	fi

	sr=`echo "$sc" | grep -o -m1 -i "SR[0-9]\+" | head -1`
	if [ -z "$sr" ]; then
		sr=`echo "$sc" | grep -o -m1 -i "SFSC[0-9]\+" | head -1`
		if [ -z "$sr" ]; then
			sr=`echo "$sc" | grep -o -m1 -i "CASE[0-9]\+" | head -1`
			if [ -z "$sr" ]; then
				sr=`echo "$sc" | grep -o -m1 "/00[0-9]\+/" | head -1`
			fi
		fi
	fi	
	if [ -z "$sr" ]; then
		[ $DEBUG ] && echo "*** DEBUG: $0: No SR in path, skipping..." >&2
		continue
	fi 
	[ $DEBUG ] && echo "*** DEBUG: $0: sr: $sr" >&2
	srId=`echo "$sr" | grep -o -i "[0-9]*"`
	if ! echo "$srId" | grep -q "^[0-9]\{6\}"; then
		[ $DEBUG ] && echo "*** DEBUG: $0: No SR ID, skipping..." >&2
		continue
	fi
	if [ "${#srId}" -eq "6" ] && ! echo $srId | grep -q -E "^00"; then
		srId="00$srId"
	fi
	[ $DEBUG ] && echo "*** DEBUG: $0: srId: $srId" >&2

	if ! grep -q "$scMd5 $srId" "$datasetsPath"/srs.dat; then
        	echo "$scMd5 $srId" >> "$datasetsPath"/srs.dat
	fi
done < $scsFile

exit 0
