# sca-datasets
Project to build/update datasets from SUSE supportconfig data.  These datasets are used by the sca supportconfig analysis utility (https://github.com/andavissuse/sca).

Binary-valued datasets are stored in pickle format (https://docs.python.org/3/library/pickle.html).

# Structure

## sca-datasets.conf file
Config file containing environment variables for use by scripts.

## rawdata.dvc.git file
Version of rawdata used to build datasets.

## bin directory
bash and python scripts to build datasets.

## datasets directory
Built datasets.  Although the datasets can be built from the scripts, the built datasets are included here so that they can be copied directly from this github project into an sca-datasets package.

# Instructions

## Building/updating datasets
Prerequisites:
* rawdata (supportconfigs) in the locations specified by RAWDATA variables in sca-datasets.conf

To update ALL datasets with new supportconfigs in the rawdata area:
* Run `datasets-update.sh`.  This will:
  * Invoke `datasets-features.sh` to update binary-valued datasets.  For each supportconfig, this will:
    * Uncompress the supportconfig
    * Run supportconfig extraction scripts (from sca github project) to extract all features
    * For each type of binary dataset, call `dataset.py`.  This will:
      * Vectorize the relevant feature data (using one-hot encoding)
      * Add the supportconfig md5sum and vector to the dataset file.  As new feature values are found, additional vector dimensions will be added and existing vectors will be modified to contain `0` values for the new dimensions.
  * Invoke `datasets-srs.sh` to update the SR dataset.  For each supportconfig, this will:
     * Search the supportconfig path for an SR number
     * Add the supportconfig md5sum and SR number to the srs.dat file
  * Invoke `datasets-bugs.sh` to update the bugs dataset.  This will:
     * Search the supportconfig path for a bug number
     * Add the supportconfig md5sum and bug number to the bugs.dat file
  * Invoke `datasets-certs.sh` to build the certs dataset.  This will:
     * Search the supportconfig path for a certification submission number
     * Search the rawdata cert-subs area to find the YES bulletin number associated with submission number
     * Add the supportconfig md5sum and YES bulletin number to the certs.dat file
