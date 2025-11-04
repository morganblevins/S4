-- Design of PC for enhances absorption into a PbTaSe2 flake for photocurrent generation
-- PbTaSe2 parameters via 
-- "DFT based investigation of bulk mechanical, thermophysical and optoelectronic 
-- properties of PbTaSe2 topological semimetal" by  A.S.M. Muhasin Reza, S.H. Naqib

function generate_filename()
    -- Get the current date and time as a formatted string
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")

    -- Split the formatted string into date and time components
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")

    -- Construct the filename
    local filename = "PbTaSe2_PC_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

    return filename
end

function abs(x)
    if x < 0 then
        return -x
    else
        return x
    end
end

c_const = 3e8
unit = 1e-6
lbda_end   = 2.000e-6 -- say we compute at 1µm wavelength
lbda_start = 0.400e-6 -- say we compute at 1µm wavelength

-- lbda_end   = 8e-6 -- wavelength in [m]
-- lbda_start = 2e-6 -- wavelength in [m]

f_start = c_const/lbda_end -- ferquency in SI units
f_end = c_const/lbda_start -- ferquency in SI units
f0_start = f_start/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
f0_end = f_end/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
print (f0_start .. '\t' .. f0_end )


-- TaIrTe4 parameters as measured by Vivian on ellipsometer
-- At 635 nm:
-- n = 4.24056
-- k = 2.031190
n = 4.24056
k = 2.031190
epsxxr  = n*n - k*k -- 13.8566
epsxxi  = 2*n*k -- 17.2268
epsyyr  = epsxxr
epsyyi  = epsxxi
print (epsxxr .. '\t' .. epsxxi )

S = S4.NewSimulation()

-- Optimized for 500 nm resist:
a = 0.250       -- Pitch 520 nm
r = 0.025      -- 0.35 a
d_disk = 0.03

d_flake = 0.100 -- 100 nm

theta= 0       -- incident angle

S:SetLattice({a,0}, {0,a})
S:SetNumG(100)

n_si = 3.847
k_si = 0.016
eps_si_r  = n_si*n_si - k_si*k_si
eps_si_i  = 2*n_si*k_si
print (eps_si_r .. '\t' .. eps_si_i )
S:AddMaterial("Silicon", {eps_si_r,eps_si_i}) 
n_sio2 = 1.4585
eps_sio2 = n_sio2*n_sio2
S:AddMaterial("SiO2", {eps_sio2,0}) 
n_resist = 1.63447 -- @ 633nm via https://www.microchemicals.com/dokumente/datenblaetter/tds/merck/en/tds_az_1500_series.pdf
eps_resist = n_resist*n_resist
S:AddMaterial("Resist", {eps_resist,0}) 
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("PerfMirror", {-1.0e10,0})
S:AddMaterial("PbTaSe2", {epsxxr, epsxxi}) -- isotropic version
n_au = 3.847 -- 630 nm
k_au = 0.016 -- 630 nm
eps_au_r  = n_au*n_au - k_au*k_au
eps_au_i  = 2*n_au*k_au
S:AddMaterial("Au", {eps_au_r,eps_au_i})

-- Structure definition
S:AddLayer('AirAbove',  -- layer name
           0,           -- thickness
           'Vacuum')    -- background 
S:AddLayer('PhC', d_disk, 'Vacuum')
S:SetLayerPatternCircle('PhC',   -- which layer to alter
                         'Au', -- material in circle
 	                    {0,0},    -- center
 	                    r)      -- radius
S:AddLayer('ActiveSlab', d_flake, 'PbTaSe2')
S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy

S:SetExcitationPlanewave(
	{theta,0}, -- incidence angles
	{0,0}, -- s-polarization amplitude and phase (in degrees)
	{1,0}) -- p-polarization amplitude and phase

--auUsePolarizationDecomposition()
-- file = "PbTaSe2_data.txt"

-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

-- Write the header specifying the columns
-- file:write("freq\tforward\tbackward\n")

-- for freq=0.3,3,0.05 do
for freq=f0_start,f0_end,0.01 do
    S:SetFrequency(freq)
	forward,backward = S:GetPoyntingFlux('AirAbove', 0)
    -- fw1, bw1 = S:GetPoyntingFlux('ActiveSlab', 0)
    -- fw1, bw1 = S:GetPoyntingFlux('PhC', 0)
    -- fw1, bw1 = S:GetPoyntingFlux('PhC', 0)
    fw1, bw1 = S:GetPoyntingFlux('ActiveSlab', 0)
    fw2, bw2 = S:GetPoyntingFlux('ActiveSlab', d_flake)
    -- See how much is absorbed by PhC:
    -- fw1, bw1 = S:GetPoyntingFlux('PhC', 0)
    -- fw2, bw2 = S:GetPoyntingFlux('PhC', d_resist)
    -- See how much is absorbed by SiO2:
    -- fw1, bw1 = S:GetPoyntingFlux('SiO2', 0)
    -- fw2, bw2 = S:GetPoyntingFlux('SiO2', 0.3)
    A = abs((fw2-fw1-(bw1-bw2))/forward) -- Absorption
	-- print (freq .. '\t' .. backward .. '\t' .. A)
    local wavelength_nm = unit*1e9 / freq   -- λ [nm] = (1 µm in nm) / (a/λ) = 1000 / f0
    file:write(string.format("%.1f\t%.6f\t%.6f\n", wavelength_nm, -backward, A))
    -- file:write(string.format("%.6f\t%.6f\t%.6f\n", freq, -backward, A))
	io.stdout:flush()
end

print("Generated filename:", filename)

file:close()

-- Define the Python script file name
local pythonScript = "morgan/plotdata2.py"

-- Execute the Python script using os.execute
local command = "python3 " .. pythonScript .. " " .. filename
local status = os.execute(command)

-- Check the status of the execution
if status == true then
    print("Python script executed successfully.")
else
    print("Error executing Python script.")
end

