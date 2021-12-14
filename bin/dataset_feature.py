#
# This script updates a dataset from a supportconfig
#
# Inputs: 1) dataset file
#         2) index value (md5sum of supportconfig tarball)
#         3) features file
#
# Output: New or updated dataset file
#

from __future__ import print_function

import sys
import os
import getopt
import subprocess
import pandas as pd

def usage():
    print("Usage: " + sys.argv[0] + " [-d(ebug)] dataset-file supportconfig-md5sum features-file", file=sys.stderr)

def main(argv):
    arg_index_start = 0
    DEBUG = "FALSE"
    try:
        opts, args = getopt.getopt(argv, 'd', ['debug'])
        if not args:
            usage()
            sys.exit(2)
    except getopt.GetoptError as err:
        usage()
        sys.exit(2)

    for opt, arg in opts:
        if opt in ('-d'):
            DEBUG = "TRUE"
            arg_index_start = 1

    # arguments
    if not argv[arg_index_start + 2]:
        usage()
        sys.exit(2)
    dataset_file = argv[arg_index_start]
    sc_md5 = argv[arg_index_start + 1]
    features_file = argv[arg_index_start + 2]

    # get dataset from disk
    if os.path.exists(dataset_file):
        df_dataset = pd.read_pickle(dataset_file, 'gzip')
        df_dataset.astype({"000_md5sum":'str'})
    else:
        df_dataset = pd.DataFrame()
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": df_dataset:", df_dataset, file=sys.stderr)
        print("*** DEBUG: " + sys.argv[0] + ": df_dataset shape:", df_dataset.shape, file=sys.stderr)

    # get features
    ff_object = open(features_file, "r")
    features = ff_object.read()
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": features:", features, file=sys.stderr)

    # build sc dataframe
    sc_cols = ['000_md5sum'] + features.split()
    sc_data = [sc_md5] + [1] * (len(sc_cols) - 1)
    df_sc = pd.DataFrame([sc_data], columns=sc_cols)
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": df_sc:", df_sc, file=sys.stderr)

    # add or replace vector into/in dataset
    df_appended = df_dataset.append(df_sc, sort=False)
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": df_appended:", df_appended, file=sys.stderr)
    df_dedup = df_appended.drop_duplicates(subset=['000_md5sum'], keep='last').fillna(0)
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": df_dedup:", df_dedup, file=sys.stderr)
    df_sc_md5 = df_dedup[['000_md5sum']]
    df_data = df_dedup.drop(columns=['000_md5sum'])
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": df_sc_md5:", df_sc_md5, file=sys.stderr)
        print("*** DEBUG: " + sys.argv[0] + ": df_data:", df_data, file=sys.stderr)
    df_data_ints = df_data.astype('int64')
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": df_data_ints:", df_data_ints, file=sys.stderr)
    df_new = pd.concat([df_sc_md5, df_data_ints], axis=1)
    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": df_new:", df_new, file=sys.stderr)
    df_new_sorted = df_new.sort_index(axis=1)
    first_col = df_new_sorted.pop("000_md5sum")
    df_new_sorted.insert(0, "000_md5sum", first_col)
    num_cols = len(df_new_sorted.columns)

    # write updated dataset to disk
#    dataset_fobj = open(dataset_file, 'w', newline='')
#    df_new_sorted.reset_index(inplace=True)
    df_new_sorted.to_pickle(dataset_file, 'gzip')

if __name__ == "__main__":
    main(sys.argv[1:])
