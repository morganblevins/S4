# This Python script allows users to input x-y data from the terminal and plots it using Matplotlib. 
# The data input format is flexible, accepting an x-value followed by an arbitrary number of y-values, 
# each separated by spaces. Each set of y-values (y1, y2, etc.) is stored separately, allowing them 
# to be plotted as individual series on the same graph.
# written using ChatGPT 3.5 April 2024

import matplotlib.pyplot as plt

def plot_data_from_terminal():
    # Initialize a dictionary to store lists of y values corresponding to each x value
    data = {}

    try:
        # Continuously read input from the terminal until an empty line is entered
        while True:
            # Read input from the terminal
            line = input("Enter x, y1, y2, y3, ... values (or press Enter to finish): ").strip()
            if not line:
                break  # Exit loop if an empty line is entered

            # Split the input line into x and y values
            values = line.split()
            x = float(values[0])
            for i, y in enumerate(values[1:]):
                y_values = float(y)
                if i not in data:
                    data[i] = {'x': [], 'y': []}
                data[i]['x'].append(x)
                data[i]['y'].append(y_values)
            
    except KeyboardInterrupt:
        print("\nKeyboard interrupt detected. Plotting data...")

    # Plot the data
    for i in range(len(data)):
        plt.plot(data[i]['x'], data[i]['y'], marker='o', linestyle='-', label=f'y{i+1}')

    plt.title('X-Y Data Plot')
    plt.xlabel('X')
    plt.ylabel('Y')
    plt.legend()
    # plt.grid(True)
    plt.show()

if __name__ == "__main__":
    plot_data_from_terminal()


