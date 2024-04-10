import numpy as np
import matplotlib.pyplot as plt
import sys


# Function to read matrix with labels from file
def read_matrix_with_labels(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()
    
    # Extract labels and data
    labels = lines[0].strip().split('\t')[1:]
    data = []
    for line in lines[1:]:
        row = list(map(float, line.strip().split('\t')[1:]))
        data.append(row)
    
    return labels, data

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <filename>")
    else:
        filename = sys.argv[1]

# Read matrix with labels from file
x_labels, matrix_data = read_matrix_with_labels(filename)

# Convert data to numpy array for plotting
matrix_data_np = np.array(matrix_data)

# Plot heatmap
plt.figure(figsize=(8, 6))
plt.imshow(matrix_data_np, cmap='hot', interpolation='nearest')
plt.colorbar(label='Value')

# Set labels for x and y axes
plt.xticks(np.arange(len(x_labels)), x_labels)
plt.yticks(np.arange(len(x_labels)), x_labels)
plt.xlabel('Columns')
plt.ylabel('Rows')
plt.title('Matrix Heatmap')

plt.show()
