-- Design of grating PC for reflection from nonlocal Cd3As2 

function generate_filename()
    -- Get the current date and time as a formatted string
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")

    -- Split the formatted string into date and time components
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")

    -- Construct the filename
    local filename = "Fizeau_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

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

local complex = require("complex")

if not complex then
    error("Failed to load the complex module.")
end

I = complex.new(0,1)

-- Cd3As2 parameters via my manuscript
local complex = require("complex")

-- Define constants
local hbar    = 1.05457e-34 -- Reduced Planck's constant [J*s].
local eV      = 1.60218e-19 -- Electronvolt [J].
local k_B     = 1.38065e-23 -- Boltzmann constant [J/K].
local eps_0   = 8.85419e-12 -- Permittivity of free space [F/m].
local c       = 2.99 * 10^8 -- Speed of light [m/s]

-- WSM/BDS Parameters
local E_F     = 0.15 * eV  -- Fermi energy
local v_F     = 1e6        -- Fermi velocity (independent of Fermi level) [m/s]. 
local g       = 4          -- Degeneracy [1].
local eps_inf = 13         -- Static or high freq. permittivity 
local tau     = 2.1e-12    -- [s]
local k_F     = E_F / (v_F * hbar) -- Fermi momentum
local Tau     = tau * E_F / hbar   -- Dimensionless scattering period [1].

-- Fizeau drag parameters
local vFactor = 0.5
local vd      = vFactor * v_F            -- current drift velocity
local gamma   = math.sqrt(1 - vd^2 / v_F^2)^(-1) -- QLT transform parameter

-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

print("Generated filename:", filename)

S = S4.NewSimulation()
S:SetLattice({1,0}, {0,1})
S:SetNumG(10)

S:AddMaterial("Cd3As2", {1,0})
S:AddMaterial('Vacuum', {1,0})

S:AddLayer('Above', 0 , 'Vacuum')
S:AddLayer('Dummy', 1 , 'Vacuum')
S:AddLayer('Below', 0, "Cd3As2")

-- S:SetExcitationPlanewave(
-- 	{70,0}, -- incidence angles
-- 	{0,0}, -- s-polarization amplitude and phase (in degrees)
-- 	{1,0}) -- p-polarization amplitude and phase

theta = 60

S:SetExcitationPlanewave(
	{theta,0}, -- incidence angles
	{0,0}, -- s-polarization amplitude and phase (in degrees)
	{1,0}) -- p-polarization amplitude and phase


for freq=0.0150,0.1000,0.001 do
-- for freq=f0_start,f_0end,0.05 do
-- for freq=f0_start,f0_end,0.03 do
    f = freq -- using units of f [eV]
    -- Define frequency
    E = f*eV -- [J]
    E_E_F = E / E_F --[nondimensionallized in E_F]
    omega = E/hbar --[1/s]
    
    q = (omega/c)*math.sin(theta*(math.pi/180))
    Q_k_F = q / k_F -- Dimensionless wave vector [1]. 

    -- Define freq, momentum, loss parameters (dimensionless)
    Omega = omega * hbar / E_F    -- Dimensionless frequency [1].      
    Q     = Q_k_F   -- Dimensionless wave vector [1].  
    -- print('Omega = ' .. Omega .. ', Q=' .. Q)

    -- Solve for conductivity, sigma(q,omega):
    -- sigma for NO current bias 
    A_1 = ((Omega + (I/Tau)) / (Q*2))
    log_real = math.log(complex.real((Omega + (I/Tau) + Q) / (Omega + (I/Tau) - Q)) )
    log_imag = math.atan2(complex.imag((Omega + (I/Tau) + Q) / (Omega + (I/Tau) - Q)) , complex.real((Omega + (I/Tau) + Q) / (Omega + (I/Tau) - Q)) ) * I
    A = ((Omega + (I/Tau)) / (Q*2))*(log_real+log_imag) - 1
    sigma_0 = ((I * g * eV^2 * k_F) / (2 * math.pi^2 * hbar)) * (Omega / (Q^2)) * (((Omega + (I / Tau)) * A) / (Omega - (I / Tau) * A))

    -- Solve for permittivity, epsilon(q,omega), from conductivity 
    eps_d0 = eps_inf + (I*(sigma_0*hbar) / (eps_0*E))    -- NO current bias

    xx_r = complex.real(eps_d0)
    xx_i = complex.imag(eps_d0)

    S:SetFrequency(freq)
    -- S:SetMaterial('Cd3As2', {xx_r, xx_i})
    S:SetMaterial("Cd3As2", {
        {xx_r, xx_i}, {0, 0}, {0, 0},
        {0, 0}, {xx_r, xx_i}, {0, 0},
        {0, 0}, {0, 0}, {xx_r, xx_i}
        })

    forward,reflected = S:GetPoyntingFlux('Dummy', 1)
	reflected = -reflected/forward
	T1x,T1y,T1z = S:GetStressTensorIntegral('Above', 0)
	T2x,T2y,T2z = S:GetStressTensorIntegral('Below', 0)


	-- Reflected power

    -- print(reflected)
    print (f .. '\t' .. reflected .. '\t' .. -T1z .. '\t' .. T2z)
    file:write(string.format("%.6f\t%.6f\n", freq, reflected))
    io.stdout:flush()
end

file:close()

-- Define the Python script file name
local pythonScript = "morgan/plotdata_eV.py"

-- Execute the Python script using os.execute
local command = "python3 " .. pythonScript .. " " .. filename
local status = os.execute(command)

-- Check the status of the execution
if status == true then
    print("Python script executed successfully.")
else
    print("Error executing Python script.")
end