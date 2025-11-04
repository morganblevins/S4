import sys
import numpy as np
import matplotlib.pyplot as plt

if len(sys.argv) < 2:
    print("Usage: python3 plot_enhancement.py <datafile>")
    sys.exit(1)

data = np.loadtxt(sys.argv[1], skiprows=1)
wl_nm = data[:,0]
enh   = data[:,1]

plt.figure()
plt.plot(wl_nm, enh, linewidth=2)
plt.xlabel("Wavelength (nm)")
plt.ylabel("Absorption enhancement (patterned / flat)")
plt.title("PbTaSe2 absorption enhancement vs. wavelength")
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
