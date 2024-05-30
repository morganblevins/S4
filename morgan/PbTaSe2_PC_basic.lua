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
lbda_end   = 0.8e-6 -- say we compute at 1µm wavelength
lbda_start = 0.4e-6 -- say we compute at 1µm wavelength
f_start = c_const/lbda_end -- ferquency in SI units
f_end = c_const/lbda_start -- ferquency in SI units
f0_start = f_start/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
f0_end = f_end/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
-- print (f0_start .. '\t' .. f0_end )

-- PbTaSe2 parameters via 
-- "DFT based investigation of bulk mechanical, thermophysical and optoelectronic 
-- properties of PbTaSe2 topological semimetal" by  A.S.M. Muhasin Reza, S.H. Naqib
epsxxr  = -20
epsxxi  = 14
epsyyr  = -14
epsyyi  = 11

S = S4.NewSimulation()

a = 0.6        -- 600 nm
d_hole = 0.050      -- 50 nm
r = 0.35*a     -- 0.35 a
d_flake = 0.4  -- 400 nm

S:SetLattice({a,0}, {0,a})
S:SetNumG(100)

S:AddMaterial("Silicon", {12.1,0}) 
S:AddMaterial("SiO2", {1.45,0}) 
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("PerfMirror", {-1.0e10,0})
-- S:AddMaterial("PbTaSe2", {  -- anisotropic version
--     {epsxxr, epsxxi}, {0, 0}, {0, 0},
-- 	{0, 0}, {epsxxr, epsxxi}, {0, 0},
-- 	{0, 0}, {0, 0}, {epsyyr, epsyyi}
-- 	})
S:AddMaterial("PbTaSe2", {epsxxr, epsxxi}) -- isotropic version


-- Structure definition
S:AddLayer('AirAbove',  -- layer name
           0,           -- thickness
           'Vacuum')    -- background material

-- PC of holes in Silicon ontop of PbTaSe2 flake
-- S:AddLayer('PhC', d_hole, 'Silicon')
-- S:SetLayerPatternCircle('PhC',   -- which layer to alter
--                         'Vacuum', -- material in circle
-- 	                    {0,0},    -- center
-- 	                    r)      -- radius

-- PC of holes in PbTaSe2 ontop of PbTaSe2 flake
S:AddLayer('PhC', d_hole, 'PbTaSe2')
S:SetLayerPatternCircle('PhC',   -- which layer to alter
                        'Vacuum', -- material in circle
	                    {0,0},    -- center
	                    r)      -- radius

S:AddLayer('ActiveSlab', d_flake-d_hole, 'PbTaSe2')

-- PC of holes in Silicon under the PbTaSe2 flake
-- S:AddLayer('PhC', d_hole, 'Silicon')
-- S:SetLayerPatternCircle('PhC',   -- which layer to alter
--                         'Vacuum', -- material in circle
-- 	                    {0,0},    -- center
-- 	                    r)      -- radius

-- If on a SiO2 on Si wafer:
S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy

-- If on a perfect mirror
-- S:AddLayer('MirrorBelow', 0, 'PerfMirror')

S:SetExcitationPlanewave(
	{0,0}, -- incidence angles
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
    fw1, bw1 = S:GetPoyntingFlux('PhC', 0)
    fw2, bw2 = S:GetPoyntingFlux('ActiveSlab', d_flake-d_hole)
    A = abs((fw2-fw1-(bw1-bw2))/forward)
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

