import csv
import os

# Function to modify the CSV file
def modify_csv(file_path):
    if not os.path.isfile(file_path):
        print("The provided file path does not exist.")
        return
    
    # Read the content of the CSV file
    with open(file_path, 'r', newline='') as file:
        rows = list(csv.reader(file))

    # Print rows before modification
    print("Before modification:")
    for row in rows:
        print(row)

    # Remove the last value from each row
    for row in rows:
        if row:
            row.pop()  # Remove the last value

    # Print rows after modification
    print("\nAfter modification:")
    for row in rows:
        print(row)

    # Write the modified content back to the CSV file
    with open(file_path, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerows(rows)
    
    print(f"\nThe last value from each row in {file_path} has been removed.")

# Print instructions
print("This script will remove the last value from each row of the specified CSV file.")
file_path = input("Please enter the path to the CSV file: ")

# Call the function to modify the CSV file
modify_csv(file_path)
