-- Design of PC for enhances absorption into flake for photocurrent generation

function generate_filename()
    -- Get the current date and time as a formatted string
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")

    -- Split the formatted string into date and time components
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")

    -- Construct the filename
    local filename = "PC_".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"

    return filename
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
lbda_end   = 0.7e-6 -- say we compute at 1µm wavelength
lbda_start = 0.5e-6 -- say we compute at 1µm wavelength
f_start = c_const/lbda_end -- ferquency in SI units
f_end = c_const/lbda_start -- ferquency in SI units
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
d_flake = 0.140 -- 56 nm, PbTaSe2 flake measured with AFM

-- TaIrTe4 parameters as measured by Vivian on ellipsometer
-- At 635 nm/1.95 eV:
-- eps_r = 4.24056
-- eps_i = 2.031190
epsxxr  = 13.219
epsxxi  = 16.8866
epsyyr  = epsxxr
epsyyi  = epsxxi

n = 4.24056
k = 2.031190
epsxxr  = n*n - k*k -- 13.8566
epsxxi  = 2*n*k -- 17.2268
epsyyr  = epsxxr
epsyyi  = epsxxi

-- n and k from TI paper
-- Digitized (lambda in meters), n, k
local lambda_nk_data = {
  {300e-9, 1.2, 2.3},
  {400e-9, 2.1, 3.5},
  {500e-9, 3.2, 4.3},
  {600e-9, 4.4, 4.5},
  {700e-9, 5.2, 4.2},
  {800e-9, 5.8, 3.8},
  {1000e-9, 6.1, 3.1},
  {1200e-9, 6.15, 2.6},
  {1400e-9, 6.1, 2.2},
  {1600e-9, 6.05, 2.0}
}

-- Convert λ to f0 and store as frequency-based table
local f0_nk_data = {}
for i, val in ipairs(lambda_nk_data) do
    local lambda = val[1]
    local n = val[2]
    local k = val[3]
    local freq = c_const / lambda
    local f0 = freq * unit / c_const
    table.insert(f0_nk_data, {f0, n, k})
end

-- Sort f0_nk_data by ascending f0
table.sort(f0_nk_data, function(a, b) return a[1] < b[1] end)

-- Linear interpolation helper
function interp(x, x0, x1, y0, y1)
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
end


d_flake = 0.250 -- 250 nm, TaIrTe4 flake measured with AFM

S = S4.NewSimulation()

a = 0.335       -- Pitch
r_s = 0.110 -- square half width
r_c = 0.06 -- circle radius
d_hole = 0.060  -- hole depth

a = 0.350       -- Pitch
r_s = 0.110 -- square half width
r_c = 0.06 -- circle radius
d_hole = 0.060  -- hole depth
-- r = 0

theta = 45      -- incident angle
phi = 0
-- Open a file in write mode
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

-- Write the header specifying the columns
-- file:write("freq\tforward\tbackward\n")

local N = 9
for i=0,N do
    local freq = f0_start + i*(f0_end - f0_start)/N
    print(string.format("Running freq point %d / %d: %.6f", i, N, freq))
-- for freq=f0_start,f0_end,0.07 do
    ::continue::

    local f0 = freq
    local n_interp = nil
    local k_interp = nil

    for i = 1, #f0_nk_data - 1 do
        local f0_a, n_a, k_a = table.unpack(f0_nk_data[i])
        local f0_b, n_b, k_b = table.unpack(f0_nk_data[i + 1])

        if f0_a <= f0 and f0 <= f0_b then
            n_interp = interp(f0, f0_a, f0_b, n_a, n_b)
            k_interp = interp(f0, f0_a, f0_b, k_a, k_b)
            break
        end
    end

    -- If outside interpolation range, skip this frequency
    if n_interp == nil or k_interp == nil then
        print(string.format("Skipping freq %.4f (outside interpolation range)", f0))
        goto continue
    end
    
    local eps_real = n_interp^2 - k_interp^2
    local eps_imag = 2 * n_interp * k_interp
    print(string.format("n = %.4f, k = %.4f, eps_r = %.4f, eps_i = %.4f",
      n_interp, k_interp, eps_real, eps_imag))

    S = S4.NewSimulation()

    S:SetLattice({a,0}, {0,a})
    S:SetNumG(100)

    S:AddMaterial("Silicon", {12.1,0}) 
    S:AddMaterial("SiO2", {1.45,0}) 
    S:AddMaterial("Vacuum", {1,0})
    S:AddMaterial("PerfMirror", {-1.0e10,0})
    S:AddMaterial("PbTaSe2", {eps_real, eps_imag}) -- isotropic version

    -- Structure
    S:AddLayer('AirAbove',  -- layer name
            0,           -- thickness
            'Vacuum')    -- background material
    -- Lattice of squares with holes in them:
    S:AddLayer('PhC', d_hole, 'Vacuum')
    S:SetLayerPatternRectangle('PhC', 
                                'PbTaSe2',
                                {0,0}, 
                                0, 
                                {r_s,r_s})
    S:SetLayerPatternCircle('PhC',   -- which layer to alter
                            'Vacuum', -- material in circle
                            {0,0},    -- center
                            r_c)      -- radius
    -- Lattice of cut out squares with circles in them:
    -- S:AddLayer('PhC', d_hole, 'PbTaSe2')
    -- S:SetLayerPatternRectangle('PhC', 
    --                             'Vacuum',
    --                             {0,0}, 
    --                             0, 
    --                             {r_s,r_s})
    -- S:SetLayerPatternCircle('PhC',   -- which layer to alter
    --                         'PbTaSe2', -- material in circle
    --                         {0,0},    -- center
    --                         r_c)      -- radius

    S:AddLayer('ActiveSlab', d_flake-d_hole, 'PbTaSe2')
    -- If on a SiO2 on Si wafer:
    S:AddLayer('SiO2', 0.3, 'SiO2') -- layer to copy
    S:AddLayer('SiWafer', 0, 'Silicon') -- layer to copy

    S:SetFrequency(freq)
    
    S:SetExcitationPlanewave(
    {theta, phi},
    {1/math.sqrt(2), 0},       -- s-pol amplitude, phase 0
    {1/math.sqrt(2), 0}       -- p-pol amplitude, phase +90 deg
    )

	forward,backward = S:GetPoyntingFlux('AirAbove', 0)
    -- fw1, bw1 = S:GetPoyntingFlux('ActiveSlab', 0)
    -- fw1, bw1 = S:GetPoyntingFlux('PhC', 0)
    fw1, bw1 = S:GetPoyntingFlux('PhC', 0)
    fw2, bw2 = S:GetPoyntingFlux('ActiveSlab', d_flake-d_hole)
    -- fw2, bw2 = S:GetPoyntingFlux('SiO2', 0)
    A = abs((fw2-fw1-(bw1-bw2))/forward)
	-- print (freq .. '\t' .. backward .. '\t' .. A)
    file:write(string.format("%.6f\t%.6f\t%.6f\n", freq, -backward, A))
    -- file:write(string.format("%.6f\t%.6f\t%.6f\n", freq, eps_real, eps_imag))
    --file:write(string.format("%.6f\t%.6f\t%.6f\n", freq, n_interp, k_interp))
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

