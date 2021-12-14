#!/bin/sh

#
# This script reads the latest new.txt file to get supportconfigs.  For each
# supportconfig, it:
#
#	1) extracts all feature data from the supportconfig
#	2) for each feature, calls dataset_feature.py to update the feature dataset
#
# Inputs: None (uses sca-databuild.conf file for configuration)
#
# Result: Updated feature datasets in the datasets directory
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
scaBinPath="$SCA_BIN_PATH"
databuildBinPath="$SCA_DATASETS_BIN_PATH"
databuildTmpPath="$SCA_DATASETS_TMP_PATH"
datasetsPath="$SCA_DATASETS_RESULTS_PATH"
dataTypes="$SCA_DATASETS_ALL_DATATYPES"
[ $DEBUG ] && echo "*** DEBUG: $0: scaBinPath: $scaBinPath, databuildBinPath: $databuildBinPath, databuildTmpPath: $databuildTmpPath, datasetsPath: $datasetsPath, dataTypes: $dataTypes" >&2

# process new supportconfigs from all sources
scsFile="$databuildTmpPath/new-scs.txt"
scNum=0
while IFS= read -r sc; do
	[ $DEBUG ] && echo "*** DEBUG: $0: sc: $sc" >&2
	scNum=$(( scNum + 1 ))
	scMd5=`md5sum -b "$sc" | cut -d" " -f1`
	[ $DEBUG ] && echo "*** DEBUG: $0: scNum: $scNum, scMd5: $scMd5" >&2
	tmpDir=""
	for dataType in $dataTypes; do
		[ $DEBUG ] && echo "*** DEBUG: $0: dataType: $dataType" >&2
		# check if we have already processed this tarball
		if grep -q "$scMd5" "$datasetsPath"/"$dataType"*.pkl 2>/dev/null; then
               		[ $DEBUG ] && echo "*** DEBUG: $0: Supportconfig already processed, skipping..." >&2
			continue
		fi
		# process the supportconfig for this datatype
		if [ -z "$tmpDir" ]; then
			tmpDir=`mktemp -d --tmpdir="$databuildTmpPath"`
			tar -xf "$sc" -C "$tmpDir" --wildcards --no-anchored 'basic*' 'hardware*' 'messages*' 'modules*' 'rpm*' 'summary*' 'supportconfig*' 2>/dev/null
		fi
		basicEnvFile=`find $tmpDir -name basic-environment.txt`
		if [ -z "$basicEnvFile" ]; then
			[ $DEBUG ] && echo "*** DEBUG: $0: No basic-environment.txt file, skipping..." >&2
			break
		fi
		scDir=`dirname $basicEnvFile`
		[ $DEBUG ] && echo "*** DEBUG: $0: scDir: $scDir" >&2
		dataset="$datasetsPath/$dataType.pkl"
		[ $DEBUG ] && echo "*** DEBUG: $0: dataset: $dataset" >&2
		fScript="$scaBinPath/$dataType.sh"
		featuresFile="$tmpDir/$dataType.out"
		[ $DEBUG ] && echo "*** DEBUG: $0: fScript: $fScript, featuresFile: $featuresFile" >&2
		$fScript $scDir > $featuresFile
		[ $DEBUG ] && echo "*** DEBUG: $0: featuresFile $featuresFile created..." >&2
		if [ -s "$featuresFile" ]; then
			[ $DEBUG ] && echo "*** DEBUG: $0: Calling dataset.py $dataset $scMd5 $featuresFile" >&2
			result=`python3 $databuildBinPath/dataset_feature.py $dataset $scMd5 $featuresFile`
		fi
	done
	rm -rf $tmpDir
done < $scsFile

exit 0
