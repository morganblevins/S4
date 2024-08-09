-- Fig. 4 a from 
-- Jessica R. Piper and Shanhui Fan
-- "Total Absorption in a Graphene Monolayer in the Optical Regime by 
-- Critical Coupling with a Photonic Crystal Guided Resonance",
-- https://pubs.acs.org/doi/full/10.1021/ph400090p

function generate_filename()
    -- Get the current date and time as a formatted string
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")

    -- Split the formatted string into date and time components
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")

    -- Construct the filename
    local filename = "Piper2014_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

    return filename
end

function abs(x)
    if x < 0 then
        return -x
    else
        return x
    end
end

S = S4.NewSimulation()

a = 0.9 -- 900 nm
S:SetLattice({a,0}, {0,a})
S:SetNumG(100)

S:AddMaterial("Silicon", {12.1,0}) 
S:AddMaterial("SiO2", {1.45,0}) 
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("PerfMirror", {-1.0e10,0})
S:AddMaterial("Graphene", {5,7})

t_g = 0.00034  -- 0.34 nm
d = 0.090      -- 90 nm
r = 0.17*a     -- 0.17 a

-- Structure definition
S:AddLayer('AirAbove',  -- layer name
           0,           -- thickness
           'Vacuum')    -- background material
S:AddLayer('Graphene', t_g, 'Graphene')
S:AddLayer('Slab', d, 'Silicon')
S:SetLayerPatternCircle('Slab',   -- which layer to alter
                        'Vacuum', -- material in circle
	                    {0,0},    -- center
	                    r)      -- radius
-- If only on a SiO2 on Si wafer:
S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy
-- If on a perfect mirror
-- S:AddLayer('MirrorBelow', 0, 'PerfMirror') -- layer to copy

S:SetExcitationPlanewave(
	{0,0}, -- incidence angles
	{1,0}, -- s-polarization amplitude and phase (in degrees)
	{0,0}) -- p-polarization amplitude and phase

--S:UsePolarizationDecomposition()

-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

for freq=0.72,0.9,0.01 do
    S:SetFrequency(freq)
	forward,backward = S:GetPoyntingFlux('AirAbove', 0)
    fw1, bw1 = S:GetPoyntingFlux('Graphene', 0)
    fw2, bw2 = S:GetPoyntingFlux('Graphene', t_g)
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

