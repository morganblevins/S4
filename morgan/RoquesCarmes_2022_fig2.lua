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
    local filename = "RoquesCarmes_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

    return filename
end

S = S4.NewSimulation()
S:SetLattice({0.43,0}, {0,0.43})
S:SetNumG(100)

c_const = 3e8
a = 0.43e-6
lbda_end   = 0.8e-6 -- say we compute at 1µm wavelength
lbda_start = 0.4e-6 -- say we compute at 1µm wavelength
f_start = c_const/lbda_end -- ferquency in SI units
f_end = c_const/lbda_start -- ferquency in SI units
f0_start = f_start/c_const*a -- so the reduced frequency is f/c_const*a[SI units]
f0_end = f_end/c_const*a -- so the reduced frequency is f/c_const*a[SI units]

PhC_h = 0.045
Si_h = 0.445
SiO2_h = 1.0
holeradius = 0.130

S:AddMaterial("Si", {12,0})
S:AddMaterial("SiO2", {1.45,0})
S:AddMaterial("Vacuum", {1,0})
S:AddLayer('AirAbove', 0 , 'Vacuum')
S:AddLayer('PhC', PhC_h, 'Si')
S:AddLayer('Si', Si_h, 'Si')
S:AddLayer('SiO2', SiO2_h, 'SiO2')
S:AddLayer('SiBelow', 0, 'Si')
S:SetLayerPatternCircle('PhC', 'Vacuum', {0,0}, holeradius)

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

for freq=f0_start,f0_end,0.03 do
	S:SetFrequency(freq)
	forward,backward = S:GetPoyntingFlux('AirAbove', 0)
	forward = S:GetPoyntingFlux('SiBelow', 0)
	print (freq .. '\t' .. forward .. '\t' .. backward)
    file:write(string.format("%.2f\t%.2f\t%.2f\n", freq, forward, backward))
	io.stdout:flush()
end

print("Generated filename:", filename)
 
file:close()