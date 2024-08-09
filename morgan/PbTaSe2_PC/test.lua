-- Initialize S4 with lattice vectors and number of Fourier harmonics
S = S4.NewSimulation()
S:SetLattice({1, 0}, {0, 1})
S:SetNumG(1)  -- Use a small number for simplicity, adjust as needed

-- Define materials
S:AddMaterial("Dielectric", {4, 0})  -- Example permittivity: real part 4, imaginary part 0
S:AddMaterial("Air", {1, 0})         -- Vacuum (air) permittivity: real part 1, imaginary part 0

-- Add layers: Air (above) and Dielectric (below)
S:AddLayer('Air', 0, 'Air')        -- Air layer with 0 thickness (effectively just an interface)
S:AddLayer('Dielectric', 1, 'Dielectric')  -- Dielectric layer with non-zero thickness

-- Set the frequency
S:SetFrequency(1)  -- Adjust frequency as needed

-- Loop over angles and calculate reflection and transmission coefficients
for angle = 0, 90, 1 do
    -- Set excitation for s-polarization
    S:SetExcitationPlanewave(
        {angle, 0}, -- incidence angles (phi in [0,180], theta in [0,360])
        {1, 0},     -- s-polarization amplitude and phase (in degrees)
        {0, 0}      -- p-polarization amplitude and phase
    )
    inc1, backward1 = S:GetPoyntingFlux('Air', 0)
    forward1 = S:GetPoyntingFlux('Dielectric', 0)

    -- Normalize flux values
    if inc1 ~= 0 then
        backward1 = -backward1 / inc1
        forward1 = forward1 / inc1
    else
        backward1 = 0
        forward1 = 0
    end

    -- Set excitation for p-polarization
    S:SetExcitationPlanewave(
        {angle, 0}, -- incidence angles (phi in [0,180], theta in [0,360])
        {0, 0},     -- s-polarization amplitude and phase (in degrees)
        {1, 0}      -- p-polarization amplitude and phase
    )
    inc2, backward2 = S:GetPoyntingFlux('Air', 0)
    forward2 = S:GetPoyntingFlux('Dielectric', 0)

    -- Normalize flux values
    if inc2 ~= 0 then
        backward2 = -backward2 / inc2
        forward2 = forward2 / inc2
    else
        backward2 = 0
        forward2 = 0
    end

    -- Print results
    print(string.format("%d\t%.6f\t%.6f\t%.6f\t%.6f", angle, forward1, backward1, forward2, backward2))
end
