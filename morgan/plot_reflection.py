import sys, numpy as np, matplotlib.pyplot as plt
data = np.loadtxt(sys.argv[1], skiprows=1)
wl = data[:,0]; Rp = data[:,1]; Rf = data[:,2]
plt.plot(wl,Rp,label="Patterned",lw=2)
plt.plot(wl,Rf,label="Flat",lw=2,ls="--")
plt.xlabel("Wavelength (nm)")
plt.ylabel("Reflection")
plt.legend(); plt.grid(True,alpha=0.3)
plt.title("Reflection spectra (PbTaSe2)")
plt.tight_layout(); plt.show()
