#!/bin/sh

#
# This script reads the latest new.txt file to get supportconfigs.  For each
# supportconfig, it:
#
#	1) searches the cert submissions path to find corresponding
#	   cert bulletin(s)
#	2) writes the supportconfig md5sum and bulletin number to the
#	   certs.dat file in the datasets area
#
# Inputs: None (uses sca-datasets.conf file for configuration)
#
# Outputs/Results:  Updated certs.dat file in the datasets directory
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
certScsDir="$SCA_DATASETS_RAWDATA_CERT_SCS_DIR"
certSubsPath="$SCA_DATASETS_RAWDATA_YES_SUBS_PATH"
datasetsPath="$SCA_DATASETS_RESULTS_PATH"
[ $DEBUG ] && echo "*** DEBUG: $0: datasetsTmpPath: $datasetsTmpPath, certScsDir: $certScsDir, certSubsPath: $certSubsPath, datasetsPath: $datasetsPath" >&2

# create list of new supportconfigs that could be related to certs
cat "$datasetsTmpPath/new-scs.txt" | grep "$certScsDir" >> $datasetsTmpPath/new-cert-scs.txt
scsFile="$datasetsTmpPath/new-cert-scs.txt"
if [ ! -s "$scsFile" ]; then
	[ $DEBUG ] && echo "*** DEBUG: $0: No new supportconfigs to process, exiting..."
        exit 0
fi

# process new supportconfigs
if [ ! -f "$datasetsPath"/certs.dat ]; then
	echo "000_md5sum Id" > "$datasetsPath"/certs.dat
fi
scNum=0
while IFS= read -r sc; do
	[ $DEBUG ] && echo "*** DEBUG: $0: sc: $sc" >&2
	scNum=$(( scNum + 1 ))
        scMd5=`md5sum -b $sc | cut -d" " -f1`
        [ $DEBUG ] && echo "*** DEBUG: $0: scNum: $scNum, scMd5: $scMd5" >&2
        if [ -z "$scMd5" ] || grep -q "$scMd5" "$datasetsPath"/certs.dat; then
                continue
        fi
	zipIndex=`basename $(dirname $sc)`
	[ $DEBUG ] && echo "*** DEBUG: $0: zipIndex: $zipIndex" >&2
	if [ -z "$zipIndex" ]; then
		continue
	fi
	subFile=`grep "fileID=$zipIndex" $(ls -tr "$certSubsPath"/*) | cut -d":" -f1`
	[ $DEBUG ] && echo "*** DEBUG: $0: subFile: $subFile" >&2
	if [ -z "$subFile" ]; then
		continue
	fi
	bulletinId=`grep -E "<B><FONT SIZE=\"2\" COLOR=\"000000\">[0-9]{6}</FONT></B></TD>" "$subFile" | cut -d">" -f3 | cut -d"<" -f1`
	[ $DEBUG ] && echo "*** DEBUG: $0: bulletinId: $bulletinId" >&2
	if [ -z "$bulletinId" ]; then
		continue
	fi
	echo "$scMd5 $bulletinId" >> "$datasetsPath"/certs.dat
done < $scsFile

exit 0
