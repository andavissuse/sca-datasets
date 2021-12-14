#
# This script converts a pickle file to a csv file.
#
# Inputs: 1) path to *.pkl file
#         2) path to csv file to be written
#
# Output: *.csv file
#

from __future__ import print_function

import getopt
import sys
import pandas as pd

def usage():
    print("Usage: " + sys.argv[0] + " [-d(ebug)] pkl-file csv-file", file=sys.stderr)

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
    if not argv[arg_index_start + 1]:
        usage()
        sys.exit(2)
    pkl_file = argv[arg_index_start]
    csv_file = argv[arg_index_start + 1]

    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": pkl_file:", pkl_file, file=sys.stderr)
        print("*** DEBUG: " + sys.argv[0] + ": csv_file:", csv_file, file=sys.stderr)

    df_pkl = pd.read_pickle(pkl_file, 'gzip')
    df_dataset = df_pkl.astype({'000_md5sum':'str'})
    dataset_fobj = open(csv_file, 'w', newline='')
    df_dataset.to_csv(dataset_fobj, sep=' ', index=False)

if __name__ == "__main__":
    ret_val = main(sys.argv[1:])
    print(ret_val)
