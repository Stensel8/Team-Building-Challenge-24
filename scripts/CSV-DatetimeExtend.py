import csv
import os

def insert_time_in_dates(input_file, output_file):
    # Check if the input file exists
    if not os.path.isfile(input_file):
        print("The provided input file path does not exist.")
        return
    
    # Read the content of the CSV file
    with open(input_file, 'r', newline='') as file:
        rows = list(csv.reader(file))

    # Process rows to insert "00:00:00" after dates
    for i in range(2, len(rows)):  # Skip the first two header rows
        if len(rows[i]) > 1:
            rows[i][1] = rows[i][1] + " 00:00:00"
        else:
            print(f"Skipping row {i} as it does not have enough columns: {rows[i]}")

    # Write the modified content to a new CSV file
    with open(output_file, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerows(rows)
    
    print(f"The dates in {input_file} have been modified and written to {output_file}.")

# Print instructions
print("This script will insert '00:00:00' after the dates in the specified CSV file, skipping the first two header rows.")

# Prompt the user to enter the input and output file paths
input_file = input("Please enter the path to the input CSV file: ")
output_file = input("Please enter the path to the output CSV file: ")

# Call the function to insert time in dates
insert_time_in_dates(input_file, output_file)
