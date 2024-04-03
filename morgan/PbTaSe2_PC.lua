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
    local filename = "data_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

    return filename
end


S = S4.NewSimulation()
S:SetLattice({1,0}, {0,1})
S:SetNumG(100)
epsxxr  = -21
epsxxi  = 15
epsyyr  = -17
epsyyi  = 11
S:AddMaterial("PbTaSe2", { 
    {epsxxr, epsxxi}, {0, 0}, {0, 0},
	{0, 0}, {epsxxr, epsxxi}, {0, 0},
	{0, 0}, {0, 0}, {epsyyr, epsyyi}
	})
S:AddMaterial("Vacuum", {1,0})
S:AddLayer('AirAbove', 0 , 'Vacuum')
S:AddLayer('Slab', 0.5, 'PbTaSe2')
S:SetLayerPatternCircle('Slab', 'Vacuum', {0,0}, 0.2)
S:AddLayerCopy('AirBelow', 0, 'AirAbove')

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

for freq=0.25,1,0.03 do
	S:SetFrequency(freq)
	forward,backward = S:GetPoyntingFlux('AirAbove', 0)
	forward = S:GetPoyntingFlux('AirBelow', 0)
	print (freq .. '\t' .. forward .. '\t' .. backward)
    file:write(string.format("%.2f\t%.2f\t%.2f\n", freq, forward, backward))
	io.stdout:flush()
end

print("Generated filename:", filename)
 
file:close()