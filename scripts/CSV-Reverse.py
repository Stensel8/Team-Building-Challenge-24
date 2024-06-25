import csv
import os

# Function to reverse the content of a CSV file
def reverse_csv(input_file, output_file):
    if not os.path.isfile(input_file):
        print("The provided input file path does not exist.")
        return
    
    # Read the content of the CSV file
    with open(input_file, 'r', newline='') as file:
        rows = list(csv.reader(file))

    # Reverse the rows
    reversed_rows = rows[::-1]

    # Write the reversed content to a new CSV file
    with open(output_file, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerows(reversed_rows)
    
    print(f"The content of {input_file} has been reversed and written to {output_file}.")

# Print instructions
print("This script will reverse the content of the specified CSV file.")

# Prompt the user to enter the input and output file paths
input_file = input("Please enter the path to the input CSV file: ")
output_file = input("Please enter the path to the output CSV file: ")

# Call the function to reverse the CSV file
reverse_csv(input_file, output_file)
