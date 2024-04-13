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
    local filename = "PbTaSe2_PhC_sweep_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

    return filename
end


-- Function to save matrix with labels to a .txt file
function saveMatrixWithLabelsToFile(matrix, xLabels, yLabels, filename)
    local file = io.open(filename, "w") -- Open file for writing
    if not file then
        print("Error: Unable to open file for writing")
        return
    end

    -- Write column labels
    file:write("\t")
    for _, label in ipairs(yLabels) do
        file:write(label .. "\t")
    end
    file:write("\n")

    -- Write matrix with row labels
    for i, row in ipairs(matrix) do
        file:write(xLabels[i] .. "\t") -- Write row label
        for j, val in ipairs(row) do
            file:write(val) -- Write element
            if j < #row then
                file:write("\t") -- Separate elements with a tab
            else
                file:write("\n") -- Move to the next line after a row is completed
            end
        end
    end

    file:close() -- Close the file
    print("Matrix with labels saved to " .. filename)
end

function abs(x)
    if x < 0 then
        return -x
    else
        return x
    end
end


c_const = 3e8
a = 0.43e-6
lbda_end   = 0.63e-6 -- say we compute at 1µm wavelength
lbda_start = 0.62e-6 -- say we compute at 1µm wavelength
f_start = c_const/lbda_end -- ferquency in SI units
f_end = c_const/lbda_start -- ferquency in SI units
f0_start = f_start/c_const*a -- so the reduced frequency is f/c_const*a[SI units]
f0_end = f_end/c_const*a -- so the reduced frequency is f/c_const*a[SI units]
print (f0_start .. '\t' .. f0_end )

a = 0.43
PhC_h = 0.05
slab_h = 0.350 -- thickness of PbTaSe2 flakes is about 400 nm
SiO2_h = 0.3
holeradius = 0.130

epsxxr  = -21
epsxxi  = 15
epsyyr  = -17
epsyyi  = 11

S = S4.NewSimulation()
S:SetLattice({a,0}, {0,a})
S:SetNumG(100)

S:AddMaterial("PbTaSe2", { 
    {epsxxr, epsxxi}, {0, 0}, {0, 0},
	{0, 0}, {epsxxr, epsxxi}, {0, 0},
	{0, 0}, {0, 0}, {epsyyr, epsyyi}
	})
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("Si", {12,0})
S:AddMaterial("SiO2", {1.45,0})

S:AddLayer('AirAbove', 0 , 'Vacuum')
S:AddLayer('PhC', PhC_h, 'PbTaSe2')
S:AddLayer('Slab', slab_h, 'PbTaSe2')
S:AddLayer('SiO2', SiO2_h, 'SiO2')
S:AddLayer('SiBelow', 0, 'Si')
-- S:SetLayerPatternCircle('PhC', 'Vacuum', {0,0}, holeradius)

S:SetExcitationPlanewave(
	{0,0}, -- incidence angles
	{0,0}, -- s-polarization amplitude and phase (in degrees)
	{1,0}) -- p-polarization amplitude and phase

--S:UsePolarizationDecomposition()
-- file = "PbTaSe2_data.txt"

-- Write the header specifying the columns
-- file:write("freq\tforward\tbackward\n")
local a = {0.4, 0.43, 0.46, 0.49, 0.52}
-- local holeradius = {0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 0.12, 0.13, 0.14, 0.15}
local holeradius = {0.05,0.1, 0.15}

mt = {}
ii = 1
jj = 1
for i = 1, #a do
	S:SetLattice({a[i],0}, {0,a[i]})
	mt[i]={}
	for j=1, #holeradius do
		S:SetLayerPatternCircle('PhC', 'Vacuum', {0,0}, holeradius[j])
		abs_int = 0
		-- for freq=f0_start,f0_end,0.01 do
		freq=f0_start do
			-- for theta=0, 30, 10 do
			theta=0 do
				S:SetExcitationPlanewave(
				{theta,0}, -- incidence angles
				{0,0}, -- s-polarization amplitude and phase (in degrees)
				{1,0}) -- p-polarization amplitude and phase
				S:SetFrequency(freq)
				-- forward,backward = S:GetPoyntingFlux('AirAbove', 0)
				-- forward = S:GetPoyntingFlux('SiBelow', 0)
				-- Absorption in the PbTaSe2 slab:
				inc, r = S:GetPowerFlux('AirAbove', 0)
				fw1, bw1 = S:GetPowerFlux('Slab', 0)
    			fw2, bw2 = S:GetPowerFlux('Slab', slab_h)
				abs_int = abs((fw2-fw1-(bw1-bw2))) + abs_int
				-- print (freq .. '\t' .. forward .. '\t' .. backward)
				io.stdout:flush()
			end
		end
		print (a[i] .. '\t' .. holeradius[j] .. '\t' .. abs_int )
		mt[i][j]= abs_int
	end
end
-- print("Generated filename:", filename)

-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

-- Save matrix with labels to file
saveMatrixWithLabelsToFile(mt, a, holeradius, filename)

file:close()

-- Define the Python script file name
local pythonScript = "morgan/plotHeatmap_matrix_with_labels.py"

-- Execute the Python script using os.execute
local command = "python3 " .. pythonScript .. " " .. filename
local status = os.execute(command)

-- Check the status of the execution
if status == true then
    print("Python script executed successfully.")
else
    print("Error executing Python script.")
end
