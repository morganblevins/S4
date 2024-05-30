import numpy as np
import matplotlib.pyplot as plt
import sys

# Function to read matrix with labels from file
def read_matrix_with_labels(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()
    
    # Extract labels and data
    y_labels = lines[0].strip().split('\t')[0:]
    x_labels = []
    data = []
    for line in lines[1:]:
        parts = line.strip().split('\t')
        x_labels.append(parts[0])
        row = list(map(float, parts[1:]))
        data.append(row)
    
    return x_labels, y_labels, data

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <filename>")
        sys.exit(1)
    else:
        filename = sys.argv[1]

    # Read matrix with labels from file
    x_labels, y_labels, matrix_data = read_matrix_with_labels(filename)

    # Convert data to numpy array for plotting
    matrix_data_np = np.array(matrix_data)

    # Find the maximum value and its indices
    max_val = np.max(matrix_data_np)
    max_idx = np.unravel_index(np.argmax(matrix_data_np, axis=None), matrix_data_np.shape)
    max_a = x_labels[max_idx[0]]
    max_r_factor = y_labels[max_idx[1]]

    print(f"Maximum A: {max_val}")
    print(f"Corresponding a: {max_a}")
    print(f"Corresponding r_factor: {max_r_factor}")

    # Plot heatmap
    plt.figure(figsize=(10, 8))
    plt.imshow(matrix_data_np, cmap='viridis', aspect='auto', origin='lower')
    plt.colorbar(label='Integrated Absorption [a.u.]')

    # Set labels for x and y axes
    plt.xticks(np.arange(len(y_labels)), y_labels, rotation=90)
    plt.yticks(np.arange(len(x_labels)), x_labels)
    plt.xlabel('r_factor')
    plt.ylabel('a (lattice parameter)')
    plt.title('Absorption Intensity Heatmap')

    # Annotate the maximum value
    plt.annotate(f'Max A\n(a={max_a}, r_factor={max_r_factor})', 
                 xy=(max_idx[1], max_idx[0]), 
                 xytext=(max_idx[1], max_idx[0] + 0.5),
                 arrowprops=dict(facecolor='white', shrink=0.05),
                 fontsize=12, color='white', bbox=dict(facecolor='black', alpha=0.5))

    plt.tight_layout()
    plt.show()
