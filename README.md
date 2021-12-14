# sca-datasets
Project to build and provide datasets for the sca-L0 utility.

# Structure

## sca-datasets.conf file
Config file containing environment and other variables for use by scripts.

## rawdata.dvc.git file
Version of rawdata used to build datasets.

## bin directory
bash and python scripts to build datasets.  The dataset scripts extract features from supportconfigs that are associated with SRs, bugs, and hardware certifications.

## datasets directory
Built datasets.  Although the datasets can be built from the scripts, the built datasets are included here so that they can be copied directly from this github project into an sca-datasets package.

# Instructions

## Building/updating datasets
Prerequisites:
* rawdata (supportconfigs) in the locations specified by RAWDATA variables in sca-datasets.conf

Types of datasets:
* text files that map supportconfig md5sums to supportconfig features
* text files that map supportconfig md5sums to hardware certs, SRs, and bugs (SR and bug numbers provided as hash values to mask official SUSE IDs)
* SUSE-internal data: text files that map SR hash values to real SUSE SR numbers, bug hash values to real SUSE bug numbers, and md5sums to supportconfig filenames

To update ALL datasets with new supportconfigs in the rawdata area:
* Run `datasets-update.sh`.  This will:
  * Invoke `datasets-features.sh` to build binary-valued datasets.  This will:
    * Find each new supportconfig
    * Get the supportconfig md5sum
    * Uncompress the supportconfig
    * Run sca-L0 scripts (from sca-L0 github project) to extract features
    * Call `dataset.py` to vectorize the features and add the vector to the dataset file (adds new columns for new features)
  * Invoke `datasets-srs.sh` to build SR datasets.  This will:
     * Search each new rawdata supportconfig path to map the supportconfig to an SR
     * Add the supportconfig md5sum and SR number hash to the srs.dat file
     * Add the hash and real SR number to the internal srs-hash.dat file
  * Invoke `datasets-bugs.sh` to build bugs datasets.  This will:
     * Search each new rawdata supportconfig path to map the supportconfig to a bug
     * Add the supportconfig md5sum and bug number hash to the bugs.dat file
     * Add the hash and real bug number to the internal bugs-hash.dat file
  * Invoke `datasets-certs.sh` to build certs dataset.  This will:
     * Search rawdata to associate supportconfigs with YES bulletin numbers
  * Invoke `datasets-sc-names.sh` to create internal sc-names.dat file mapping md5sums to supportconfig filenames
  * gpg-encrypt the srs-hash.dat, bugs-hash.dat, and sc-names.dat files with a user-entered token
