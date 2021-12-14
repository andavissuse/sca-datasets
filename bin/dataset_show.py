#
# This script reads a pickle file and prints the dataframe.
#
# Inputs: 1) path to *.pkl file
#
# Output: dataframe
#

from __future__ import print_function

import getopt
import sys
import pandas as pd

def usage():
    print("Usage: " + sys.argv[0] + " [-d(ebug)] pkl-file", file=sys.stderr)

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
    if not argv[arg_index_start]:
        usage()
        sys.exit(2)
    pkl_file = argv[arg_index_start]

    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": pkl_file:", pkl_file, file=sys.stderr)

    df_pkl = pd.read_pickle(pkl_file, 'gzip')
#    df_pkl.drop(columns='level_0', inplace=True)
    df_dataset = df_pkl.astype({'000_md5sum':'str'})
    print(df_dataset)

if __name__ == "__main__":
    ret_val = main(sys.argv[1:])
    print(ret_val)
