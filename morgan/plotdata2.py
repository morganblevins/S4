# morgan/plotdata.py
import sys
import numpy as np
import matplotlib.pyplot as plt

def main(filename):
    # Load the tab-separated file (freq, backward, absorption)
    data = np.loadtxt(filename)

    wavelength = data[:,0]
    R = data[:,1]  # reflection (backward flux)
    A = data[:,2]  # absorption

    plt.figure(figsize=(6,4), dpi=120)

    # Plot absorption
    plt.plot(wavelength, A, label="Absorption", linewidth=2.0)
    plt.plot(wavelength, R, label="Reflection", linestyle="--", linewidth=1.5)

    # Style
    plt.xlabel("Frequency (1/µm)", fontsize=12)
    plt.ylabel("Fraction", fontsize=12)
    plt.title("Absorption", fontsize=13)
    plt.legend(frameon=False)
    plt.grid(True, alpha=0.3)
    # plt.xlim(wavelength.min(), wavelength.max())
    plt.ylim(0, 1.05)

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plotdata.py <datafile>")
    else:
        main(sys.argv[1])
