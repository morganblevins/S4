-- PbTaSe2 absorption enhancement with/without PhC pattern (inline, separate loops)

function generate_filename()
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")
    return "PbTaSe2_PC_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"
end

function abs(x) if x<0 then return -x else return x end end

c_const = 3e8
unit = 1e-6
lbda_end   = 0.730e-6
lbda_start = 0.560e-6

f_start = c_const/lbda_end
f_end   = c_const/lbda_start
f0_start = f_start/c_const*unit
f0_end   = f_end/c_const*unit

-- PbTaSe2 optical constants
n = 4.24056
k = 2.031190
epsxxr  = n*n - k*k
epsxxi  = 2*n*k

-- Geometry
a = 0.6
r = 0.23
d_resist = 0.48
d_flake  = 0.250
theta = 0

-- Sweep step
freq_step = 0.01

-- Tables to store results
wl_list = {}
A_pat_list = {}
A_flat_list = {}
R_pat_list = {}
R_flat_list = {}

-- -----------------------
-- 1) Patterned simulation
S_pat = S4.NewSimulation()
S_pat:SetLattice({a,0},{0,a})
S_pat:SetNumG(100)
S_pat:AddMaterial("Silicon", {12.1,0}) 
S_pat:AddMaterial("SiO2", {1.45,0}) 
S_pat:AddMaterial("Resist", {1.626,0}) 
S_pat:AddMaterial("Vacuum", {1,0})
S_pat:AddMaterial("PerfMirror", {-1e10,0})
S_pat:AddMaterial("PbTaSe2", {epsxxr, epsxxi})
S_pat:AddLayer('AirAbove',0,'Vacuum')
S_pat:AddLayer('PhC', d_resist, 'Resist')
-- S_pat:AddLayer('PhC', d_resist-0.1, 'Resist')
S_pat:SetLayerPatternCircle('PhC','Vacuum',{0,0}, r)
-- S_pat:AddLayer('MoreResist', 0.1, 'Resist')
S_pat:AddLayer('ActiveSlab', d_flake, 'PbTaSe2')
S_pat:AddLayer('SiO2', 0.3, 'SiO2')
S_pat:AddLayer('SiWafer', 0, 'Silicon')
S_pat:SetExcitationPlanewave({theta,0},{0,0},{1,0})

freq = f0_start
index = 1
while freq <= f0_end+1e-10 do
    S_pat:SetFrequency(freq)
    forward,backward = S_pat:GetPoyntingFlux('AirAbove',0)
    fw1,bw1 = S_pat:GetPoyntingFlux('ActiveSlab',0)
    fw2,bw2 = S_pat:GetPoyntingFlux('ActiveSlab', d_flake)
    A = abs((fw2-fw1-(bw1-bw2))/forward)
    A_pat_list[index] = A
    R_pat_list[index] = -backward
    wl_list[index] = unit*1e9 / freq
    freq = freq + freq_step
    index = index + 1
end

-- -----------------------
-- 2) Flat (unpatterned) simulation
S_flat = S4.NewSimulation()
S_flat:SetLattice({a,0},{0,a})
S_flat:SetNumG(100)
S_flat:AddMaterial("Silicon", {12.1,0}) 
S_flat:AddMaterial("SiO2", {1.45,0}) 
S_flat:AddMaterial("Resist", {1.626,0}) 
S_flat:AddMaterial("Vacuum", {1,0})
S_flat:AddMaterial("PerfMirror", {-1e10,0})
S_flat:AddMaterial("PbTaSe2", {epsxxr, epsxxi})
S_flat:AddLayer('AirAbove',0,'Vacuum')
S_flat:AddLayer('PhC', d_resist, 'Resist')  -- no holes!
S_flat:AddLayer('ActiveSlab', d_flake, 'PbTaSe2')
S_flat:AddLayer('SiO2', 0.3, 'SiO2')
S_flat:AddLayer('SiWafer', 0, 'Silicon')
S_flat:SetExcitationPlanewave({theta,0},{0,0},{1,0})

freq = f0_start
index = 1
while freq <= f0_end+1e-10 do
    S_flat:SetFrequency(freq)
    forward,backward = S_flat:GetPoyntingFlux('AirAbove',0)
    fw1,bw1 = S_flat:GetPoyntingFlux('ActiveSlab',0)
    fw2,bw2 = S_flat:GetPoyntingFlux('ActiveSlab', d_flake)
    A = abs((fw2-fw1-(bw1-bw2))/forward)
    A_flat_list[index] = A
    R_flat_list[index] = -backward
    index = index + 1
    freq = freq + freq_step
end

-- -----------------------
-- 3) Compute enhancement and save file
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename,"w")

for i=1,#wl_list do
    -- local enh = (A_flat_list[i] > 0) and (A_pat_list[i]/A_flat_list[i]) or 0
    local enh = (R_flat_list[i] > 0) and (R_pat_list[i]/R_flat_list[i]) or 0
    -- file:write(string.format("%.2f\t%.6f\t%.6f\t%.6f\n", wl_list[i], A_flat_list[i], A_pat_list[i], enh))
    file:write(string.format("%.2f\t%.6f\t%.6f\t%.6f\n", wl_list[i], R_flat_list[i], R_pat_list[i], enh))
end

file:close()
print("Generated filename:", filename)

-- -----------------------
-- Optional: call Python to plot
local pythonScript = "morgan/plot_abs_enhancement.py"
local command = "python3 " .. pythonScript .. " " .. filename
local status = os.execute(command)
if status == true then
    print("Python script executed successfully.")
else
    print("Error executing Python script.")
end
