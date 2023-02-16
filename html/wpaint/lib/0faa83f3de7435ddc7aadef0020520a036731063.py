#-*- coding: utf-8 -*-
from glob import glob
import os
import pandas as pd
import sys

"""
    A simple script to concatenate all csv files in a folder into one file.
    Look to the bottom of this file to set the names of the input folder, 
    output folder, output file, etc.

    This file uses spaces for indentation, not tabs.

    daniel.riggs1@gmail.com, September 2018
"""

def concat_csv_files(input_dir, output_dir, output_file='all_data.csv', 
                     input_separator=',', output_separator=','):

    # Going to make sure the input and output folders exist before doing anything
    dir_not_found_message = 'The {} folder "{}" could not be found. The current directory is {}'
    if not os.path.exists(input_dir):
        raise OSError(dir_not_found_message.format('input', input_dir, os.getcwd()))
    if not os.path.exists(output_dir):
        raise OSError(dir_not_found_message.format('ouptut', output_dir, os.getcwd()))

    # Ask if we want to erase an existing output file
    output_path = os.path.join(output_dir, output_file)
    if os.path.exists(output_path):
        try:
            # I'm trying to make this script python2 vs python3 agnostic
            global input
            input = raw_input
        except NameError:
            pass

        overwrite = input('The output_file already exists. Overwrite? [y/n]')
        if overwrite != 'y':
            sys.exit(0)

    # Now the real work starts
    # Initialize an empty pandas dataframe
    all_data = pd.DataFrame()
    # Loop through all files in the input_dir with a csv extension
    for f in glob(os.path.join(input_dir, "*.csv")):
 
        # Create a data frame from the file
        df = pd.read_csv(f, sep=input_separator)

        # Normally, you would just do this on normal python sequence objects:
        #     >>> all_data.append(df, ignore_index=True)
        #
        # But for reasons I don't feel like googling, pandas DataFrames
        # are different. If you don't do it this way, the columns are 
        # re-copied every time. There's probably a better way to do this.
        all_data = all_data.append(df, ignore_index=True)
    
    all_data.to_csv(output_path, output_separator)

    print('Files combined to: "{}"'.format(output_path))


if __name__ == '__main__':

    # This uses a relative path: The script will look for a folder
    # named 'input_files' in the same folder as this python file.
    input_dir = os.path.join('input_files')
    output_dir = os.path.join('output_files')
    output_file = 'my_big_file.csv'

    concat_csv_files(input_dir, output_dir, output_file)
