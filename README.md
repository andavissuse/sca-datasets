# sca-datasets
Project to build/update datasets from SUSE supportconfig data.  These datasets are used by the sca supportconfig analysis utility (https://github.com/andavissuse/sca).

Each dataset corresponds to a pandas dataframe containing a header row and one or more data rows.  Each data row contains a supportconfig md5sum and binary values corresponding to one-hot encoding of specific data in the supportconfig.

Binary-valued datasets are stored in pickle format (https://docs.python.org/3/library/pickle.html).  Scripts are provided to view the data in pickle-formatted dataset and to transform datasets between csv and pickle formats.

# Structure

## sca-datasets.conf file
Config file containing environment variables for use by scripts.

## bin directory
bash and python scripts to build datasets.

# Instructions

## Building/updating datasets
Prerequisites:
* Text file containing paths to one or more supportconfigs

To build/update all the datasets with new supportconfigs:
* Run `datasets-features.sh`.  For each supportconfig, this will:
    * Uncompress the supportconfig
    * Run supportconfig extraction scripts from sca github project (https://github.com/andavissuse/sca) to extract info from the supportconfig 
    * Call `dataset.py` for each type of dataset.  Each invocation of `dataset.py` will:
      * Vectorize the relevant data (using one-hot encoding)
      * Add the supportconfig md5sum and vector to the dataset file.  As new feature values are found, additional vector dimensions will be added and existing vectors will be modified to contain `0` values for the new dimensions.
