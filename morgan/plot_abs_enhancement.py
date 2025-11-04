import sys
import numpy as np
import matplotlib.pyplot as plt

def main(filename):
    # Load data, skipping the header row
    data = np.loadtxt(filename, skiprows=1)
    
    wl = data[:,0]          # wavelength [nm]
    A_flat = data[:,1]      # absorption flat
    A_pat = data[:,2]       # absorption patterned
    Enhancement = data[:,3] # A_pat / A_flat

    plt.figure(figsize=(8,5))
    plt.plot(wl, A_flat, label='Flat Refl', lw=2, ls='--')
    plt.plot(wl, A_pat, label='Patterned Refl', lw=2)
    plt.plot(wl, Enhancement, label='Patterned Refl/Flat Refl', lw=2, ls=':')
    
    plt.xlabel("Wavelength (nm)")
    # plt.ylabel("Absorption / Enhancement")
    plt.title("PbTaSe2 Flake: Absorption Enhancement")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plotdata2.py <filename>")
        sys.exit(1)
    main(sys.argv[1])
