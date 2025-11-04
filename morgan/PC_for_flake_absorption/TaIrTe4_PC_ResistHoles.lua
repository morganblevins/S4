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
    local filename = "TaIrTe4_Resist_PC_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

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
lbda_end   = 0.730e-6 -- wavelength in [m]
lbda_start = 0.560e-6 -- wavelength in [m]

-- lbda_end   = 12.000e-6 -- wavelength in [m]
-- lbda_start = 8.000e-6 -- wavelength in [m]

-- lbda_end   = 8e-6 -- wavelength in [m]
-- lbda_start = 2e-6 -- wavelength in [m]

f_start = c_const/lbda_end -- ferquency in SI units
f_end = c_const/lbda_start -- ferquency in SI units
f0_start = f_start/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
f0_end = f_end/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
print (f0_start .. '\t' .. f0_end )


-- TaIrTe4 parameters as measured by Vivian on ellipsometer
n = 4.24056     -- At 635 nm
k = 2.031190    -- At 635 nm    
epsxxr  = n*n - k*k -- 13.8566
epsxxi  = 2*n*k     -- 17.2268
print (epsxxr .. '\t' .. epsxxi )

-- Silicon
n_si = 3.847 -- @ 633 nm
k_si = 0.016 -- @ 633 nm
-- n_si = 3.4      -- @ 10um
-- k_si = 0.0001   -- @ 10um
eps_si_r  = n_si*n_si - k_si*k_si
eps_si_i  = 2*n_si*k_si

--SiO2
n_sio2 = 1.4585   -- @ 633 nm
k_sio2 = 0.0       -- @ 633nm 
-- n_sio2 = 2.5 -- @ 10um 
-- k_sio2 = 0.36-- @ 10um 
eps_sio2_r = n_sio2*n_sio2  - k_sio2*k_sio2
eps_sio2_i  = 2*n_sio2*k_sio2

-- Resist
n_resist = 1.63447 -- @ 633nm via https://www.microchemicals.com/dokumente/datenblaetter/tds/merck/en/tds_az_1500_series.pdf
k_resist = 0.0
-- n_resist = 1.3  -- @ 10 um via doi:10.1364/ome.8.002017
-- k_resist = 0.01 -- @ 10 um via doi:10.1364/ome.8.002017
eps_resist_r = n_resist*n_resist- k_resist*k_resist
eps_resist_i  = 2*n_resist*k_resist

S = S4.NewSimulation()

-- Optimized for 500 nm resist:
a = 0.620       -- Pitch 520 nm
r = 0.29*a      -- 0.35 a
d_resist = 0.3

a = 0.600       -- Pitch 520 nm
r = 0.2500      -- 0.35 a
d_resist = 0.475

-- Optimized for 300 nm resist:
-- a = 0.63       -- Pitch 600 nm
-- r = 0.29*a      -- 0.35 a
-- d_resist = 0.3  -- 2 microns

d_flake = 0.100 -- 100 nm

theta= 0       -- incident angle

S:SetLattice({a,0}, {0,a})
S:SetNumG(100)
S:AddMaterial("Silicon", {eps_si_r,eps_si_i}) 
S:AddMaterial("SiO2", {eps_sio2_r,eps_sio2_i}) 
S:AddMaterial("Resist", {eps_resist_r,eps_resist_i}) 
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("PerfMirror", {-1.0e10,0})
S:AddMaterial("PbTaSe2", {epsxxr, epsxxi}) -- isotropic version

-- Structure definition
S:AddLayer('AirAbove',  -- layer name
           0,           -- thickness
           'Vacuum')    -- background 
S:AddLayer('PhC', d_resist, 'Resist')
S:SetLayerPatternCircle('PhC',   -- which layer to alter
                        'Vacuum', -- material in circle
	                    {0,0},    -- center
	                    r)      -- radius
-- S:AddLayer('PhC', d_resist, 'Vacuum')
-- S:SetLayerPatternCircle('PhC',   -- which layer to alter
--                         'Resist', -- material in circle
-- 	                    {0,0},    -- center
-- 	                    r)      -- radius
S:AddLayer('ActiveSlab', d_flake, 'PbTaSe2')
-- S:AddLayer('ActiveSlab', d_flake, 'Resist')
-- If on a SiO2 on Si wafer:
S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy

-- If on a perfect mirror
-- S:AddLayer('MirrorBelow', 0, 'PerfMirror')
-- PC of holes in Silicon under the PbTaSe2 flake
-- S:AddLayer('PhC', d_hole, 'Silicon')
-- S:SetLayerPatternCircle('PhC',   -- which layer to alter
--                         'Vacuum', -- material in circle
-- 	                    {0,0},    -- center
-- 	                    r)      -- radius

S:SetExcitationPlanewave(
	{theta,0}, -- incidence angles
	{0,0}, -- s-polarization amplitude and phase (in degrees)
	{1,0}) -- p-polarization amplitude and phase

--S:UsePolarizationDecomposition()
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

