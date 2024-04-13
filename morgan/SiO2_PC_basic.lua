-- Bottom pane of Fig. 12 in
-- Shanhui Fan and J. D. Joannopoulos,
-- "Analysis of guided resonances in photonic crystal slabs",
-- Phys. Rev. B, Vol. 65, 235112

function generate_filename()
    -- Get the current date and time as a formatted string
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")

    -- Split the formatted string into date and time components
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")

    -- Construct the filename
    local filename = "SiO2_PC_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

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
print (f0_start .. '\t' .. f0_end )

a = 0.43 -- 430 nm
PhC_d = 0.05 -- 50 nm
slab_d = 400-PhC_d -- thickness of PbTaSe2 flakes is about 400 nm
r = 0.130 -- 130 nm

S = S4.NewSimulation()
S:SetLattice({a,0}, {0,a})
S:SetNumG(100)

S:AddMaterial("SiO2", {1.45,0})
S:AddMaterial("Silicon", {12.1,0}) 
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("PerfMirror", {-1.0e10,0})

-- Structure definition
S:AddLayer('AirAbove',  -- layer name
           0,           -- thickness
           'Vacuum')    -- background material
S:AddLayer('PhC', PhC_d, 'SiO2')
S:SetLayerPatternCircle('PhC',   -- which layer to alter
                        'Vacuum', -- material in circle
	                    {0,0},    -- center
	                    r)      -- radius
S:AddLayer('Slab', slab_d, 'SiO2')
-- If only on a SiO2 on Si wafer:
S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy
-- If on a perfect mirror
-- S:AddLayer('MirrorBelow', 0, 'PerfMirror') -- layer to copy


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


for freq=0.72,2.5,0.01 do
    S:SetFrequency(freq)
	forward,backward = S:GetPoyntingFlux('AirAbove', 0)
    fw1, bw1 = S:GetPoyntingFlux('Slab', 0)
    fw2, bw2 = S:GetPoyntingFlux('Slab', slab_d)
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

