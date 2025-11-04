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
lbda_end   = 0.7e-6 -- say we compute at 1µm wavelength
lbda_start = 0.5e-6 -- say we compute at 1µm wavelength

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

-- Load S4
S = S4.NewSimulation()

-- Parameters
period = 0.66         -- lattice period (square lattice)
tri_side = 0.4       -- side length of equilateral triangle
dPhC = 0.5           -- thickness of patterned layer

-- Sample refl. index
n = 4.24056
k = 2.031190
epsxxr  = n*n - k*k -- 13.8566
epsxxi  = 2*n*k -- 17.2268
epsyyr  = epsxxr
epsyyi  = epsxxi

d_flake = 0.100 -- 250 nm
d_resist = 0.5  -- 2 microns

-- Triangular pattern
local r = tri_side / math.sqrt(3)
print("r is", r)
local vertices = {
    0,  r,
    -r*math.sin(math.pi/3), -r*0.5,
     r*math.sin(math.pi/3), -r*0.5
}
print("period = ", period)
print("tri_side = ", tri_side)

-- Fourier orders
orders = 10
-- Square lattice:
S:SetLattice({period,0}, {0,period})
-- Hexagon lattice:
-- Hexagonal lattice
S:SetLattice(
    {period, 0},
    {period/2, period*math.sqrt(3)/2}
)

S:SetNumG(2*orders+1)

-- Materials
S:AddMaterial("Silicon", {12.1,0}) 
S:AddMaterial("SiO2", {1.45,0}) 
S:AddMaterial("Resist", {1.626,0}) 
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("PerfMirror", {-1.0e10,0})
S:AddMaterial("PbTaSe2", {epsxxr, epsxxi}) -- isotropic version

-- Define layers
-- S:AddLayer("AirAbove", 0, "Vacuum")
-- S:AddLayer("PhC", dPhC, "SiO2")
-- S:AddLayer('ActiveSlab', d_flake, 'PbTaSe2')
-- S:AddLayer("Substrate", 0, "SiO2")

-- Structure definition
S:AddLayer('AirAbove',  -- layer name
           0,           -- thickness
           'Vacuum')    -- background material
S:AddLayer('PhC', d_resist, 'Resist')
S:SetLayerPatternPolygon("PhC", "Vacuum", {0, 0}, 0, vertices)
S:AddLayer('ActiveSlab', d_flake, 'PbTaSe2')
-- If on a SiO2 on Si wafer:
S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy

-- Circularly polarized excitation (RHCP)
theta = 0
phi = 0
S:SetExcitationPlanewave(
    {theta, phi},
    {1/math.sqrt(2), 0},       -- s-pol amplitude, phase 0
    {1/math.sqrt(2), 90}       -- p-pol amplitude, phase +90 deg
)

-- Linear:
-- S:SetExcitationPlanewave(
-- 	{theta,0}, -- incidence angles
-- 	{1,0}, -- s-polarization amplitude and phase (in degrees)
-- 	{0,0}) -- p-polarization amplitude and phase

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
    file:write(string.format("%.6f\t%.6f\t%.6f\n", freq, -backward, A))
	io.stdout:flush()
end

print("Generated filename:", filename)

file:close()

-- Define the Python script file name
local pythonScript = "morgan/plotdata.py"

-- Execute the Python script using os.execute
local command = "python3 " .. pythonScript .. " " .. filename
local status = os.execute(command)

-- Check the status of the execution
if status == true then
    print("Python script executed successfully.")
else
    print("Error executing Python script.")
end

