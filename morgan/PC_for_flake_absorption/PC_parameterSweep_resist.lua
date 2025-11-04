-- Design of PC for enhances absorption into flakes for photocurrent generation

function generate_filename()
    -- Get the current date and time as a formatted string
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")

    -- Split the formatted string into date and time components
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")

    -- Construct the filename
    local filename = "PC_sweep_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

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
lbda_end   = 0.640e-6 -- wavelength in [m]
lbda_start = 0.620e-6 -- wavelength in [m]

-- For IR:
-- lbda_end   = 4.1e-6 -- wavelength in [m]
-- lbda_start = 3.9e-6 -- wavelength in [m]

f_start = c_const/lbda_end -- frequency in SI units
f_end = c_const/lbda_start -- frequency in SI units
f0_start = f_start/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
f0_end = f_end/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
print (f0_start .. '\t' .. f0_end )

-- PbTaSe2 parameters via 
-- "DFT based investigation of bulk mechanical, thermophysical and optoelectronic 
-- properties of PbTaSe2 topological semimetal" by  A.S.M. Muhasin Reza, S.H. Naqib
-- epsxxr  = -20
-- epsxxi  = 14
-- epsyyr  = -14
-- epsyyi  = 11

-- PbTaSe2 parameters as measured by Vivian on ellipsometer
-- [eV]         [eps_1]     [eps_2]
-- 1.955065037	4.039733	10.946194
epsxxr  = 4.039733
epsxxi  = 10.946194
epsyyr  = 4.039733
epsyyi  = 10.946194
d_flake = 0.056 -- 56 nm, PbTaSe2 flake measured with AFM

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
d_flake = 0.100 -- 250 nm, TaIrTe4 flake measured with AFM
-- d_flake = 1.000 -- 1000 nm, thick TaIrTe4 flake 

n_si = 3.847
k_si = 0.016
eps_si_r  = n_si*n_si - k_si*k_si
eps_si_i  = 2*n_si*k_si
n_sio2 = 1.4585
eps_sio2 = n_sio2*n_sio2
n_resist = 1.63447 -- @ 633nm via https://www.microchemicals.com/dokumente/datenblaetter/tds/merck/en/tds_az_1500_series.pdf
eps_resist = n_resist*n_resist

d_resist = 0.5

-- local a = {0.42, 0.43, 0.44, 0.45, 0.46, 0.47, 0.48, 0.49, 0.5, 0.51, 0.52, 0.53, 0.54, 0.55, 0.56, 0.57, 0.58, 0.59, 0.6, 0.61, 0.62, 0.63, 0.64, 0.65}
-- local a = {3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 4.0, 4.1, 4.1,4.5,4.8,5,5.2,5.6}
-- local a = {0.3, 0.31, 0.32, 0.33, 0.34, 0.35, 0.36, 0.37, 0.38, 0.39,0.4, 0.41, 0.42, 0.43, 0.44, 0.45, 0.46, 0.47, 0.48, 0.49, 0.5, 0.51, 0.52, 0.53, 0.54, 0.55, 0.56, 0.57, 0.58, 0.59, 0.6, 0.61, 0.62, 0.63, 0.64, 0.65}
local a = {0.59, 0.6, 0.62, 0.64, 0.66, 0.68}
local r_factor = {0.2, 0.21, 0.22, 0.23, 0.24, 0.25, 0.26, 0.27, 0.28, 0.29, 0.3, 0.31, 0.32, 0.33, 0.34, 0.35, 0.36, 0.37, 0.38, 0.39, 0.4}
-- local r_factor = {0.06, 0.08, 0.1, 0.12, 0.14, 0.16, 0.18, 0.2, 0.22, 0.24, 0.26, 0.28,0.3}
mt = {}
local abs_int = 0
for i = 1, #a do
	mt[i]={}
	for j=1, #r_factor do
        r = r_factor[j]*a[i] 
		abs_int = 0
		for freq=f0_start,f0_end,0.01 do
		-- freq=f0_start do
		    for theta=0, 5, 2 do
			-- theta=0 do
                    S = S4.NewSimulation()
                    S:AddMaterial("Silicon", {eps_si_r,eps_si_i}) 
                    S:AddMaterial("SiO2", {eps_sio2,0}) 
                    S:AddMaterial("Resist", {eps_resist,0}) 
                    S:AddMaterial("Vacuum", {1,0})
                    S:AddMaterial("PbTaSe2", {epsxxr, epsxxi}) -- isotropic version
                    S:SetLattice({a[i],0}, {0,a[i]})
                    S:SetNumG(100)
                    -- Structure definition
                    -- Structure definition
                    S:AddLayer('AirAbove',  -- layer name
                            0,           -- thickness
                            'Vacuum')    -- background material
                    S:AddLayer('PhC', d_resist, 'Resist')
                    S:SetLayerPatternCircle('PhC',   -- which layer to alter
                                            'Vacuum', -- material in circle
                                            {0,0},    -- center
                                            r)      -- radius
                    S:AddLayer('ActiveSlab', d_flake, 'PbTaSe2')
                    -- If on a SiO2 on Si wafer:
                    S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
                    S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy      
                    S:SetExcitationPlanewave(
                    {theta,0}, -- incidence angles
                    {0,0}, -- s-polarization amplitude and phase (in degrees)
                    {1,0}) -- p-polarization amplitude and phase
                    S:SetFrequency(freq)
                    forward,backward = S:GetPoyntingFlux('AirAbove', 0)
                    fw1, bw1 = S:GetPoyntingFlux('ActiveSlab', 0)
                    fw2, bw2 = S:GetPoyntingFlux('ActiveSlab', d_flake)
                    A = abs((fw2-fw1-(bw1-bw2))/forward) -- Absorption
                    -- print (freq .. '\t' .. backward .. '\t' .. A)
                    -- print (fw1 .. '\t' .. bw1 .. '\t' .. fw2 .. '\t' .. bw2)
                    -- file:write(string.format("%.6f\t%.6f\t%.6f\n", freq, -backward, A))
                    abs_int = abs_int + A
			end
		end
		-- print (a[i] .. '\t' .. r_factor[j] .. '\t' .. abs_int )
		-- print (a[i] .. '\t' .. d_hole[j] .. '\t' .. abs_int )
        mt[i][j]= abs_int
	end
end
-- print("Generated filename:", filename)
-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

-- Save matrix with labels to file
saveMatrixWithLabelsToFile(mt, a, r_factor, filename)
-- saveMatrixWithLabelsToFile(mt, a, d_hole, filename)

file:close()

-- Define the Python script file name
local pythonScript = "morgan/plotHeatmap_matrix_with_labels.py"
local pythonScript = "morgan/heatmap.py"

-- Execute the Python script using os.execute
local command = "python3 " .. pythonScript .. " " .. filename
local status = os.execute(command)

-- Check the status of the execution
if status == true then
    print("Python script executed successfully.")
else
    print("Error executing Python script.")
end
