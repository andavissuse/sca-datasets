#
# This script converts a csv file to pickle format.
#
# Inputs: 1) path to csv file
#         2) path to *.pkl file to be written
#
# Output: pickle-format file
#

from __future__ import print_function

import getopt
import sys
import pandas as pd

def usage():
    print("Usage: " + sys.argv[0] + " [-d(ebug)] csv-file pkl-file", file=sys.stderr)

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
    csv_file = argv[arg_index_start]
    pkl_file = argv[arg_index_start + 1]

    if DEBUG == "TRUE":
        print("*** DEBUG: " + sys.argv[0] + ": csv_file:", csv_file, file=sys.stderr)
        print("*** DEBUG: " + sys.argv[0] + ": pkl_file:", pkl_file, file=sys.stderr)

    df_csv = pd.read_csv(csv_file, sep=" ", dtype={'000_md5sum':'str'})
    df_csv.to_pickle(pkl_file, 'gzip')

if __name__ == "__main__":
    ret_val = main(sys.argv[1:])
    print(ret_val)
