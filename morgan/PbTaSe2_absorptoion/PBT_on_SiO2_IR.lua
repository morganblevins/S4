-- Reflection spectra comparison: PbTaSe2 structure with/without patterning
-- Uses S4 (Lua) with frequency-dependent permittivity

function generate_filename()
    local datetime_string = os.date("%Y-%m-%d_%H-%M-%S")
    local year, month, day, hour, min, sec = datetime_string:match("(%d+)-(%d+)-(%d+)_(%d+)-(%d+)-(%d+)")
    local filename = "PBT_on_SiO2".. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. ".txt"
    return filename
end

function abs(x)
    if x < 0 then
        return -x
    else
        return x
    end
end

-- Linear interpolation function
function interpolate(freq, freq_array, data_array)
    local n = #freq_array
    
    -- Handle edge cases
    if freq <= freq_array[1] then
        return data_array[1]
    end
    if freq >= freq_array[n] then
        return data_array[n]
    end
    
    -- Find the two points to interpolate between
    for i = 1, n-1 do
        if freq >= freq_array[i] and freq < freq_array[i+1] then
            local t = (freq - freq_array[i]) / (freq_array[i+1] - freq_array[i])
            return data_array[i] + t * (data_array[i+1] - data_array[i])
        end
    end
    
    return data_array[n]
end

-- ============================================
-- FREQUENCY-DEPENDENT DATA
-- ============================================

-- Frequency array (in reduced units: f/c*unit)
-- Covers 7-13 µm wavelength range
frequencies = {
    0.05,0.0673469,0.0846939,0.102041,0.119388,0.136735,0.154082,0.171429,0.188776,0.206122,0.223469,0.240816,0.258163,0.27551,0.292857,0.310204,0.327551,0.344898,0.362245,0.379592,0.396939,0.414286,0.431633,0.44898,0.466327,0.483673,0.50102,0.518367,0.535714,0.553061,0.570408,0.587755,0.605102,0.622449,0.639796,0.657143,0.67449,0.691837,0.709184,0.726531,0.743878,0.761224,0.778571,0.795918,0.813265,0.830612,0.847959,0.865306,0.882653,0.9
}

-- epsxxr array (real part of epsilon_xx) - METALLIC behavior
-- Negative real part indicates metallic response
epsxxr_data = {
    -116.896,-68.5138,-46.7273,-39.4755,-38.5469,-39.4689,-40.2084,-40.0718,-38.9995,-37.1731,-34.8292,-32.1806,-29.3937,-26.5882,-23.844,-21.2113,-18.719,-16.3815,-14.2029,-12.1811,-10.3101,-8.58169,-6.98652,-5.51499,-4.15724,-2.90396,-1.74634,-0.676184,0.313978,1.23118,2.0818,2.87159,3.60579,4.28912,4.92586,5.51997,6.07496,6.59403,7.08008,7.53569,7.96329,8.36505,8.74293,9.09874,9.4341,9.75048,10.0493,10.3317,10.599,10.8521
}

-- epsxxi array (imaginary part of epsilon_xx) - METALLIC behavior
-- Large imaginary part indicates strong absorption/metallic behavior
epsxxi_data = {
    389.302,274.076,218.32,184.058,158.216,136.458,117.481,100.907,86.5622,74.2688,63.8128,54.9621,47.489,41.1794,35.8462,31.3287,27.4912,24.221,21.4238,19.0219,16.9516,15.16,13.6039,12.2474,11.0603,10.0178,9.09915,8.28695,7.56669,6.92594,6.35421,5.84263,5.38364,4.97078,4.59852,4.26201,3.95712,3.68028,3.42837,3.19871,2.9889,2.79686,2.62076,2.459,2.31018,2.17304,2.04645,1.92943,1.8211,1.72067
}

-- epsyyr array (real part of epsilon_yy) - DIELECTRIC behavior
-- Positive real part indicates dielectric response
epsyyr_data = {
    7.18407,10.9526,12.8261,13.8753,14.5175,14.9376,15.2268,15.4342,15.5879,15.705,15.7961,15.8684,15.9267,15.9744,16.0139,16.0471,16.0751,16.099,16.1196,16.1375,16.153,16.1667,16.1787,16.1894,16.1989,16.2074,16.215,16.2219,16.2282,16.2338,16.239,16.2437,16.248,16.2519,16.2555,16.2589,16.262,16.2648,16.2675,16.27,16.2723,16.2744,16.2764,16.2783,16.28,16.2817,16.2832,16.2847,16.2861,16.2873
}

-- epsyyi array (imaginary part of epsilon_yy) - DIELECTRIC behavior
-- Small imaginary part indicates low loss/dielectric behavior
epsyyi_data = {
    50.3967,36.1188,28.2222,23.1953,19.7058,17.1379,15.1674,13.6063,12.3382,11.2874,10.4023,9.64637,8.99334,8.42335,7.92147,7.47615,7.07833,6.72082,6.39776,6.10437,5.83674,5.59162,5.36629,5.15845,4.96612,4.78763,4.62153,4.46658,4.3217,4.18593,4.05843,3.93848,3.82541,3.71866,3.61772,3.52211,3.43143,3.3453,3.26338,3.1854,3.11105,3.04009,2.9723,2.90747,2.8454,2.78594,2.72891,2.67416,2.62157,2.57101
}


freq_sio2 = {
    0.0656858,0.0672607,0.0688356,0.0704105,0.0719855,0.0735604,0.0751353,0.0767102,0.0782852,0.0798601,0.081435,0.0830099,0.0845849,0.0861598,0.0877347,0.0893097,0.0908846,0.0924595,0.0940344,0.0956094,0.0971843,0.0987592,0.100334,0.101909,0.103484,0.105059,0.106634,0.108209,0.109784,0.111359,0.112934,0.114508,0.116083,0.117658,0.119233,0.120808,0.122383,0.123958,0.125533,0.127108,0.128683,0.130258,0.131833,0.133408,0.134983,0.136557,0.138132,0.139707,0.141282,0.142857
}
eps_sio2_r_data = {2.48236,2.64418,2.82546,3.03117,3.25466,3.46338,3.59969,3.60171,3.44488,3.18604,2.9397,2.81026,2.85137,3.02528,3.27053,3.52953,3.77455,4.00776,4.24887,4.53967,4.95269,5.62469,6.56476,7.34518,6.93125,4.7406,1.98767,-1.15388,-4.69205,-4.46363,-2.62588,-1.52576,-0.962648,-0.652339,-0.473968,-0.345546,-0.218418,-0.0704816,0.0952053,0.265016,0.424676,0.565246,0.686268,0.789047,0.877429,0.954145,1.02143,1.08138,1.1349,1.18331
}
eps_sio2_i_data = {0.205631,0.16699,0.148009,0.16613,0.24598,0.4146,0.675198,0.981051,1.23704,1.35105,1.27538,1.06865,0.828097,0.647429,0.568133,0.580687,0.655575,0.763813,0.884576,1.00827,1.15309,1.45049,2.23224,4.00722,6.63112,8.79383,9.48919,9.5898,6.79764,2.67914,1.23207,0.951955,0.896371,0.853082,0.773157,0.649014,0.497363,0.346259,0.219339,0.128851,0.0708775,0.0383501,0.0205998,0.0113757,0.00637957,0.00360946,0.00203161,0.00112005,0.000608552,0.000318878
}

-- ============================================
-- END OF DATA INPUT SECTION
-- ============================================

-- units / geometry
c_const = 3e8
unit = 1e-6

lbda_end   = 13e-6 -- wavelength in [m]
lbda_start = 7e-6 -- wavelength in [m]

f_start = c_const/lbda_end
f_end = c_const/lbda_start
f0_start = f_start/c_const*unit
f0_end = f_end/c_const*unit
print (f0_start .. '\t' .. f0_end )

theta = 0

d_flake = 0.200
d_sio2 = 0.300
d_air = 0.400
d_step = 0.360

a = 1

-- Static permittivities for epszz
epszzr = 18
epszzi = 0

-- Other permittivities
n_si = 3.41
k_si = 0.0001
eps_si_r = n_si*n_si - k_si*k_si
eps_si_i = 2*n_si*k_si

n_sio2 = 1.74
k_sio2 = 0.74
eps_sio2_r = n_sio2*n_sio2 - k_sio2*k_sio2
eps_sio2_i = 2*n_sio2*k_sio2

-- Open output file
local filen = generate_filename()
local filename = "/home/mo/S4/morgan/" .. filen
local file = io.open(filename, "w")

-- Main frequency loop
for freq=f0_start,f0_end,0.0025 do
    local wavelength_nm = unit*1e9 / freq
    
    -- Get frequency-dependent permittivity values via interpolation
    local epsxxr = interpolate(freq, frequencies, epsxxr_data)
    local epsxxi = interpolate(freq, frequencies, epsxxi_data)
    local epsyyr = interpolate(freq, frequencies, epsyyr_data)
    local epsyyi = interpolate(freq, frequencies, epsyyi_data)

    local eps_sio2_r = interpolate(freq, freq_sio2, eps_sio2_r_data)
    local eps_sio2_i = interpolate(freq, freq_sio2, eps_sio2_i_data)
    
    -- -------------------------
    -- Build patterned simulation (uses epsilon_xx - METALLIC)
    S_pat = S4.NewSimulation()
    S_pat:SetLattice({a,0},{0,a})
    S_pat:SetNumG(100)
    S_pat:AddMaterial("Silicon1", {eps_si_r,eps_si_i}) 
    S_pat:AddMaterial("SiO21", {eps_sio2_r,eps_sio2_i}) 
    S_pat:AddMaterial("Vacuum1", {1,0})
    S_pat:SetMaterial("PbTaSe21",{epsxxr, epsxxi})
    S_pat:AddLayer("AirAbove1", 0, "Vacuum1")
    S_pat:AddLayer("ActiveSlab1", d_flake, "PbTaSe21")
    S_pat:AddLayer("SiO21", 0.3, "SiO21")
    S_pat:AddLayer("SiWafer1", 0, "Silicon1")
    S_pat:SetExcitationPlanewave(
            {theta, 0},
            {0, 0},
            {1, 0})
    
    S_pat:SetFrequency(freq)
    forward1,backward1 = S_pat:GetPoyntingFlux('AirAbove1', 0)
    fw1, bw1 = S_pat:GetPoyntingFlux('ActiveSlab1', 0)
    fw2, bw2 = S_pat:GetPoyntingFlux('ActiveSlab1', d_flake)
    A1 = abs((fw2-fw1-(bw1-bw2))/forward1)
    
    -- -------------------------
    -- Build flat simulation (uses epsilon_yy - DIELECTRIC)
    S_flat = S4.NewSimulation()
    S_flat:SetLattice({a,0},{0,a})
    S_flat:SetNumG(100)
    S_flat:AddMaterial("Silicon2", {eps_si_r,eps_si_i}) 
    S_flat:AddMaterial("SiO22", {eps_sio2_r,eps_sio2_i}) 
    S_flat:AddMaterial("Vacuum2", {1,0})
    S_flat:SetMaterial("PbTaSe22", {epsyyr, epsyyi})
    S_flat:AddLayer("AirAbove2", 0, "Vacuum2")
    S_flat:AddLayer("ActiveSlab2", d_flake, "PbTaSe22")
    S_flat:AddLayer("SiO22", 0.3, "SiO22")
    S_flat:AddLayer("SiWafer2", 0, "Silicon2")
    S_flat:SetExcitationPlanewave(
            {theta, 0},
            {0, 0},
            {1, 0})
    
    S_flat:SetFrequency(freq)
    forward2,backward2 = S_flat:GetPoyntingFlux('AirAbove2', 0)
    fw1, bw1 = S_flat:GetPoyntingFlux('ActiveSlab2', 0)
    fw2, bw2 = S_flat:GetPoyntingFlux('ActiveSlab2', d_flake)
    A2 = abs((fw2-fw1-(bw1-bw2))/forward2)
    
    -- Write results
    ratio = A2/A1
    file:write(string.format("%.1f\t%.6f\t%.6f\t%.6f\n", wavelength_nm, A1, A2, ratio))
end

print("Generated filename:", filename)
file:close()

-- Execute Python plotting script
local pythonScript = "morgan/plotdata.py"
local command = "python3 " .. pythonScript .. " " .. filename
local status = os.execute(command)

if status == true then
    print("Python script executed successfully.")
else
    print("Error executing Python script.")
end