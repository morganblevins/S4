"""
This Python script reads x-y data from a text file and plots it using Matplotlib.

The script expects a text file containing x-y data as input. Each line of the file should contain an x value 
followed by one or more y values, separated by spaces. The script dynamically handles an arbitrary number of 
y values for each x value, allowing for flexible plotting of multiple data series.

Usage:
    python plotdata.py <filename>

Arguments:
    <filename>: Name of the text file containing the x-y data.

Functions:
    read_data_from_file(filename):
        Reads x-y data from the specified text file and returns a dictionary containing x and y data.

    plot_data_from_file(filename):
        Plots the x-y data read from the specified text file using Matplotlib.

File Structure:
    - The script consists of two main functions: read_data_from_file and plot_data_from_file.
    - The read_data_from_file function reads data from the file and returns a dictionary containing x and y data.
    - The plot_data_from_file function plots the x-y data using Matplotlib.

Error Handling:
    - The script handles errors gracefully, including FileNotFoundError if the specified file does not exist.

Dependencies:
    - Matplotlib: A plotting library for Python. Install it using pip if not already installed: pip install matplotlib.
"""

import sys
import matplotlib.pyplot as plt

def read_data_from_file(filename):
    """
    Read x-y data from a text file.

    Args:
    filename (str): Name of the text file containing the data.

    Returns:
    dict: A dictionary containing x and y data read from the file.
    """
    data = {'x': [], 'y': []}

    try:
        with open(filename, 'r') as file:
            max_y_arrays = 0
            for line in file:
                values = line.split()
                x = 1/float(values[0])
                data['x'].append(x)
                for i, y in enumerate(values[1:], 1):
                    y_value = float(y)
                    if i > max_y_arrays:
                        max_y_arrays = i
                        data['y'].append([])
                    data['y'][i-1].append(y_value)
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")

    return data


def plot_data_from_file(filename):
    # Read data from file
    data = read_data_from_file(filename)
    
    # Debug: Print the lengths of x and y arrays
    print("Length of x array:", len(data['x']))
    print("Lengths of y arrays:", [len(y) for y in data['y']])
    
    # Plot the data
    for i, y_values in enumerate(data['y']):
        plt.plot(data['x'], y_values, marker='o', linestyle='-', label=f'y{i+1}')

    plt.title('X-Y Data Plot')
    # plt.xlabel('Frequency (um)^-1')
    plt.xlabel('Wavelength (um)')
    # plt.xlabel('m')
    plt.ylabel('Reflection / Transmissions')
    plt.legend()
    # plt.grid(True)
    plt.show()


# if __name__ == "__main__":
#     filename = "/home/mo/S4/morgan/data.txt"  # Specify the name of your text file here
#     plot_data_from_file(filename)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <filename>")
    else:
        filename = sys.argv[1]
        plot_data_from_file(filename)