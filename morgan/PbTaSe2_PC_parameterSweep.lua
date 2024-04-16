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
    local filename = "PbTaSe2_PC_sweep_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

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
unit = 1e-6
lbda_end   = 0.8e-6 -- say we compute at 1µm wavelength
lbda_start = 0.625e-6 -- say we compute at 1µm wavelength
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

a = 0.55 -- 900 nm
S:SetLattice({a,0}, {0,a})
S:SetNumG(100)
d = 0.090      -- 90 nm
r = 0.17*a     -- 0.17 a
r = 0.32*a     -- 0.30 a
d_flake = 0.400 -- 400 nm

local a = {0.2, 0.25, 0.35, 0.4, 0.45, 0.5, 0.55, 0.60, 0.65, 0.7, 0.75 , 0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1}
local r_factor = {0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4}
local d_hole = {0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09}
-- d = 0.03
d_flake = 0.4
mt = {}
for i = 1, #a do
	S:SetLattice({a[i],0}, {0,a[i]})
	mt[i]={}
	for j=1, #d_hole do
        -- r = r_factor[j]*a[i] 
        r = 0.35*a[i]
		abs_int = 0
		-- for freq=f0_start,f0_end,0.01 do
		freq=f0_start do
        -- d_flake = d_f - d[j]
			for theta=0, 30, 10 do
			-- theta=0 do
                S = S4.NewSimulation()
                S:SetLattice({a[i],0}, {0,a[i]})
                S:SetNumG(100)
                S:AddMaterial("Silicon", {12.1,0}) 
                S:AddMaterial("SiO2", {1.45,0}) 
                S:AddMaterial("Vacuum", {1,0})
                S:AddMaterial("PbTaSe2", {epsxxr, epsxxi}) -- isotropic version
                -- Structure definition
                S:AddLayer('AirAbove',0,'Vacuum')
                S:SetLayer('PhC', d_hole[j], 'PbTaSe2')
                S:SetLayerPatternCircle('PhC','Vacuum',{0,0},r)
                S:AddLayer('ActiveSlab', d_flake-d_hole[j], 'PbTaSe2')
                S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
                S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy        
				S:SetExcitationPlanewave(
				{theta,0}, -- incidence angles
				{0,0}, -- s-polarization amplitude and phase (in degrees)
				{1,0}) -- p-polarization amplitude and phase
				S:SetFrequency(freq)
                forward,backward = S:GetPoyntingFlux('AirAbove', 0)
                fw1, bw1 = S:GetPoyntingFlux('PhC', 0)
                fw2, bw2 = S:GetPoyntingFlux('ActiveSlab', d_flake-d_hole[j])
                A = abs((fw2-fw1-(bw1-bw2))/forward)
                print (freq .. '\t' .. backward .. '\t' .. A)
                -- file:write(string.format("%.6f\t%.6f\t%.6f\n", freq, -backward, A))
                abs_int = abs_int + A
			end
		end
		-- print (a[i] .. '\t' .. r_factor[j] .. '\t' .. abs_int )
		print (a[i] .. '\t' .. d_hole[j] .. '\t' .. abs_int )
        mt[i][j]= abs_int
	end
end
-- print("Generated filename:", filename)
-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

-- Save matrix with labels to file
-- saveMatrixWithLabelsToFile(mt, a, r_factor, filename)
saveMatrixWithLabelsToFile(mt, a, d_hole, filename)

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
