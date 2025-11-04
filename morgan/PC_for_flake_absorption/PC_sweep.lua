-- run_sweep.lua
-- Sweep a2 from 1 to 2.5 and integrate reflection enhancement around 630 nm

function generate_filename()
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")
    return "Sweep_ReflectionEnhancement_" .. datetime_string .. ".txt"
end

-- Units and constants
c_const = 3e8
unit = 1e-6

-- wavelength range
lbda_start = 0.560e-6
lbda_end   = 0.730e-6

f_start = c_const/lbda_end
f_end   = c_const/lbda_start
f0_start = f_start/c_const*unit
f0_end   = f_end/c_const*unit

-- geometry
a = 0.600
r_hole = 0.200
theta = 0
d_flake   = 0.100
d_resist  = 0.475

-- permittivities
n = 4.24056; k = 2.031190
epsxxr  = n*n - k*k
epsxxi  = 2*n*k
n_si = 3.847; k_si = 0.016
eps_si_r  = n_si*n_si - k_si*k_si
eps_si_i  = 2*n_si*k_si
n_sio2 = 1.4585
eps_sio2 = n_sio2*n_sio2
n_resist = 1.63447
eps_resist = n_resist*n_resist

-- wavelength window for integration [nm]
win_min = 620
win_max = 640

-- Output file
local filename = "/home/mo/S4/morgan/" .. generate_filename()
local file = io.open(filename, "w")
file:write("a2\tIntegratedEnhancement\n")

-- Loop over a2
for a2=1.0,2.5,0.1 do
    -- Build patterned sim
    S_pat = S4.NewSimulation()
    S_pat:SetLattice({a,0},{0,a})
    S_pat:SetNumG(100)
    S_pat:AddMaterial("Si", {eps_si_r,eps_si_i})
    S_pat:AddMaterial("SiO2", {eps_sio2,0})
    S_pat:AddMaterial("Resist", {eps_resist,0})
    S_pat:AddMaterial("Vacuum", {1,0})
    S_pat:AddMaterial("Active", {epsxxr, epsxxi})
    S_pat:AddLayer("Air", 0, "Vacuum")
    S_pat:AddLayer("Res", d_resist, "Resist")
    S_pat:SetLayerPatternCircle("Res", "Vacuum", {0,0}, r_hole)
    S_pat:AddLayer("Flake", d_flake, "Active")
    S_pat:AddLayer("Oxide", 0.3, "SiO2")
    S_pat:AddLayer("Si", 0, "Si")
    S_pat:SetExcitationPlanewave({theta,0},{0,0},{1,0})

    -- Build flat sim (different lattice size a2)
    S_flat = S4.NewSimulation()
    S_flat:SetLattice({a2,0},{0,a})
    S_flat:SetNumG(100)
    S_flat:AddMaterial("Si", {eps_si_r,eps_si_i})
    S_flat:AddMaterial("SiO2", {eps_sio2,0})
    S_flat:AddMaterial("Resist", {eps_resist,0})
    S_flat:AddMaterial("Vacuum", {1,0})
    S_flat:AddMaterial("Active", {epsxxr, epsxxi})
    S_flat:AddLayer("Air", 0, "Vacuum")
    S_flat:AddLayer("Res", d_resist, "Resist")
    S_flat:SetLayerPatternCircle("Res", "Vacuum", {0,0}, r_hole)
    S_flat:AddLayer("Flake", d_flake, "Active")
    S_flat:AddLayer("Oxide", 0.3, "SiO2")
    S_flat:AddLayer("Si", 0, "Si")
    S_flat:SetExcitationPlanewave({theta,0},{0,0},{1,0})

    -- integrate reflection ratio
    local integral = 0.0
    local count = 0

    for freq=f0_start,f0_end,0.003 do
        local wavelength_nm = unit*1e9 / freq
        if wavelength_nm >= win_min and wavelength_nm <= win_max then
            -- patterned refl
            S_pat:SetFrequency(freq)
            _,backward1 = S_pat:GetPoyntingFlux('Air', 0)
            -- flat refl
            S_flat:SetFrequency(freq)
            _,backward2 = S_flat:GetPoyntingFlux('Air', 0)

            ratio = backward1/backward2
            integral = integral + ratio
            count = count + 1
        end
    end

    local avg_ratio = 0
    if count > 0 then
        avg_ratio = integral / count
    end

    file:write(string.format("%.2f\t%.6f\n", a2, avg_ratio))
    print("a2=", a2, " IntegratedEnhancement=", avg_ratio)
end

file:close()
print("Results written to", filename)

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