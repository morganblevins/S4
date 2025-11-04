-- Reflection spectra comparison: PbTaSe2 structure with/without patterning
-- Uses S4 (Lua)

function generate_filename()
    -- Get the current date and time as a formatted string
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")

    -- Split the formatted string into date and time components
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")

    -- Construct the filename
    local filename = "TaIrTe4_PC_Refl_Enhancement".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

    return filename
end

-- units / geometry
c_const = 3e8
unit = 1e-6
lbda_end   = 0.730e-6 -- say we compute at 1µm wavelength
lbda_start = 0.560e-6 -- say we compute at 1µm wavelength

-- lbda_end   = 8e-6 -- wavelength in [m]
-- lbda_start = 2e-6 -- wavelength in [m]

f_start = c_const/lbda_end -- ferquency in SI units
f_end = c_const/lbda_start -- ferquency in SI units
f0_start = f_start/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
f0_end = f_end/c_const*unit -- so the reduced frequency is f/c_const*a[SI units]
print (f0_start .. '\t' .. f0_end )

a = 0.600      
r_hole = 0.25  
-- a = 0.630      
-- r_hole = a*0.29  

theta    = 0

d_flake   = 0.100
d_hole    = 0.100
d_resist  = 0.475

-- PbTaSe2 permittivity
n = 4.24056
k = 2.031190
epsxxr  = n*n - k*k -- 13.8566
epsxxi  = 2*n*k -- 17.2268
-- Other permittivities
n_si = 3.847
k_si = 0.016
eps_si_r  = n_si*n_si - k_si*k_si
eps_si_i  = 2*n_si*k_si

n_sio2 = 1.4585
eps_sio2 = n_sio2*n_sio2

n_resist = 1.63447 -- @ 633nm via https://www.microchemicals.com/dokumente/datenblaetter/tds/merck/en/tds_az_1500_series.pdf
eps_resist = n_resist*n_resist
-- -------------------------
-- Build patterned (or changed) simulation
S_pat = S4.NewSimulation()
S_pat:SetLattice({a,0},{0,a})
S_pat:SetNumG(100)
S_pat:AddMaterial("Silicon1", {eps_si_r,eps_si_i}) 
S_pat:AddMaterial("SiO21", {eps_sio2,0}) 
S_pat:AddMaterial("Resist1", {eps_resist,0}) 
S_pat:AddMaterial("Vacuum1", {1,0})
S_pat:AddMaterial("PbTaSe21", {epsxxr, epsxxi}) -- isotropic version
S_pat:AddLayer("AirAbove1", 0, "Vacuum1")
S_pat:AddLayer("PhC1", d_resist, "Resist1")
-- S_pat:AddLayer("PhC1", d_hole, "Resist1")
-- S_pat:SetLayerPatternCircle("PhC1", "Vacuum1", {0,0}, r_hole)
-- S_pat:AddLayer("Res", d_resist-d_hole, "Resist1")
S_pat:AddLayer("ActiveSlab1", d_flake, "PbTaSe21")
-- S_pat:AddLayer("AirBubble", 0.4, "Vacuum1") -- Fabrey perot mode under wrinkled flake?
S_pat:AddLayer("SiO21", 0.3, "SiO21")
S_pat:AddLayer("SiWafer1", 0, "Silicon1")
S_pat:SetExcitationPlanewave({theta,0},{0,0},{1,0})

-- -------------------------
-- Build flat (or base line) simulation
a2 = a
S_flat = S4.NewSimulation()
S_flat:SetLattice({a,0},{0,a})
S_flat:SetNumG(100)
S_flat:AddMaterial("Silicon2", {eps_si_r,eps_si_i}) 
S_flat:AddMaterial("SiO22", {eps_sio2,0}) 
S_flat:AddMaterial("Resist2", {eps_resist,0}) 
S_flat:AddMaterial("Vacuum2", {1,0})
S_flat:AddMaterial("PbTaSe22", {epsxxr, epsxxi}) -- isotropic version
S_flat:AddLayer("AirAbove2", 0, "Vacuum2")
-- S_flat:AddLayer("PhC2", d_resist, "Resist2")
-- S_flat:SetLayerPatternCircle("PhC2", "Vacuum2", {0,0}, r_hole)
S_flat:AddLayer("ActiveSlab2", d_flake, "PbTaSe22")
S_flat:AddLayer("SiO22", 0.3, "SiO22")
S_flat:AddLayer("SiWafer2", 0, "Silicon2")
S_flat:SetExcitationPlanewave({theta,0},{0,0},{1,0})

-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

for freq=f0_start,f0_end,0.01 do
    local wavelength_nm = unit*1e9 / freq   -- λ [nm]

    -- Patterned
    S_pat:SetFrequency(freq)
	forward1,backward1 = S_pat:GetPoyntingFlux('AirAbove1', 0)
    -- print (freq .. '\t' .. backward1)

    -- Flat
    S_flat:SetFrequency(freq)
    forward2,backward2 = S_flat:GetPoyntingFlux('AirAbove2', 0)
	-- print (freq .. '\t' .. backward2)
    -- Ratio of Refl 1/ Refl 2
    ratio = backward1/backward2
    -- file:write(string.format("%.1f\t%.6f\t%.6f\n", wavelength_nm, -backward1, -backward2))
    file:write(string.format("%.1f\t%.6f\t%.6f\t%.6f\n", wavelength_nm, -backward1, -backward2, ratio))
    -- file:write(string.format("%.1f\t%.6f\n", wavelength_nm, ratio))

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