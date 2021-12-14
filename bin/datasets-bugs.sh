#!/bin/sh

#
# This script reads <tmpdir>/new-scs.txt for supportconfigs.  For each
# supportconfig, it:
#
#	1) searches the supportconfig path for a bug ID
#	2) writes the supportconfig md5sum and bug ID to
#	   a bugs.dat file in the datasets area 
#
# Inputs: None (uses sca-datasets.conf file for configuration)
#
# Outputs/Results:  Updated bugs.dat file in the datasets directory
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
        echo "*** ERROR: No sca-datasets.conf file, exiting..." >&2
        exit 1
fi
datasetsTmpPath="$SCA_DATASETS_TMP_PATH"
bscScsDir="$SCA_DATASETS_RAWDATA_BSC_SCS_DIR"
l3ScsDir="$SCA_DATASETS_RAWDATA_L3_SCS_DIR"
datasetsPath="$SCA_DATASETS_RESULTS_PATH"
[ $DEBUG ] && echo "*** DEBUG: $0: datasetsTmpPath: $datasetsTmpPath, bscScsDir: $bscScsDir, l3ScsDir: $l3ScsDir, datasetsPath: $datasetsPath" >&2

# create list of new supportconfigs that could be related to bugs
scsFile="$datasetsTmpPath/new-bug-scs.txt"
cat "$datasetsTmpPath/new-scs.txt" | grep -E "$bscScsDir|$l3ScsDir" > $scsFile
if [ ! -s "$scsFile" ]; then
	[ $DEBUG ] && echo "*** DEBUG: $0: No new supportconfigs to process, exiting..."
	exit 0
fi

# process new supportconfigs
if [ ! -f "$datasetsPath"/bugs.dat ]; then
        echo "000_md5sum Id" > "$datasetsPath"/bugs.dat
fi
scNum=0
while IFS= read -r sc; do
	[ $DEBUG ] && echo "*** DEBUG: $0: sc: $sc" >&2
	scNum=$(( scNum + 1 ))
        scMd5=`md5sum -b "$sc" | cut -d" " -f1`
        [ $DEBUG ] && echo "*** DEBUG: $0: scNum: $scNum, scMd5: $scMd5" >&2
        if [ -z "$scMd5" ]; then
		[ $DEBUG ] && echo "*** DEBUG: $0: No md5sum, skipping..." >&2
		continue
	fi
	if grep -q "$scMd5" "$datasetsPath"/bugs.dat; then
		[ $DEBUG ] && echo "*** DEBUG: $0: Supportconfig already processed, skipping..." >&2
                continue
        fi
	scTxtFile=`tar tf "$sc" | grep "supportconfig\.txt"`
	if [ -z "$scTxtFile" ]; then
		[ $DEBUG ] && echo "*** DEBUG: $0: No supportconfig.txt, skipping..." >&2
		continue
	fi

	bug=`echo "$sc" | grep -o -m1 -i "b[su][cg][0-9]\+" | head -1`
	if [ -z "$bug" ]; then
		bug=`echo "$sc" | grep -o -m1 "\-[0-9]\{7\}\/" | sed "s/^-//" | sed "s/\/$//"`
		if [ -z "$bug" ]; then
			bug=`echo "$sc" | grep -o -m1 "\/[0-9]\{7\}\/" | sed "s/^-//" | sed "s/^\///" | sed "s/\/$//"`
			if [ -z "$bug" ]; then
				bug=`echo "$sc" | grep -o -m1 -E '/1[0-9]{6}/' | sed "s/\///g"`
			fi
		fi
	fi
	[ $DEBUG ] && echo "*** DEBUG: $0: bug: $bug" >&2
	if [ -z "$bug" ]; then
		continue
	fi
        bugId=`echo "$bug" | grep -o -i "[0-9]*" | sed "s/^0*//"`
	[ $DEBUG ] && echo "*** DEBUG: $0: bugId: $bugId" >&2
	if (( ${#bugId} < 7 )); then
		continue
	fi

	if ! grep -q "$scMd5 $bugId" "$datasetsPath"/bugs.dat; then
		echo "$scMd5 $bugId" >> "$datasetsPath"/bugs.dat
	fi
done < $scsFile

exit 0
